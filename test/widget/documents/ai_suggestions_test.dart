// "Suggest with AI" on document detail (native AI #44, Phase 1): who sees the
// action, what the sheet's header shows, and the one-time capability refresh.
// The request flow itself is in ai_suggestions_flow_test.dart.
//
// Fixtures: see test/helpers/ai_suggestions_fakes.dart.
//
// Run: flutter test test/widget/documents/ai_suggestions_test.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/api/server_capabilities.dart';
import 'package:paperless_go/core/models/ai_suggestions.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/models/storage_path.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_action.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_header.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_prefill.dart';

import '../../helpers/ai_suggestions_fakes.dart';

AiSuggestionsPrefill _prefill(
  Document doc,
  AiSuggestions s, {
  Map<int, StoragePath> storagePaths = const {},
}) => buildAiSuggestionsPrefill(
  document: doc,
  suggestions: s,
  tags: fixtureTags,
  correspondents: fixtureCorrespondents,
  documentTypes: fixtureTypes,
  storagePaths: storagePaths,
);

void main() {
  group(
    'gating: AI enabled, global change_document, and doc.userCanChange',
    () {
      Future<void> pumpTile(
        WidgetTester tester, {
        required bool ai,
        required Document doc,
        Set<String> permissions = const {'view_document', 'change_document'},
        VoidCallback? onTap,
      }) => tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectiveServerCapabilitiesProvider.overrideWith(
              (ref) => capsWith(ai: ai, permissions: permissions),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SuggestWithAiTile(document: doc, onTap: onTap ?? () {}),
            ),
          ),
        ),
      );

      final docs = {
        'true': adminDoc,
        'false': viewerDoc,
        'null (field absent)': adminDoc.copyWith(userCanChange: null),
      };

      for (final ai in [true, false]) {
        for (final MapEntry(key: label, value: doc) in docs.entries) {
          final visible = ai && label == 'true';
          testWidgets('AI ${ai ? 'on' : 'off'}, userCanChange $label: '
              '${visible ? 'shown' : 'hidden'}', (tester) async {
            await pumpTile(tester, ai: ai, doc: doc);
            expect(
              find.text('Suggest with AI'),
              visible ? findsOneWidget : findsNothing,
            );
          });
        }
      }

      testWidgets('fails closed while capabilities are unknown (none)', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              effectiveServerCapabilitiesProvider.overrideWith(
                (ref) => ServerCapabilities.none,
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SuggestWithAiTile(document: adminDoc, onTap: () {}),
              ),
            ),
          ),
        );
        expect(find.text('Suggest with AI'), findsNothing);
      });

      testWidgets(
        'fails closed without the global change_document permission',
        (tester) async {
          await pumpTile(
            tester,
            ai: true,
            doc: adminDoc,
            permissions: const {'view_document'},
          );
          expect(find.text('Suggest with AI'), findsNothing);
        },
      );

      testWidgets('says where the document goes', (tester) async {
        await pumpTile(tester, ai: true, doc: adminDoc);
        expect(
          find.text("Sends this document's text to your server's AI provider"),
          findsOneWidget,
        );
      });

      testWidgets('read once: capabilities arriving later never make the tile '
          'pop in while the sheet is open', (tester) async {
        final caps = StateProvider<ServerCapabilities>(
          (ref) => ServerCapabilities.none,
        );
        final container = ProviderContainer(
          overrides: [
            effectiveServerCapabilitiesProvider.overrideWith(
              (ref) => ref.watch(caps),
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SuggestWithAiTile(document: adminDoc, onTap: () {}),
              ),
            ),
          ),
        );
        expect(find.text('Suggest with AI'), findsNothing);

        container.read(caps.notifier).state = capsWith(ai: true);
        await tester.pump();
        expect(find.text('Suggest with AI'), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('tapping the tile calls onTap', (tester) async {
        var taps = 0;
        await pumpTile(tester, ai: true, doc: adminDoc, onTap: () => taps++);
        await tester.tap(find.text('Suggest with AI'));
        expect(taps, 1);
      });
    },
  );

  group('sheet header (topSlot) from the real bill response', () {
    final billPrefill = _prefill(adminDoc, billSuggestions);

    Future<List<bool>> pumpHeader(
      WidgetTester tester, {
      AiSuggestionsPrefill? p,
    }) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AiSuggestionsHeader(
                prefill: p ?? billPrefill,
                onUseTitleChanged: changes.add,
              ),
            ),
          ),
        ),
      );
      return changes;
    }

    testWidgets('suggested title with an unticked "Use this title" box that '
        'the header itself keeps', (tester) async {
      final changes = await pumpHeader(tester);

      expect(find.text('Electricity Bill - March 2026'), findsOneWidget);
      final box = find.widgetWithText(CheckboxListTile, 'Use this title');
      expect(box, findsOneWidget);
      expect(tester.widget<CheckboxListTile>(box).value, isFalse);

      await tester.tap(box);
      await tester.pump();
      expect(changes, [true]);
      expect(tester.widget<CheckboxListTile>(box).value, isTrue);

      await tester.tap(box);
      await tester.pump();
      expect(changes, [true, false]);
    });

    testWidgets('dates are shown as info, not as an editable value', (
      tester,
    ) async {
      await pumpHeader(tester);

      expect(find.textContaining('Mar 31, 2026'), findsOneWidget);
      expect(find.textContaining('Apr 15, 2026'), findsOneWidget);
      expect(find.textContaining("date isn't changed"), findsOneWidget);
    });

    testWidgets('"Not in your library" lists the new names by kind', (
      tester,
    ) async {
      await pumpHeader(tester);

      expect(find.text('Not in your library'), findsOneWidget);
      expect(find.text('Tags: Electricity, Energy'), findsOneWidget);
      expect(
        find.text('Document types: Electricity Bill, Invoice'),
        findsOneWidget,
      );
      expect(
        find.text('Storage paths: Utilities/Electricity, Finance/Bills'),
        findsOneWidget,
      );
      expect(find.textContaining('Correspondents:'), findsNothing);
      expect(find.textContaining('Not loaded'), findsNothing);
    });

    testWidgets('IDs the app hasn\'t loaded are their own line, not "create '
        'them"', (tester) async {
      final p = _prefill(
        adminDoc,
        const AiSuggestions(tagIds: [99], correspondentIds: [42]),
      );
      await pumpHeader(tester, p: p);

      expect(
        find.text('Not loaded in the app yet — try again later'),
        findsOneWidget,
      );
      expect(find.text('Tags: #99'), findsOneWidget);
      expect(find.text('Correspondents: #42'), findsOneWidget);
      expect(find.text('Not in your library'), findsNothing);
      expect(find.textContaining('Create them'), findsNothing);
    });

    testWidgets('an "AI suggests" line when a set field disagrees', (
      tester,
    ) async {
      final p = _prefill(
        adminDoc.copyWith(correspondent: 2, documentType: 2),
        billSuggestions,
      );
      await pumpHeader(tester, p: p);

      expect(
        find.text('AI suggests correspondent: Acme Energy'),
        findsOneWidget,
      );
      expect(find.text('AI suggests document type: Bill'), findsOneWidget);
    });

    testWidgets('an existing storage path is info only', (tester) async {
      final p = _prefill(
        adminDoc,
        const AiSuggestions(storagePathIds: [5]),
        storagePaths: const {
          5: StoragePath(id: 5, name: 'Utilities', slug: 'utilities'),
        },
      );
      await pumpHeader(tester, p: p);

      expect(find.text('AI suggests storage path: Utilities'), findsOneWidget);
      expect(find.textContaining("doesn't edit storage paths"), findsOneWidget);
      expect(find.text('Not in your library'), findsNothing);
    });

    testWidgets('no title row when the title is unchanged', (tester) async {
      final p = _prefill(
        adminDoc.copyWith(title: 'Electricity Bill - March 2026'),
        billSuggestions,
      );
      await pumpHeader(tester, p: p);
      expect(find.text('Use this title'), findsNothing);
    });
  });

  group('one-time capability refresh on the detail screen', () {
    Future<int> fetchesAfterOpening(
      WidgetTester tester, {
      DioException? error,
      bool warmFirst = false,
    }) async {
      var fetches = 0;
      final container = ProviderContainer(
        overrides: [
          serverCapabilitiesProvider.overrideWith((ref) async {
            fetches++;
            if (error != null) throw error;
            return capsWith(ai: true);
          }),
        ],
      );
      addTearDown(container.dispose);
      if (warmFirst) {
        // Already failed before the screen opened (e.g. app started offline).
        container.listen(serverCapabilitiesProvider, (_, __) {});
        await tester.pump();
        expect(container.read(serverCapabilitiesProvider).hasError, isTrue);
      }
      final before = fetches;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: _RefreshHost()),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      final opened = fetches - before;
      // Unmount before the container is disposed.
      await tester.pumpWidget(const SizedBox.shrink());
      return opened;
    }

    final offline = DioException(
      requestOptions: RequestOptions(path: 'api/ui_settings/'),
      type: DioExceptionType.connectionError,
    );

    DioException status(int code) {
      final options = RequestOptions(path: 'api/ui_settings/');
      return DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: code),
      );
    }

    testWidgets('an error is retried exactly once', (tester) async {
      expect(await fetchesAfterOpening(tester, error: offline), 2);
    });

    testWidgets('an error that was there before the screen opened is '
        'retried once', (tester) async {
      expect(
        await fetchesAfterOpening(tester, error: offline, warmFirst: true),
        1,
      );
    });

    testWidgets('401 / 403 (no permission to read ui_settings) are not '
        'retried: asking again gives the same answer', (tester) async {
      expect(await fetchesAfterOpening(tester, error: status(403)), 1);
      expect(await fetchesAfterOpening(tester, error: status(401)), 1);
    });

    testWidgets('a success is never refreshed (no flicker)', (tester) async {
      expect(await fetchesAfterOpening(tester), 1);
    });
  });
}

/// Stands in for the detail screen's State: the refresh hooks in initState.
class _RefreshHost extends ConsumerStatefulWidget {
  const _RefreshHost();

  @override
  ConsumerState<_RefreshHost> createState() => _RefreshHostState();
}

class _RefreshHostState extends ConsumerState<_RefreshHost> {
  @override
  void initState() {
    super.initState();
    refreshServerCapabilitiesOnceOnError(ref);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
