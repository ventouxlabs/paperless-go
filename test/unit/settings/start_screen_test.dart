import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/settings/start_screen.dart';

void main() {
  group('StartScreen.parse', () {
    test('maps stored names to screens and anything else to Library', () {
      expect(StartScreen.parse('inbox'), StartScreen.inbox);
      expect(StartScreen.parse('library'), StartScreen.library);
      expect(StartScreen.parse(null), StartScreen.library);
      expect(StartScreen.parse(''), StartScreen.library);
      expect(StartScreen.parse('dashboard'), StartScreen.library);
    });

    test('every screen has a shell route and a label', () {
      for (final screen in StartScreen.values) {
        expect(screen.route, startsWith('/'));
        expect(screen.label, isNotEmpty);
      }
    });
  });

  group('startScreenProvider', () {
    late ProviderContainer container;

    ProviderContainer build(Map<String, String> stored) {
      FlutterSecureStorage.setMockInitialValues({...stored});
      final storage =
          SecureStorageService(storage: const FlutterSecureStorage());
      return ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
    }

    test('loads the stored choice', () async {
      container = build({'start_screen': 'inbox'});
      addTearDown(container.dispose);
      expect(
        await container.read(startScreenProvider.future),
        StartScreen.inbox,
      );
    });

    test('defaults to Library when nothing is stored', () async {
      container = build({});
      addTearDown(container.dispose);
      expect(
        await container.read(startScreenProvider.future),
        StartScreen.library,
      );
    });

    test('set() updates state immediately and persists', () async {
      container = build({});
      addTearDown(container.dispose);
      await container.read(startScreenProvider.future);

      await container.read(startScreenProvider.notifier).set(StartScreen.inbox);

      expect(
        container.read(startScreenProvider).valueOrNull,
        StartScreen.inbox,
      );
      expect(
        await SecureStorageService(storage: const FlutterSecureStorage())
            .getStartScreen(),
        'inbox',
      );
    });
  });
}
