import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_providers.dart';
import '../api/paperless_api.dart';
import '../api/upload_retry_policy.dart';
import '../auth/auth_provider.dart';
import '../database/app_database.dart';
import '../database/cache_provider.dart';
import '../database/cache_repository.dart';
import 'connectivity_service.dart';
import 'pending_upload_store.dart';
import 'upload_decision.dart';

part 'upload_queue_service.g.dart';

@Riverpod(keepAlive: true)
class UploadQueueService extends _$UploadQueueService {
  bool _draining = false;
  bool _drainRequested = false;

  /// The drain currently in flight, if any.
  ///
  /// Every trigger is deliberately fire-and-forget, which leaves tests nothing
  /// to await — they used to poll on a wall clock, so a slow CI runner failed
  /// with "expected [x], got []", indistinguishable from a real regression.
  Future<void>? _activeDrain;

  @visibleForTesting
  Future<void>? get debugActiveDrain => _activeDrain;

  @override
  void build() {
    ref.listen(connectivityNotifierProvider, (previous, next) {
      if (previous == false && next == true) {
        _activeDrain = _drainQueue();
      }
    });

    // Connectivity edges alone are not enough. A share queued because no
    // server was configured yet would sit untouched until an unrelated network
    // blip happened to fire — configuring the server, or simply relaunching
    // the app, has to be enough to flush it.
    ref.listen(authStateProvider, (previous, next) {
      final wasAuthenticated = previous?.valueOrNull?.isAuthenticated ?? false;
      final isAuthenticated = next.valueOrNull?.isAuthenticated ?? false;
      if (!wasAuthenticated && isAuthenticated) {
        // Deferred a turn on purpose. dioProvider throws while unauthenticated,
        // and Riverpod serves that cached error to dependents
        // until the invalidation from this very state change propagates —
        // draining synchronously here reads the stale error and gives up.
        _activeDrain = Future.microtask(_drainQueue);
      }
    });

    _activeDrain = Future.microtask(_drainQueue);
  }

  /// Retries every queued upload now. Safe to call at any time — a drain
  /// already in flight is a no-op.
  Future<void> drainNow() => _drainQueue();

  /// How long the drain keeps retrying a queued upload before giving up on it.
  ///
  /// Four ways a row stops being acted on, and all of them need a stop:
  ///  - terminally failed, so the drain skips it;
  ///  - its server is unreachable, which deliberately does not consume retries;
  ///  - it belongs to another profile, possibly one since deleted;
  ///  - no server is configured at all, so the upload pass never starts.
  ///
  /// The last one is why the sweep runs before the API is resolved rather than
  /// as a guard inside the upload loop.
  ///
  /// Expiring a row records an outcome, visible on the upload queue screen
  /// with its `lastError`, Retry and Delete — that screen shipped in v1.2.0,
  /// which is what makes releasing the file here defensible: a row the sweep
  /// got wrong is no longer a silent, permanent loss, it is a row the user can
  /// see and undo with Retry.
  ///
  /// [DateTime.now] is still not monotonic, and that risk survives the queue
  /// screen: a device clock jump can make a row LOOK 30 days old when it is
  /// really hours old, and the file itself does not come back just because the
  /// user can now see what happened to it. [_confirmationWindow] is the
  /// mitigation — see its doc for what it does and does not close.
  static const _retention = Duration(days: 30);

  /// How long a row must stay observed-expired before its file is released.
  ///
  /// [_giveUpIfExpired] never releases a file on the same sweep that first
  /// notices a row has outlived [_retention] — it only records `expiredAt` and
  /// stops. The file is released on a LATER sweep, once `expiredAt` is itself
  /// at least this old.
  ///
  /// This defeats a single bad [DateTime.now] read: one glitched sample marks
  /// a row failed (recoverable — Retry clears it) but cannot delete anything,
  /// because deletion needs a second, later sample that still agrees. It does
  /// NOT defeat a clock that is wrong and stays wrong: two consistent-but-wrong
  /// readings 24 hours apart still agree with each other. A 45-day forward
  /// jump is indistinguishable from 45 days elapsed either way — this narrows
  /// that hole to a sustained clock fault, it does not close it.
  static const _confirmationWindow = Duration(hours: 24);

