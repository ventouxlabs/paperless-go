// Which platform errors mean "this device cannot authenticate" (offer Sign
// out) versus an ordinary failure (keep the Unlock button).

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:paperless_go/core/services/biometric_service.dart';

class _ThrowingAuth implements LocalAuthentication {
  _ThrowingAuth(this.error);
  final Object error;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<dynamic> authMessages = const [],
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async =>
      throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BiometricResult> _resultFor(Object error) =>
    BiometricService(auth: _ThrowingAuth(error)).authenticateResult();

void main() {
  for (final code in ['NotAvailable', 'NotEnrolled', 'PasscodeNotSet']) {
    test('$code => unavailable (Sign out offered)', () async {
      expect(await _resultFor(PlatformException(code: code)),
          BiometricResult.unavailable);
    });
  }

  for (final code in ['LockedOut', 'PermanentlyLockedOut', 'other']) {
    test('$code => plain failure (no Sign out)', () async {
      expect(await _resultFor(PlatformException(code: code)),
          BiometricResult.failed);
    });
  }

  test('a non-platform error => plain failure', () async {
    expect(await _resultFor(StateError('x')), BiometricResult.failed);
  });
}
