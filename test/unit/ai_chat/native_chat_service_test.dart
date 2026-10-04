import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/dio_client.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/features/ai_chat/native_chat_service.dart';

class _ChunkedAdapter implements HttpClientAdapter {
  _ChunkedAdapter(
    this.chunks, {
    this.statusCode = 200,
    this.contentType = 'text/event-stream',
    this.onCancel,
  });

  final List<List<int>> chunks;
  final int statusCode;
  final String contentType;
  final void Function()? onCancel;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final controller = StreamController<Uint8List>(onCancel: onCancel);
    for (final chunk in chunks) {
      controller.add(Uint8List.fromList(chunk));
    }
    unawaited(controller.close());
    return ResponseBody(
      controller.stream,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('NativeChatStreamParser', () {
    test(
      'hides a split delimiter and reads references from its trailer',
      () async {
        final delimiter = NativeChatStreamParser.metadataDelimiter;
        final updates = await NativeChatStreamParser.parse(
          Stream.fromIterable([
            utf8.encode('Answer.$delimiter'.substring(0, 12)),
            utf8.encode('Answer.$delimiter'.substring(12)),
            utf8.encode('{"references":[{"id":6,"title":"Utility bill"}]}'),
          ]),
        ).toList();

        expect(updates.map((u) => u.answer), ['Answer.', 'Answer.']);
        final done = updates.last;
        expect(done.isComplete, isTrue);
        expect(done.references.single.id, 6);
        expect(done.references.single.title, 'Utility bill');
      },
    );

    test('decodes a multi-byte character split at every byte', () async {
      final bytes = utf8.encode('café € 📄');
      final updates = await NativeChatStreamParser.parse(
        Stream.fromIterable([
          for (final byte in bytes) [byte],
        ]),
      ).toList();

      expect(updates.last.answer, 'café € 📄');
      expect(updates.last.references, isEmpty);
    });

    test('keeps answer and drops malformed metadata', () async {
      final updates = await NativeChatStreamParser.parse(
        Stream.value(
          utf8.encode('Useful answer.\n\n__PAPERLESS_CHAT_METADATA__not-json'),
        ),
      ).toList();

      expect(updates.last.answer, 'Useful answer.');
      expect(updates.last.references, isEmpty);
    });

    test('keeps a response without a metadata trailer', () async {
      final updates = await NativeChatStreamParser.parse(
        Stream.value(utf8.encode('Plain answer')),
      ).toList();

      expect(updates.last.answer, 'Plain answer');
      expect(updates.last.isComplete, isTrue);
    });

    test(
      'recognizes the no-content response as a soft terminal error',
      () async {
        final updates = await NativeChatStreamParser.parse(
          Stream.value(
            utf8.encode(
              "Sorry, I couldn't find any content to answer your question.",
            ),
          ),
        ).toList();

        expect(updates.last.answer, isEmpty);
        expect(updates.last.softError, NativeChatSoftError.noContent);
      },
    );

    test('keeps a partial answer before a generation-failed soft error',
        () async {
      const error = 'Sorry, something went wrong while generating a response.';
      final updates = await NativeChatStreamParser.parse(
        Stream.fromIterable([utf8.encode('Partial answer. $error')]),
      ).toList();

      expect(updates.last.answer, 'Partial answer. ');
      expect(updates.last.softError, NativeChatSoftError.generationFailed);
    });

    test('drops malformed reference members but retains valid ones', () async {
      final updates = await NativeChatStreamParser.parse(
        Stream.value(utf8.encode(
          'Answer${NativeChatStreamParser.metadataDelimiter}'
          '{"references":[{"id":1,"title":"Good"},'
          '{"id":"2","title":"Wrong id"},{"id":3},null]}',
        )),
      ).toList();

      expect(updates.last.references, hasLength(1));
      expect(updates.last.references.single.id, 1);
    });

    test('hides the delimiter at every possible split offset', () async {
      const answer = 'Answer';
      const trailer = '{"references":[]}';
      final complete = '$answer${NativeChatStreamParser.metadataDelimiter}$trailer';
      for (var split = 1; split < complete.length; split++) {
        final updates = await NativeChatStreamParser.parse(
          Stream.fromIterable([
            utf8.encode(complete.substring(0, split)),
            utf8.encode(complete.substring(split)),
          ]),
        ).toList();
        expect(updates.last.answer, answer, reason: 'split at $split');
        expect(
          updates.where((update) => !update.isComplete).every(
                (update) =>
                    !update.answer.contains(
                      NativeChatStreamParser.metadataDelimiter,
                    ),
              ),
          isTrue,
          reason: 'split at $split',
        );
      }
    });

    test('holds an unfinished delimiter out of visible answer text', () async {
      final partial = NativeChatStreamParser.metadataDelimiter.substring(0, 12);
      final updates = await NativeChatStreamParser.parse(
        Stream.value(utf8.encode('Answer$partial')),
      ).toList();

      expect(updates.first.answer, 'Answer');
      expect(updates.last.answer, 'Answer$partial');
      expect(updates.last.isComplete, isTrue);
    });
  });

  group('NativeChatService transport', () {
    test('uses authenticated-main-Dio chat contract and no retry', () async {
      final adapter = _ChunkedAdapter([utf8.encode('Hello')]);
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://paperless.example.test/',
          headers: {'Accept': 'application/json; version=9'},
        ),
      )..httpClientAdapter = adapter;
      final service = NativeChatService(PaperlessApi(dio));
      final token = CancelToken();

      final updates = await service
          .send('What is this?', documentId: 5, cancelToken: token)
          .toList();

      expect(updates.last.answer, 'Hello');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, 'api/documents/chat/');
      expect(request.data, {'q': 'What is this?', 'document_id': 5});
      expect(request.responseType, ResponseType.stream);
      expect(request.receiveTimeout, const Duration(seconds: 300));
      expect(request.headers['Accept-Encoding'], 'identity');
      expect(request.headers['Accept'], 'application/json; version=9');
      expect(request.extra[kNoRetryExtraKey], isTrue);
      expect(request.cancelToken, same(token));
    });

