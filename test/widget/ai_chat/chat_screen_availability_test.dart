import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/server_capabilities.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/ai_chat/chat_notifier.dart';
import 'package:paperless_go/features/ai_chat/chat_screen.dart';
import 'package:paperless_go/features/ai_chat/native_chat_providers.dart';

class _TestAiChatUrl extends AiChatUrl {
  _TestAiChatUrl(this.url);

  final String? url;

  @override
  String? build() => url;
}

class _LoadingChatNotifier extends ChatNotifier {
  bool stopCalled = false;

  @override
  ChatState build() => const ChatState(isLoading: true);

  @override
  void stop() => stopCalled = true;
}

class _TestChatBackendPreference extends ChatBackendPreferenceNotifier {
  @override
  ChatBackendPreference build() => ChatBackendPreference.auto;
}

void main() {
  Future<void> pumpChat(
    WidgetTester tester, {
    required bool nativeAi,
    String? aiUrl,
  }) => tester.pumpWidget(
    ProviderScope(
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
          _TestChatBackendPreference.new,
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const ChatScreen()),
    ),
  );

  testWidgets('native-only chat is usable without a Paperless-AI URL', (
    tester,
  ) async {
    await pumpChat(tester, nativeAi: true);

    expect(find.text('AI Chat not configured'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Paperless-AI remains usable when native AI is unavailable', (
    tester,
  ) async {
    await pumpChat(tester, nativeAi: false, aiUrl: 'https://paperless-ai.test');

    expect(find.text('AI Chat not configured'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('chat is blocked when no backend is available', (tester) async {
    await pumpChat(tester, nativeAi: false);

    expect(find.text('AI Chat not configured'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('native chat keeps questions over 4,000 code points local', (
    tester,
  ) async {
    await pumpChat(tester, nativeAi: true);
    await tester.enterText(find.byType(TextField), 'a' * 4001);
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pump();

    expect(find.textContaining('at most 4000 characters'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      hasLength(4001),
    );
  });

  testWidgets('shows a stop control while a response is loading', (
    tester,
  ) async {
    late _LoadingChatNotifier notifier;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveServerCapabilitiesProvider.overrideWith(
            (ref) => ServerCapabilities(
              aiEnabled: true,
              permissions: const {},
              version: null,
            ),
          ),
          chatBackendPreferenceProvider.overrideWith(
            _TestChatBackendPreference.new,
          ),
          chatNotifierProvider.overrideWith(() {
            notifier = _LoadingChatNotifier();
            return notifier;
          }),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const ChatScreen()),
      ),
    );

    expect(find.bySemanticsLabel('Stop'), findsOneWidget);
    expect(find.bySemanticsLabel('Send'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Stop'));
    expect(notifier.stopCalled, isTrue);
  });

  testWidgets('legacy loading does not show the native stop control', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectiveServerCapabilitiesProvider.overrideWith(
            (ref) => const ServerCapabilities(
              aiEnabled: false,
              permissions: {},
              version: null,
            ),
          ),
          aiChatUrlProvider.overrideWith(
            () => _TestAiChatUrl('https://paperless-ai.test'),
          ),
          chatBackendPreferenceProvider.overrideWith(
            _TestChatBackendPreference.new,
          ),
          chatNotifierProvider.overrideWith(_LoadingChatNotifier.new),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const ChatScreen()),
      ),
    );

    expect(find.bySemanticsLabel('Stop'), findsNothing);
    expect(find.bySemanticsLabel('Send'), findsOneWidget);
  });
}
