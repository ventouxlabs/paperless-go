// A lock screen that cannot authenticate must not strand the user: it offers
// Sign out (which clears the session), never a bypass.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/services/biometric_service.dart';
import 'package:paperless_go/features/login/lock_screen.dart';

class _FakeBiometrics implements BiometricService {
  _FakeBiometrics({this.available = true, this.result = BiometricResult.failed});
  final bool available;
  final BiometricResult result;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticateResult({String reason = ''}) async =>
      result;

  @override
  Future<bool> authenticate({String reason = ''}) async =>
      result == BiometricResult.success;
}

Future<void> _pump(WidgetTester tester, _FakeBiometrics bio) async {
  await tester.pumpWidget(MaterialApp(
    home: LockScreen(
      biometrics: bio,
      onUnlocked: () {},
      onSignOut: () {},
    ),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('no Sign out while biometrics work and auth merely failed',
      (tester) async {
    await _pump(tester, _FakeBiometrics());
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('Sign out is offered when biometrics are unavailable',
      (tester) async {
    await _pump(tester, _FakeBiometrics(available: false));
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('Sign out is offered after a not-available/not-enrolled error',
      (tester) async {
    await _pump(tester, _FakeBiometrics(result: BiometricResult.unavailable));
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('tapping Sign out calls onSignOut and never onUnlocked',
      (tester) async {
    var signedOut = 0;
    var unlocked = 0;
    await tester.pumpWidget(MaterialApp(
      home: LockScreen(
        biometrics: _FakeBiometrics(available: false),
        onUnlocked: () => unlocked++,
        onSignOut: () => signedOut++,
      ),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Sign out'));
    await tester.pump();

    expect(signedOut, 1);
    expect(unlocked, 0);
  });
}
