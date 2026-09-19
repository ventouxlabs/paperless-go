// Regression coverage for: AuthService.testConnection swallowed every
// exception with a bare `catch (_)` and returned a plain bool, so a user
// behind a private CA (badCertificate) or an unreachable/misconfigured
// server saw only a red icon with no reason. testConnection now returns a
// ConnectionProbe record carrying a user-facing reason string.
//
// Run: flutter test test/unit/auth/auth_service_probe_test.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_error_mapper.dart';
import 'package:paperless_go/core/api/dio_client.dart';
import 'package:paperless_go/core/auth/auth_service.dart';

/// Throws whatever [buildError] returns for every request, without making
/// a real HTTP call.
class _ThrowingAdapter implements HttpClientAdapter {
  _ThrowingAdapter(this.buildError);

  final DioException Function(RequestOptions options) buildError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw buildError(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Throws whatever [buildError] returns for every request, exactly as a real
/// `IOHttpClientAdapter` would throw a raw socket/TLS exception — dio's own
/// `assureDioException` is what wraps it into a `DioException`, unlike
/// [_ThrowingAdapter] which hands dio an already-built `DioException`.
class _ThrowingRawAdapter implements HttpClientAdapter {
  _ThrowingRawAdapter(this.buildError);

  final Object Function() buildError;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw buildError();
  }

  @override
  void close({bool force = false}) {}
}

/// Returns a canned response for every request, without making a real HTTP
/// call.
class _RespondingAdapter implements HttpClientAdapter {
  _RespondingAdapter(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(body, statusCode);
  }

  @override
  void close({bool force = false}) {}
}

/// Builds a real production Dio (via DioClient.createUnauthenticated, the
/// same factory AuthService defaults to) with its transport swapped for a
/// fake adapter, so tests exercise the actual base-url/header wiring instead
/// of a parallel one built by hand.
Dio _dioWithAdapter(String serverUrl, HttpClientAdapter adapter) {
  return DioClient.createUnauthenticated(serverUrl)
    ..httpClientAdapter = adapter;
}

void main() {
  group('AuthService.testConnection', () {
    test('badCertificate failure names the certificate as the reason',
        () async {
      final adapter = _ThrowingAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.badCertificate,
        ),
      );
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isFalse);
      expect(probe.reason, isNotNull);
      expect(probe.reason!.toLowerCase(), contains('certificate'));
    });

    test('connectionError failure reports the server as unreachable',
        () async {
      final adapter = _ThrowingAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'connection refused',
        ),
      );
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isFalse);
      expect(probe.reason, contains('Could not reach'));
    });

    test(
        'connectionError failure never leaks the raw platform error into the '
        'reason', () async {
      // A real SocketException's toString() includes the hostname and the
      // exception class name — neither belongs in user-facing UI text.
      final adapter = _ThrowingAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const SocketException('Failed host lookup: paperless.invalid'),
        ),
      );
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isFalse);
      expect(probe.reason, isNotNull);
      expect(probe.reason, isNot(contains('SocketException')));
      expect(probe.reason, isNot(contains('paperless.invalid')));
    });

    test(
        'a real handshake failure (not a DioException — dio wraps it) '
        'reports the untrusted-certificate reason', () async {
      // Production path: dio's IOHttpClientAdapter lets a raw
      // HandshakeException from the socket escape its `on SocketException`
      // and wraps it via assureDioException as type: unknown. The adapter
      // here throws the raw exception, not a DioException, so this exercises
      // that wrapping instead of bypassing it.
      final adapter = _ThrowingRawAdapter(
        () => const HandshakeException(
          'Handshake error in client',
          OSError(
            'CERTIFICATE_VERIFY_FAILED: unable to get local issuer '
            'certificate(handshake.cc:393)',
            0,
          ),
        ),
      );
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isFalse);
      expect(probe.reason, equals(kUntrustedCertificateMessage));
    });

    test('connectionTimeout failure reports a timeout', () async {
      final adapter = _ThrowingAdapter(
        (options) => DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isFalse);
      expect(probe.reason, equals('Connection timed out'));
    });

    test('a 200 response reports the server as reachable', () async {
      final adapter = _RespondingAdapter(200, '{}');
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isTrue);
      expect(probe.reason, isNull);
    });

    test('a 401 response still reports the server as reachable', () async {
      // Reachability is a separate concern from authentication: an
      // unauthenticated probe hitting a protected endpoint gets a 401,
      // which is not a connection failure.
      final adapter = _RespondingAdapter(
        401,
        '{"detail":"not authenticated"}',
      );
      final authService = AuthService(
        dioFactory: (url) => _dioWithAdapter(url, adapter),
      );

      final probe = await authService.testConnection(
        'https://paperless.example.com',
      );

      expect(probe.ok, isTrue);
      expect(probe.reason, isNull);
    });

    test('a URL with no host reports a validation reason', () async {
      // No injected dioFactory here: an empty-host URL is rejected by
      // testConnection's own pre-flight check before any factory or Dio
      // instance is ever created.
      final authService = AuthService();

      final probe = await authService.testConnection('https://[invalid');

      expect(probe.ok, isFalse);
      expect(probe.reason, equals('Enter a valid URL'));
    });

    for (final url in ['https://', 'https:', 'https://:8000']) {
      test(
          'rejects "$url" (empty host) without ever calling the dio factory',
          () async {
        var factoryCalls = 0;
        final authService = AuthService(
          dioFactory: (_) {
            factoryCalls++;
            throw StateError('dioFactory must not be called for "$url"');
          },
        );

        final probe = await authService.testConnection(url);

        expect(probe.ok, isFalse);
        expect(probe.reason, equals('Enter a valid URL'));
        expect(factoryCalls, equals(0));
      });
    }

    test('passes the exact serverUrl through to the dio factory', () async {
      String? receivedUrl;
      final adapter = _RespondingAdapter(200, '{}');
      final authService = AuthService(
        dioFactory: (url) {
          receivedUrl = url;
          return _dioWithAdapter(url, adapter);
        },
      );

      await authService.testConnection('https://paperless.example.com:9443');

      expect(receivedUrl, equals('https://paperless.example.com:9443'));
    });
  });
}
