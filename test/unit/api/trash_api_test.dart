// Regression test for the Trash screen listing live documents (not trash).
//
// Root cause: there is no `is_in_trash` filter on /api/documents/ — DRF
// silently ignores unknown filters, so getTrashedDocuments() was returning
// whatever the default /api/documents/ queryset returns (live documents),
// and restoreFromTrash()/emptyTrash() were routed through bulk_edit, which
// has no idea which documents are actually trashed. The real trash API
// (since Paperless-ngx 2.10) is a dedicated resource:
//   GET  /api/trash/  -> paginated {count, next, previous, results}
//   POST /api/trash/  {"documents": [ids], "action": "restore" | "empty"}
//
// Run: flutter test test/unit/api/trash_api_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

dynamic _loadFixture(String name) {
  final file = File('test/fixtures/api/$name');
  return jsonDecode(file.readAsStringSync());
}

/// Records every outgoing request and replies with a fixed, canned body —
/// so tests can assert both the exact request that went out (path, method,
/// body) and, for GET, parse a real response.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({String responseBody = ''}) : _responseBody = responseBody;

  final String _responseBody;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(_responseBody, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
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
  group('PaperlessApi.getTrashedDocuments', () {
    test('GETs api/trash/ with page and page_size and parses the paginated response', () async {
      final adapter = _RecordingAdapter(responseBody: jsonEncode(_loadFixture('documents_page1.json')));
      final api = _makeApi(adapter);

      final page = await api.getTrashedDocuments(page: 2, pageSize: 10);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.first;
      expect(request.method, equals('GET'));
      expect(request.path, equals('api/trash/'));
      // Exact match: the old is_in_trash / ordering / truncate_content
      // params must not come back (the trash endpoint ignores them).
      expect(request.queryParameters, equals({'page': 2, 'page_size': 10}));

      expect(page.count, equals(2));
      expect(page.results, hasLength(2));
    });
  });

  group('PaperlessApi.restoreFromTrash', () {
    test('POSTs to api/trash/ with action restore', () async {
      final adapter = _RecordingAdapter();
      final api = _makeApi(adapter);

      await api.restoreFromTrash([1, 2]);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.first;
      expect(request.method, equals('POST'));
      expect(request.path, equals('api/trash/'));

      final data = request.data as Map<String, dynamic>;
      expect(data, equals({'documents': [1, 2], 'action': 'restore'}));
    });
  });

  group('PaperlessApi.emptyTrash', () {
    test('POSTs to api/trash/ with action empty', () async {
      final adapter = _RecordingAdapter();
      final api = _makeApi(adapter);

      await api.emptyTrash([5]);

      expect(adapter.requests, hasLength(1));
      final request = adapter.requests.first;
      expect(request.method, equals('POST'));
      expect(request.path, equals('api/trash/'));

      final data = request.data as Map<String, dynamic>;
      expect(
        data,
        equals({'documents': [5], 'action': 'empty'}),
        reason:
            'A permanent delete must go to the trash endpoint, which rejects '
            'the whole request if any id is not already in the trash.',
      );
    });
  });
}
