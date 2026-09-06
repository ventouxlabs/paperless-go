import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/auth/auth_provider.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/upload_queue/queue_status_banner.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';

class _FakeAuthenticated extends AuthState {
  @override
  Future<AuthStatus> build() async => const AuthStatus.authenticated(
        serverUrl: 'https://paperless.example.com',
        token: 'test-token',
      );
}

PendingUpload _row({
  int id = 1,
  bool isFailed = false,
  int retryCount = 0,
  String? serverUrl = 'https://paperless.example.com',
}) {
  return PendingUpload(
    id: id,
    filePath: '/queue/doc$id.pdf',
    filename: 'doc$id.pdf',
    queuedAt: DateTime(2026, 8, 1),
    retryCount: retryCount,
    isFailed: isFailed,
    serverUrl: serverUrl,
  );
}

void main() {
  _waitingProviderTests();
  Future<void> pumpBanner(WidgetTester tester, List<PendingUpload> rows) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingUploadsProvider.overrideWith((ref) => Stream.value(rows)),
          authStateProvider.overrideWith(_FakeAuthenticated.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: QueueStatusBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says nothing when the queue is empty', (tester) async {
    await pumpBanner(tester, const []);
    expect(find.textContaining('never reached'), findsNothing);
  });

  testWidgets('says nothing at all when the queue is empty', (tester) async {
    await pumpBanner(tester, const []);
    expect(find.textContaining('not sent yet'), findsNothing);
    expect(find.text('View'), findsNothing);
  });

  testWidgets(
      'uploads that are merely waiting get a quiet line, not the error banner',
      (tester) async {
    // Waiting uploads used to be invisible here so the error banner never
    // became noise. That left "what is still on my phone?" unanswerable
    // without opening Settings, so waiting rows now get a neutral,
    // non-dismissable line that opens the queue; the error banner keeps its
    // own voice for rows that need a decision.
    await pumpBanner(tester, [_row(), _row(id: 2)]);
    expect(find.text('2 uploads not sent yet'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.textContaining('never reached'), findsNothing);
    expect(find.byTooltip('Dismiss'), findsNothing);
  });

  testWidgets(
      'rows parked for another server profile are not counted as waiting, '
      'retrying rows are', (tester) async {
    await pumpBanner(tester, [
      _row(),
      _row(id: 2, serverUrl: 'https://other.example.com'),
      _row(id: 3, retryCount: 2),
    ]);
    expect(find.text('2 uploads not sent yet'), findsOneWidget);
  });

  testWidgets('the not-sent line is one 48dp-tall button for a screen reader',
      (tester) async {
    await pumpBanner(tester, [_row()]);
    final size = tester.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      find.bySemanticsLabel(RegExp(r'1 upload not sent yet\. View upload queue')),
      findsOneWidget,
    );
  });

  testWidgets('a single waiting upload reads in the singular', (tester) async {
    await pumpBanner(tester, [_row()]);
    expect(find.text('1 upload not sent yet'), findsOneWidget);
  });

  testWidgets('speaks up when an upload has stopped trying', (tester) async {
    await pumpBanner(tester, [_row(), _row(id: 2, isFailed: true)]);

    expect(find.text('1 upload never reached your server'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('counts only what needs attention, and pluralises',
      (tester) async {
    await pumpBanner(tester, [
      _row(isFailed: true),
      _row(id: 2, isFailed: true),
      _row(id: 3),
    ]);

    expect(find.text('2 uploads never reached your server'), findsOneWidget);
  });

  testWidgets('can be dismissed for this visit', (tester) async {
    await pumpBanner(tester, [_row(isFailed: true)]);
    expect(find.textContaining('never reached'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.textContaining('never reached'), findsNothing);
  });
}

/// The count feeding the line, across every row status.
void _waitingProviderTests() {
  group('uploadsWaitingProvider', () {
    int countFor(List<PendingUpload> rows) {
      final container = ProviderContainer(
        overrides: [
          pendingUploadsProvider.overrideWith((ref) => Stream.value(rows)),
          authStateProvider.overrideWith(_FakeAuthenticated.new),
        ],
      );
      addTearDown(container.dispose);
      return container.read(uploadsWaitingProvider);
    }

    test('counts waiting and retrying rows for the active server only',
        () async {
      // The stream has to deliver before the provider can see the rows.
      final container = ProviderContainer(
        overrides: [
          pendingUploadsProvider.overrideWith((ref) => Stream.value([
                _row(id: 1), // waiting
                _row(id: 2, retryCount: 3), // retrying
                _row(id: 3, isFailed: true), // failed: attention, not waiting
                _row(id: 4, serverUrl: null), // legacy: attention
                _row(id: 5, serverUrl: 'https://other.example.com'), // parked
              ])),
          authStateProvider.overrideWith(_FakeAuthenticated.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pendingUploadsProvider.future);
      await container.read(authStateProvider.future);
      expect(container.read(uploadsWaitingProvider), 2);
      expect(container.read(uploadsNeedingAttentionProvider), 2);
    });

    test('is zero for an empty queue', () {
      expect(countFor(const []), 0);
    });
  });
}
