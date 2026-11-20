// Diff of a native-AI save into AI-trail entries (finding #2).
//
// Run: flutter test test/unit/documents/ai_edit_diff_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/ai_edit_diff.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_prefill.dart';
import 'package:paperless_go/shared/widgets/metadata_sheet.dart';

const _names = AiEditNames(
  tags: {1: 'Bills', 3: 'Energy', 4: 'Misc'},
  correspondents: {5: 'ACME', 6: 'Other'},
  documentTypes: {7: 'Invoice'},
);

final _base = Document.fromJson({
  'id': 1,
  'title': 'scan_001',
  'tags': [1],
  'correspondent': null,
  'document_type': 7,
  'created': '2026-01-02',
});

AiSuggestionsPrefill prefill({
  int? correspondentId,
  bool suggestedCorrespondent = false,
  Set<int> suggestedTagIds = const {},
  List<DateTime> dates = const [],
}) =>
    AiSuggestionsPrefill(
      correspondentId: correspondentId,
      documentTypeId: 7,
      tagIds: const [1],
      suggestedCorrespondent: suggestedCorrespondent,
      suggestedDocumentType: false,
      suggestedTagIds: suggestedTagIds,
      suggestedTitle: null,
      dates: dates,
      correspondentDisagreement: null,
      documentTypeDisagreement: null,
      storagePathNames: const [],
      newTagNames: const [],
      newCorrespondentNames: const [],
      newDocumentTypeNames: const [],
      newStoragePathNames: const [],
      unknownTagIds: const [],
      unknownCorrespondentIds: const [],
      unknownDocumentTypeIds: const [],
      unknownStoragePathIds: const [],
    );

void main() {
  test('records suggested fields the user kept, with resolved names', () {
    final edits = buildAiEdits(
      _base,
      const MetadataSheetResult(
        correspondentId: 5,
        documentTypeId: 7,
        tagIds: [1, 3],
        created: null,
      ),
      title: 'Electricity Bill',
      prefill: prefill(
          correspondentId: 5,
          suggestedCorrespondent: true,
          suggestedTagIds: {3}),
      names: _names,
    );
    expect(edits, {
      'title': (oldValue: 'scan_001', newValue: 'Electricity Bill'),
      'correspondent': (oldValue: null, newValue: 'ACME'),
      'tags': (oldValue: 'Bills', newValue: 'Bills, Energy'),
    });
  });

  test('user overrides write no row for the overridden field', () {
    final edits = buildAiEdits(
      _base,
      MetadataSheetResult(
        correspondentId: 6, // AI suggested 5
        documentTypeId: 7,
        tagIds: const [1, 4], // user added 4, dropped AI's 3
        created: DateTime(2026, 3, 3), // not one of the AI's dates
      ),
      prefill: prefill(
          correspondentId: 5,
          suggestedCorrespondent: true,
          suggestedTagIds: {3},
          dates: [DateTime(2026, 5, 5)]),
      names: _names,
    );
    expect(edits, isEmpty);
  });

  test('hand edits with nothing suggested write no rows', () {
    final edits = buildAiEdits(
      _base,
      const MetadataSheetResult(correspondentId: 6, tagIds: []),
      prefill: prefill(),
      names: _names,
    );
    expect(edits, isEmpty);
  });

  test('created is recorded only when it is one of the AI dates', () {
    final edits = buildAiEdits(
      _base,
      MetadataSheetResult(tagIds: const [1], documentTypeId: 7, created: DateTime(2026, 5, 5)),
      prefill: prefill(dates: [DateTime(2026, 5, 5)]),
      names: _names,
    );
    expect(edits, {'created': (oldValue: '2026-01-02', newValue: '2026-05-05')});
  });
}
