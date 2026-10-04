// Error kinds and their text for "Suggest with AI" (native AI #44, Phase 1).
//
// The mapper returns a KIND (aiSuggestionsErrorKind); the flow widget owns the
// English text (aiSuggestionsErrorText), so translations live in one place.
//
// Every case goes through PaperlessApi.getAiSuggestions with a fake adapter,
// so Dio decodes (or doesn't decode) each body exactly as it would in the app:
// a JSON content type becomes a Map, text/html stays a String.
//
// REAL bodies (Paperless-ngx 3.2.1, test/fixtures/api/ai/README.md): 403, 404,
// 502. CONSTRUCTED bodies (no live capture yet; shapes from the 3.2.1 source
// or from the proxy in front of it): 400 x2, 500, 502/503 from a proxy, 503
// from the AI module, 524.
//
// Run: flutter test test/unit/documents/ai_suggestions_error_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_error.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_flow.dart';

const _html = 'text/html; charset=utf-8';
const _json = 'application/json';

/// Answers every request with one canned status, body and content type, or
/// throws [error] when set (client-side failures).
class _CannedAdapter implements HttpClientAdapter {
  _CannedAdapter({
    this.status = 200,
    this.body = '',
    this.contentType = _json,
    this.error,
  });

  final int status;
  final String body;
  final String contentType;
  final DioExceptionType? error;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final type = error;
    if (type != null) throw DioException(requestOptions: options, type: type);
    return ResponseBody.fromString(body, status, headers: {
      Headers.contentTypeHeader: [contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// Runs the real request and returns the DioException it fails with.
Future<DioException> _failure(_CannedAdapter adapter,
    {CancelToken? cancelToken}) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://secret-server.example.com/'))
    ..httpClientAdapter = adapter;
  try {
    await PaperlessApi(dio).getAiSuggestions(7, cancelToken: cancelToken);
  } on DioException catch (e) {
    return e;
  }
  fail('expected getAiSuggestions to throw');
}

Future<AiSuggestionsErrorKind?> _kindFor(_CannedAdapter adapter) async =>
    aiSuggestionsErrorKind(await _failure(adapter));

/// The user-facing text, the way the snackbar renders it.
Future<String> _textFor(_CannedAdapter adapter) async {
  final e = await _failure(adapter);
  final kind = aiSuggestionsErrorKind(e);
  if (kind == null) fail('expected a kind, got a silent cancel');
  return aiSuggestionsErrorText(kind, e);
}

String _fixture(String name) =>
    File('test/fixtures/api/ai/$name').readAsStringSync();

_CannedAdapter _real403() => _CannedAdapter(
    status: 403, body: _fixture('ai_suggestions_403.txt'), contentType: _html);

void main() {
  group('real fixtures', () {
    test('403 text/html "Insufficient permissions": cannotEdit', () async {
      final e = await _failure(_real403());
      // Dio left the text/html body alone; nothing tried to decode it.
      expect(e.response?.data, isA<String>());
      expect(aiSuggestionsErrorKind(e), AiSuggestionsErrorKind.cannotEdit);
    });

    test('404 JSON {"detail": …}: documentGone', () async {
      expect(
        await _kindFor(_CannedAdapter(
            status: 404, body: _fixture('ai_suggestions_404.json'))),
        AiSuggestionsErrorKind.documentGone,
      );
    });

    test('502 JSON {"ai": […rejected…]}: aiRejected', () async {
      expect(
        await _kindFor(_CannedAdapter(
          status: 502,
          body: _fixture('ai_suggestions_502_backend_rejected.json'),
        )),
        AiSuggestionsErrorKind.aiRejected,
      );
    });
  });

  group('constructed bodies', () {
    test('400 text "AI is required for this feature": aiDisabled', () async {
      expect(
        await _kindFor(_CannedAdapter(
          status: 400,
          body: 'AI is required for this feature',
          contentType: _html,
        )),
        AiSuggestionsErrorKind.aiDisabled,
      );
    });

    test('400 JSON {"ai": ["Invalid AI configuration."]}: aiMisconfigured',
        () async {
      expect(
        await _kindFor(_CannedAdapter(
            status: 400, body: '{"ai":["Invalid AI configuration."]}')),
        AiSuggestionsErrorKind.aiMisconfigured,
      );
    });

    test('400 JSON without an "ai" key: other (generic)', () async {
      expect(
        await _kindFor(
            _CannedAdapter(status: 400, body: '{"detail":"Bad request"}')),
        AiSuggestionsErrorKind.other,
      );
    });

    test('400 JSON that merely contains the sentence is not aiDisabled',
        () async {
      // Content type decides: a JSON body is never read as the plain-text
      // "AI disabled" sentence.
      expect(
        await _kindFor(_CannedAdapter(
            status: 400, body: '{"detail":"AI is required for this feature"}')),
        AiSuggestionsErrorKind.other,
      );
    });

    test('403 without "Insufficient permissions" (a proxy, a WAF): failed',
        () async {
      expect(
        await _kindFor(_CannedAdapter(
            status: 403, body: '<html>Forbidden</html>', contentType: _html)),
        AiSuggestionsErrorKind.failed,
      );
    });

    test('403 JSON that mentions the sentence is not cannotEdit', () async {
      expect(
        await _kindFor(_CannedAdapter(
            status: 403, body: '{"detail":"Insufficient permissions"}')),
        AiSuggestionsErrorKind.failed,
      );
    });

    test('404 HTML (a proxy\'s page, wrong base URL): other', () async {
      expect(
        await _kindFor(_CannedAdapter(
            status: 404, body: '<h1>Not Found</h1>', contentType: _html)),
        AiSuggestionsErrorKind.other,
      );
    });

    test('500 text/html: serverError', () async {
      expect(
        await _kindFor(_CannedAdapter(
          status: 500,
          body: '<!doctype html><h1>Server Error (500)</h1>',
          contentType: _html,
        )),
        AiSuggestionsErrorKind.serverError,
      );
    });

    test('502 text/html from a reverse proxy is NOT aiRejected', () async {
      expect(
        await _kindFor(_CannedAdapter(
          status: 502,
          body: '<html><body><h1>502 Bad Gateway</h1></body></html>',
          contentType: _html,
        )),
        AiSuggestionsErrorKind.other,
      );
    });

    test('503 JSON {"ai": ["AI backend request timed out."]}: aiTimedOut',
        () async {
      expect(
        await _kindFor(_CannedAdapter(
            status: 503, body: '{"ai":["AI backend request timed out."]}')),
        AiSuggestionsErrorKind.aiTimedOut,
      );
    });

    test('503 text/html from a proxy: other', () async {
      expect(
        await _kindFor(_CannedAdapter(
          status: 503,
          body: '<html>Service Unavailable</html>',
          contentType: _html,
        )),
        AiSuggestionsErrorKind.other,
      );
    });

    test('524 (Cloudflare) and 504 (any gateway): proxyTimeout', () async {
      for (final status in [524, 504]) {
        expect(
          await _kindFor(_CannedAdapter(
            status: status,
            body: '<html>timeout</html>',
            contentType: _html,
          )),
          AiSuggestionsErrorKind.proxyTimeout,
          reason: 'HTTP $status',
        );
      }
    });
  });

  group('client-side failures', () {
    test('our own 150 s receive timeout: tooSlow', () async {
      expect(
        await _kindFor(_CannedAdapter(error: DioExceptionType.receiveTimeout)),
        AiSuggestionsErrorKind.tooSlow,
      );
    });

    test('a cancel (user tapped Cancel, screen closed) has no kind', () async {
      final token = CancelToken()..cancel();
      final e = await _failure(_CannedAdapter(), cancelToken: token);
      expect(e.type, DioExceptionType.cancel);
      expect(aiSuggestionsErrorKind(e), isNull);
    });

    test('connection errors and 401: other (the app-wide message)', () async {
      expect(
        await _kindFor(_CannedAdapter(error: DioExceptionType.connectionError)),
        AiSuggestionsErrorKind.other,
      );
      expect(
        await _kindFor(
            _CannedAdapter(status: 401, body: '{"detail":"Invalid token."}')),
        AiSuggestionsErrorKind.other,
      );
    });
  });

  group('text (the snackbar)', () {
    test('real 403: you can\'t edit this document, not "session expired"',
        () async {
      final text = await _textFor(_real403());
      expect(text, contains("can't edit this document"));
      expect(text, isNot(contains('session')));
    });

    test('a 403 that isn\'t Paperless\'s gets a neutral message, never '
        '"session expired"', () async {
      expect(
        await _textFor(_CannedAdapter(
            status: 403, body: '<html>Forbidden</html>', contentType: _html)),
        'Could not get AI suggestions.',
      );
    });

    test('each kind has its own sentence', () async {
      final e = await _failure(_real403());
      final texts = {
        for (final kind in AiSuggestionsErrorKind.values)
          kind: aiSuggestionsErrorText(kind, e),
      };
      expect(texts[AiSuggestionsErrorKind.aiDisabled],
          contains('AI is turned off'));
      expect(texts[AiSuggestionsErrorKind.aiMisconfigured],
          contains('AI settings are invalid'));
      expect(texts[AiSuggestionsErrorKind.documentGone],
          contains('no longer exists'));
      expect(texts[AiSuggestionsErrorKind.serverError],
          allOf(contains('server hit an error'), contains('unreachable')));
      expect(texts[AiSuggestionsErrorKind.aiRejected],
          contains('AI service rejected'));
      expect(texts[AiSuggestionsErrorKind.aiTimedOut],
          contains('AI service timed out'));
      expect(texts[AiSuggestionsErrorKind.proxyTimeout],
          contains("server's proxy"));
      expect(texts[AiSuggestionsErrorKind.tooSlow], contains('took too long'));
      expect(texts[AiSuggestionsErrorKind.libraryUnavailable],
          allOf(contains("Couldn't load your"), isNot(contains('AI'))));
      // A permission problem is not a connection problem.
      expect(texts[AiSuggestionsErrorKind.libraryForbidden],
          allOf(contains("isn't allowed"), isNot(contains('connection'))));
      expect(texts[AiSuggestionsErrorKind.failed],
          'Could not get AI suggestions.');
      // Every non-generic kind reads differently.
      final specific = texts.entries
          .where((e) => e.key != AiSuggestionsErrorKind.other)
          .map((e) => e.value);
      expect(specific.toSet(), hasLength(specific.length));
    });

    test('connection error: the app-wide friendly message', () async {
      expect(
        await _textFor(_CannedAdapter(error: DioExceptionType.connectionError)),
        contains('reach the server'),
      );
    });

    test('a 200 HTML page (captive portal): exactly the generic fallback',
        () async {
      expect(
        await _textFor(
            _CannedAdapter(body: '<html>Sign in</html>', contentType: _html)),
        'Could not get AI suggestions.',
      );
    });

    test('no text leaks the server URL or a response body', () async {
      final adapters = [
        _real403(),
        _CannedAdapter(status: 404, body: _fixture('ai_suggestions_404.json')),
        _CannedAdapter(
            status: 502,
            body: _fixture('ai_suggestions_502_backend_rejected.json')),
        _CannedAdapter(
            status: 500, body: '<h1>Server Error</h1>', contentType: _html),
        _CannedAdapter(status: 524, body: 'timeout', contentType: _html),
        _CannedAdapter(status: 403, body: '<p>WAF</p>', contentType: _html),
      ];
      for (final adapter in adapters) {
        final text = await _textFor(adapter);
        expect(text, isNot(contains('example.com')));
        expect(text, isNot(contains('Check logs for details')));
        expect(text, isNot(contains('Insufficient permissions')));
        expect(text, isNot(contains('No Document matches')));
        expect(text, isNot(contains('<')));
      }
    });
  });
}
