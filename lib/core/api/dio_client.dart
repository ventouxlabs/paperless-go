import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';

/// Request `extra` key that opts a single request out of [_RetryInterceptor].
///
/// Set `Options(extra: {kNoRetryExtraKey: true})` on requests that must reach
/// the server at most once even when they time out — e.g. the native AI
/// suggestions call, where every attempt is a paid model call and the server
/// has no rate limit. Any other value (or no key) keeps the default retries.
const kNoRetryExtraKey = 'noRetry';

class DioClient {
  static Dio create(String baseUrl, String token) {
    final normalizedUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final dio = Dio(
      BaseOptions(
        baseUrl: normalizedUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        followRedirects: true,
        maxRedirects: ApiConstants.maxRedirects,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
        headers: {
          'Accept': ApiConstants.acceptHeader,
          'Authorization': 'Token $token',
        },
      ),
    );

    dio.interceptors.addAll([
      _CsrfInterceptor(dio: dio, baseUrl: normalizedUrl),
      _RetryInterceptor(dio: dio),
      if (kDebugMode)
        LogInterceptor(
          requestHeader: false,
          requestBody: false, // Don't log bodies — may contain PII/credentials
          responseBody: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);

    return dio;
  }

  /// Create a Dio instance without auth for login requests.
  static Dio createUnauthenticated(String baseUrl) {
    final normalizedUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Dio(
      BaseOptions(
        baseUrl: normalizedUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        followRedirects: true,
        maxRedirects: ApiConstants.maxRedirects,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
        headers: {'Accept': ApiConstants.acceptHeader},
      ),
    );
  }
}

/// Fetches and caches a CSRF token from the server, then attaches it
/// as X-CSRFToken header on all mutating requests (POST, PUT, PATCH, DELETE).
/// Required because some Paperless-ngx endpoints enforce Django CSRF checks
/// even for token-authenticated API requests.
class _CsrfInterceptor extends Interceptor {
  final Dio dio;
  final String baseUrl;
  String? _csrfToken;
  Future<void>? _fetchInFlight;

  _CsrfInterceptor({required this.dio, required this.baseUrl});

  static const _mutatingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_mutatingMethods.contains(options.method.toUpperCase())) {
      return handler.next(options);
    }

    // Deduplicate concurrent fetches: if a fetch is already in flight,
    // subsequent callers await the same future instead of firing duplicates.
    if (_csrfToken == null) {
      _fetchInFlight ??= _fetchCsrfToken().whenComplete(
        () => _fetchInFlight = null,
      );
      await _fetchInFlight;
    }

    if (_csrfToken != null) {
      options.headers['X-CSRFToken'] = _csrfToken;
      // Also set Referer — Django checks this for HTTPS CSRF validation
      options.headers['Referer'] = baseUrl;
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Update CSRF token from any Set-Cookie header
    _extractCsrfFromCookies(response.headers);
    handler.next(response);
  }

  Future<void> _fetchCsrfToken() async {
    try {
      // Make a lightweight GET to get the csrftoken cookie
      final tempDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (_) => true, // Accept any status
          headers: dio.options.headers,
        ),
      );
      final response = await tempDio.get('api/');
      _extractCsrfFromCookies(response.headers);
    } catch (e) {
      // Failed to fetch CSRF token — requests will proceed without it
      assert(() {
        print('CSRF token fetch failed: $e');
        return true;
      }());
    }
  }

  void _extractCsrfFromCookies(Headers headers) {
    final cookies = headers['set-cookie'];
    if (cookies == null) return;
    for (final cookie in cookies) {
      final match = RegExp(r'csrftoken=([^;]+)').firstMatch(cookie);
      if (match != null) {
        _csrfToken = match.group(1);
        return;
      }
    }
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int _maxRetries = 3;

  _RetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final currentRetry = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (_shouldRetry(err) && currentRetry < _maxRetries) {
      final nextRetry = currentRetry + 1;
      err.requestOptions.extra['retryCount'] = nextRetry;

      final delay = Duration(milliseconds: 500 * nextRetry);
      await Future.delayed(delay);

      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        if (e is DioException) {
          handler.next(e);
        } else {
          // Wrap unexpected exceptions so the handler always resolves/rejects.
          // Without this, the request hangs forever with no response or error.
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: e,
              type: DioExceptionType.unknown,
              message: 'Retry failed with unexpected error: $e',
            ),
          );
        }
        return;
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.extra[kNoRetryExtraKey] == true) return false;
    // Only retry idempotent methods (GET, HEAD, OPTIONS) to avoid
    // duplicate side effects on POST/PATCH/DELETE
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD' && method != 'OPTIONS') {
      return false;
    }
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
