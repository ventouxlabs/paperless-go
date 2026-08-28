import 'package:drift/drift.dart';

part 'app_database.g.dart';

class CachedDocuments extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedTags extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCorrespondents extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedDocumentTypes extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedStoragePaths extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSavedViews extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedCustomFields extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedWorkflows extends Table {
  IntColumn get id => integer()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingUploads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get filePath => text()();
  TextColumn get filename => text()();
  TextColumn get title => text().nullable()();
  IntColumn get correspondent => integer().nullable()();
  IntColumn get documentType => integer().nullable()();
  TextColumn get tagsJson => text().nullable()();
  DateTimeColumn get created => dateTime().nullable()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get isFailed => boolean().withDefault(const Constant(false))();

  /// The server this upload was queued for.
  ///
  /// Without it the drain sends every pending row to whatever server happens to
  /// be active. Switching profiles emits an unauthenticated->authenticated edge,
  /// which triggers a drain, so documents queued for account A were uploaded to
  /// account B. Nullable only because rows predating this column exist; the
  /// drain refuses to send those rather than guess.
  TextColumn get serverUrl => text().nullable()();

  /// When the retention sweep first observed this row past its window, or null
  /// if it never has been.
  ///
  /// Deliberately separate from `queuedAt`: the file is not released the
  /// moment a row is first seen expired, only on a later sweep once this
  /// timestamp itself is far enough in the past. See
  /// `UploadQueueService._giveUpIfExpired` for why — in short, a single bad
  /// `DateTime.now()` read must not be enough to destroy a document.
  DateTimeColumn get expiredAt => dateTime().nullable()();
}

class LockedDocuments extends Table {
  IntColumn get documentId => integer()();

  @override
  Set<Column> get primaryKey => {documentId};
}

@DataClassName('DocumentTemplateRow')
class DocumentTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jsonData => text()();
}

/// Records metadata fields auto-applied from AI suggestions (OCR or chat).
class AiEdits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer()();
  TextColumn get fieldName => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();

  /// Source: 'ocr_suggestion' or 'chat'
  TextColumn get source => text()();
  DateTimeColumn get appliedAt => dateTime()();
}

class PendingEdits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer()();
  TextColumn get field => text()();
  TextColumn get value => text()();
  DateTimeColumn get queuedAt => dateTime()();
}

@DriftDatabase(
  tables: [
    CachedDocuments,
    CachedTags,
    CachedCorrespondents,
    CachedDocumentTypes,
    CachedStoragePaths,
    CachedSavedViews,
    CachedCustomFields,
    CachedWorkflows,
    PendingUploads,
    AiEdits,
    LockedDocuments,
    DocumentTemplates,
    PendingEdits,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(aiEdits);
      }
      if (from < 3) {
        await migrator.createTable(cachedWorkflows);
      }
      if (from < 4) {
        await migrator.createTable(lockedDocuments);
      }
      if (from < 5) {
        await migrator.createTable(documentTemplates);
      }
      if (from < 6) {
        await migrator.createTable(pendingEdits);
      }
      if (from < 7) {
        await migrator.addColumn(pendingUploads, pendingUploads.isFailed);
      }
      if (from < 8) {
        await migrator.addColumn(pendingUploads, pendingUploads.serverUrl);
      }
      if (from < 9) {
        await migrator.addColumn(pendingUploads, pendingUploads.expiredAt);
      }
    },
  );
}
