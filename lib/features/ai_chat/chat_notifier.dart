import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/auth/auth_provider.dart';
import 'chat_service.dart';
import 'native_chat_providers.dart';
import 'native_chat_service.dart';

part 'chat_notifier.g.dart';

@Riverpod(keepAlive: true)
ChatService? chatService(Ref ref) {
  final aiUrl = ref.watch(aiChatUrlProvider);
  if (aiUrl == null || aiUrl.isEmpty) {
    return null;
  }
  final normalizedUrl = aiUrl.endsWith('/') ? aiUrl : '$aiUrl/';
  final dio = Dio(
    BaseOptions(
      baseUrl: normalizedUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 120),
      followRedirects: true,
      maxRedirects: 5,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  return ChatService(dio);
}

enum ChatMode { rag, document }

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ChatMode mode;
  final int? documentId;
  final String? documentTitle;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.mode = ChatMode.rag,
    this.documentId,
    this.documentTitle,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    Object? error = _sentinel,
    ChatMode? mode,
    int? documentId,
    String? documentTitle,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      mode: mode ?? this.mode,
      documentId: documentId ?? this.documentId,
      documentTitle: documentTitle ?? this.documentTitle,
    );
  }

  static const Object _sentinel = Object();
}

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  bool _loggedIn = false;
  bool _disposed = false;
  bool _sending = false;
  CancelToken? _nativeCancelToken;
  int _requestEpoch = 0;
  int _sendEpoch = 0;

  @override
  ChatState build() {
    ref.listen(authStateProvider, (previous, next) {
      final wasAuthenticated = previous?.valueOrNull?.isAuthenticated ?? false;
      final isAuthenticated = next.valueOrNull?.isAuthenticated ?? false;
      if (wasAuthenticated != isAuthenticated ||
          previous?.valueOrNull?.serverUrl != next.valueOrNull?.serverUrl) {
        _cancelActiveNativeRequest();
        _loggedIn = false;
        state = const ChatState();
      }
    });
    ref.onDispose(() {
      _disposed = true;
      _nativeCancelToken?.cancel();
    });
    return const ChatState();
  }

  /// Get the ChatService, throwing a clear error if not configured.
  ChatService _getService() {
    final service = ref.read(chatServiceProvider);
    if (service == null) {
      throw Exception(
        'Paperless-AI URL not configured. Go to Settings to set it up.',
      );
    }
    return service;
  }

  /// Ensure the ChatService is logged in with Paperless-AI credentials.
  Future<void> _ensureLoggedIn() async {
    if (_loggedIn) return;

    // Read directly from secure storage to avoid async provider race condition
    final storage = ref.read(secureStorageProvider);
    final username = await storage.getAiChatUsername();
    final password = await storage.getAiChatPassword();
    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      // No credentials configured — proceed without auth (may work on internal networks)
      return;
    }

    final service = _getService();
    await service.login(username, password);
    _loggedIn = true;
  }

  /// Reset to RAG mode (called when Chat tab opens without a documentId).
  void resetToRagMode() {
    if (state.mode == ChatMode.document) {
      _cancelActiveNativeRequest();
      _loggedIn = false;
      state = const ChatState();
    }
  }

  Future<void> initDocumentMode(int documentId, String title) async {
    // If already initialized for this exact document, skip re-init
    if (state.mode == ChatMode.document && state.documentId == documentId) {
      return;
    }

    _cancelActiveNativeRequest();
    _loggedIn = false;
    state = ChatState(
      mode: ChatMode.document,
      documentId: documentId,
      documentTitle: title,
    );

    // Native chat has no session to initialize. Its document context is sent
    // with each single-turn request.
    if (_usesNativeChat) return;

    try {
      await _ensureLoggedIn();
      final service = _getService();
      await service.initDocumentChat(documentId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (_sending) return;
    _sending = true;
    final sendEpoch = ++_sendEpoch;
    try {
      if (_usesNativeChat) {
        await _sendNativeMessage(text);
        return;
      }
      if (state.mode == ChatMode.document) {
        await _sendDocumentMessage(text);
      } else {
        await _sendRagMessage(text);
      }
    } finally {
      if (sendEpoch == _sendEpoch) _sending = false;
    }
  }

  bool get _usesNativeChat => ref.read(nativeChatAvailableProvider);

  /// Stops an active native generation. Paperless-AI's existing endpoints do
  /// not expose a cancellable request, so this intentionally leaves that path
  /// unchanged.
  void stop() {
    final token = _nativeCancelToken;
    if (token == null || token.isCancelled) return;
    _cancelActiveNativeRequest();
  }

  void _cancelActiveNativeRequest() {
    _requestEpoch++;
    _sendEpoch++;
    _sending = false;
    final token = _nativeCancelToken;
    _nativeCancelToken = null;
    if (token != null && !token.isCancelled) {
      token.cancel('Chat stopped by user');
    }
    if (state.isLoading) state = state.copyWith(isLoading: false);
  }

  Future<void> _sendNativeMessage(String text) async {
    final userMessage = ChatMessage(role: 'user', content: text);
    final placeholder = ChatMessage(role: 'assistant', content: '');
    final cancelToken = CancelToken();
    _nativeCancelToken = cancelToken;
    final requestEpoch = ++_requestEpoch;

    state = state.copyWith(
      messages: [...state.messages, userMessage, placeholder],
      isLoading: true,
      error: null,
    );

    try {
      final service = ref.read(nativeChatServiceProvider);
      // Native Paperless-ngx chat is explicitly single-turn: do not turn the
      // app's rendered history into hidden prompt context.
      final stream = service.send(
        text,
        documentId: state.mode == ChatMode.document ? state.documentId : null,
        cancelToken: cancelToken,
      );
      await for (final update in stream) {
        if (_disposed ||
            cancelToken.isCancelled ||
            requestEpoch != _requestEpoch ||
            !identical(_nativeCancelToken, cancelToken)) {
          break;
        }
        final messages = List<ChatMessage>.from(state.messages);
        if (messages.isEmpty || messages.last.role != 'assistant') break;
        messages[messages.length - 1] = messages.last.copyWith(
          content: update.answer,
          references: update.references,
        );
        state = state.copyWith(
          messages: messages,
          error: update.softError == null
              ? null
              : _nativeSoftErrorText(update.softError!),
        );
      }
      if (!_disposed &&
          !cancelToken.isCancelled &&
          requestEpoch == _requestEpoch &&
          identical(_nativeCancelToken, cancelToken)) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (_disposed ||
          cancelToken.isCancelled ||
          requestEpoch != _requestEpoch ||
          !identical(_nativeCancelToken, cancelToken)) {
        return;
      }
      // Remove an empty streaming placeholder, but retain any partial answer
      // that was useful before an interrupted connection.
      final messages = List<ChatMessage>.from(state.messages);
      if (messages.isNotEmpty &&
          messages.last.role == 'assistant' &&
          messages.last.content.isEmpty) {
        messages.removeLast();
      }
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        error: e.toString(),
      );
    } finally {
      if (identical(_nativeCancelToken, cancelToken)) {
        _nativeCancelToken = null;
      }
    }
  }

  String _nativeSoftErrorText(NativeChatSoftError error) => switch (error) {
    NativeChatSoftError.generationFailed =>
      'Sorry, something went wrong while generating a response.',
    NativeChatSoftError.noContent =>
      "Sorry, I couldn't find any content to answer your question.",
  };

  Future<void> _sendRagMessage(String text) async {
    final userMessage = ChatMessage(role: 'user', content: text);
    final previousMessages = List<ChatMessage>.from(state.messages);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      await _ensureLoggedIn();
      final service = _getService();
      final response = await service.sendMessage(text, previousMessages);
      state = state.copyWith(
        messages: [...state.messages, response],
        isLoading: false,
      );
    } catch (e) {
      _loggedIn = false; // Allow re-authentication on next attempt
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _sendDocumentMessage(String text) async {
    final documentId = state.documentId;
    if (documentId == null) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    final placeholder = ChatMessage(role: 'assistant', content: '');

    state = state.copyWith(
      messages: [...state.messages, userMessage, placeholder],
      isLoading: true,
      error: null,
    );

    try {
      await _ensureLoggedIn();
      final service = _getService();
      final stream = service.sendDocumentMessage(documentId, text);

      await for (final accumulated in stream) {
        if (_disposed) break;
        final messages = List<ChatMessage>.from(state.messages);
        messages[messages.length - 1] = messages.last.copyWith(
          content: accumulated,
        );
        state = state.copyWith(messages: messages);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Remove empty placeholder if streaming failed before any content arrived
      final messages = List<ChatMessage>.from(state.messages);
      if (messages.isNotEmpty &&
          messages.last.role == 'assistant' &&
          messages.last.content.isEmpty) {
        messages.removeLast();
      }
      _loggedIn = false; // Allow re-authentication on next attempt
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearHistory() {
    _cancelActiveNativeRequest();
    _loggedIn = false;
    if (state.mode == ChatMode.document) {
      state = ChatState(
        mode: ChatMode.document,
        documentId: state.documentId,
        documentTitle: state.documentTitle,
      );
    } else {
      state = const ChatState();
    }
  }

  void dismissError() {
    state = state.copyWith(error: null);
  }
}
