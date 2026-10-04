// Contract test for PaperlessApi.getAiSuggestions and AiSuggestions.fromJson
// (native AI #44, Phase 1).
//
// The 200 bodies are real Paperless-ngx 3.2.1 responses (see
// test/fixtures/api/ai/README.md). The odd shapes in the "defensive" group are
// constructed: they're what a future server or a broken proxy might send.
//
// Run: flutter test test/unit/api/ai_suggestions_api_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/dio_client.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/ai_suggestions.dart';

/// Records every outgoing request and replies with a fixed 200 body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._responseBody,
      {this.contentType = Headers.jsonContentType});

  final String _responseBody;
  final String contentType;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(_responseBody, 200, headers: {
      Headers.contentTypeHeader: [contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

PaperlessApi _apiFor(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://paperless.example.com/'));
  dio.httpClientAdapter = adapter;
  return PaperlessApi(dio);
}

String _fixture(String name) =>
    File('test/fixtures/api/ai/$name').readAsStringSync();

void main() {
  group('getAiSuggestions', () {
    test('GETs api/documents/<id>/ai_suggestions/ with a 150 s receive '
        'timeout, the noRetry flag and the caller\'s CancelToken', () async {
      final adapter = _RecordingAdapter(_fixture('ai_suggestions_bill.json'));
      final token = CancelToken();

      await _apiFor(adapter).getAiSuggestions(1, cancelToken: token);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.path, 'api/documents/1/ai_suggestions/');
      expect(request.receiveTimeout, const Duration(seconds: 150));
      expect(request.extra[kNoRetryExtraKey], isTrue);
      expect(request.cancelToken, same(token));
    });

    test('parses the real bill response', () async {
      final adapter = _RecordingAdapter(_fixture('ai_suggestions_bill.json'));

      final s = await _apiFor(adapter).getAiSuggestions(1);

      expect(s.title, 'Electricity Bill - March 2026');
      expect(s.tagIds, [2]);
      expect(s.suggestedTagNames, ['Electricity', 'Energy']);
      expect(s.correspondentIds, [1]);
      expect(s.suggestedCorrespondentNames, isEmpty);
      expect(s.documentTypeIds, [1]);
      expect(s.suggestedDocumentTypeNames, ['Electricity Bill', 'Invoice']);
      expect(s.storagePathIds, isEmpty);
      expect(s.suggestedStoragePathNames,
          ['Utilities/Electricity', 'Finance/Bills']);
      expect(s.dates, [DateTime(2026, 3, 31), DateTime(2026, 4, 15)]);
    });

    test('parses the real new-correspondent response', () async {
      final adapter = _RecordingAdapter(
          _fixture('ai_suggestions_new_correspondent.json'));

      final s = await _apiFor(adapter).getAiSuggestions(2);

      expect(s.title, 'Property Tax Assessment Notice 2025');
      expect(s.tagIds, [4]);
      expect(s.suggestedTagNames, ['Property Tax']);
      expect(s.correspondentIds, isEmpty);
      expect(s.suggestedCorrespondentNames, ['City Tax Office']);
      expect(s.documentTypeIds, [2]);
      expect(s.suggestedDocumentTypeNames, ['Notice']);
      expect(s.storagePathIds, isEmpty);
      expect(s.suggestedStoragePathNames, isEmpty);
      expect(s.dates, [DateTime(2026, 1, 20)]);
    });

    test('a 200 HTML body (captive portal / access page) throws a '
        'badResponse DioException, not a TypeError', () async {
      final api = _apiFor(
          _RecordingAdapter('<html>Sign in</html>', contentType: 'text/html'));

      await expectLater(
        api.getAiSuggestions(1),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.badResponse)
            .having((e) => e.response?.statusCode, 'status', 200)
            .having((e) => e.message, 'message',
                contains('expected a JSON object'))),
      );
    });

    test('a 200 JSON array is rejected as a badResponse too', () async {
      await expectLater(
        _apiFor(_RecordingAdapter('[]')).getAiSuggestions(1),
        throwsA(isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.badResponse)),
      );
    });
  });

  group('AiSuggestions.fromJson is defensive (constructed shapes)', () {
    test('an empty object is "no suggestions", not an error', () {
      final s = AiSuggestions.fromJson(const {});
      expect(s.title, isNull);
      expect(s.tagIds, isEmpty);
      expect(s.correspondentIds, isEmpty);
      expect(s.documentTypeIds, isEmpty);
      expect(s.storagePathIds, isEmpty);
      expect(s.suggestedTagNames, isEmpty);
      expect(s.suggestedCorrespondentNames, isEmpty);
      expect(s.suggestedDocumentTypeNames, isEmpty);
      expect(s.suggestedStoragePathNames, isEmpty);
      expect(s.dates, isEmpty);
    });

    test('wrong types never throw and are dropped item by item', () {
      final s = AiSuggestions.fromJson(const {
        'title': 42,
        'tags': [1, '2', null, 3.0, 4],
        'correspondents': 'Acme',
        'document_types': {'id': 1},
        'storage_paths': null,
        'suggested_tags': ['Utilities', 7, null, '   ', ' Water '],
        'suggested_correspondents': 'City Tax Office',
        'dates': [20260331, null],
      });
      expect(s.title, isNull);
      expect(s.tagIds, [1, 4]);
      expect(s.correspondentIds, isEmpty);
      expect(s.documentTypeIds, isEmpty);
      expect(s.storagePathIds, isEmpty);
      expect(s.suggestedTagNames, ['Utilities', 'Water']);
      expect(s.suggestedCorrespondentNames, isEmpty);
      expect(s.dates, isEmpty);
    });

    test('a blank title is no title; a padded one is trimmed', () {
      expect(AiSuggestions.fromJson(const {'title': '  '}).title, isNull);
      expect(AiSuggestions.fromJson(const {'title': ' Bill '}).title, 'Bill');
    });

    test('dates: only real YYYY-MM-DD calendar dates survive', () {
      final s = AiSuggestions.fromJson(const {
        'dates': [
          '2026-03-31',
          '2026-02-30', // DateTime.tryParse would roll this over to Mar 2
          '2026-13-01', // ...and this to Jan 2027
          '20260331', // compact form DateTime.tryParse accepts
          '2026-03-31T10:00', // a datetime, not a date
          'next Tuesday',
          ' 2024-02-29 ', // leap day, padded
        ],
      });
      expect(s.dates, [DateTime(2026, 3, 31), DateTime(2024, 2, 29)]);
    });

    test('the title is clamped to 128 characters (the server\'s own cap)', () {
      final s = AiSuggestions.fromJson({'title': 'x' * 500});
      expect(s.title, 'x' * 128);
    });

    test('clamping never splits a character made of two UTF-16 units', () {
      // 127 ASCII + an emoji (2 code units) + more: the emoji is kept whole.
      final s = AiSuggestions.fromJson({'title': '${'a' * 127}😀tail'});
      expect(s.title, '${'a' * 127}😀');
    });

    test('name lists: at most 10 items of at most 100 characters', () {
      final s = AiSuggestions.fromJson({
        'suggested_tags': [for (var i = 0; i < 25; i++) 'tag$i'],
        'suggested_correspondents': ['n' * 300],
        'suggested_document_types': [for (var i = 0; i < 11; i++) 'type$i'],
        'suggested_storage_paths': [for (var i = 0; i < 12; i++) 'p$i'],
      });
      expect(s.suggestedTagNames, [for (var i = 0; i < 10; i++) 'tag$i']);
      expect(s.suggestedCorrespondentNames, ['n' * 100]);
      expect(s.suggestedDocumentTypeNames, hasLength(10));
      expect(s.suggestedStoragePathNames, hasLength(10));
    });

    test('dates: at most 10 are kept', () {
      final s = AiSuggestions.fromJson({
        'dates': [
          for (var d = 1; d <= 20; d++) '2026-01-${'$d'.padLeft(2, '0')}',
        ],
      });
      expect(s.dates, hasLength(10));
      expect(s.dates.last, DateTime(2026, 1, 10));
    });

    test('the parsed lists are unmodifiable', () {
      final s = AiSuggestions.fromJson(const {
        'tags': [1],
        'suggested_tags': ['A'],
        'dates': ['2026-01-01'],
      });
      expect(() => s.tagIds.add(2), throwsUnsupportedError);
      expect(() => s.suggestedTagNames.add('B'), throwsUnsupportedError);
      expect(() => s.dates.clear(), throwsUnsupportedError);
    });
  });
}
