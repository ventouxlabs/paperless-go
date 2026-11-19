import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/api_providers.dart';
import 'package:paperless_go/core/api/paperless_api.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/inbox/inbox_notifier.dart';
import 'package:paperless_go/features/inbox/inbox_screen.dart';
import 'package:paperless_go/features/upload_queue/upload_queue_notifier.dart';
import 'package:paperless_go/shared/widgets/document_card.dart'
    show lockedDocumentTitle;

class _FakeInbox extends InboxNotifier {
  @override
  Future<InboxState> build() async => const InboxState(
        documents: [
          Document(id: 1, title: 'Secret'),
          Document(id: 2, title: 'Second'),
        ],
        totalCount: 2,
        hasMore: false,
      );
}

class _PagedInbox extends InboxNotifier {
  static int loadMoreCalls = 0;

  @override
  Future<InboxState> build() async => InboxState(
        documents: [
          for (var i = 1; i <= 5; i++) Document(id: i, title: 'Doc $i'),
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
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboxNotifierProvider.overrideWith(inbox ?? _FakeInbox.new),
        lockedDocumentIdsProvider.overrideWith((ref) async => locked),
        paperlessApiProvider.overrideWithValue(PaperlessApi(Dio())),
        correspondentsProvider.overrideWith((ref) async => {}),
        uploadsNeedingAttentionProvider.overrideWithValue(0),
        uploadsWaitingProvider.overrideWithValue(0),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const InboxScreen()),
    ),
  );
}

void main() {
  group('Inbox card for a locked document', () {
    testWidgets('masks the title and disables Edit and Accept',
        (tester) async {
      await _pump(tester, locked: {1});
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsNothing);
      expect(find.text(lockedDocumentTitle), findsOneWidget);
      expect(
        tester.widget<ButtonStyleButton>(
            find.ancestor(
                of: find.text('Edit'),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton))),
        isA<ButtonStyleButton>().having((b) => b.onPressed, 'onPressed', null),
      );
      expect(
        tester.widget<ButtonStyleButton>(
            find.ancestor(
                of: find.text('Accept'),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton))),
        isA<ButtonStyleButton>().having((b) => b.onPressed, 'onPressed', null),
      );
    });

    testWidgets('a left swipe does not open the edit sheet', (tester) async {
      await _pump(tester, locked: {1});
      await tester.pumpAndSettle();

      await tester.fling(
          find.text(lockedDocumentTitle), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsNothing);
      expect(find.text('Secret'), findsNothing);
    });

    testWidgets('a left swipe skips it so the next document is reachable',
        (tester) async {
      await _pump(tester, locked: {1});
      await tester.pumpAndSettle();

      await tester.fling(
          find.text(lockedDocumentTitle), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Second'), findsWidgets);
      final accept = tester.widget<ButtonStyleButton>(find.ancestor(
          of: find.text('Accept'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
      expect(accept.onPressed, isNotNull);
      expect(find.text('Secret'), findsNothing);
    });

    testWidgets('loads the next page when 5+ locked docs fill the queue',
        (tester) async {
      _PagedInbox.loadMoreCalls = 0;
      await _pump(tester,
          locked: {1, 2, 3, 4, 5}, inbox: _PagedInbox.new);
      await tester.pumpAndSettle();

      expect(_PagedInbox.loadMoreCalls, greaterThan(0));
    });

    testWidgets('an unlocked card keeps Edit and Accept enabled',
        (tester) async {
      await _pump(tester, locked: <int>{});
      await tester.pumpAndSettle();

      expect(find.text('Secret'), findsOneWidget);
      final edit = tester.widget<ButtonStyleButton>(find.ancestor(
          of: find.text('Edit'),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
      expect(edit.onPressed, isNotNull);
    });
  });
}
