import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_go/app.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';

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
  AuthState Function() authState,
) async {
  final container = ProviderContainer(
    overrides: [authStateProvider.overrideWith(authState)],
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
  testWidgets(
      'a content:// share/open-with route lands on /inbox, not the '
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
      '/inbox',
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
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith(_FakeLoadingForever.new)],
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
