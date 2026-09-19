import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_error_mapper.dart';

DioException _dio(
  DioExceptionType type, {
  int? status,
  String path = 'https://secret-server.example.com/api/documents/',
}) {
  final opts = RequestOptions(path: path);
  return DioException(
    requestOptions: opts,
    type: type,
    response: status == null
        ? null
        : Response(
            requestOptions: opts,
            statusCode: status,
            data: {'detail': 'internal stack trace leak'},
          ),
  );
}

void main() {
  group('friendlyApiMessage', () {
    test('never leaks server URL, body, or DioException internals', () {
      for (final type in DioExceptionType.values) {
        final msg = friendlyApiMessage(
          _dio(type, status: type == DioExceptionType.badResponse ? 500 : null),
        );
        expect(msg.contains('example.com'), isFalse,
            reason: 'URL leaked for $type');
        expect(msg.contains('/api/'), isFalse, reason: 'path leaked for $type');
        expect(msg.contains('DioException'), isFalse);
        expect(msg.contains('stack trace leak'), isFalse);
        expect(msg, isNotEmpty);
      }
    });

    test('maps connection failures to a friendly reason', () {
      expect(friendlyApiMessage(_dio(DioExceptionType.connectionError)),
          contains('reach the server'));
      expect(friendlyApiMessage(_dio(DioExceptionType.receiveTimeout)),
          contains('too long'));
    });

    test('maps auth status to a sign-in message', () {
      expect(friendlyApiMessage(_dio(DioExceptionType.badResponse, status: 401)),
          contains('session'));
      expect(friendlyApiMessage(_dio(DioExceptionType.badResponse, status: 403)),
          contains('session'));
    });

    test('maps 404 and 5xx', () {
      expect(friendlyApiMessage(_dio(DioExceptionType.badResponse, status: 404)),
          contains('found'));
      expect(friendlyApiMessage(_dio(DioExceptionType.badResponse, status: 503)),
          contains('server'));
    });

    test('falls back for non-Dio errors without leaking toString', () {
      final msg = friendlyApiMessage(
        StateError('internal state secret'),
        fallback: 'Failed to load.',
      );
      expect(msg, 'Failed to load.');
      expect(msg.contains('secret'), isFalse);
    });

    test('uses the provided fallback for unknown type', () {
      expect(
        friendlyApiMessage(_dio(DioExceptionType.unknown), fallback: 'Custom.'),
        'Custom.',
      );
    });

    test(
        'a real handshake failure (wrapped by dio as type: unknown) maps to '
        'the untrusted-certificate message', () {
      final opts = RequestOptions(path: 'https://secret-server.example.com/');
      final err = DioException(
        requestOptions: opts,
        type: DioExceptionType.unknown,
        error: const HandshakeException(
          'Handshake error in client',
          OSError(
            'CERTIFICATE_VERIFY_FAILED: unable to get local issuer '
            'certificate(handshake.cc:393)',
            0,
          ),
        ),
      );
      expect(friendlyApiMessage(err), kUntrustedCertificateMessage);
    });

    test(
        'a non-certificate handshake failure gets its own message, not the '
        'CA message or the generic fallback', () {
      final opts = RequestOptions(path: 'https://secret-server.example.com/');
      final err = DioException(
        requestOptions: opts,
        type: DioExceptionType.unknown,
        error: const HandshakeException(
          'Handshake error in client',
          OSError('WRONG_VERSION_NUMBER(handshake.cc:393)', 0),
        ),
      );
      final msg = friendlyApiMessage(err, fallback: 'Custom fallback.');
      expect(msg, isNot(kUntrustedCertificateMessage));
      expect(msg, isNot('Custom fallback.'));
    });
  });

  group('isUntrustedCertificateError', () {
    test('true for DioExceptionType.badCertificate regardless of the error',
        () {
      final opts = RequestOptions(path: 'https://x.example.com/');
      expect(
        isUntrustedCertificateError(
          DioException(
            requestOptions: opts,
            type: DioExceptionType.badCertificate,
          ),
        ),
        isTrue,
      );
    });

    test('false for a plain unknown DioException with no error', () {
      final opts = RequestOptions(path: 'https://x.example.com/');
      expect(
        isUntrustedCertificateError(
          DioException(requestOptions: opts, type: DioExceptionType.unknown),
        ),
        isFalse,
      );
    });
  });
}
