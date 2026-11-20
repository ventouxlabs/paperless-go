import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/database/app_database.dart';
import 'package:paperless_go/core/database/database_provider.dart';
import 'package:paperless_go/features/documents/ai_edit_trail_notifier.dart';
import 'package:paperless_go/features/documents/document_detail_screen.dart';

void main() {
  testWidgets('headings are source-aware and rows grouped by source',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container =
        ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    final n = container.read(aiEditTrailProvider(1).notifier);
    await n.recordEdits(
        {'title': (oldValue: null, newValue: 'Upload title')}, 'ocr_suggestion');
    await n.recordEdits(
        {'tags': (oldValue: null, newValue: 'Energy')}, 'native_ai');
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: AiEditTrailSection(documentId: 1))),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('AI Applied at Upload'), findsOneWidget);
    expect(find.text('AI Suggested'), findsOneWidget);
    expect(find.text('Upload title'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
  });
}
