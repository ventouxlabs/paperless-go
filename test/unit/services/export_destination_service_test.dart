import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/services/export_destination_service.dart';
import 'package:saf/saf.dart';

/// A controllable [Saf] double: every plugin call the service touches can be
/// made to succeed, return null (user cancelled), or throw.
class _FakeSaf extends Saf {
  SafDocumentFile? pickResult;
  Object? pickError;
  List<SafPersistedPermission> permissions = [];
  Object? permissionsError;
  Object? pasteError;
  Object? releaseError;
  final released = <String>[];

  @override
  Future<SafDocumentFile?> pickDirectory({
    String? initialUri,
    bool writePermission = true,
    bool persistablePermission = true,
  }) async {
    if (pickError != null) throw pickError!;
    return pickResult;
  }

  @override
  Future<List<SafPersistedPermission>> persistedPermissions() async {
    if (permissionsError != null) throw permissionsError!;
    return permissions;
  }

  @override
  Future<void> releasePersistedPermission(String uri) async {
    released.add(uri);
    if (releaseError != null) throw releaseError!;
  }

  @override
  Future<SafDocumentFile> pasteLocalFile(
    String srcPath,
    String destDirUri,
    String name,
    String mime, {
    bool overwrite = false,
    SafProgressCallback? onProgress,
  }) async {
    if (pasteError != null) throw pasteError!;
    return SafDocumentFile(
      uri: '$destDirUri/document/$name',
      name: name,
      isDir: false,
      length: 0,
      lastModified: 0,
    );
  }
}

/// The form `pickDirectory()` returns: `tree/<id>/document/<id>`.
const _pickedUri =
    'content://com.android.externalstorage.documents/tree/primary%3ADownload'
    '/document/primary%3ADownload';

/// The form `persistedPermissions()` reports: the bare `tree/<id>`.
const _persistedUri =
    'content://com.android.externalstorage.documents/tree/primary%3ADownload';

SafPersistedPermission _grant(String uri, {bool write = true}) =>
    SafPersistedPermission(
      uri: uri,
      read: true,
      write: write,
      persistedTime: 0,
    );

