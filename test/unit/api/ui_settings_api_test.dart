// Contract test for PaperlessApi.getUiSettings (native AI #44, Phase 0).
//
// GET /api/ui_settings/ is where Paperless-ngx 3.x reports
// `settings.ai_enabled` and the user's `permissions`. The fixture was
// captured from a real Paperless-ngx 3.2.1 server (AI off).
//
// Run: flutter test test/unit/api/ui_settings_api_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

/// Records every outgoing request and replies with a fixed 200 body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._responseBody, {this.contentType = Headers.jsonContentType});

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

void main() {
  test('getUiSettings GETs api/ui_settings/ and returns the parsed JSON map', () async {
    final body = File('test/fixtures/api/ui_settings_ai_disabled.json').readAsStringSync();
    final adapter = _RecordingAdapter(body);

    final json = await _apiFor(adapter).getUiSettings();

    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.first.method, equals('GET'));
    expect(adapter.requests.first.path, equals('api/ui_settings/'));
    expect(json, equals(jsonDecode(body)));
    expect((json['settings'] as Map<String, dynamic>)['ai_enabled'], isFalse);
    expect(json['permissions'], contains('change_document'));
  });

  test('a 200 HTML body (captive portal / Cloudflare Access) throws a badResponse DioException, not a TypeError', () async {
    final api = _apiFor(_RecordingAdapter('<html>Sign in</html>', contentType: 'text/html'));

    await expectLater(
      api.getUiSettings(),
      throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.badResponse)
            .having((e) => e.response?.statusCode, 'status', 200)
            .having((e) => e.message, 'message', contains('expected a JSON object')),
      ),
    );
  });

  test('a 200 JSON array (not an object) is also rejected as a badResponse', () async {
    final api = _apiFor(_RecordingAdapter('[]'));

    await expectLater(
      api.getUiSettings(),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.badResponse)),
    );
  });
}
