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
        documents: [Document(id: 1, title: 'Secret')],
        totalCount: 1,
        hasMore: false,
      );
}

Future<void> _pump(WidgetTester tester, {required Set<int> locked}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboxNotifierProvider.overrideWith(_FakeInbox.new),
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
