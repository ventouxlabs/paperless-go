import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/user_trust_store.dart';

/// A self-signed EC test CA generated once with:
///   openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 \
///     -nodes -days 3650 -subj "/CN=Paperless Go test CA" \
///     -keyout /dev/null -out ca.pem
///   openssl x509 -in ca.pem -outform der | base64 -w0
/// No private key is committed anywhere — it was written to /dev/null.
const _fixtureCaDerBase64 =
    'MIIBkjCCATmgAwIBAgIUQWYpy6lDBM/r55A3JMx/bn4U3BIwCgYIKoZIzj0EAwIwHzEd'
    'MBsGA1UEAwwUUGFwZXJsZXNzIEdvIHRlc3QgQ0EwHhcNMjYwOTE5MjEyOTQzWhcNMzYw'
    'OTE2MjEyOTQzWjAfMR0wGwYDVQQDDBRQYXBlcmxlc3MgR28gdGVzdCBDQTBZMBMGByqG'
    'SM49AgEGCCqGSM49AwEHA0IABEFZ+FfzCiDGHqvb3zfvAP+4dJAiX8g0uJ2t7/6hAYVE'
    'scietJShUO1yWlWOScvcp7Rf79FQpMsVnqN/hslcr+OjUzBRMB0GA1UdDgQWBBSKuhsM'
    '8/pj4mxZ2oCFRngBR+RyBzAfBgNVHSMEGDAWgBSKuhsM8/pj4mxZ2oCFRngBR+RyBzAP'
    'BgNVHRMBAf8EBTADAQH/MAoGCCqGSM49BAMCA0cAMEQCIFBIZkTIKudE5GeG97Khk7/J'
    'eh4wu/s67LiU2j2mNrhkAiBABer6iMrD2Joxi0z50zH//dLdI2nX+xaEt/xzOUklfw==';

const _channel = MethodChannel('com.ventoux.paperlessgo/user_certificates');

/// A stand-in for some other package's [HttpOverrides] that might already be
/// installed — install() must never replace this with null just because it
/// read zero user CAs.
class _ForeignOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtureDer = base64.decode(_fixtureCaDerBase64);
  final garbageDer = Uint8List.fromList(List.generate(200, (i) => i % 256));

  HttpOverrides? savedOverrides;

  setUp(() {
    // This SDK's dart:io only exposes HttpOverrides.global as a setter;
    // .current reads the same root-zone value (no zone override is active
    // in these tests) and is available on both this SDK and CI's older one.
    savedOverrides = HttpOverrides.current;
  });

  tearDown(() {
    HttpOverrides.global = savedOverrides;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  group('derToPem', () {
    test('wraps the base64 body with BEGIN/END markers and a trailing newline', () {
      final pem = UserTrustStore.derToPem(fixtureDer);
      expect(pem, startsWith('-----BEGIN CERTIFICATE-----\n'));
      expect(pem, endsWith('-----END CERTIFICATE-----\n'));
    });

    test('wraps body lines at 64 characters', () {
      final pem = UserTrustStore.derToPem(fixtureDer);
      final lines = const LineSplitter().convert(pem);
      final bodyLines = lines.sublist(1, lines.length - 1);
      expect(bodyLines, isNotEmpty);
      for (final line in bodyLines) {
        expect(line.length, lessThanOrEqualTo(64));
      }
    });

    test('base64 body round-trips to the original bytes', () {
      final pem = UserTrustStore.derToPem(fixtureDer);
      final lines = const LineSplitter().convert(pem);
      final body = lines.sublist(1, lines.length - 1).join();
      expect(base64.decode(body), fixtureDer);
    });
  });

  group('buildSecurityContext', () {
    test('accepts a single valid certificate', () {
      expect(
        () => UserTrustStore.buildSecurityContext([fixtureDer]),
        returnsNormally,
      );
    });

    test('skips an unusable certificate but keeps the valid one', () {
      expect(
        () => UserTrustStore.buildSecurityContext([garbageDer, fixtureDer]),
        returnsNormally,
      );
    });

    test('handles an empty list', () {
      expect(() => UserTrustStore.buildSecurityContext(const []), returnsNormally);
    });
  });

  group('install', () {
    test('installs an override when the channel returns a certificate', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        expect(call.method, 'getUserCaCertificates');
        return [fixtureDer];
      });

      await UserTrustStore.install();

      expect(HttpOverrides.current, isNotNull);
      expect(HttpOverrides.current, isNot(same(savedOverrides)));
      expect(() => HttpClient(), returnsNormally);
    });

    test('leaves HttpOverrides.global unchanged when the store errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        throw PlatformException(code: 'KEYSTORE_ERROR', message: 'boom');
      });

      await UserTrustStore.install();

      expect(HttpOverrides.current, same(savedOverrides));
    });

    test('leaves HttpOverrides.global unchanged when no handler is registered', () async {
      // No mock handler registered for this test -> invokeMethod throws
      // MissingPluginException, as it would on a non-Android host.
      await UserTrustStore.install();

      expect(HttpOverrides.current, same(savedOverrides));
    });

    test('leaves HttpOverrides.global unchanged when there are no user CAs', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async => <Object?>[]);

      await UserTrustStore.install();

      expect(HttpOverrides.current, same(savedOverrides));
    });
  });

  group('install revocation', () {
    test(
        'a later empty read clears an override this class installed earlier',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async => [fixtureDer]);
      await UserTrustStore.install();
      expect(UserTrustStore.isInstalled, isTrue);

      // The user removed the CA (or this races a revoke) — the next read
      // comes back empty.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async => <Object?>[]);
      await UserTrustStore.install();

      expect(UserTrustStore.isInstalled, isFalse);
    });

    test('an empty read never clobbers a foreign HttpOverrides', () async {
      final foreign = _ForeignOverrides();
      HttpOverrides.global = foreign;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async => <Object?>[]);

      await UserTrustStore.install();

      expect(HttpOverrides.current, same(foreign));
    });

    test('a keystore error leaves an already-installed override in place',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async => [fixtureDer]);
      await UserTrustStore.install();
      expect(UserTrustStore.isInstalled, isTrue);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_channel, (call) async {
        throw PlatformException(code: 'KEYSTORE_ERROR', message: 'boom');
      });
      await UserTrustStore.install();

      expect(UserTrustStore.isInstalled, isTrue);
    });
  });

  group('fixture vs. garbage (sanity check for the test data itself)', () {
    test('the fixture is a well-formed certificate', () {
      final pem = UserTrustStore.derToPem(fixtureDer);
      expect(
        () => SecurityContext(
          withTrustedRoots: false,
        ).setTrustedCertificatesBytes(utf8.encode(pem)),
        returnsNormally,
      );
    });

    test('the garbage bytes are not a well-formed certificate', () {
      final pem = UserTrustStore.derToPem(garbageDer);
      expect(
        () => SecurityContext(
          withTrustedRoots: false,
        ).setTrustedCertificatesBytes(utf8.encode(pem)),
        throwsA(isA<TlsException>()),
      );
    });
  });
}
