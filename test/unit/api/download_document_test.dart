// Regression test for #43: PaperlessApi.downloadDocumentTyped writes the file
// under the extension the response calls for, so callers never label text
// or images as PDF.
//
// Run: flutter test test/unit/api/download_document_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';

/// Replies to every request with [body] and the given response headers.
class _FixedAdapter implements HttpClientAdapter {
  _FixedAdapter(this.body, this.headers);

  final String body;
  final Map<String, List<String>> headers;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(body, 200, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('download_typed_test_');
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  PaperlessApi apiReplying(String body, Map<String, List<String>> headers) {
    final dio = Dio(BaseOptions(baseUrl: 'https://paperless.example.com/'));
    dio.httpClientAdapter = _FixedAdapter(body, headers);
    return PaperlessApi(dio);
  }

  test('a text original is written as .txt with its bytes intact', () async {
    final api = apiReplying('plain text', {
      'content-type': ['text/plain; charset=utf-8'],
      'content-disposition': ['attachment; filename="2026-09-30 note.txt"'],
    });

    final file = await api.downloadDocumentTyped(
      20,
      (ext) => '${dir.path}/20_note.$ext',
    );

    expect(file.path, '${dir.path}/20_note.txt');
    expect(await file.readAsString(), 'plain text');
  });

  test('an archived PDF is still written as .pdf', () async {
    final api = apiReplying('%PDF-1.4', {
      'content-type': ['application/pdf'],
      'content-disposition': ['attachment; filename="2026-05-01 bill.pdf"'],
    });

    final file = await api.downloadDocumentTyped(
      1,
      (ext) => '${dir.path}/1_bill.$ext',
    );

    expect(file.path, '${dir.path}/1_bill.pdf');
  });

  test('uses the original file name when the headers say nothing useful',
      () async {
    final api = apiReplying('jpeg bytes', {
      'content-type': ['application/octet-stream'],
    });

    final file = await api.downloadDocumentTyped(
      7,
      (ext) => '${dir.path}/7_photo.$ext',
      originalFileName: 'IMG_0001.jpg',
    );

    expect(file.path, '${dir.path}/7_photo.jpg');
  });
}
