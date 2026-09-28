// Regression test for: batch tagging 403 error.
//
// Root cause: bulkEdit() was posting to 'api/bulk_edit/' but Paperless-ngx
// registers bulk_edit as a custom action on DocumentViewSet, placing it at
// 'api/documents/bulk_edit/'. The wrong URL caused a 403 (via Nginx Proxy
// Manager) instead of the expected 200.
//
// Run: flutter test test/unit/api/bulk_edit_url_test.dart

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

/// Records all outgoing requests without making real HTTP calls.
class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('', 200);
  }

  @override
  void close({bool force = false}) {}
}

PaperlessApi _makeApi(_RecordingAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://paperless.example.com/',
      headers: {'Authorization': 'Token test-token'},
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
  dio.httpClientAdapter = adapter;
  return PaperlessApi(dio);
}

void main() {
  group('PaperlessApi.bulkEdit remove_tags', () {
    late _RecordingAdapter adapter;
    late PaperlessApi api;

    setUp(() {
      adapter = _RecordingAdapter();
      api = _makeApi(adapter);
    });

    test('remove_tags sends non-empty remove_tags and empty add_tags', () async {
      await api.bulkEdit(
        documents: [1, 2],
        method: 'modify_tags',
        parameters: {'add_tags': <int>[], 'remove_tags': [7]},
      );

      final data = adapter.requests.first.data as Map<String, dynamic>;
      expect(data['method'], equals('modify_tags'));
      expect(data['parameters']['add_tags'], isEmpty);
      expect(data['parameters']['remove_tags'], equals([7]));
    });
  });

  group('PaperlessApi.bulkEdit URL', () {
    late _RecordingAdapter adapter;
    late PaperlessApi api;

    setUp(() {
      adapter = _RecordingAdapter();
      api = _makeApi(adapter);
    });

    test('posts to api/documents/bulk_edit/ — not api/bulk_edit/', () async {
      await api.bulkEdit(
        documents: [1, 2, 3],
        method: 'modify_tags',
        parameters: {
          'add_tags': [5],
          'remove_tags': <int>[],
        },
      );

      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.first.path,
        equals('api/documents/bulk_edit/'),
        reason:
            'bulk_edit is a custom action on DocumentViewSet and must be '
            'reached at /api/documents/bulk_edit/. '
            'Posting to /api/bulk_edit/ returns 403 via Nginx Proxy Manager.',
      );
    });

    test('sends correct payload for modify_tags', () async {
      await api.bulkEdit(
        documents: [1, 2],
        method: 'modify_tags',
        parameters: {
          'add_tags': [5, 6],
          'remove_tags': [3],
        },
      );

      final data = adapter.requests.first.data as Map<String, dynamic>;
      expect(data['documents'], equals([1, 2]));
      expect(data['method'], equals('modify_tags'));
      expect(data['parameters'], equals({'add_tags': [5, 6], 'remove_tags': [3]}));
    });

    test('omits parameters key when not provided (e.g. delete)', () async {
      await api.bulkEdit(documents: [1], method: 'delete');

      final data = adapter.requests.first.data as Map<String, dynamic>;
      expect(data.containsKey('parameters'), isFalse);
    });

    test('uses POST method', () async {
      await api.bulkEdit(
        documents: [1],
        method: 'modify_tags',
        parameters: {'add_tags': [5], 'remove_tags': <int>[]},
      );

      expect(adapter.requests.first.method, equals('POST'));
    });
  });

  // Regression test for #39: 'trash' is not a bulk_edit method on any
  // Paperless-ngx version — the server answered 400 and delete always failed.
  group('PaperlessApi.trashDocuments', () {
    late _RecordingAdapter adapter;
    late PaperlessApi api;

    setUp(() {
      adapter = _RecordingAdapter();
      api = _makeApi(adapter);
    });

    test('soft-deletes via bulk_edit method delete', () async {
      await api.trashDocuments([3, 4]);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.first;
      expect(request.method, equals('POST'));
      expect(request.path, equals('api/documents/bulk_edit/'));
      final data = request.data as Map<String, dynamic>;
      expect(data['method'], equals('delete'));
      expect(data['documents'], equals([3, 4]));
    });
  });

  // Regression test for #41: 'redo_ocr' is not an accepted bulk_edit choice
  // on Paperless-ngx 2.20 or 3.x — bulk "Redo OCR" was rejected with a 400.
  group('PaperlessApi.reprocessDocuments', () {
    late _RecordingAdapter adapter;
    late PaperlessApi api;

    setUp(() {
      adapter = _RecordingAdapter();
      api = _makeApi(adapter);
    });

    test('re-runs OCR via bulk_edit method reprocess', () async {
      await api.reprocessDocuments([5, 6]);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.first;
      expect(request.path, equals('api/documents/bulk_edit/'));
      final data = request.data as Map<String, dynamic>;
      expect(data['method'], equals('reprocess'));
      expect(data['documents'], equals([5, 6]));
    });
  });
}
