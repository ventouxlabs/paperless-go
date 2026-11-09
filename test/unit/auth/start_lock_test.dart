// The cold-start lock decision. Anything we cannot read must fail closed.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/start_lock.dart';

void main() {
  const quick = Duration(milliseconds: 20);

  test('setting true => locked', () async {
    expect(await resolveStartLock(() async => true, timeout: quick),
        StartLock.locked);
  });

  test('setting false => unlocked', () async {
    expect(await resolveStartLock(() async => false, timeout: quick),
        StartLock.unlocked);
  });

  test('read timeout => unknown (the app starts locked)', () async {
    expect(
        await resolveStartLock(() => Completer<bool>().future, timeout: quick),
        StartLock.unknown);
  });

  test('read error => unknown (the app starts locked)', () async {
    expect(
        await resolveStartLock(() async => throw StateError('keystore'),
            timeout: quick),
        StartLock.unknown);
  });

  test('a late true after the timeout cannot unlock: unknown stays locked',
      () async {
    final late = Completer<bool>();
    final result = await resolveStartLock(() => late.future, timeout: quick);
    late.complete(true);
    expect(result, StartLock.unknown);
    expect(result.startsLocked, isTrue);
  });

  test('only unlocked starts unlocked', () {
    expect(StartLock.unlocked.startsLocked, isFalse);
    expect(StartLock.locked.startsLocked, isTrue);
    expect(StartLock.unknown.startsLocked, isTrue);
  });
}
