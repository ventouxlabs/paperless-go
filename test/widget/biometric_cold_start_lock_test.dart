// A cold start with the biometric lock enabled must show the lock screen on
// the very first frame. Before, _isLocked only flipped on a background
// transition, so a killed-and-relaunched app opened straight to the library.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/features/login/lock_screen.dart';

class _UnauthenticatedAuthState extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();
}

class _EnabledBiometricLock extends BiometricLock {
  @override
  bool build() => true;
}

Future<void> _pumpApp(WidgetTester tester, {required bool startLocked}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _UnauthenticatedAuthState()),
        biometricLockProvider.overrideWith(() => _EnabledBiometricLock()),
      ],
      child: PaperlessGoApp(startLocked: startLocked),
    ),
  );
}

void main() {
  testWidgets('cold start with biometric lock enabled shows LockScreen on '
      'the first frame', (tester) async {
    await _pumpApp(tester, startLocked: true);

    expect(find.byType(LockScreen), findsOneWidget);
  });

  testWidgets('cold start without the lock does not show LockScreen',
      (tester) async {
    await _pumpApp(tester, startLocked: false);

    expect(find.byType(LockScreen), findsNothing);
  });
}
