import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/database/cache_provider.dart';
import '../../core/services/pending_upload_store.dart';
import '../../core/services/upload_queue_service.dart';
import 'queue_row_status.dart';

part 'upload_queue_notifier.g.dart';

/// Every queued upload, live.
@riverpod
Stream<List<PendingUpload>> pendingUploads(Ref ref) {
  return ref.watch(cacheRepositoryProvider).watchPendingUploads();
}

/// How many rows need the user to do something.
///
/// Drives the Settings badge and the inbox banner, and deliberately counts only
/// failed and legacy rows — a queue of uploads waiting for signal is normal and
/// interrupting someone about it would train them to ignore the badge.
@riverpod
int uploadsNeedingAttention(Ref ref) {
  final rows = ref.watch(pendingUploadsProvider).valueOrNull ?? const [];
  final activeServer = ref.watch(authStateProvider).valueOrNull?.serverUrl;
  return rows
      .where((r) =>
          queueRowNeedsAttention(queueRowStatus(r, activeServer: activeServer)))
      .length;
}

/// How many rows are simply waiting their turn (queued, retrying on
/// schedule, or mid-upload) — everything that is not in
/// [uploadsNeedingAttention].
///
/// Hand-written rather than @riverpod: code generation cannot run on this
/// toolchain (see export_destination_providers.dart).
final uploadsWaitingProvider = Provider<int>((ref) {
  final rows = ref.watch(pendingUploadsProvider).valueOrNull ?? const [];
  return rows.length - ref.watch(uploadsNeedingAttentionProvider);
});

/// Queued rows the app cannot decode at all.
///
/// Zero in every healthy install. Non-zero means corrupt rows are holding files
/// that nothing can act on — invisible storage, which is the failure mode this
/// whole screen exists to end.
@riverpod
Future<int> unreadableUploads(Ref ref) {
  // Rebuilds with the queue so clearing rows updates the notice.
  ref.watch(pendingUploadsProvider);
  return ref.watch(cacheRepositoryProvider).countUnreadablePendingUploads();
}

/// Actions the queue screen can take on a row.
///
/// Separate from [UploadQueueService], which owns the drain. This is the user
/// asking for something; that is the app deciding on its own. Keeping them
/// apart means a retry button cannot accidentally change drain policy.
@riverpod
class UploadQueueActions extends _$UploadQueueActions {
  @override
  void build() {}

  /// Clears the failure state and immediately drains.
  ///
  /// Draining here rather than waiting for the next trigger is the whole point
  /// of the button: the user pressed retry because they believe the problem is
  /// fixed, and an app that agreed and then did nothing visible for an hour
  /// would read as broken.
  Future<void> retry(PendingUpload upload) async {
    await ref.read(cacheRepositoryProvider).resetUploadForRetry(upload.id);
    await ref.read(uploadQueueServiceProvider.notifier).drainNow();
  }

  /// Deletes a queued upload and its file.
  ///
  /// This destroys the user's only copy of that document — the file was moved
  /// into app-private storage precisely because nothing else holds it. Callers
  /// MUST confirm first; nothing in here asks.
  Future<void> delete(PendingUpload upload) async {
    final store = await ref.read(pendingUploadStoreProvider.future);
    // Row first. A file deleted without its row removed leaves a queue entry
    // pointing at nothing, which the drain then marks failed for a reason that
    // has nothing to do with why the user pressed delete.
    await ref.read(cacheRepositoryProvider).removePendingUpload(upload.id);
    try {
      await store.discard(upload.filePath);
    } on FileSystemException catch (_) {
      // The row is gone, which is what the user asked for. A leftover file is
      // reclaimed when the app's data is cleared.
    }
  }

  /// Deletes every terminally failed row and its file.
  ///
  /// Only `isFailed` rows: anything still retrying might yet succeed, and a
  /// bulk action that quietly swept those up would destroy documents the user
  /// never chose to give up on.
  /// Returns how many were actually deleted, which is not always how many were
  /// tried: a row whose delete throws stays in the queue, and reporting it as
  /// cleared would have the snackbar claim a number the user can see is wrong
  /// on the list behind it.
  Future<int> clearFailed() async {
    final rows = await ref.read(cacheRepositoryProvider).getFailedUploads();
    var deleted = 0;
    for (final row in rows) {
      // Per row, so one failure does not abandon the rest of the sweep.
      try {
        await delete(row);
        deleted++;
      } catch (_) {
        continue;
      }
    }
    return deleted;
  }
}
