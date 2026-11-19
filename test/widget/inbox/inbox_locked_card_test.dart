import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/services/biometric_service.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/inbox/inbox_notifier.dart';
import 'package:paperless_go/features/inbox/inbox_screen.dart';
import 'package:paperless_go/features/scanner/processing/metadata_matcher.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';
import 'package:paperless_go/shared/widgets/document_card.dart'
    show lockedDocumentTitle;

class _FakeBiometrics extends BiometricService {
  _FakeBiometrics({required this.result});

  final bool result;
  int calls = 0;

  @override
  Future<bool> authenticate({String reason = ''}) async {
    calls++;
    return result;
  }
}

/// Two-document inbox whose accept removes the document from the queue, the
/// way the real notifier does, and records which ids were filed.
class _FakeInbox extends InboxNotifier {
  static List<int> accepted = [];

  @override
  Future<InboxState> build() async => const InboxState(
        documents: [
          Document(id: 1, title: 'Secret'),
          Document(id: 2, title: 'Second'),
        ],
        totalCount: 2,
        hasMore: false,
      );

  @override
  Future<Map<String, dynamic>?> acceptSuggestions(
    Document doc,
    MetadataSuggestions suggestions,
  ) async {
    accepted = [...accepted, doc.id];
    final current = state.requireValue;
    state = AsyncData(current.copyWith(
      documents: current.documents.where((d) => d.id != doc.id).toList(),
      totalCount: current.totalCount - 1,
    ));
    return {'tags': doc.tags};
  }
}

class _PagedInbox extends InboxNotifier {
  static int loadMoreCalls = 0;

  @override
  Future<InboxState> build() async => InboxState(
        documents: [
          for (var i = 1; i <= 4; i++) Document(id: i, title: 'Doc $i'),
        ],
        totalCount: 50,
        hasMore: true,
      );

  @override
  Future<void> loadMore() async {
    loadMoreCalls++;
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required Set<int> locked,
  InboxNotifier Function()? inbox,
  BiometricService? biometrics,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboxNotifierProvider.overrideWith(inbox ?? _FakeInbox.new),
        lockedDocumentIdsProvider.overrideWith((ref) async => locked),
        biometricServiceProvider
            .overrideWithValue(biometrics ?? _FakeBiometrics(result: false)),
        paperlessApiProvider.overrideWithValue(PaperlessApi(Dio())),
        correspondentsProvider.overrideWith((ref) async => {}),
        documentTypesProvider.overrideWith((ref) async => {}),
        tagsProvider.overrideWith((ref) async => {}),
        uploadsNeedingAttentionProvider.overrideWithValue(0),
        uploadsWaitingProvider.overrideWithValue(0),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const InboxScreen()),
    ),
  );
}

Finder _button(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));

void main() {
  setUp(() => _FakeInbox.accepted = []);

  group('Inbox card for a locked document', () {
    testWidgets('masks the title and keeps Edit and Accept enabled',
        (tester) async {
      await _pump(tester, locked: {1});
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsNothing);
      expect(find.text(lockedDocumentTitle), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(_button('Edit')).onPressed,
          isNotNull);
      expect(tester.widget<ButtonStyleButton>(_button('Accept')).onPressed,
          isNotNull);
    });

    testWidgets('Accept without authentication files nothing', (tester) async {
      final bio = _FakeBiometrics(result: false);
      await _pump(tester, locked: {1}, biometrics: bio);
      await tester.pumpAndSettle();

      await tester.tap(_button('Accept'));
      await tester.pumpAndSettle();

      expect(bio.calls, 1);
      expect(_FakeInbox.accepted, isEmpty);
      expect(find.text(lockedDocumentTitle), findsOneWidget);
      expect(find.text('Secret'), findsNothing);
    });

    testWidgets('Accept after authentication files it and keeps it masked',
        (tester) async {
      final bio = _FakeBiometrics(result: true);
      await _pump(tester, locked: {1}, biometrics: bio);
      await tester.pumpAndSettle();

      await tester.tap(_button('Accept'));
      await tester.pumpAndSettle();

      expect(bio.calls, 1);
      expect(_FakeInbox.accepted, [1]);
      expect(find.text('Filed "$lockedDocumentTitle"'), findsOneWidget);
      expect(find.textContaining('Secret'), findsNothing);
      // The queue moves on to the next document.
      expect(find.text('Second'), findsWidgets);
    });

    testWidgets('a right swipe after authentication files it',
        (tester) async {
      await _pump(tester,
          locked: {1}, biometrics: _FakeBiometrics(result: true));
      await tester.pumpAndSettle();

      await tester.fling(
          find.text(lockedDocumentTitle), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(_FakeInbox.accepted, [1]);
    });

    testWidgets('a left swipe without authentication opens no edit sheet',
        (tester) async {
      await _pump(tester, locked: {1});
      await tester.pumpAndSettle();

      await tester.fling(
          find.text(lockedDocumentTitle), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
      expect(find.text('Secret'), findsNothing);
    });

    testWidgets('a left swipe after authentication opens the edit sheet',
        (tester) async {
      await _pump(tester,
          locked: {1}, biometrics: _FakeBiometrics(result: true));
      await tester.pumpAndSettle();

      await tester.fling(
          find.text(lockedDocumentTitle), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('an unlocked card files without asking to authenticate',
        (tester) async {
      final bio = _FakeBiometrics(result: false);
      await _pump(tester, locked: <int>{}, biometrics: bio);
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsOneWidget);
      await tester.tap(_button('Accept'));
      await tester.pumpAndSettle();

      expect(bio.calls, 0);
      expect(_FakeInbox.accepted, [1]);
    });

    testWidgets('loads the next page when fewer than 5 docs remain',
        (tester) async {
      _PagedInbox.loadMoreCalls = 0;
      await _pump(tester, locked: {1, 2, 3, 4}, inbox: _PagedInbox.new);
      await tester.pumpAndSettle();

      expect(_PagedInbox.loadMoreCalls, greaterThan(0));
    });
  });
}
