import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

enum BiometricResult {
  success,
  failed,

  /// No biometrics or device credential can be used (not available, not
  /// enrolled, no passcode set); retrying will not help.
  unavailable,
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to access Paperless Go'}) async =>
      (await authenticateResult(reason: reason)) == BiometricResult.success;

  Future<BiometricResult> authenticateResult({
    String reason = 'Authenticate to access Paperless Go',
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return _unavailableCodes.contains(e.code)
          ? BiometricResult.unavailable
          : BiometricResult.failed;
    } catch (_) {
      return BiometricResult.failed;
    }
  }

  static const _unavailableCodes = {
    auth_error.notAvailable,
    auth_error.notEnrolled,
    auth_error.passcodeNotSet,
  };
}
