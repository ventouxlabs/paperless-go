import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';

part 'document_lock_service.g.dart';

class DocumentLockService {
  final AppDatabase _db;

  DocumentLockService(this._db);

  Future<bool> isLocked(int documentId) async {
    final row = await (_db.select(_db.lockedDocuments)
          ..where((t) => t.documentId.equals(documentId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> lock(int documentId) async {
    await _db.into(_db.lockedDocuments).insertOnConflictUpdate(
          LockedDocumentsCompanion.insert(documentId: Value(documentId)),
        );
  }

  Future<void> unlock(int documentId) async {
    await (_db.delete(_db.lockedDocuments)
          ..where((t) => t.documentId.equals(documentId)))
        .go();
  }

  Future<Set<int>> getLockedIds() async {
    final rows = await _db.select(_db.lockedDocuments).get();
    return rows.map((r) => r.documentId).toSet();
  }
}

@Riverpod(keepAlive: true)
DocumentLockService documentLockService(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return DocumentLockService(db);
}

/// IDs of all documents behind a per-document lock. Invalidate after
/// lock/unlock so list views and thumbnails update.
final lockedDocumentIdsProvider = FutureProvider<Set<int>>((ref) {
  return ref.watch(documentLockServiceProvider).getLockedIds();
});
