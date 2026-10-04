// Retry opt-out for the production Dio (native AI #44, Phase 1).
//
// `_RetryInterceptor` retries idempotent requests on a timeout up to 3 times.
// One AI-suggestions tap must never become 4 paid model calls, so a request
// can opt out with `extra: {kNoRetryExtraKey: true}`.
//
// Run: flutter test test/unit/api/dio_retry_opt_out_test.dart

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/dio_client.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

/// Counts calls and fails every one with a client-side receive timeout.
class _TimingOutAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.receiveTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _productionDio(_TimingOutAdapter adapter) =>
    DioClient.create('https://paperless.example.com', 'test-token')
      ..httpClientAdapter = adapter;

Matcher get _receiveTimeout => throwsA(isA<DioException>()
    .having((e) => e.type, 'type', DioExceptionType.receiveTimeout));

void main() {
  test('a GET flagged noRetry that times out reaches the adapter exactly once',
      () async {
    final adapter = _TimingOutAdapter();

    await expectLater(
      _productionDio(adapter).get(
        'api/documents/1/',
        options: Options(extra: {kNoRetryExtraKey: true}),
      ),
      _receiveTimeout,
    );
    expect(adapter.calls, 1);
  });

  test('getAiSuggestions opts out of retry end to end (one model call)',
      () async {
    final adapter = _TimingOutAdapter();

    await expectLater(
      PaperlessApi(_productionDio(adapter)).getAiSuggestions(1),
      _receiveTimeout,
    );
    expect(adapter.calls, 1);
  });

  test('an unflagged GET still retries 3 times (4 calls) on timeout', () async {
    final adapter = _TimingOutAdapter();

    await expectLater(
      _productionDio(adapter).get('api/documents/1/'),
      _receiveTimeout,
    );
    expect(adapter.calls, 4);
  });

  test('noRetry: false behaves like no flag', () async {
    final adapter = _TimingOutAdapter();

    await expectLater(
      _productionDio(adapter).get(
        'api/documents/1/',
        options: Options(extra: {kNoRetryExtraKey: false}),
      ),
      _receiveTimeout,
    );
    expect(adapter.calls, 4);
  });
}
