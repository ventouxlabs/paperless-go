// "Sign out" on the lock screen must clear the session BEFORE the lock lifts,
// and a failed logout must leave the app locked.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/start_lock.dart';
import 'package:paperless_go/features/login/lock_screen.dart';

final _events = <String>[];
Completer<void> _logoutGate = Completer<void>();
bool _logoutThrows = false;

class _RecordingAuth extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();

  @override
  Future<void> logout() async {
    _events.add('logout-start');
    await _logoutGate.future;
    if (_logoutThrows) throw StateError('logout failed');
    _events.add('logout-done');
  }
}

class _RecordingLock extends BiometricLock {
  @override
  bool build() => true;

  @override
  Future<void> setEnabled(bool enabled) async {
    _events.add('lock-enabled=$enabled');
  }
}

Future<void> _pumpLocked(WidgetTester tester) async {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/local_auth'),
    (call) async => false,
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'), null));
  _events.clear();
  _logoutGate = Completer<void>();
  _logoutThrows = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _RecordingAuth()),
        biometricLockProvider.overrideWith(() => _RecordingLock()),
      ],
      child: const PaperlessGoApp(startLock: StartLock.locked),
    ),
  );
  // No biometrics in the test VM => LockScreen reports unavailable.
  await tester.pump();
  await tester.pump();
  expect(find.text('Sign out'), findsOneWidget);
}

void main() {
  testWidgets('lock stays up until logout completes, then the lock setting is '
      'turned off, then the lock lifts', (tester) async {
    await _pumpLocked(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pump();

    expect(_events, ['logout-start']);
    expect(find.byType(LockScreen), findsOneWidget,
        reason: 'must not unlock while logout is still running');

    _logoutGate.complete();
    await tester.pump();
    await tester.pump();

    expect(_events, ['logout-start', 'logout-done', 'lock-enabled=false']);
    expect(find.byType(LockScreen), findsNothing);
  });

  testWidgets('a failing logout leaves the app locked and the setting on',
      (tester) async {
    await _pumpLocked(tester);
    _logoutThrows = true;

    await tester.tap(find.text('Sign out'));
    _logoutGate.complete();
    await tester.pump();
    await tester.pump();

    expect(_events, ['logout-start']);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