  /// Gives up on a row that has outlived [_retention], and releases its file
  /// once that has held for a further [_confirmationWindow].
  ///
  /// Returns true when the row was handled and the caller should move on. The
  /// row itself is never deleted here — only its file, and only once — because
  /// deleting the row too is how a document disappears with no trace.
  Future<bool> _giveUpIfExpired(
    CacheRepository cache,
    PendingUpload upload,
  ) async {
    final now = DateTime.now();
    if (now.difference(upload.queuedAt) < _retention) return false;

    final expiredAt = upload.expiredAt;
    if (expiredAt == null) {
      // First sweep to see this row past retention. Record it and stop — see
      // [_confirmationWindow] for why nothing is released yet.
      await cache.markUploadExpired(
        upload.id,
        now,
        'Gave up after ${_retention.inDays} days without reaching the server.',
      );
      return true;
    }

    // Not confirmed yet: either this sweep runs on a clock that looks earlier
    // than the one that recorded expiredAt (untrustworthy either way), or not
    // enough time has passed since the first observation.
    if (now.isBefore(expiredAt) ||
        now.difference(expiredAt) < _confirmationWindow) {
      return true;
    }

    if (!await File(upload.filePath).exists()) {
      // Already released on a previous sweep, or never had a file. Nothing to
      // do — avoids rewriting the row on every sweep forever.
      return true;
    }

    final store = await ref.read(pendingUploadStoreProvider.future);
    try {
      await store.discard(upload.filePath);
    } on FileSystemException catch (_) {
      // Already gone; nothing left to release.
    }
    await cache.markUploadFailed(
      upload.id,
      'This file sat in the upload queue for over ${_retention.inDays} days '
      'without reaching the server, and has been deleted from this device.',
    );
    return true;
  }

