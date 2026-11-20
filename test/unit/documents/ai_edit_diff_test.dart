// Diff of a native-AI save into AI-trail entries (finding #2).
//
// Run: flutter test test/unit/documents/ai_edit_diff_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/ai_edit_diff.dart';
import 'package:paperless_go/shared/widgets/metadata_sheet.dart';

const _names = AiEditNames(
  tags: {1: 'Bills', 3: 'Energy'},
  correspondents: {5: 'ACME'},
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

void main() {
  test('records only changed fields with resolved names', () {
    final edits = buildAiEdits(
      _base,
      const MetadataSheetResult(
        correspondentId: 5,
        documentTypeId: 7,
        tagIds: [1, 3],
        created: null,
      ),
      title: 'Electricity Bill',
      names: _names,
    );
    expect(edits, {
      'title': (oldValue: 'scan_001', newValue: 'Electricity Bill'),
      'correspondent': (oldValue: null, newValue: 'ACME'),
      'tags': (oldValue: 'Bills', newValue: 'Bills, Energy'),
    });
  });

  test('cleared document type records null new value', () {
    final edits = buildAiEdits(
      _base,
      const MetadataSheetResult(tagIds: [1]),
      names: _names,
    );
    expect(edits, {'document_type': (oldValue: 'Invoice', newValue: null)});
  });

  test('unknown id falls back to the id', () {
    final edits = buildAiEdits(
      _base,
      const MetadataSheetResult(documentTypeId: 7, correspondentId: 99, tagIds: [1]),
      names: _names,
    );
    expect(edits['correspondent'], (oldValue: null, newValue: '#99'));
  });
}
