import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/features/ai_chat/chat_notifier.dart';
import 'package:paperless_go/features/ai_chat/chat_service.dart';
import 'package:paperless_go/features/ai_chat/native_chat_providers.dart';
import 'package:paperless_go/features/ai_chat/native_chat_service.dart';

class _NativeCall {
  const _NativeCall({
    required this.question,
    required this.documentId,
    required this.cancelToken,
  });

  final String question;
  final int? documentId;
  final CancelToken? cancelToken;
}

class _FakeNativeChatService extends NativeChatService {
  _FakeNativeChatService() : super(PaperlessApi(Dio()));

  final calls = <_NativeCall>[];
  final controller = StreamController<NativeChatUpdate>();

  @override
  Stream<NativeChatUpdate> send(
    String question, {
    int? documentId,
    CancelToken? cancelToken,
  }) {
    calls.add(
      _NativeCall(
        question: question,
        documentId: documentId,
        cancelToken: cancelToken,
      ),
    );
    return controller.stream;
  }
}

void main() {
  late _FakeNativeChatService service;
  late ProviderContainer container;

  setUp(() {
    service = _FakeNativeChatService();
    container = ProviderContainer(
      overrides: [
        nativeChatAvailableProvider.overrideWithValue(true),
        nativeChatServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(() async {
      await service.controller.close();
      container.dispose();
    });
  });

  test(
    'native global chat is single-turn and retains returned references',
    () async {
      final notifier = container.read(chatNotifierProvider.notifier);
      final pending = notifier.sendMessage('What is this archive about?');
      await Future<void>.delayed(Duration.zero);

      expect(service.calls, hasLength(1));
      expect(service.calls.single.question, 'What is this archive about?');
      expect(service.calls.single.documentId, isNull);

      service.controller
        ..add(const NativeChatUpdate(answer: 'It concerns utilities.'))
        ..add(
          const NativeChatUpdate(
            answer: 'It concerns utilities.',
            references: [DocumentReference(id: 4, title: 'Electricity bill')],
            isComplete: true,
          ),
        )
        ..close();
      await pending;

      final state = container.read(chatNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.map((message) => message.role), [
        'user',
        'assistant',
      ]);
      expect(state.messages.last.content, 'It concerns utilities.');
      expect(state.messages.last.references.single.id, 4);
    },
  );

  test(
    'native document chat skips external initialization and sends its id',
    () async {
      final notifier = container.read(chatNotifierProvider.notifier);
      await notifier.initDocumentMode(19, 'Statement');
      expect(service.calls, isEmpty);

      final pending = notifier.sendMessage('Summarize this.');
      await Future<void>.delayed(Duration.zero);
      expect(service.calls.single.documentId, 19);

      await service.controller.close();
      await pending;
    },
  );

  test(
    'stop cancels the native request without showing a chat error',
    () async {
      final notifier = container.read(chatNotifierProvider.notifier);
      final pending = notifier.sendMessage('Please keep generating.');
      await Future<void>.delayed(Duration.zero);

      notifier.stop();
      expect(service.calls.single.cancelToken?.isCancelled, isTrue);
      expect(container.read(chatNotifierProvider).isLoading, isFalse);

      await service.controller.close();
      await pending;
      expect(container.read(chatNotifierProvider).error, isNull);
    },
  );

  test(
    'changing document mode cancels and ignores the previous native stream',
    () async {
      final notifier = container.read(chatNotifierProvider.notifier);
      final pending = notifier.sendMessage('Question for the old context');
      await Future<void>.delayed(Duration.zero);

      await notifier.initDocumentMode(42, 'New document');
      expect(service.calls.single.cancelToken?.isCancelled, isTrue);

      service.controller.add(const NativeChatUpdate(answer: 'stale answer'));
      await service.controller.close();
      await pending;

      final state = container.read(chatNotifierProvider);
      expect(state.mode, ChatMode.document);
      expect(state.documentId, 42);
      expect(state.messages, isEmpty);
    },
  );
}
