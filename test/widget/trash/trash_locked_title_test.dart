import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/services/document_lock_service.dart';
import 'package:paperless_go/core/theme.dart';
import 'package:paperless_go/features/trash/trash_notifier.dart';
import 'package:paperless_go/features/trash/trash_screen.dart';
import 'package:paperless_go/shared/widgets/document_card.dart'
    show lockedDocumentTitle;

class _FakeTrash extends TrashNotifier {
  @override
  Future<TrashState> build() async => const TrashState(
        documents: [
          Document(id: 1, title: 'Secret'),
          Document(id: 2, title: 'Public'),
        ],
        totalCount: 2,
        hasMore: false,
      );
}

void main() {
  testWidgets('trash masks the title of a locked document', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        trashNotifierProvider.overrideWith(_FakeTrash.new),
        lockedDocumentIdsProvider.overrideWith((ref) async => {1}),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const TrashScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Secret'), findsNothing);
    expect(find.text(lockedDocumentTitle), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);
  });
}
