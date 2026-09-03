import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/export_destination_service.dart';
import 'package:saf/saf.dart';

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
}
