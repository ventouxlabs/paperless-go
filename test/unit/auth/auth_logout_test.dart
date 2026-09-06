import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/auth_service.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/database/cache_provider.dart';
import 'package:paperless_go/core/services/export_destination_providers.dart';
import 'package:paperless_go/core/services/export_destination_service.dart';

import '../../helpers/fake_saf.dart';

void main() {
  group('AuthState.logout', () {
    late FakeSaf saf;
    late SecureStorageService storage;
    late ProviderContainer container;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'server_url': 'https://paperless.example',
        'api_token': 'token',
        'downloads_uri': pickedTreeUri,
        'downloads_name': 'Download',
      });
      saf = FakeSaf()..permissions = [grantFor(persistedTreeUri)];
      storage = SecureStorageService(storage: const FlutterSecureStorage());
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          authServiceProvider.overrideWithValue(AuthService(storage: storage)),
          exportDestinationServiceProvider.overrideWithValue(
            ExportDestinationService(storage: storage, saf: saf),
          ),
          // No database in a unit test; logout tolerates a missing cache.
          cacheRepositoryProvider.overrideWith(
            (_) => throw StateError('no cache in this test'),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('releases the downloads folder grant, not just the stored hint',
        () async {
      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      expect(
        saf.released,
        [pickedTreeUri],
        reason: 'the OS write grant must be revoked on sign-out; once storage '
            'is wiped nothing can release it any more',
      );
      expect(await storage.getDownloadsUri(), isNull);
      expect(await storage.getApiToken(), isNull);
    });

    test('still signs out when releasing the grant blows up', () async {
      // Not a SafException, so forget() does not swallow it: the plugin
      // channel itself is missing, as on a platform without the plugin.
      saf.releaseError = MissingPluginException('saf');
      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      expect(await storage.getApiToken(), isNull);
      expect(
        container.read(authStateProvider).valueOrNull,
        const AuthStatus.unauthenticated(),
      );
    });

    test('still signs out when no folder was ever chosen', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'server_url': 'https://paperless.example',
        'api_token': 'token',
      });
      await container.read(authStateProvider.future);
      await container.read(authStateProvider.notifier).logout();

      expect(saf.released, isEmpty);
      expect(await storage.getApiToken(), isNull);
    });
  });
}
