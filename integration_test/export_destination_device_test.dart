// On-device verification of the SAF write path behind "Save to folder".
//
// Runs inside the installed app (same package, same UID) so it sees the
// persisted URI grant the user took through Settings -> Storage. It never
// opens the system folder picker — that needs a human — and never touches the
// app's real secure storage: every test injects its own in-memory storage.
//
// Precondition: the app already holds a persisted *write* grant on some
// folder. Every test skips itself cleanly when that is not the case.
//
// Run it with `flutter run`, NOT `flutter test`:
//
//   flutter run --android-skip-build-dependency-validation \
//     -t integration_test/export_destination_device_test.dart -d <id>
//
// `flutter test -d <id>` uninstalls the app when the run finishes, which
// throws away the login and the very folder grant this test depends on.
// `flutter run` leaves the install in place; results print to the console.
//
// Not part of `flutter test` on CI (that only runs test/).

import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/services/export_destination_service.dart';
import 'package:saf/saf.dart';

const _noGrantUri =
    'content://com.android.externalstorage.documents/tree/primary%3APaperlessGoNoSuchGrant';
const _probeBytes = '%PDF-1.4\n% paperless-go device probe\n';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final saf = Saf();
  SafPersistedPermission? grant;

  setUpAll(() async {
    final grants = await saf.persistedPermissions();
    final writable = grants.where((p) => p.write).toList();
    grant = writable.isEmpty ? null : writable.first;
  });

  /// Returns the write grant, or marks the current test skipped.
  SafPersistedPermission? requireGrant() {
    if (grant == null) {
      markTestSkipped('No persisted write grant on this device — '
          'pick a folder in Settings > Storage first.');
    }
    return grant;
  }

  ExportDestinationService serviceWith(Map<String, String> stored) {
    FlutterSecureStorage.setMockInitialValues(stored);
    return ExportDestinationService(
      storage: SecureStorageService(storage: const FlutterSecureStorage()),
      saf: saf,
    );
  }

  Future<File> probeFile(String name) async {
    final file = File('${Directory.systemTemp.path}/$name');
    await file.writeAsString(_probeBytes, flush: true);
    return file;
  }

  Future<void> deleteIfPresent(String treeUri, String name) async {
    final doc = await saf.child(treeUri, [name]);
    if (doc != null) await saf.delete(doc.uri);
  }

  group('grant persistence', () {
    test('resolve() reports the stored folder as ready', () async {
      final g = requireGrant();
      if (g == null) return;
      final service = serviceWith({
        'downloads_uri': g.uri,
        'downloads_name': 'Device test',
      });
      final destination = await service.resolve();
      expect(destination.status, DestinationStatus.ready);
      expect(destination.name, 'Device test');
    });

    test('resolve() reports a folder the OS never granted as unavailable',
        () async {
      if (requireGrant() == null) return;
      final service = serviceWith({'downloads_uri': _noGrantUri});
      final destination = await service.resolve();
      expect(destination.status, DestinationStatus.unavailable);
    });
  });

  group('saveToDestination on the real provider', () {
    test('writes the file into the granted folder and returns its name',
        () async {
      final g = requireGrant();
      if (g == null) return;
      const name = 'paperless-go-device-probe.pdf';
      await deleteIfPresent(g.uri, name);
      final local = await probeFile(name);
      final service = serviceWith({'downloads_uri': g.uri});
      try {
        final written = await service.saveToDestination(
          localPath: local.path,
          fileName: name,
        );
        expect(written, name);
        final doc = await saf.child(g.uri, [written]);
        expect(doc, isNotNull, reason: 'file should exist in the folder');
        expect(doc?.length, _probeBytes.length);
        final bytes = await saf.readFileBytes(doc!.uri);
        expect(String.fromCharCodes(bytes), _probeBytes);
      } finally {
        await deleteIfPresent(g.uri, name);
        if (await local.exists()) await local.delete();
      }
    });

    test('a second save with the same name is auto-renamed, not overwritten',
        () async {
      final g = requireGrant();
      if (g == null) return;
      const name = 'paperless-go-device-collision.pdf';
      await deleteIfPresent(g.uri, name);
      final local = await probeFile(name);
      final service = serviceWith({'downloads_uri': g.uri});
      final written = <String>[];
      try {
        written.add(await service.saveToDestination(
          localPath: local.path,
          fileName: name,
        ));
        written.add(await service.saveToDestination(
          localPath: local.path,
          fileName: name,
        ));
        expect(written[0], name);
        expect(written[1], isNot(name));
        expect(await saf.child(g.uri, [written[0]]), isNotNull);
        expect(await saf.child(g.uri, [written[1]]), isNotNull);
      } finally {
        for (final n in written) {
          await deleteIfPresent(g.uri, n);
        }
        if (await local.exists()) await local.delete();
      }
    });

    test('keeps a non-ASCII document title in the written name', () async {
      final g = requireGrant();
      if (g == null) return;
      final name =
          '${sanitizeExportName('Rechnung Müller: März?', fallback: 'x')}.pdf';
      expect(name, 'Rechnung Müller März.pdf');
      await deleteIfPresent(g.uri, name);
      final local = await probeFile('unicode-probe.pdf');
      final service = serviceWith({'downloads_uri': g.uri});
      try {
        final written = await service.saveToDestination(
          localPath: local.path,
          fileName: name,
        );
        expect(written, name);
        expect(await saf.child(g.uri, [name]), isNotNull);
      } finally {
        await deleteIfPresent(g.uri, name);
        if (await local.exists()) await local.delete();
      }
    });

    test('a folder without a grant fails closed and asks to reselect',
        () async {
      if (requireGrant() == null) return;
      final local = await probeFile('no-grant-probe.pdf');
      final service = serviceWith({'downloads_uri': _noGrantUri});
      try {
        await expectLater(
          service.saveToDestination(
            localPath: local.path,
            fileName: 'no-grant-probe.pdf',
            // Bypass resolve() so the native write itself is what fails,
            // the way a grant revoked mid-bulk-save would surface.
            known: const ExportDestination.ready(uri: _noGrantUri),
          ),
          throwsA(isA<ExportSaveException>()
              .having((e) => e.needsReselect, 'needsReselect', isTrue)),
        );
      } finally {
        if (await local.exists()) await local.delete();
      }
    });

    test('a missing source file is reported without blaming the folder',
        () async {
      final g = requireGrant();
      if (g == null) return;
      final service = serviceWith({'downloads_uri': g.uri});
      await expectLater(
        service.saveToDestination(
          localPath: '${Directory.systemTemp.path}/does-not-exist.pdf',
          fileName: 'x.pdf',
        ),
        throwsA(isA<ExportSaveException>()
            .having((e) => e.needsReselect, 'needsReselect', isFalse)),
      );
    });
  });
}
