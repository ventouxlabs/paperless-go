// A cold start with the biometric lock enabled must show the lock screen on
// the very first frame. Before, _isLocked only flipped on a background
// transition, so a killed-and-relaunched app opened straight to the library.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/auth/start_lock.dart';
import 'package:paperless_go/features/login/lock_screen.dart';

class _UnauthenticatedAuthState extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();
}

class _EnabledBiometricLock extends BiometricLock {
  @override
  bool build() => true;
}

class _Storage extends SecureStorageService {
  _Storage(this.lockSetting);
  final Future<bool> Function() lockSetting;
  @override
  Future<bool> getBiometricLock() => lockSetting();
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required StartLock startLock,
  Future<bool> Function()? lockSetting,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _UnauthenticatedAuthState()),
        biometricLockProvider.overrideWith(() => _EnabledBiometricLock()),
        if (lockSetting != null)
          secureStorageProvider.overrideWithValue(_Storage(lockSetting)),
      ],
      child: PaperlessGoApp(startLock: startLock),
    ),
  );
}

void main() {
  testWidgets('cold start with biometric lock enabled shows LockScreen on '
      'the first frame', (tester) async {
    await _pumpApp(tester, startLock: StartLock.locked);

    expect(find.byType(LockScreen), findsOneWidget);
  });

  testWidgets('cold start without the lock does not show LockScreen',
      (tester) async {
    await _pumpApp(tester, startLock: StartLock.unlocked);

    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('unknown setting starts locked, then unlocks itself when the '
      'setting re-reads as false', (tester) async {
    await _pumpApp(tester,
        startLock: StartLock.unknown, lockSetting: () async => false);
    expect(find.byType(LockScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('unknown setting stays locked when it re-reads as true',
      (tester) async {
    await _pumpApp(tester,
        startLock: StartLock.unknown, lockSetting: () async => true);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LockScreen), findsOneWidget);
  });

  testWidgets('unknown setting stays locked when the re-read keeps failing',
      (tester) async {
    await _pumpApp(tester,
        startLock: StartLock.unknown,
        lockSetting: () async => throw StateError('keystore'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LockScreen), findsOneWidget);
  });

  testWidgets('routed content is hidden from accessibility while locked',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpApp(tester, startLock: StartLock.locked);
    await tester.pump(const Duration(milliseconds: 300));

    // The login screen sits under the lock; none of it may be reachable.
    expect(find.bySemanticsLabel('Connect to your Paperless-ngx server'),
        findsNothing);
    expect(find.byType(LockScreen), findsOneWidget);
    handle.dispose();
  });
}