    test('omits absent and zero document IDs', () async {
      for (final documentId in <int?>[null, 0]) {
        final adapter = _ChunkedAdapter([utf8.encode('Hello')]);
        final service = NativeChatService(
          PaperlessApi(Dio(BaseOptions(baseUrl: 'https://example.test/'))
            ..httpClientAdapter = adapter),
        );

        await service.send('Question', documentId: documentId).drain<void>();
        expect(adapter.requests.single.data, {'q': 'Question'});
      }
    });

    test('propagates an already-cancelled token to Dio', () async {
      final adapter = _ChunkedAdapter([utf8.encode('Hello')]);
      final service = NativeChatService(
        PaperlessApi(Dio(BaseOptions(baseUrl: 'https://example.test/'))
          ..httpClientAdapter = adapter),
      );
      final token = CancelToken()..cancel('stop');

      await expectLater(
        service.send('Question', cancelToken: token).drain<void>(),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, isEmpty);
    });

    test('passes through non-2xx statuses', () async {
      final adapter = _ChunkedAdapter(
        [utf8.encode('Insufficient permissions')],
        statusCode: 403,
        contentType: 'text/plain',
      );
      final service = NativeChatService(
        PaperlessApi(Dio(BaseOptions(baseUrl: 'https://example.test/'))
          ..httpClientAdapter = adapter),
      );

      await expectLater(
        service.send('Question').drain<void>(),
        throwsA(isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status code',
          403,
        )),
      );
    });

    test('rejects a 200 HTML or JSON body and cancels its stream', () async {
      for (final contentType in ['text/html', 'application/json']) {
        var cancelled = false;
        final adapter = _ChunkedAdapter(
          [utf8.encode('<html>Login</html>')],
          contentType: contentType,
          onCancel: () => cancelled = true,
        );
        final service = NativeChatService(
          PaperlessApi(Dio(BaseOptions(baseUrl: 'https://example.test/'))
            ..httpClientAdapter = adapter),
        );

        await expectLater(
          service.send('Question').drain<void>(),
          throwsA(isA<DioException>()
              .having((error) => error.type, 'type', DioExceptionType.badResponse)
              .having((error) => error.message, 'message',
                  contains('text/event-stream'))),
        );
        expect(cancelled, isTrue, reason: contentType);
      }
    });

    test('rejects blank and too-long questions before the request', () async {
      final adapter = _ChunkedAdapter([]);
      final service = NativeChatService(
        PaperlessApi(
          Dio(BaseOptions(baseUrl: 'https://example.test/'))
            ..httpClientAdapter = adapter,
        ),
      );

      await expectLater(service.send(' ').toList(), throwsArgumentError);
      await expectLater(service.send('a' * 4001).toList(), throwsArgumentError);
      expect(adapter.requests, isEmpty);
    });

    test('counts the server limit in Unicode code points', () async {
      final adapter = _ChunkedAdapter([utf8.encode('Hello')]);
      final service = NativeChatService(
        PaperlessApi(
          Dio(BaseOptions(baseUrl: 'https://example.test/'))
            ..httpClientAdapter = adapter,
        ),
      );

      await service.send('📄' * 4000).drain<void>();
      await expectLater(
        service.send('📄' * 4001).drain<void>(),
        throwsArgumentError,
      );
    });
  });
}
