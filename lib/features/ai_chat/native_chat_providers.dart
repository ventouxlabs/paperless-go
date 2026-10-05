import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/api/server_capabilities.dart';
import '../../core/auth/auth_provider.dart';
import 'native_chat_service.dart';

/// Native Paperless-ngx chat on the authenticated, profile-scoped API client.
/// UI wiring intentionally lands separately from this transport foundation.
final nativeChatServiceProvider = Provider<NativeChatService>(
  (ref) => NativeChatService(ref.watch(paperlessApiProvider)),
);

/// Whether the active Paperless-ngx server advertises its built-in AI.
///
/// This is deliberately synchronous and fail-closed, just like the rest of
/// the capability consumers. Keeping the selection here also makes it easy
/// for tests (and a later settings selector) to inject a specific backend.
enum ChatBackend { native, paperlessAi, unavailable }

const nativeChatMaxQuestionCodePoints = 4000;

enum ChatBackendPreference { loading, auto, native, paperlessAi }

/// Persisted user choice for servers that expose both chat implementations.
/// Invalid or absent values deliberately resolve to [ChatBackendPreference.auto]
/// so existing installations retain their native-first behavior.
class ChatBackendPreferenceNotifier extends Notifier<ChatBackendPreference> {
  var _disposed = false;
  var _userSelected = false;
  var _readGeneration = 0;

  @override
  ChatBackendPreference build() {
    _disposed = false;
    _userSelected = false;
    _readGeneration = 0;
    ref.onDispose(() => _disposed = true);
    _load();
    return ChatBackendPreference.loading;
  }

  Future<void> _load() async {
    final generation = ++_readGeneration;
    try {
      final saved = await ref.read(secureStorageProvider).getAiChatBackend();
      if (_disposed || _userSelected || generation != _readGeneration) return;
      state = ChatBackendPreference.values.firstWhere(
        (value) => value.name == saved,
        orElse: () => ChatBackendPreference.auto,
      );
    } catch (_) {
      if (!_disposed && !_userSelected && generation == _readGeneration) {
        state = ChatBackendPreference.auto;
      }
    }
  }

  Future<void> select(ChatBackendPreference preference) async {
    assert(preference != ChatBackendPreference.loading);
    _userSelected = true;
    _readGeneration++;
    try {
      await ref.read(secureStorageProvider).saveAiChatBackend(preference.name);
      if (!_disposed) state = preference;
    } catch (_) {
      if (!_disposed) {
        _userSelected = false;
        _load();
      }
      rethrow;
    }
  }
}

final chatBackendPreferenceProvider =
    NotifierProvider<ChatBackendPreferenceNotifier, ChatBackendPreference>(
      ChatBackendPreferenceNotifier.new,
    );

/// The one selection rule for every chat entry point.
///
/// Native Paperless-ngx chat is preferred whenever the connected server
/// advertises AI. Older servers (or servers with native AI disabled) keep the
/// existing Paperless-AI integration when it has been configured. This is
/// synchronous and fail-closed while capabilities are loading.
final chatBackendProvider = Provider<ChatBackend>((ref) {
  final nativeAvailable = ref
      .watch(effectiveServerCapabilitiesProvider)
      .aiEnabled;
  final hasPaperlessAiUrl = (ref.watch(aiChatUrlProvider) ?? '').isNotEmpty;
  final preference = ref.watch(chatBackendPreferenceProvider);
  if (preference == ChatBackendPreference.loading) {
    return ChatBackend.unavailable;
  }
  if (preference == ChatBackendPreference.native && nativeAvailable) {
    return ChatBackend.native;
  }
  if (preference == ChatBackendPreference.paperlessAi && hasPaperlessAiUrl) {
    return ChatBackend.paperlessAi;
  }
  if (preference != ChatBackendPreference.auto) {
    return ChatBackend.unavailable;
  }
  if (nativeAvailable) return ChatBackend.native;
  return hasPaperlessAiUrl ? ChatBackend.paperlessAi : ChatBackend.unavailable;
});

/// Whether any configured backend can offer chat to the current user.
final chatAvailableProvider = Provider<bool>(
  (ref) => ref.watch(chatBackendProvider) != ChatBackend.unavailable,
);

/// Whether this selection resolves to native Paperless-ngx chat.
///
/// Keep this provider as the notifier's seam: its existing focused tests can
/// override it without having to construct server capability state.
final nativeChatAvailableProvider = Provider<bool>(
  (ref) => ref.watch(chatBackendProvider) == ChatBackend.native,
);
