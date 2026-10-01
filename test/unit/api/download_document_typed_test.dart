// A document downloaded once as its .txt original and later archived is then
// served as a PDF. The download must replace the cached .txt, not sit beside it.

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

/// Answers every request with [body] under [contentType].
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.body, this.contentType, [this.status = 200]);

  final String body;
  final String contentType;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromString(body, status, headers: {
        Headers.contentTypeHeader: [contentType],
      });

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('typed_dl_test_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a PDF download removes the stale .txt copy of the same document',
      () async {
    final stale = File('${dir.path}/preview_7.txt')..writeAsStringSync('old');
    final other = File('${dir.path}/preview_8.txt')..writeAsStringSync('x');
    final dio = Dio(BaseOptions(baseUrl: 'https://paperless.test/'))
      ..httpClientAdapter = _FixedAdapter('%PDF-1.7', 'application/pdf');

    final file = await PaperlessApi(dio).downloadDocumentTyped(
      7,
      (extension) => '${dir.path}/preview_7.$extension',
    );

    expect(file.path, '${dir.path}/preview_7.pdf');
    expect(file.readAsStringSync(), '%PDF-1.7');
    expect(stale.existsSync(), isFalse);
    expect(other.existsSync(), isTrue);
  });

  test('a failed download keeps the cached copy', () async {
    final cached = File('${dir.path}/preview_7.txt')..writeAsStringSync('old');
    final dio = Dio(BaseOptions(baseUrl: 'https://paperless.test/'))
      ..httpClientAdapter = _FixedAdapter('gone', 'application/pdf', 404);

    await expectLater(
      PaperlessApi(dio).downloadDocumentTyped(
        7,
        (extension) => '${dir.path}/preview_7.$extension',
      ),
      throwsA(isA<DioException>()),
    );

    expect(cached.readAsStringSync(), 'old');
  });
}
