import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/auth/secure_storage.dart';
import 'package:paperless_go/core/settings/start_screen.dart';

class _FakeAuthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.authenticated(
        serverUrl: 'https://paperless.example.com',
        token: 'test-token',
      );
}

class _FakeUnauthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.unauthenticated();
}

/// Never resolves — models the window while the keystore read is still in
/// flight, which is exactly when a shared file arrives on a cold start.
class _FakeLoadingForever extends AuthState {
  @override
  Future<AuthStatus> build() => Completer<AuthStatus>().future;
}

Future<GoRouterHarness> _harness(
  WidgetTester tester,
  AuthState Function() authState, {
  Map<String, String> stored = const {},
}) async {
  // The router awaits the start-screen setting, so the keystore has to
  // answer; an in-memory one stands in for it.
  FlutterSecureStorage.setMockInitialValues({...stored});
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(authState),
      secureStorageProvider.overrideWithValue(
        SecureStorageService(storage: const FlutterSecureStorage()),
      ),
    ],
  );
  await container.read(authStateProvider.future);
  final router = container.read(routerProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return GoRouterHarness(container, router);
}

class GoRouterHarness {
  GoRouterHarness(this.container, this.router);
  final ProviderContainer container;
  final GoRouter router;
}

void main() {
  testWidgets('the app lands on Library by default', (tester) async {
    final harness = await _harness(tester, _FakeAuthenticated.new);
    addTearDown(harness.container.dispose);

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/documents',
    );
  });

  testWidgets(
      'with the setting pre-read (as main() does) the first redirect is '
      'synchronous, so frame one already has the start screen and a '
      'Navigator for a cold-start share to push onto', (tester) async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_FakeAuthenticated.new),
        secureStorageProvider.overrideWithValue(
          SecureStorageService(storage: const FlutterSecureStorage()),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authStateProvider.future);
    await container.read(startScreenProvider.future);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // One frame, no settling: an async redirect would still be resolving.
    await tester.pump();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/documents',
    );
    expect(rootNavigatorKey.currentContext, isNotNull);
    // Drain the Library screen's own timers before teardown.
    await tester.pumpAndSettle();
  });

  testWidgets('the app lands on Inbox when that start screen is stored',
      (tester) async {
    final harness = await _harness(
      tester,
      _FakeAuthenticated.new,
      stored: {'start_screen': 'inbox'},
    );
    addTearDown(harness.container.dispose);

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/inbox',
    );
  });

  testWidgets('an unknown stored start screen falls back to Library',
      (tester) async {
    final harness = await _harness(
      tester,
      _FakeAuthenticated.new,
      stored: {'start_screen': 'dashboard'},
    );
    addTearDown(harness.container.dispose);

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/documents',
    );
  });

  testWidgets('"/" resolves to the chosen start screen, not a dead route',
      (tester) async {
    final harness = await _harness(
      tester,
      _FakeAuthenticated.new,
      stored: {'start_screen': 'inbox'},
    );
    addTearDown(harness.container.dispose);

    harness.router.go('/documents');
    await tester.pumpAndSettle();
    harness.router.go('/');
    await tester.pumpAndSettle();

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/inbox',
    );
    expect(find.text('Page not found'), findsNothing);
  });

  testWidgets('a logged-out user lands on /login', (tester) async {
    final harness = await _harness(tester, _FakeUnauthenticated.new);
    addTearDown(harness.container.dispose);
    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/login',
    );
  });

  testWidgets('a visit to /login while logged in bounces to the start screen',
      (tester) async {
    final harness = await _harness(tester, _FakeAuthenticated.new);
    addTearDown(harness.container.dispose);
    harness.router.go('/login');
    await tester.pumpAndSettle();
    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/documents',
    );
  });

  testWidgets(
      'a content:// share/open-with route is parked on the start screen '
      '(the share handler pushes the upload screen on top), not the '
      'unmatched intermediate "/" '
      '(regression: onNewIntent-pushed routes on a reused singleTask '
      'Activity showed "Page not found" instead of following through a '
      'second redirect pass)', (tester) async {
    final harness = await _harness(tester, _FakeAuthenticated.new);
    addTearDown(harness.container.dispose);

    harness.router.go(
      'content://com.android.providers.downloads.documents/document/1',
    );
    await tester.pumpAndSettle();

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/documents',
    );
  });

  testWidgets(
      'a content:// share arriving before auth has restored does not flash '
      '"Page not found" (regression: the isLoading guard returned null for '
      'every route, so a platform URI fell through to errorBuilder for the '
      'frames between the share landing and the keystore read finishing)',
      (tester) async {
    // Deliberately does NOT await authStateProvider.future — the whole point
    // is the window while it is still pending.
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_FakeLoadingForever.new),
        secureStorageProvider.overrideWithValue(
          SecureStorageService(storage: const FlutterSecureStorage()),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    router.go(
      'content://com.android.providers.downloads.documents/document/1',
    );
    await tester.pump();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      isNot(startsWith('content://')),
      reason: 'an unmatched platform URI renders the "Page not found" page',
    );
    expect(find.text('Page not found'), findsNothing);
  });

  // This drives GoRouter's defensive /inbox-or-login fallback for a
  // content:// route directly (bypassing native Android entirely). On a
  // real device, MainActivity.getInitialRoute() now suppresses this route
  // before Flutter ever sees it (see SharePlugin.kt's
  // shouldSuppressInitialRoute) — this test covers the backstop, not the
  // primary "Open with" path.
  testWidgets(
      'a content:// route while logged out lands on /login, not the '
      'unmatched intermediate "/"', (tester) async {
    final harness = await _harness(tester, _FakeUnauthenticated.new);
    addTearDown(harness.container.dispose);

    harness.router.go(
      'content://com.android.providers.downloads.documents/document/1',
    );
    await tester.pumpAndSettle();

    expect(
      harness.router.routerDelegate.currentConfiguration.uri.toString(),
      '/login',
    );
  });
}
