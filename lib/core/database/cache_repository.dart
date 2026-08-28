import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../models/correspondent.dart';
import '../models/custom_field.dart';
import '../models/document_type.dart';
import '../models/saved_view.dart';
import '../models/storage_path.dart';
import '../models/tag.dart';
import '../models/workflow.dart';
import 'app_database.dart';

class CacheRepository {
  final AppDatabase _db;

  CacheRepository(this._db);

  // Tags

  Future<Map<int, Tag>> getCachedTags() async {
    final rows = await _db.select(_db.cachedTags).get();
    return {
      for (final row in rows)
        row.id: Tag.fromJson(jsonDecode(row.jsonData) as Map<String, dynamic>),
    };
  }

  Future<void> cacheTags(Map<int, Tag> tags) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedTags);
      batch.insertAll(
        _db.cachedTags,
        tags.entries.map(
          (e) => CachedTagsCompanion.insert(
            id: Value(e.key),
            jsonData: jsonEncode(e.value.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Correspondents

  Future<Map<int, Correspondent>> getCachedCorrespondents() async {
    final rows = await _db.select(_db.cachedCorrespondents).get();
    return {
      for (final row in rows)
        row.id: Correspondent.fromJson(
          jsonDecode(row.jsonData) as Map<String, dynamic>,
        ),
    };
  }

  Future<void> cacheCorrespondents(Map<int, Correspondent> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedCorrespondents);
      batch.insertAll(
        _db.cachedCorrespondents,
        items.entries.map(
          (e) => CachedCorrespondentsCompanion.insert(
            id: Value(e.key),
            jsonData: jsonEncode(e.value.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Document Types

  Future<Map<int, DocumentType>> getCachedDocumentTypes() async {
    final rows = await _db.select(_db.cachedDocumentTypes).get();
    return {
      for (final row in rows)
        row.id: DocumentType.fromJson(
          jsonDecode(row.jsonData) as Map<String, dynamic>,
        ),
    };
  }

  Future<void> cacheDocumentTypes(Map<int, DocumentType> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedDocumentTypes);
      batch.insertAll(
        _db.cachedDocumentTypes,
        items.entries.map(
          (e) => CachedDocumentTypesCompanion.insert(
            id: Value(e.key),
            jsonData: jsonEncode(e.value.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Storage Paths

  Future<Map<int, StoragePath>> getCachedStoragePaths() async {
    final rows = await _db.select(_db.cachedStoragePaths).get();
    return {
      for (final row in rows)
        row.id: StoragePath.fromJson(
          jsonDecode(row.jsonData) as Map<String, dynamic>,
        ),
    };
  }

  Future<void> cacheStoragePaths(Map<int, StoragePath> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedStoragePaths);
      batch.insertAll(
        _db.cachedStoragePaths,
        items.entries.map(
          (e) => CachedStoragePathsCompanion.insert(
            id: Value(e.key),
            jsonData: jsonEncode(e.value.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Saved Views

  Future<List<SavedView>> getCachedSavedViews() async {
    final rows = await _db.select(_db.cachedSavedViews).get();
    return rows
        .map(
          (row) => SavedView.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> cacheSavedViews(List<SavedView> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedSavedViews);
      batch.insertAll(
        _db.cachedSavedViews,
        items.map(
          (e) => CachedSavedViewsCompanion.insert(
            id: Value(e.id),
            jsonData: jsonEncode(e.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Custom Fields

  Future<Map<int, CustomField>> getCachedCustomFields() async {
    final rows = await _db.select(_db.cachedCustomFields).get();
    return {
      for (final row in rows)
        row.id: CustomField.fromJson(
          jsonDecode(row.jsonData) as Map<String, dynamic>,
        ),
    };
  }

  Future<void> cacheCustomFields(Map<int, CustomField> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedCustomFields);
      batch.insertAll(
        _db.cachedCustomFields,
        items.entries.map(
          (e) => CachedCustomFieldsCompanion.insert(
            id: Value(e.key),
            jsonData: jsonEncode(e.value.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Workflows

  Future<List<Workflow>> getCachedWorkflows() async {
    final rows = await _db.select(_db.cachedWorkflows).get();
    return rows
        .map(
          (row) => Workflow.fromJson(
            jsonDecode(row.jsonData) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> cacheWorkflows(List<Workflow> items) async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedWorkflows);
      batch.insertAll(
        _db.cachedWorkflows,
        items.map(
          (e) => CachedWorkflowsCompanion.insert(
            id: Value(e.id),
            jsonData: jsonEncode(e.toJson()),
            cachedAt: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Pending Uploads

  Future<void> enqueueUpload({
    required String filePath,
    required String filename,
    String? serverUrl,
    String? title,
    int? correspondent,
    int? documentType,
    List<int>? tags,
    DateTime? created,
  }) async {
    await _db
        .into(_db.pendingUploads)
        .insert(
          PendingUploadsCompanion.insert(
            filePath: filePath,
            filename: filename,
            serverUrl: Value(serverUrl),
            title: Value(title),
            correspondent: Value(correspondent),
            documentType: Value(documentType),
            tagsJson: Value(tags != null ? jsonEncode(tags) : null),
            created: Value(created),
            queuedAt: DateTime.now(),
          ),
        );
  }

  /// Decodes queued rows one at a time, skipping any the mapper rejects.
  ///
  /// A plain `select(...).get()` decodes the whole result set as a unit, so a
  /// single corrupt row takes down the entire read — and SQLite makes that
  /// reachable: its column affinity accepts a text value in the `queued_at`
  /// INTEGER column, after which mapping throws
  /// `FormatException: Invalid radix-10 number`. Verified with a probe.
  ///
  /// One bad row would then kill the retention sweep AND the upload pass for
  /// every OTHER row, permanently, with the queue screen showing only "Could
  /// not read the queue". Per-row decoding is the same fault-boundary argument
  /// the drain already makes, applied one layer down.
  ///
  /// Skipped rows are counted, not silently dropped — see
  /// [countUnreadablePendingUploads]. A row that cannot be decoded still holds
  /// a file, and this queue's whole history is about not losing documents
  /// invisibly.
  List<PendingUpload> _decodeUploads(List<QueryRow> raw) {
    final rows = <PendingUpload>[];
    for (final row in raw) {
      try {
        rows.add(_db.pendingUploads.map(row.data));
      } catch (e) {
        assert(() {
          debugPrint('Skipping an undecodable pending_uploads row: $e');
          return true;
        }());
      }
    }
    return rows;
  }

  static const _pendingUploadsByIdSql =
      'SELECT * FROM pending_uploads ORDER BY id ASC';

  /// How many queued rows cannot be decoded at all.
  ///
  /// Zero in every healthy install. Non-zero means corrupt rows are holding
  /// files that nothing can act on, which the queue screen surfaces rather
  /// than leaving the user to wonder where their storage went.
  Future<int> countUnreadablePendingUploads() async {
    final raw = await _db
        .customSelect(_pendingUploadsByIdSql, readsFrom: {_db.pendingUploads})
        .get();
    return raw.length - _decodeUploads(raw).length;
  }

  /// Queued uploads, oldest first.
  ///
  /// Ordered by `id`, not `queuedAt`. Both are insertion-ordered in the normal
  /// case, but `queuedAt` is stamped from [DateTime.now], which is not
  /// monotonic — a device clock that moves backwards between two shares would
  /// sort the newer one first. `id` is autoIncrement and cannot go backwards.
  ///
  /// The order matters beyond tidiness: the drain processes this list in
  /// sequence, so without an ORDER BY "which upload is retried first" is
  /// whatever SQLite feels like returning. That also made the drain's
  /// fault-boundary tests unfalsifiable — a test proving "one bad row does not
  /// strand the row behind it" cannot be written when there is no defined
  /// behind.
  Future<List<PendingUpload>> getPendingUploads() async {
    return _decodeUploads(
      await _db
          .customSelect(_pendingUploadsByIdSql, readsFrom: {_db.pendingUploads})
          .get(),
    );
  }

  /// Live view of the queue, oldest first, for the queue screen and its badge.
  ///
  /// A stream rather than a one-shot read because the drain mutates these rows
  /// from outside any UI event — a retry that succeeds while the screen is open
  /// should remove the row, not leave a stale one the user can act on.
  Stream<List<PendingUpload>> watchPendingUploads() {
    return _db
        .customSelect(_pendingUploadsByIdSql, readsFrom: {_db.pendingUploads})
        .watch()
        .map(_decodeUploads);
  }

  /// Puts a terminally failed row back in play.
  ///
  /// Clears `isFailed`, the retry count and the recorded error together — a
  /// reset that left `retryCount` at its limit would be skipped again on the
  /// very next pass, and a stale `lastError` would keep describing a failure
  /// the user has explicitly asked to retry past.
  ///
  /// `queuedAt` is restamped for the same reason, and it is not cosmetic: the
  /// retention sweep runs BEFORE the upload pass, so a row that retention gave
  /// up on is still older than the window when the drain next looks at it. It
  /// would be re-failed without a single upload attempt, making Retry a
  /// guaranteed no-op on exactly the rows this screen exists to rescue.
  /// Restarting the clock is also the honest reading of the button: the user
  /// has just said they want this document delivered, so the countdown to
  /// giving up on it starts again from now.
  Future<void> resetUploadForRetry(int id) async {
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(
        isFailed: const Value(false),
        retryCount: const Value(0),
        lastError: const Value(null),
        // Clears the retention sweep's memory of this row too — otherwise a row
        // that expires again after a retry would be eligible for immediate file
        // release, skipping the confirmation window meant to guard against a
        // clock glitch.
        expiredAt: const Value(null),
        queuedAt: Value(DateTime.now()),
      ),
    );
  }

  /// One queued row, or null when it has since been removed.
  Future<PendingUpload?> getPendingUpload(int id) async {
    return (_db.select(
      _db.pendingUploads,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<PendingUpload>> getFailedUploads() async {
    return (_db.select(
      _db.pendingUploads,
    )..where((t) => t.isFailed.equals(true))).get();
  }

  Future<void> removePendingUpload(int id) async {
    await (_db.delete(_db.pendingUploads)..where((t) => t.id.equals(id))).go();
  }

  /// Marks an upload terminally failed without consuming a retry, for failures
  /// that retrying cannot fix (e.g. the queued file is gone). The row is kept
  /// rather than deleted so the failure stays on the record, visible on the
  /// upload queue screen with Retry and Delete.
  Future<void> markUploadFailed(int id, String error) async {
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(
        lastError: Value(error),
        isFailed: const Value(true),
      ),
    );
  }

  /// Records that the retention sweep has observed [id] past its window, for
  /// the first time, without releasing its file yet.
  ///
  /// See `UploadQueueService._giveUpIfExpired`: the file is only released on a
  /// later sweep, once [expiredAt] is itself far enough in the past.
  Future<void> markUploadExpired(
    int id,
    DateTime expiredAt,
    String error,
  ) async {
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(
        lastError: Value(error),
        isFailed: const Value(true),
        expiredAt: Value(expiredAt),
      ),
    );
  }

  /// Records why an attempt failed without counting it against the retry
  /// budget. For failures that say nothing about the document — offline, server
  /// unreachable, not signed in — where consuming a retry would let five
  /// launches in a tunnel terminally fail a perfectly good upload.
  Future<void> recordUploadError(int id, String error) async {
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(lastError: Value(error)),
    );
  }

  /// Records a failed upload attempt. Once [maxRetries] is reached the
  /// upload is marked terminally failed so the drain loop stops retrying it
  /// silently forever. Surfacing those rows still needs a queue UI.
  Future<void> incrementRetryCount(
    int id,
    String error, {
    required int maxRetries,
  }) async {
    final row = await (_db.select(
      _db.pendingUploads,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    // Already removed (a concurrent drain finished it) — nothing to record.
    if (row == null) return;
    final newRetryCount = row.retryCount + 1;
    await (_db.update(_db.pendingUploads)..where((t) => t.id.equals(id))).write(
      PendingUploadsCompanion(
        retryCount: Value(newRetryCount),
        lastError: Value(error),
        isFailed: Value(newRetryCount >= maxRetries),
      ),
    );
  }

  // Clear

  /// Drops everything mirrored from a server. Used on logout and when
  /// switching server profiles.
  ///
  /// Deliberately leaves [PendingUploads] alone: a queued upload is a document
  /// the user handed us that has not reached any server yet, so it is their
  /// data, not server cache. Clearing it here used to mean that fixing an
  /// unreachable server — which goes through logout — destroyed the very
  /// uploads that were waiting on that fix.
  Future<void> clearServerCache() async {
    await _db.batch((batch) {
      batch.deleteAll(_db.cachedDocuments);
      batch.deleteAll(_db.cachedTags);
      batch.deleteAll(_db.cachedCorrespondents);
      batch.deleteAll(_db.cachedDocumentTypes);
      batch.deleteAll(_db.cachedStoragePaths);
      batch.deleteAll(_db.cachedSavedViews);
      batch.deleteAll(_db.cachedCustomFields);
      batch.deleteAll(_db.cachedWorkflows);
    });
  }

  /// Server cache *and* the pending-upload queue. For a full local wipe only —
  /// callers must discard the queued files themselves, or they are orphaned in
  /// app storage with no row left to reference them.
  Future<void> clearAll() async {
    await clearServerCache();
    await _db.delete(_db.pendingUploads).go();
  }
}
