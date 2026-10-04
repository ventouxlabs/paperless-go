// "Suggest with AI" request flow (native AI #44, Phase 1): tap → progress
// dialog → pre-filled sheet / "No changes suggested" / error snackbar, and the
// dialog never closing anything but itself.
//
// Fixtures: see test/helpers/ai_suggestions_fakes.dart.
//
// Run: flutter test test/widget/documents/ai_suggestions_flow_test.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/server_capabilities.dart';
import 'package:paperless_go/core/models/ai_suggestions.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_action.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_flow.dart';
import 'package:paperless_go/shared/widgets/metadata_sheet.dart';

import '../../helpers/ai_suggestions_fakes.dart';

typedef _Save = (Document base, MetadataSheetResult result, String? title);

/// A document that already has everything the bill fixture suggests.
final _alreadyFiled = adminDoc.copyWith(
  title: 'Electricity Bill - March 2026',
  correspondent: 1,
  documentType: 1,
  tags: [2],
);

void main() {
  late FakeAiApi api;
  late List<_Save> saves;

  setUp(() {
    api = FakeAiApi();
    saves = [];
  });

  Widget goButton(Document doc) => Builder(
        builder: (context) => TextButton(
          onPressed: () => showAiSuggestions(
            context,
            doc,
            onSave: (base, result, title) => saves.add((base, result, title)),
          ),
          child: const Text('go'),
        ),
      );

  /// Taps "go" and lets the progress dialog open fully, request in flight.
  Future<void> startFlow(WidgetTester tester) async {
    await tester.tap(find.text('go'));
    await tester.pump(); // dialog route
    await tester.pump(); // post-frame request
    expect(api.tokens, hasLength(1));
    // Fully open: a dialog that never opened closes instantly, which would
    // hide the close-the-wrong-route bugs below.
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> pumpHost(WidgetTester tester, Document doc) async {
    await tester.pumpWidget(ProviderScope(
      overrides: aiLibraryOverrides(api),
      child: MaterialApp(home: Scaffold(body: goButton(doc))),
    ));
    await startFlow(tester);
  }

  /// The real detail screen is a pushed page: "go" lives on a second route.
  Future<void> pumpPushedHost(WidgetTester tester, Document doc) async {
    await tester.pumpWidget(ProviderScope(
      overrides: aiLibraryOverrides(api),
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(body: goButton(doc)))),
            child: const Text('open detail'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open detail'));
    await tester.pumpAndSettle();
    await startFlow(tester);
  }

  NavigatorState navigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator));

  testWidgets('showing the action never asks; only the tap does',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...aiLibraryOverrides(api),
        effectiveServerCapabilitiesProvider
            .overrideWith((ref) => capsWith(ai: true)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SuggestWithAiTile(document: adminDoc, onTap: () {}),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Suggest with AI'), findsOneWidget);
    expect(api.tokens, isEmpty);
  });

  testWidgets('the progress dialog says Cancel only stops waiting',
      (tester) async {
    await pumpHost(tester, adminDoc);
    expect(find.textContaining('the server may still finish the request'),
        findsOneWidget);
  });

  testWidgets('changes: the pre-filled sheet opens; saving passes the fresh '
      'document as base, the title only when ticked, and the document date',
      (tester) async {
    await pumpHost(tester, adminDoc);
    api.succeed(billSuggestions);
    await tester.pumpAndSettle();

    expect(find.byType(MetadataSheet), findsOneWidget);
    final sheet = tester.widget<MetadataSheet>(find.byType(MetadataSheet));
    expect(sheet.correspondentId, 1);
    expect(sheet.suggestedCorrespondent, isTrue);
    expect(sheet.documentTypeId, 1);
    expect(sheet.suggestedDocumentType, isTrue);
    expect(sheet.tagIds, [2]);
    expect(sheet.suggestedTagIds, {2});
    expect(sheet.created, adminDoc.created);
    expect(sheet.suggestedDate, isFalse);
    expect(find.text('Not in your library'), findsOneWidget);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Use this title'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saves, hasLength(1));
    final (base, result, title) = saves.single;
    expect(base, api.nextDocument);
    expect(title, 'Electricity Bill - March 2026');
    expect(result.correspondentId, 1);
    expect(result.documentTypeId, 1);
    expect(result.tagIds, [2]);
    expect(result.created, adminDoc.created);
  });

  testWidgets('saving with the box unticked passes no title', (tester) async {
    await pumpHost(tester, adminDoc);
    api.succeed(billSuggestions);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saves.single.$3, isNull);
  });

  testWidgets('a concurrent edit is what the sheet starts from',
      (tester) async {
    await pumpHost(tester, adminDoc);
    api.nextDocument = adminDoc.copyWith(correspondent: 2);
    api.succeed(billSuggestions);
    await tester.pumpAndSettle();

    final sheet = tester.widget<MetadataSheet>(find.byType(MetadataSheet));
    expect(sheet.correspondentId, 2);
    expect(sheet.suggestedCorrespondent, isFalse);
    expect(find.text('AI suggests correspondent: Acme Energy'), findsOneWidget);
  });

  testWidgets('no changes, but info: "No changes suggested" with Details, '
      'which opens the same sheet', (tester) async {
    api.nextDocument = _alreadyFiled;
    await pumpHost(tester, _alreadyFiled);
    api.succeed(billSuggestions);
    await tester.pumpAndSettle();

    expect(find.byType(MetadataSheet), findsNothing);
    expect(find.text('No changes suggested'), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Details'));
    await tester.pumpAndSettle();

    expect(find.byType(MetadataSheet), findsOneWidget);
    expect(find.text('Not in your library'), findsOneWidget);
    expect(find.text('Use this title'), findsNothing);
  });

  testWidgets('"No changes suggested" goes away on its own and never blocks '
      'the next snackbar', (tester) async {
    api.nextDocument = _alreadyFiled;
    await pumpHost(tester, _alreadyFiled);
    api.succeed(billSuggestions);
    await tester.pumpAndSettle();
    expect(find.text('No changes suggested'), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
    expect(find.text('No changes suggested'), findsNothing);

    ScaffoldMessenger.of(tester.element(find.text('go')))
        .showSnackBar(const SnackBar(content: Text('the next message')));
    await tester.pumpAndSettle();
    expect(find.text('the next message'), findsOneWidget);
  });

  testWidgets('Details does nothing once another page covers the screen',
      (tester) async {
    api.nextDocument = _alreadyFiled;
    await pumpHost(tester, _alreadyFiled);
    api.succeed(billSuggestions);
    await tester.pumpAndSettle();

    // Another document's page opens; the snackbar follows to its Scaffold.
    navigator(tester).push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('another document'))));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SnackBarAction, 'Details'));
    await tester.pumpAndSettle();

    expect(find.byType(MetadataSheet, skipOffstage: false), findsNothing);
    expect(find.text('another document'), findsOneWidget);
  });

  testWidgets('nothing at all: "No changes suggested", no Details',
      (tester) async {
    await pumpHost(tester, adminDoc);
    api.succeed(const AiSuggestions());
    await tester.pumpAndSettle();

    expect(find.byType(MetadataSheet), findsNothing);
    expect(find.text('No changes suggested'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('an error shows its text', (tester) async {
    await pumpHost(tester, adminDoc);
    final options = RequestOptions(path: 'api/documents/1/ai_suggestions/');
    api.fail(DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: options,
        statusCode: 403,
        data: 'Insufficient permissions',
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        }),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MetadataSheet), findsNothing);
    expect(find.textContaining("can't edit this document"), findsOneWidget);
  });

  testWidgets('Cancel closes the dialog and cancels the request',
      (tester) async {
    await pumpHost(tester, adminDoc);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(api.tokens.single?.isCancelled, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(MetadataSheet), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Back closes the dialog and cancels the request too',
      (tester) async {
    await pumpHost(tester, adminDoc);
    // What the system back button does: pops unless a PopScope objects.
    await navigator(tester).maybePop();
    await tester.pumpAndSettle();

    expect(api.tokens.single?.isCancelled, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  group('the dialog only ever closes itself', () {
    testWidgets('a reply that was already on its way when Back was pressed '
        'never pops the page underneath', (tester) async {
      api.ignoreCancel = true;
      await pumpPushedHost(tester, adminDoc);

      // Back: the dialog starts its exit animation but is still mounted...
      await navigator(tester).maybePop();
      await tester.pump();
      // ...when the model's answer arrives anyway.
      api.succeed(billSuggestions);
      await tester.pumpAndSettle();

      expect(find.text('go'), findsOneWidget, reason: 'still on the page');
      expect(find.byType(MetadataSheet), findsNothing);
      expect(api.tokens.single?.isCancelled, isTrue);
    });

    testWidgets('a reply arriving while another page covers the dialog '
        'removes the dialog and leaves that page alone', (tester) async {
      await pumpPushedHost(tester, adminDoc);

      // Something (a deep link, a notification tap) pushes a page on top.
      navigator(tester).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('covering page'))));
      await tester.pumpAndSettle();
      api.succeed(billSuggestions);
      await tester.pumpAndSettle();

      expect(find.text('covering page'), findsOneWidget);
      expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
      expect(find.byType(MetadataSheet), findsNothing);

      // Back from the covering page lands on the detail page, not a spinner.
      await navigator(tester).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('go'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
