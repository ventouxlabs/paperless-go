// Contract test for PaperlessApi.getDocument's response boundary
// (native AI #44 review).
//
// A captive portal or an access proxy can answer 200 with an HTML page. That
// must surface as a DioException(badResponse), like getUiSettings, not as a
// TypeError from a cast: callers (the AI suggestions re-read among them) only
// catch DioException.
//
// Run: flutter test test/unit/api/get_document_api_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

/// Replies to every request with a fixed 200 body.
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this._body, {this.contentType = Headers.jsonContentType});

  final String _body;
  final String contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(_body, 200, headers: {
        Headers.contentTypeHeader: [contentType],
      });

  @override
  void close({bool force = false}) {}
}

PaperlessApi _apiFor(_FixedAdapter adapter) =>
    PaperlessApi(Dio(BaseOptions(baseUrl: 'https://paperless.example.com/'))
      ..httpClientAdapter = adapter);

void main() {
  test('parses the real 3.2.1 detail response', () async {
    final body = File('test/fixtures/api/ai/document_detail_admin.json')
        .readAsStringSync();

    final doc = await _apiFor(_FixedAdapter(body)).getDocument(1);

    expect(doc.id, 1);
    expect(doc.title, 'Acme Energy electricity bill March 2026');
    expect(doc.userCanChange, isTrue);
  });

  test('a 200 HTML page throws a badResponse DioException, not a TypeError',
      () async {
    final api = _apiFor(
        _FixedAdapter('<html>Sign in</html>', contentType: 'text/html'));

    await expectLater(
      api.getDocument(1),
      throwsA(isA<DioException>()
          .having((e) => e.type, 'type', DioExceptionType.badResponse)
          .having((e) => e.response?.statusCode, 'status', 200)
          .having(
              (e) => e.message, 'message', contains('expected a JSON object'))),
    );
  });

  test('a 200 JSON array is rejected as a badResponse too', () async {
    await expectLater(
      _apiFor(_FixedAdapter('[]')).getDocument(1),
      throwsA(isA<DioException>()
          .having((e) => e.type, 'type', DioExceptionType.badResponse)),
    );
  });
}
