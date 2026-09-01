import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:paperless_go/features/upload/share_intent_handler.dart';

SharedFile _shared(String path, {String filename = '', String? mimeType}) =>
    SharedFile(
      path: path,
      filename: filename.isEmpty ? path.split('/').last : filename,
      mimeType: mimeType,
    );

Future<GlobalKey<NavigatorState>> _pumpTestRouter(WidgetTester tester) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const Text('home')),
      GoRoute(path: '/scan/upload', builder: (_, __) => const Text('upload screen')),
      GoRoute(path: '/scan/review', builder: (_, __) => const Text('review screen')),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  // The test binding's lifecycleState defaults to null (not `resumed`),
  // which ShareIntentHandler._pushRoute now treats the same as `inactive`
  // — matching a real running app rather than the binding's unset default.
  WidgetsBinding.instance.handleAppLifecycleStateChanged(
    AppLifecycleState.resumed,
  );
  return navigatorKey;
}

void main() {
  group('resolveShareRoute', () {
    test('single shared image launches the PDF scan pipeline', () {
      // Regression: a single shared image used to route to /scan/upload as a
      // raw image, bypassing the PDF pipeline. It must now go to /scan/review.
      final route = resolveShareRoute([
        _shared('/tmp/photo.jpg', mimeType: 'image/jpeg'),
      ]);

      expect(route, isNotNull);
      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/photo.jpg']);
    });

    test('multiple shared images launch the PDF scan pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/a.jpg', mimeType: 'image/jpeg'),
        _shared('/tmp/b.png', mimeType: 'image/png'),
      ]);

      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/a.jpg', '/tmp/b.png']);
    });

    test('single shared PDF uploads directly without the pipeline', () {
      final route = resolveShareRoute([
        _shared(
          '/tmp/share_123_invoice.pdf',
          filename: 'invoice.pdf',
          mimeType: 'application/pdf',
        ),
      ]);

      expect(route!.location, '/scan/upload');
      expect(
        route.extra,
        {'filePath': '/tmp/share_123_invoice.pdf', 'filename': 'invoice.pdf'},
      );
    });

    test('mixed share with at least one image prefers the pipeline', () {
      final route = resolveShareRoute([
        _shared('/tmp/scan.png', mimeType: 'image/png'),
        _shared('/tmp/notes.pdf', mimeType: 'application/pdf'),
      ]);

      expect(route!.location, '/scan/review');
      expect(route.extra, ['/tmp/scan.png']);
    });

    test('empty and path-less shares resolve to null', () {
      expect(resolveShareRoute([]), isNull);
      expect(
        resolveShareRoute([_shared('', mimeType: 'image/jpeg')]),
        isNull,
      );
    });
  });

  group('ShareIntentHandler pending share queue', () {
    // Regression (#24): a share/open-with arriving while logged out used to
    // push straight through onto /login. It must now wait for login and
    // resume automatically, never navigating while unauthenticated.
    testWidgets('queues a share received while logged out, flushes after login', (
      tester,
    ) async {
      final navigatorKey = await _pumpTestRouter(tester);
      var authenticated = false;
      final handler = ShareIntentHandler(navigatorKey, () => authenticated);

      handler.debugHandleSharedFiles([
        _shared('/tmp/share_1_invoice.pdf', filename: 'invoice.pdf', mimeType: 'application/pdf'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('upload screen'), findsNothing);
      expect(handler.debugPendingRoute, isNotNull);

      authenticated = true;
      handler.flushPendingShare();
      await tester.pumpAndSettle();

      expect(find.text('upload screen'), findsOneWidget);
      expect(handler.debugPendingRoute, isNull);
    });

    testWidgets('pushes immediately when already authenticated', (tester) async {
      final navigatorKey = await _pumpTestRouter(tester);
      final handler = ShareIntentHandler(navigatorKey, () => true);

      handler.debugHandleSharedFiles([
        _shared('/tmp/photo.jpg', mimeType: 'image/jpeg'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('review screen'), findsOneWidget);
      expect(handler.debugPendingRoute, isNull);
    });

    testWidgets('flushing with nothing pending is a no-op', (tester) async {
      final navigatorKey = await _pumpTestRouter(tester);
      final handler = ShareIntentHandler(navigatorKey, () => true);

      handler.flushPendingShare();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    // Regression: measured on a Pixel 9 Pro Fold — a share arriving via
    // onNewIntent on a warm resume (task switched back to via "Open with")
    // reached _pushRoute while AppLifecycleState was still `inactive`.
    // context.push() reported success (mounted context, a frame even
    // fired) but the navigation was silently lost by the time the render
    // pipeline finished reattaching on resume.
    testWidgets(
        'queues a share received before the app lifecycle is resumed, '
        'flushes once resumed', (tester) async {
      final navigatorKey = await _pumpTestRouter(tester);
      addTearDown(
        () => WidgetsBinding.instance
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      final handler = ShareIntentHandler(navigatorKey, () => true);

      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      handler.debugHandleSharedFiles([
        _shared(
          '/tmp/share_1_invoice.pdf',
          filename: 'invoice.pdf',
          mimeType: 'application/pdf',
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('upload screen'), findsNothing);
      expect(handler.debugPendingRoute, isNotNull);

      WidgetsBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      handler.flushPendingShare();
      await tester.pumpAndSettle();

      expect(find.text('upload screen'), findsOneWidget);
      expect(handler.debugPendingRoute, isNull);
    });
  });
}
