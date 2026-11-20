// Native-AI save wiring: rows only after a successful PATCH (finding #2).
//
// Run: flutter test test/unit/documents/metadata_save_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/ai_edit_diff.dart';
import 'package:paperless_go/features/documents/ai_edit_trail_notifier.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_prefill.dart';
import 'package:paperless_go/features/documents/metadata_save.dart';
import 'package:paperless_go/shared/widgets/metadata_sheet.dart';

final _doc = Document.fromJson({
  'id': 1,
  'title': 't',
  'tags': <int>[],
  'correspondent': null,
});

const _result = MetadataSheetResult(correspondentId: 5, tagIds: []);

const _prefill = AiSuggestionsPrefill(
  correspondentId: 5,
  documentTypeId: null,
  tagIds: [],
  suggestedCorrespondent: true,
  suggestedDocumentType: false,
  suggestedTagIds: {},
  suggestedTitle: null,
  dates: [],
  correspondentDisagreement: null,
  documentTypeDisagreement: null,
  storagePathNames: [],
  newTagNames: [],
  newCorrespondentNames: [],
  newDocumentTypeNames: [],
  newStoragePathNames: [],
  unknownTagIds: [],
  unknownCorrespondentIds: [],
  unknownDocumentTypeIds: [],
  unknownStoragePathIds: [],
);

const _ai = AiSaveContext(
  source: 'native_ai',
  prefill: _prefill,
  names: AiEditNames(correspondents: {5: 'ACME'}),
);

void main() {
  late List<(EditMap, String)> recorded;
  late List<Object> errors;

  setUp(() {
    recorded = [];
    errors = [];
  });

  Future<void> run({
    AiSaveContext? ai,
    bool patchThrows = false,
  }) =>
      saveMetadata(
        doc: _doc,
        result: _result,
        ai: ai,
        patchDocument: (_) async {
          if (patchThrows) throw StateError('boom');
        },
        recordEdits: (e, s) async => recorded.add((e, s)),
        onError: errors.add,
      );

  test('successful AI save writes rows', () async {
    await run(ai: _ai);
    expect(recorded, hasLength(1));
    expect(recorded.single.$2, 'native_ai');
    expect(recorded.single.$1['correspondent'],
        (oldValue: null, newValue: 'ACME'));
  });

  test('failed PATCH writes no rows and reports the error', () async {
    await run(ai: _ai, patchThrows: true);
    expect(recorded, isEmpty);
    expect(errors, hasLength(1));
  });

  test('plain metadata save writes no rows', () async {
    await run();
    expect(recorded, isEmpty);
    expect(errors, isEmpty);
  });
}
