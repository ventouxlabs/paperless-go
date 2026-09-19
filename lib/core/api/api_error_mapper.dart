import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Shown for any TLS failure caused by an untrusted certificate — both the
/// `badCertificate` type dio sets itself and a raw [HandshakeException] (see
/// [isUntrustedCertificateError]). Mentions restarting the app because
/// thumbnails use a process-lifetime `HttpClient` that a later refresh of
/// the trust store can't reach — only a fresh app start rebuilds it.
const kUntrustedCertificateMessage =
    "The server's security certificate isn't trusted by this device. If "
    'your server uses a private CA, install its root certificate under '
    'Android Settings → Security → Install a certificate (CA certificate), '
    'then restart Paperless Go.';

/// Whether [error] is a TLS handshake failure caused by an untrusted
/// certificate.
///
/// dio 5.9.1's `IOHttpClientAdapter` only produces
/// [DioExceptionType.badCertificate] from its `validateCertificate` hook. A
/// real CERTIFICATE_VERIFY_FAILED from the underlying socket instead arrives
/// as a [HandshakeException] (a [TlsException], not a [SocketException]),
/// which escapes the adapter's `on SocketException` and gets wrapped by
/// `assureDioException` as `type: unknown` with no message.
bool isUntrustedCertificateError(DioException error) {
  if (error.type == DioExceptionType.badCertificate) return true;
  final cause = error.error;
  if (cause is! HandshakeException) return false;
  final detail = cause.osError?.message ?? cause.message;
  return detail.contains('CERTIFICATE_VERIFY_FAILED');
}

/// Maps an error (typically a [DioException]) to a short, user-friendly message.
///
/// Never exposes internals: no server URL, no request/response body, no stack
/// trace, no raw `DioException.toString()`. Screens must interpolate the RESULT
/// of this function, never the raw error object:
///
/// ```dart
/// // SnackBar that keeps an action prefix:
/// Text('Failed to share: ${friendlyApiMessage(e)}')
/// // Full-screen error where the screen implies the action:
/// Text(friendlyApiMessage(err, fallback: 'Failed to load documents.'))
/// ```
String friendlyApiMessage(
  Object? error, {
  String fallback = 'An unexpected error occurred.',
}) {
  // Debug-only breadcrumb: keep the real error visible to developers without
  // ever leaking it into the release UI. assert(...) is stripped in release.
  assert(() {
    if (error != null) debugPrint('API error: $error');
    return true;
  }());
  if (error is DioException) {
    if (isUntrustedCertificateError(error)) return kUntrustedCertificateMessage;
    // A HandshakeException that isn't a trust failure (e.g. the port speaks
    // plain HTTP and returns WRONG_VERSION_NUMBER) still needs its own
    // message — it also arrives as type: unknown with no message.
    if (error.error is HandshakeException) {
      return 'Could not establish a secure connection to the server.';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. '
            'Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badCertificate:
        return kUntrustedCertificateMessage;
      case DioExceptionType.cancel:
        // Callers that cancel intentionally (navigation, a superseded request)
        // should not render this — it's only meaningful for an unexpected cancel.
        return 'The request was cancelled.';
      case DioExceptionType.badResponse:
        return _messageForStatus(error.response?.statusCode, fallback);
      case DioExceptionType.unknown:
        return fallback;
    }
  }
  return fallback;
}

String _messageForStatus(int? status, String fallback) {
  if (status == null) return fallback;
  if (status == 400 || status == 422) {
    return 'The server rejected the request.';
  }
  if (status == 401 || status == 403) {
    return 'Your session has expired. Please sign in again.';
  }
  if (status == 404) return 'That item could not be found.';
  if (status == 409) {
    return 'This conflicts with the current state — it may have changed.';
  }
  if (status == 413) return 'The file is too large for the server.';
  if (status == 429) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  if (status >= 500 && status < 600) {
    return 'The server had a problem. Please try again.';
  }
  return fallback;
}
