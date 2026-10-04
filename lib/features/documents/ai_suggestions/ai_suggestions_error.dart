import 'package:dio/dio.dart';

/// Why "Suggest with AI" failed. The UI turns a kind into text (see
/// `aiSuggestionsErrorText` in ai_suggestions_flow.dart), so every sentence
/// for this feature lives in one place.
enum AiSuggestionsErrorKind {
  /// 400 plain text "AI is required for this feature": AI is switched off.
  aiDisabled,

  /// 400 `{"ai": …}`: the server's AI settings are invalid.
  aiMisconfigured,

  /// 403 text "Insufficient permissions": the user can't change THIS document.
  cannotEdit,

  /// 404 `{"detail": …}`: the document no longer exists.
  documentGone,

  /// 500: unmapped server error; usually the AI backend is unreachable.
  serverError,

  /// 502 `{"ai": …}`: the AI backend returned an error.
  aiRejected,

  /// 503 `{"ai": …}`: the AI backend timed out.
  aiTimedOut,

  /// 504 / 524: a proxy in front of the server gave up waiting.
  proxyTimeout,

  /// Our own 150 s receive timeout.
  tooSlow,

  /// The app's own tag / correspondent / type lists couldn't load (not an AI
  /// error; no model call was made). Set by the notifier, never by
  /// [aiSuggestionsErrorKind].
  libraryUnavailable,

  /// Like [libraryUnavailable], but the server refused (403): the account
  /// may not view those lists. Set by the notifier.
  libraryForbidden,

  /// Failed with nothing more specific to say, e.g. a 403 from a proxy or
  /// WAF rather than Paperless: a neutral message, never "session expired".
  failed,

  /// Anything else: show the app-wide message for the underlying error.
  other,
}

/// Classifies a failed `ai_suggestions` request, or returns null when there
/// is nothing to tell the user (they cancelled, or left the screen).
///
/// The server answers its errors in different formats, so the content type is
/// checked before the body is trusted: Dio has already turned a JSON body into
/// a Map and left text/html as a String; nothing here decodes a body. The
/// `{"ai": […]}` JSON errors come from Paperless's AI module; the same status
/// as an HTML page comes from a reverse proxy and must not be blamed on the AI.
AiSuggestionsErrorKind? aiSuggestionsErrorKind(DioException error) {
  if (error.type == DioExceptionType.cancel) return null;
  if (error.type == DioExceptionType.receiveTimeout) {
    return AiSuggestionsErrorKind.tooSlow;
  }
  final response = error.response;
  if (error.type != DioExceptionType.badResponse || response == null) {
    return AiSuggestionsErrorKind.other;
  }
  return switch (response.statusCode) {
    400 when _isAiModuleError(response) =>
      AiSuggestionsErrorKind.aiMisconfigured,
    400 when _textContains(response, 'AI is required') =>
      AiSuggestionsErrorKind.aiDisabled,
    // Only Paperless's own answer means "can't edit"; any other 403 (a
    // proxy, a WAF) is neutral, never the app-wide "session expired".
    403 when _textContains(response, 'Insufficient permissions') =>
      AiSuggestionsErrorKind.cannotEdit,
    403 => AiSuggestionsErrorKind.failed,
    404 when _isDrfDetail(response) => AiSuggestionsErrorKind.documentGone,
    500 => AiSuggestionsErrorKind.serverError,
    502 when _isAiModuleError(response) => AiSuggestionsErrorKind.aiRejected,
    503 when _isAiModuleError(response) => AiSuggestionsErrorKind.aiTimedOut,
    504 || 524 => AiSuggestionsErrorKind.proxyTimeout,
    _ => AiSuggestionsErrorKind.other,
  };
}

bool _isJson(Response<dynamic> response) =>
    (response.headers[Headers.contentTypeHeader] ?? const <String>[])
        .any((value) => value.toLowerCase().contains('json'));

/// `{"ai": ["…"]}`, the body of the AI module's own 400/502/503 errors.
bool _isAiModuleError(Response<dynamic> response) {
  final data = response.data;
  return _isJson(response) && data is Map && data.containsKey('ai');
}

/// Django REST framework's `{"detail": "…"}` (its 404 for a missing object).
bool _isDrfDetail(Response<dynamic> response) {
  final data = response.data;
  return _isJson(response) && data is Map && data.containsKey('detail');
}

/// A plain-text (non-JSON) body containing [text].
bool _textContains(Response<dynamic> response, String text) {
  final data = response.data;
  return !_isJson(response) && data is String && data.contains(text);
}