void main() {
  group('SafTreeKey', () {
    test('picked and persisted URI forms key to the same grant', () {
      // The whole point: these two strings are never `==`, but they name the
      // same folder. A raw comparison here would silently break every save.
      expect(_pickedUri == _persistedUri, isFalse);
      expect(SafTreeKey.parse(_pickedUri), SafTreeKey.parse(_persistedUri));
    });

    test('is insensitive to percent-encoding of the tree id', () {
      const encoded =
          'content://com.android.externalstorage.documents/tree/primary%3ADocs';
      const decoded =
          'content://com.android.externalstorage.documents/tree/primary:Docs';
      expect(SafTreeKey.parse(encoded), SafTreeKey.parse(decoded));
    });

    test('a subdirectory under a granted tree keys to that tree', () {
      const child =
          'content://com.android.externalstorage.documents/tree/primary%3ADownload'
          '/document/primary%3ADownload%2Fscans';
      expect(SafTreeKey.parse(child), SafTreeKey.parse(_persistedUri));
    });

    test('different folders do not collide', () {
      const other =
          'content://com.android.externalstorage.documents/tree/primary%3ADocs';
      expect(SafTreeKey.parse(_persistedUri), isNot(SafTreeKey.parse(other)));
    });

    test('different providers do not collide on the same tree id', () {
      const sdcard =
          'content://com.example.other.documents/tree/primary%3ADownload';
      expect(SafTreeKey.parse(_persistedUri), isNot(SafTreeKey.parse(sdcard)));
    });

    test('returns null for null, empty, and non-tree URIs', () {
      expect(SafTreeKey.parse(null), isNull);
      expect(SafTreeKey.parse(''), isNull);
      expect(SafTreeKey.parse('file:///storage/emulated/0/Download'), isNull);
      expect(
        SafTreeKey.parse(
          'content://com.android.externalstorage.documents/document/primary%3AX',
        ),
        isNull,
      );
    });
  });

  group('resolveDestination', () {
    test('unset when nothing has been stored', () {
      final result = resolveDestination(
        storedUri: null,
        storedName: null,
        permissions: [],
      );
      expect(result.status, DestinationStatus.unset);
    });

    test('unset when the stored value is not a tree URI', () {
      final result = resolveDestination(
        storedUri: 'not a uri at all',
        storedName: 'Junk',
        permissions: [_grant(_persistedUri)],
      );
      expect(result.status, DestinationStatus.unset);
    });

    test('ready when a live write grant matches the stored URI', () {
      final result = resolveDestination(
        storedUri: _pickedUri,
        storedName: 'Download',
        permissions: [_grant(_persistedUri)],
      );
      expect(result.status, DestinationStatus.ready);
      expect(result.uri, _pickedUri);
      expect(result.name, 'Download');
    });

    test('unavailable when the grant was revoked', () {
      final result = resolveDestination(
        storedUri: _pickedUri,
        storedName: 'Download',
        permissions: [],
      );
      expect(result.status, DestinationStatus.unavailable);
      // The name survives so the UI can say *which* folder went missing.
      expect(result.name, 'Download');
    });

    test('unavailable when the grant is read-only', () {
      final result = resolveDestination(
        storedUri: _pickedUri,
        storedName: 'Download',
        permissions: [_grant(_persistedUri, write: false)],
      );
      expect(result.status, DestinationStatus.unavailable);
    });

    test('unavailable when only an unrelated folder is granted', () {
      final result = resolveDestination(
        storedUri: _pickedUri,
        storedName: 'Download',
        permissions: [
          _grant(
            'content://com.android.externalstorage.documents/tree/primary%3ADocs',
          ),
        ],
      );
      expect(result.status, DestinationStatus.unavailable);
    });

    test('finds the matching grant among several', () {
      final result = resolveDestination(
        storedUri: _pickedUri,
        storedName: 'Download',
        permissions: [
          _grant(
            'content://com.android.externalstorage.documents/tree/primary%3ADocs',
          ),
          _grant(_persistedUri),
        ],
      );
      expect(result.status, DestinationStatus.ready);
    });
  });

  group('sanitizeExportName', () {
    test('strips characters SAF providers reject', () {
      expect(
        sanitizeExportName('Invoice: 2024/03 <final>', fallback: 'doc'),
        'Invoice 202403 final',
      );
    });

    test('keeps word characters, spaces, and hyphens', () {
      expect(
        sanitizeExportName('ACME Corp - Receipt_12', fallback: 'doc'),
        'ACME Corp - Receipt_12',
      );
    });

    test('falls back when nothing survives sanitisation', () {
      expect(sanitizeExportName('///', fallback: 'document_7'), 'document_7');
      expect(sanitizeExportName('   ', fallback: 'document_7'), 'document_7');
    });

    test('preserves non-Latin titles instead of erasing them', () {
      // The old allow-list regex (\w is ASCII-only in Dart) reduced these to
      // near nothing: 'Rechnung Müller' -> 'Rechnung Mller', '発票 2024' ->
      // '2024'. The deny-list only strips characters SAF actually rejects.
      expect(
        sanitizeExportName('Rechnung Müller 2024', fallback: 'doc'),
        'Rechnung Müller 2024',
      );
      expect(sanitizeExportName('発票 2024', fallback: 'doc'), '発票 2024');
      expect(sanitizeExportName('Счёт 12', fallback: 'doc'), 'Счёт 12');
    });

    test('caps length so it cannot exceed provider display-name limits', () {
      final long = 'a' * 300;
      expect(sanitizeExportName(long, fallback: 'doc').length, 100);
    });
  });

  group('ExportDestination', () {
    test('displayName falls back when no name was stored', () {
      const d = ExportDestination.ready(uri: _pickedUri);
      expect(d.displayName, 'Selected folder');
    });

    test('displayName uses the stored folder name', () {
      const d = ExportDestination.ready(uri: _pickedUri, name: 'Download');
      expect(d.displayName, 'Download');
    });
  });

  group('ExportDestinationService.saveToDestination', () {
    late Directory tempDir;
    late File localFile;
    late _FakeSaf saf;
    late ExportDestinationService service;
    const destination = ExportDestination.ready(uri: _pickedUri, name: 'Download');

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      tempDir = await Directory.systemTemp.createTemp('export_dest_test_');
      localFile = File('${tempDir.path}/doc.pdf')..writeAsStringSync('pdf');
      saf = _FakeSaf();
      service = ExportDestinationService(
        storage: SecureStorageService(storage: const FlutterSecureStorage()),
        saf: saf,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('throws needsReselect when no folder was ever chosen', () async {
      await expectLater(
        service.saveToDestination(
          localPath: localFile.path,
          fileName: 'doc.pdf',
          known: const ExportDestination.unset(),
        ),
        throwsA(
          isA<ExportSaveException>().having(
            (e) => e.needsReselect,
            'needsReselect',
            isTrue,
          ),
        ),
      );
    });

    test('throws needsReselect when the folder grant is unavailable',
        () async {
      await expectLater(
        service.saveToDestination(
          localPath: localFile.path,
          fileName: 'doc.pdf',
          known: const ExportDestination.unavailable(uri: _pickedUri),
        ),
        throwsA(
          isA<ExportSaveException>().having(
            (e) => e.needsReselect,
            'needsReselect',
            isTrue,
          ),
        ),
      );
    });

    test(
        'reports a missing local file distinctly, without offering to '
        'reselect the folder', () async {
      // Regression: the plugin throws the same SafNotFoundException for a
      // missing source file as for a missing destination folder. Deleting
      // the file the folder is otherwise perfectly fine used to surface
      // "download folder no longer exists" and send the user to re-pick a
      // folder that was never the problem.
      await localFile.delete();
      await expectLater(
        service.saveToDestination(
          localPath: localFile.path,
          fileName: 'doc.pdf',
          known: destination,
        ),
        throwsA(
          isA<ExportSaveException>()
              .having((e) => e.needsReselect, 'needsReselect', isFalse)
              .having((e) => e.message, 'message', contains('no longer available')),
        ),
      );
    });

    test('maps a revoked grant to needsReselect', () async {
      saf.pasteError = const SafPermissionException(_pickedUri, 'denied');
      await expectLater(
        service.saveToDestination(
          localPath: localFile.path,
          fileName: 'doc.pdf',
          known: destination,
        ),
        throwsA(
          isA<ExportSaveException>().having(
            (e) => e.needsReselect,
            'needsReselect',
            isTrue,
          ),
        ),
      );
    });

    test('maps a folder that vanished mid-write to needsReselect', () async {
      // Distinct from the missing-local-file case above: here the local
      // file exists, so this SafNotFoundException genuinely means the
      // destination is gone.
      saf.pasteError = const SafNotFoundException(_pickedUri, 'gone');
      await expectLater(
        service.saveToDestination(
          localPath: localFile.path,
          fileName: 'doc.pdf',
          known: destination,
        ),
        throwsA(
          isA<ExportSaveException>().having(
            (e) => e.needsReselect,
            'needsReselect',
            isTrue,
          ),
        ),
      );
    });

    test('maps any other SAF failure without offering to reselect', () async {
      saf.pasteError = const SafIoException(_pickedUri, 'disk error');
      await expectLater(
        service.saveToDestination(
          localPath: localFile.path,
          fileName: 'doc.pdf',
          known: destination,
        ),
        throwsA(
          isA<ExportSaveException>().having(
            (e) => e.needsReselect,
            'needsReselect',
            isFalse,
          ),
        ),
      );
    });

    test('returns the written name on success', () async {
      final written = await service.saveToDestination(
        localPath: localFile.path,
        fileName: 'doc.pdf',
        known: destination,
      );
      expect(written, 'doc.pdf');
    });
  });

  group('ExportDestinationService.chooseFolder', () {
    late _FakeSaf saf;
    late ExportDestinationService service;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      saf = _FakeSaf();
      service = ExportDestinationService(
        storage: SecureStorageService(storage: const FlutterSecureStorage()),
        saf: saf,
      );
    });

    test('returns null when the user cancels the picker', () async {
      saf.pickResult = null;
      expect(await service.chooseFolder(), isNull);
    });

    test('throws ExportSaveException when the picker itself fails', () async {
      saf.pickError = const SafIoException('', 'no DocumentsUI on device');
      await expectLater(
        service.chooseFolder(),
        throwsA(isA<ExportSaveException>()),
      );
    });

    test(
        'throws when the grant was picked but not actually persisted '
        '(the plugin swallows a failed takePersistableUriPermission)',
        () async {
      saf.pickResult = const SafDocumentFile(
        uri: _pickedUri,
        name: 'Download',
        isDir: true,
        length: 0,
        lastModified: 0,
      );
      saf.permissions = []; // no matching grant reported back
      await expectLater(
        service.chooseFolder(),
        throwsA(isA<ExportSaveException>()),
      );
    });

    test('persists the folder once the grant is confirmed', () async {
      saf.pickResult = const SafDocumentFile(
        uri: _pickedUri,
        name: 'Download',
        isDir: true,
        length: 0,
        lastModified: 0,
      );
      saf.permissions = [_grant(_persistedUri)];

      final result = await service.chooseFolder();

      expect(result?.isReady, isTrue);
      final resolved = await service.resolve();
      expect(resolved.uri, _pickedUri);
      expect(resolved.name, 'Download');
    });

    test('releases the previous grant when switching to a different folder',
        () async {
      const otherUri =
          'content://com.android.externalstorage.documents/tree/primary%3ADocs'
          '/document/primary%3ADocs';
      const otherPersisted =
          'content://com.android.externalstorage.documents/tree/primary%3ADocs';

      saf.pickResult = const SafDocumentFile(
        uri: _pickedUri,
        name: 'Download',
        isDir: true,
        length: 0,
        lastModified: 0,
      );
      saf.permissions = [_grant(_persistedUri), _grant(otherPersisted)];
      await service.chooseFolder(); // first folder: nothing to release yet
      expect(saf.released, isEmpty);

      saf.pickResult = const SafDocumentFile(
        uri: otherUri,
        name: 'Docs',
        isDir: true,
        length: 0,
        lastModified: 0,
      );
      await service.chooseFolder();

      expect(saf.released, [_pickedUri]);
    });
  });

  group('ExportDestinationService.resolve', () {
    test('reports unavailable, not unset, when a configured folder cannot '
        'be checked', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final saf = _FakeSaf()
        ..pickResult = const SafDocumentFile(
          uri: _pickedUri,
          name: 'Download',
          isDir: true,
          length: 0,
          lastModified: 0,
        )
        ..permissions = [_grant(_persistedUri)];
      final service = ExportDestinationService(
        storage: SecureStorageService(storage: const FlutterSecureStorage()),
        saf: saf,
      );
      await service.chooseFolder();

      // Simulate the OS grant check itself failing on a later launch.
      saf.permissionsError = const SafIoException('', 'provider unavailable');
      final result = await service.resolve();

      expect(result.status, DestinationStatus.unavailable);
      expect(result.name, 'Download');
    });
  });

  group('ExportDestinationService.forget', () {
    test('releases the persisted grant and clears the stored hint', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final saf = _FakeSaf()
        ..pickResult = const SafDocumentFile(
          uri: _pickedUri,
          name: 'Download',
          isDir: true,
          length: 0,
          lastModified: 0,
        )
        ..permissions = [_grant(_persistedUri)];
      final storage =
          SecureStorageService(storage: const FlutterSecureStorage());
      final service = ExportDestinationService(storage: storage, saf: saf);
      await service.chooseFolder();

      await service.forget();

      expect(saf.released, [_pickedUri]);
      expect(await storage.getDownloadsUri(), isNull);
    });

    test('is a no-op when nothing was ever configured', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final saf = _FakeSaf();
      final service = ExportDestinationService(
        storage: SecureStorageService(storage: const FlutterSecureStorage()),
        saf: saf,
      );

      await service.forget();

      expect(saf.released, isEmpty);
    });

    test('still clears the stored hint even if releasing the grant fails',
        () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final saf = _FakeSaf()
        ..pickResult = const SafDocumentFile(
          uri: _pickedUri,
          name: 'Download',
          isDir: true,
          length: 0,
          lastModified: 0,
        )
        ..permissions = [_grant(_persistedUri)];
      final storage =
          SecureStorageService(storage: const FlutterSecureStorage());
      final service = ExportDestinationService(storage: storage, saf: saf);
      await service.chooseFolder();

      saf.releaseError = const SafIoException(_pickedUri, 'already gone');

      await service.forget();

      expect(await storage.getDownloadsUri(), isNull);
    });
  });
}