  /// Drains until nothing new has been requested.
  ///
  /// A loop rather than tail recursion: a share enqueued during every pass
  /// would otherwise grow the stack one frame per pass with no bound.
  Future<void> _drainQueue() async {
    if (_draining) {
      _drainRequested = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainRequested = false;
        await _drainOnce();
      } while (_drainRequested);
    } finally {
      _draining = false;
    }
  }

  Future<void> _drainOnce() async {
    try {
      final cache = ref.read(cacheRepositoryProvider);
      final store = await ref.read(pendingUploadStoreProvider.future);
      final pending = await cache.getPendingUploads();

      // The retention sweep is a separate pass, ahead of resolving the API on
      // purpose. Anything that stops the drain acting on a row also stops that
      // row's outcome ever being recorded, and the biggest of those is having
      // no server at all: as a guard inside the upload pass, retention never
      // ran for a signed-out user, whose queue then grew without record.
      final live = <PendingUpload>[];
      for (final upload in pending) {
        try {
          if (await _giveUpIfExpired(cache, upload)) continue;
        } catch (e) {
          // One unreadable row must not strand the sweep for every row behind
          // it — the whole point of the sweep is that it always runs.
          //
          // Catches Error as well as Exception, deliberately: the likeliest
          // escapee is a Drift StateError, which `on Exception` would let
          // through to the outer handler — abandoning every row behind this
          // one, which is exactly the boundary this block exists to draw.
          //
          // The assert-guard is NOT for the outer catch's reason. That one
          // hides a DioException, which stringifies with the user's
          // self-hosted server URL; a Drift StateError carries no such
          // payload. It is guarded only because a dropped row has nowhere
          // better to go until the queue has a UI and this can reach
          // `lastError`.
          assert(() {
            debugPrint('Upload queue retention skipped a row: $e');
            return true;
          }());
          continue;
        }
        live.add(upload);
      }

      final PaperlessApi api;
      try {
        api = ref.read(paperlessApiProvider);
      } catch (_) {
        // Not logged in — nothing to upload against, but the sweep above has
        // already run.
        return;
      }
      final activeServer = ref.read(authStateProvider).valueOrNull?.serverUrl;

      for (final upload in live) {
        // One row, one fault boundary. Everything below — the file check, the
        // bookkeeping writes, and the writes made from inside the send's own
        // catch — is inside it, because every one of them has abandoned the
        // rest of the queue at some point in this file's history.
        try {
          final decision = decideUpload(
            upload,
            activeServer: activeServer,
            fileExists: await File(upload.filePath).exists(),
          );
          switch (decision) {
            case SkipUpload():
              break;
            case FailUpload(:final reason):
              await cache.markUploadFailed(upload.id, reason);
            case SendUpload(:final tags):
              await _send(api, cache, store, upload, tags);
          }
        } catch (e) {
          assert(() {
            debugPrint('Upload queue skipped a row: $e');
            return true;
          }());
        }
      }
    } catch (e) {
      // Catches Error as well as Exception, deliberately. The drain is
      // fire-and-forget (a startup microtask, a ref.listen on the auth edge),
      // so anything escaping is an unhandled async error that kills the pass
      // silently — and the likeliest escapee is a StateError from a provider,
      // which `on Exception` does not catch. Queue rows are untouched by a
      // failed pass, so the next trigger retries them.
      //
      // Behind an assert: a DioException stringifies with the full request URL,
      // i.e. the user's self-hosted server address, which must not reach a
      // release logcat. Same rule friendlyApiMessage follows.
      assert(() {
        debugPrint('Upload queue drain aborted: $e');
        return true;
      }());
    }
  }

  /// How many attempts a row gets before the drain stops retrying it.
  static const _maxRetries = 5;

  /// Sends one row and records the outcome.
  ///
  /// Throws nothing the caller has to special-case: every failure lands in the
  /// caller's per-row boundary, including a bookkeeping write that fails while
  /// recording another failure.
  Future<void> _send(
    PaperlessApi api,
    CacheRepository cache,
    PendingUploadStore store,
    PendingUpload upload,
    List<int>? tags,
  ) async {
    // Last check before the bytes leave. The queue screen can delete a row
    // while this pass is running, and the drain is working from a snapshot
    // taken before the user tapped Delete — without this it would upload a
    // document the user has just told it to throw away.
    //
    // This NARROWS the window to the gap between here and the POST; it does
    // not close it. A send already in flight cannot be recalled without a
    // per-row CancelToken threaded through the API client, which is a larger
    // change. The residual outcome is an unwanted document on the server,
    // recoverable from its trash — not lost data.
    if (await cache.getPendingUpload(upload.id) == null) return;

    var uploaded = false;
    try {
      await api.uploadDocument(
        filePath: upload.filePath,
        filename: upload.filename,
        title: upload.title,
        correspondent: upload.correspondent,
        documentType: upload.documentType,
        tags: tags,
        created: upload.created,
      );

      // At-least-once, not exactly-once: if the process dies between the
      // server accepting this upload and the row being removed, the next
      // drain sends it again.
      //
      // That does NOT produce a duplicate document. Verified against a real
      // paperless-ngx 2.20: consumption is checksum-deduplicated, and the
      // second copy is rejected with
      //   "Not consuming <file>: It is a duplicate of <doc> (#N)"
      // so the re-upload costs one failed task on the server and nothing
      // else. Client-side checksum suppression would reimplement this.
      await cache.removePendingUpload(upload.id);
      uploaded = true;
    } catch (e) {
      if (isUnreachableServerError(e)) {
        // Says nothing about the document — offline, server unreachable, no
        // session. Consuming a retry here meant five launches out of signal
        // terminally failed a perfectly good upload, and the drain then
        // skipped it forever even once connectivity came back. Made worse
        // by ConnectivityNotifier optimistically reporting online until its
        // first real check lands, so the startup drain runs while offline.
        await cache.recordUploadError(upload.id, e.toString());
      } else {
        await cache.incrementRetryCount(
          upload.id,
          e.toString(),
          maxRetries: _maxRetries,
        );
      }
      return;
    }

    // Outside the try on purpose. The document is already on the server by
    // now, so a failure to delete our local copy is cosmetic — letting it
    // reach the catch above would retry an upload that already succeeded
    // against a row that no longer exists.
    if (uploaded) {
      try {
        await store.discard(upload.filePath);
      } on FileSystemException catch (_) {
        // Leftover file; harmless.
      }
    }
  }
}
