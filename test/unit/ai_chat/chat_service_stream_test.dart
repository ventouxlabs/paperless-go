// Paperless-AI document chat streams SSE over HTTP. Network chunks can end
// in the middle of a multi-byte UTF-8 character; decoding each chunk on its
// own threw a FormatException for any answer with accented letters.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/features/ai_chat/chat_service.dart';

/// Replies to every request with [chunks] as the streamed body.
class _ChunkedAdapter implements HttpClientAdapter {
  _ChunkedAdapter(this.chunks);

  final List<List<int>> chunks;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      Stream.fromIterable(chunks.map(Uint8List.fromList)),
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ChatService _serviceReplying(List<List<int>> chunks) {
  final dio = Dio(BaseOptions(baseUrl: 'https://ai.example.test/'))
    ..httpClientAdapter = _ChunkedAdapter(chunks);
  return ChatService(dio);
}

void main() {
  test('streams accumulated content until [DONE]', () async {
    final service = _serviceReplying([
      utf8.encode('data: {"content":"Hel"}\n\n'),
      utf8.encode('data: {"content":"lo"}\n\ndata: [DONE]\n\n'),
    ]);

    final updates = await service.sendDocumentMessage(1, 'hi').toList();

    expect(updates, ['Hel', 'Hello']);
  });

  test('decodes a multi-byte character split across chunks', () async {
    final bytes = utf8.encode('data: {"content":"café"}\n\ndata: [DONE]\n\n');
    // "é" is 0xC3 0xA9: cut between its two bytes.
    final split = bytes.indexOf(0xC3) + 1;
    final service = _serviceReplying([
      bytes.sublist(0, split),
      bytes.sublist(split),
    ]);

    final updates = await service.sendDocumentMessage(1, 'hi').toList();

    expect(updates, ['café']);
  });

  test('decodes 2-, 3- and 4-byte characters split at every byte', () async {
    final bytes =
        utf8.encode('data: {"content":"é € 📄"}\n\ndata: [DONE]\n\n');
    final service = _serviceReplying([
      for (final b in bytes) [b],
    ]);

    final updates = await service.sendDocumentMessage(1, 'hi').toList();

    expect(updates, ['é € 📄']);
  });
}
