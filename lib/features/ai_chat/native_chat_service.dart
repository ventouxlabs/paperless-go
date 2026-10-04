import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/api/paperless_api.dart';
import 'chat_service.dart';

/// Native Paperless-ngx (3.x) single-turn document chat.
///
/// This intentionally has no dependency on the Paperless-AI service or its
/// JWT.  Its transport is [PaperlessApi], which uses the authenticated main
/// Dio client.
class NativeChatService {
  NativeChatService(this._api);

  final PaperlessApi _api;

  Stream<NativeChatUpdate> send(
    String question, {
    int? documentId,
    CancelToken? cancelToken,
  }) async* {
    final bytes = await _api.openNativeChat(
      question,
      documentId: documentId,
      cancelToken: cancelToken,
    );
    yield* NativeChatStreamParser.parse(bytes);
  }
}

/// The two English terminal strings Paperless-ngx sends inside a successful
/// (HTTP 200) chat response. They are failures rather than assistant answers.
enum NativeChatSoftError {
  generationFailed,
  noContent;

  static NativeChatSoftError? fromTerminalText(String text) {
    if (text.endsWith(_generationFailedText)) return generationFailed;
    if (text.endsWith(_noContentText)) return noContent;
    return null;
  }
}

const _generationFailedText =
    'Sorry, something went wrong while generating a response.';
const _noContentText =
    "Sorry, I couldn't find any content to answer your question.";

/// A cumulative native-chat result. Before [isComplete], [references] and
/// [softError] are unavailable because their trailer / terminal text may still
/// be split across network chunks.
class NativeChatUpdate {
  const NativeChatUpdate({
    required this.answer,
    this.references = const [],
    this.softError,
    this.isComplete = false,
  });

  final String answer;
  final List<DocumentReference> references;
  final NativeChatSoftError? softError;
  final bool isComplete;
}

/// Incrementally parses Paperless-ngx's raw UTF-8 chat body.
///
/// Despite its content type, the endpoint is not SSE. It is answer text with
/// an optional metadata trailer separated by [metadataDelimiter].  This is a
/// pure stream transformer: no HTTP, Dio, or UI state is involved.
class NativeChatStreamParser {
  static const metadataDelimiter = '\n\n__PAPERLESS_CHAT_METADATA__';

  static Stream<NativeChatUpdate> parse(Stream<List<int>> bytes) async* {
    var raw = '';
    var lastEmitted = '';

    // `bind` retains incomplete multi-byte sequences across chunks; decoding
    // every byte chunk independently would throw for an accented character.
    await for (final chunk in utf8.decoder.bind(bytes)) {
      raw += chunk;
      final visible = _visibleAnswer(raw);
      if (visible != lastEmitted) {
        lastEmitted = visible;
        yield NativeChatUpdate(answer: visible);
      }
    }

    final delimiterIndex = raw.indexOf(metadataDelimiter);
    final answerWithPossibleError = delimiterIndex < 0
        ? raw
        : raw.substring(0, delimiterIndex);
    final softError = NativeChatSoftError.fromTerminalText(
      answerWithPossibleError,
    );
    final answer = softError == null
        ? answerWithPossibleError
        : answerWithPossibleError.substring(
            0,
            answerWithPossibleError.length - _terminalText(softError).length,
          );
    final references = delimiterIndex < 0
        ? const <DocumentReference>[]
        : _parseReferences(
            raw.substring(delimiterIndex + metadataDelimiter.length),
          );

    // Always emit a terminal event, including when its visible answer did not
    // change. Consumers need the completion marker to attach references or
    // present an in-band failure.
    yield NativeChatUpdate(
      answer: answer,
      references: references,
      softError: softError,
      isComplete: true,
    );
  }

  static String _visibleAnswer(String raw) {
    final delimiterIndex = raw.indexOf(metadataDelimiter);
    if (delimiterIndex >= 0) return raw.substring(0, delimiterIndex);

    // Do not leak a partially-arrived trailer into the answer. Hold the
    // longest suffix that is also a delimiter prefix until the next chunk
    // proves whether it is ordinary text or the metadata sentinel.
    final longest = raw.length < metadataDelimiter.length
        ? raw.length
        : metadataDelimiter.length - 1;
    for (var length = longest; length > 0; length--) {
      if (raw.endsWith(metadataDelimiter.substring(0, length))) {
        return raw.substring(0, raw.length - length);
      }
    }
    return raw;
  }

  static List<DocumentReference> _parseReferences(String metadata) {
    try {
      final decoded = jsonDecode(metadata);
      if (decoded is! Map<String, dynamic>) return const [];
      final rawReferences = decoded['references'];
      if (rawReferences is! List) return const [];
      return [
        for (final reference in rawReferences)
          if (reference is Map)
            if (reference['id'] is int && reference['title'] is String)
              DocumentReference(
                id: reference['id'] as int,
                title: reference['title'] as String,
              ),
      ];
    } on FormatException {
      // Metadata is advisory. A malformed trailer must never discard the
      // otherwise useful answer text.
      return const [];
    }
  }

  static String _terminalText(NativeChatSoftError error) => switch (error) {
    NativeChatSoftError.generationFailed => _generationFailedText,
    NativeChatSoftError.noContent => _noContentText,
  };
}
