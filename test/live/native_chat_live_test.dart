import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/dio_client.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/features/ai_chat/native_chat_service.dart';

void main() {
  final baseUrl = Platform.environment['PAPERLESS_CHAT_TEST_URL'];
  final token = Platform.environment['PAPERLESS_CHAT_TEST_TOKEN'];
  final documentId = int.tryParse(
    Platform.environment['PAPERLESS_CHAT_TEST_DOCUMENT_ID'] ?? '',
  );
  final configured = baseUrl != null && token != null && documentId != null;

  group(
    'live native chat on fictional documents',
    () {
      late Dio dio;
      late NativeChatService service;

      setUp(() {
        dio = DioClient.create(baseUrl!, token!);
        // Keep credentials and session headers out of diagnostic test output.
        dio.interceptors.removeWhere(
          (interceptor) => interceptor is LogInterceptor,
        );
        service = NativeChatService(PaperlessApi(dio));
      });
      tearDown(() => dio.close(force: true));

      test('document answer includes usable references', () async {
        final updates = await service
            .send('What is this document about?', documentId: documentId)
            .toList();
        final result = updates.last;
        expect(result.isComplete, isTrue);
        expect(result.softError, isNull);
        expect(result.answer.trim(), isNotEmpty);
        expect(result.answer, isNot(contains('__PAPERLESS_CHAT_METADATA__')));
        expect(
          result.references.map((reference) => reference.id),
          contains(documentId),
        );
      }, timeout: const Timeout(Duration(minutes: 6)));

      test('archive answer includes references', () async {
        final result =
            (await service
                    .send('Summarize the documents available in this archive.')
                    .toList())
                .last;
        expect(result.isComplete, isTrue);
        expect(result.softError, isNull);
        expect(result.answer.trim(), isNotEmpty);
        expect(result.references, isNotEmpty);
      }, timeout: const Timeout(Duration(minutes: 6)));

      test('missing document surfaces an HTTP error', () async {
        await expectLater(
          service
              .send('Summarize this document.', documentId: 2147483647)
              .toList(),
          throwsA(
            isA<DioException>().having(
              (error) => error.response?.statusCode,
              'status',
              400,
            ),
          ),
        );
      });
    },
    skip: configured
        ? false
        : 'Requires an explicitly configured fictional-document server.',
  );
}
