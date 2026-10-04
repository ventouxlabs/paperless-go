import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/server_capabilities.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/features/ai_chat/native_chat_providers.dart';

class _TestAiChatUrl extends AiChatUrl {
  _TestAiChatUrl(this.url);

  final String? url;

  @override
  String? build() => url;
}

class _TestChatBackendPreference extends ChatBackendPreferenceNotifier {
  _TestChatBackendPreference(this.preference);

  final ChatBackendPreference preference;

  @override
  ChatBackendPreference build() => preference;
}

class _ControlledStorage extends SecureStorageService {
  final read = Completer<String?>();
  final write = Completer<void>();

  @override
  Future<String?> getAiChatBackend() => read.future;

  @override
  Future<void> saveAiChatBackend(String backend) => write.future;
}

void main() {
  ProviderContainer container({
    required bool nativeAi,
    String? aiUrl,
    ChatBackendPreference preference = ChatBackendPreference.auto,
  }) => ProviderContainer(
    overrides: [
      effectiveServerCapabilitiesProvider.overrideWith(
        (ref) => ServerCapabilities(
          aiEnabled: nativeAi,
          permissions: const {},
          version: null,
        ),
      ),
      aiChatUrlProvider.overrideWith(() => _TestAiChatUrl(aiUrl)),
      chatBackendPreferenceProvider.overrideWith(
        () => _TestChatBackendPreference(preference),
      ),
    ],
  );

  test('native-only servers select native chat and make chat available', () {
    final scope = container(nativeAi: true);
    addTearDown(scope.dispose);

    expect(scope.read(chatBackendProvider), ChatBackend.native);
    expect(scope.read(nativeChatAvailableProvider), isTrue);
    expect(scope.read(chatAvailableProvider), isTrue);
  });

  test('native chat takes priority over an optional Paperless-AI URL', () {
    final scope = container(nativeAi: true, aiUrl: 'https://paperless-ai.test');
    addTearDown(scope.dispose);

    expect(scope.read(chatBackendProvider), ChatBackend.native);
  });

  test('Paperless-AI remains the fallback when native chat is unavailable', () {
    final scope = container(
      nativeAi: false,
      aiUrl: 'https://paperless-ai.test',
    );
    addTearDown(scope.dispose);

    expect(scope.read(chatBackendProvider), ChatBackend.paperlessAi);
    expect(scope.read(nativeChatAvailableProvider), isFalse);
    expect(scope.read(chatAvailableProvider), isTrue);
  });

  test(
    'explicit Paperless-AI preference wins when both backends are usable',
    () {
      final scope = container(
        nativeAi: true,
        aiUrl: 'https://paperless-ai.test',
        preference: ChatBackendPreference.paperlessAi,
      );
      addTearDown(scope.dispose);

      expect(scope.read(chatBackendProvider), ChatBackend.paperlessAi);
    },
  );

  test(
    'chat is unavailable when neither native AI nor Paperless-AI is set',
    () {
      final scope = container(nativeAi: false);
      addTearDown(scope.dispose);

      expect(scope.read(chatBackendProvider), ChatBackend.unavailable);
      expect(scope.read(chatAvailableProvider), isFalse);
    },
  );

  test(
    'does not select native before a saved Paperless-AI preference loads',
    () async {
      final storage = _ControlledStorage();
      final scope = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          effectiveServerCapabilitiesProvider.overrideWith(
            (ref) => const ServerCapabilities(
              aiEnabled: true,
              permissions: {},
              version: null,
            ),
          ),
          aiChatUrlProvider.overrideWith(
            () => _TestAiChatUrl('https://paperless-ai.test'),
          ),
        ],
      );
      addTearDown(scope.dispose);

      expect(
        scope.read(chatBackendPreferenceProvider),
        ChatBackendPreference.loading,
      );
      expect(scope.read(chatBackendProvider), ChatBackend.unavailable);

      storage.read.complete('paperlessAi');
      await Future<void>.delayed(Duration.zero);
      expect(scope.read(chatBackendProvider), ChatBackend.paperlessAi);
    },
  );

  test('late load cannot overwrite a successfully saved selection', () async {
    final storage = _ControlledStorage();
    final scope = ProviderContainer(
      overrides: [secureStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(scope.dispose);
    scope.read(chatBackendPreferenceProvider);

    final selecting = scope
        .read(chatBackendPreferenceProvider.notifier)
        .select(ChatBackendPreference.native);
    storage.read.complete('paperlessAi');
    storage.write.complete();
    await selecting;
    await Future<void>.delayed(Duration.zero);

    expect(
      scope.read(chatBackendPreferenceProvider),
      ChatBackendPreference.native,
    );
  });

  test(
    'failed preference writes keep the previous selection and rethrow',
    () async {
      final storage = _ControlledStorage();
      final scope = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(scope.dispose);
      scope.read(chatBackendPreferenceProvider);
      storage.read.complete('auto');
      await Future<void>.delayed(Duration.zero);
      final selecting = scope
          .read(chatBackendPreferenceProvider.notifier)
          .select(ChatBackendPreference.native);
      storage.write.completeError(StateError('storage unavailable'));
      await expectLater(selecting, throwsStateError);
      expect(
        scope.read(chatBackendPreferenceProvider),
        ChatBackendPreference.auto,
      );
    },
  );
}
