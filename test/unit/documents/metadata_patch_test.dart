// The PATCH the document-detail metadata sheet sends (native AI #44 review).
//
// Only fields that differ from the document the sheet was opened with are
// sent, so a concurrent edit to a field the user didn't touch is never
// overwritten; a title-only change (AI "Use this title") still saves.
//
// Run: flutter test test/unit/documents/metadata_patch_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/features/documents/metadata_patch.dart';
import 'package:paperless_go/shared/widgets/metadata_sheet.dart';

/// The real 3.2.1 admin detail response, with a few fields set.
final _base = Document.fromJson(jsonDecode(
            File('test/fixtures/api/ai/document_detail_admin.json')
                .readAsStringSync())
        as Map<String, dynamic>)
    .copyWith(correspondent: 1, documentType: 1, tags: [3, 1]);

/// The sheet saved without touching anything.
MetadataSheetResult _unchanged() => MetadataSheetResult(
      correspondentId: _base.correspondent,
      documentTypeId: _base.documentType,
      tagIds: _base.tags,
      created: _base.created,
    );

void main() {
  test('nothing changed: empty patch', () {
    expect(buildMetadataPatch(_base, _unchanged()), isEmpty);
  });

  test('title-only change: just the title', () {
    expect(
      buildMetadataPatch(_base, _unchanged(), title: 'Electricity Bill'),
      {'title': 'Electricity Bill'},
    );
  });

  test('the same title is not sent', () {
    expect(buildMetadataPatch(_base, _unchanged(), title: _base.title),
        isEmpty);
  });

  test('title plus tags', () {
    final result = MetadataSheetResult(
      correspondentId: _base.correspondent,
      documentTypeId: _base.documentType,
      tagIds: const [3, 1, 2],
      created: _base.created,
    );
    expect(
      buildMetadataPatch(_base, result, title: 'Electricity Bill'),
      {'title': 'Electricity Bill', 'tags': [3, 1, 2]},
    );
  });

  test('tags in another order are not a change', () {
    final result = MetadataSheetResult(
      correspondentId: _base.correspondent,
      documentTypeId: _base.documentType,
      tagIds: const [1, 3],
      created: _base.created,
    );
    expect(buildMetadataPatch(_base, result), isEmpty);
  });

  test('created untouched: same date or cleared date sends nothing', () {
    expect(_base.created, isNotNull);
    final cleared = MetadataSheetResult(
      correspondentId: _base.correspondent,
      documentTypeId: _base.documentType,
      tagIds: _base.tags,
    );
    expect(buildMetadataPatch(_base, cleared), isEmpty);
    expect(buildMetadataPatch(_base, _unchanged()), isEmpty);
  });

  test('a new created date is sent as YYYY-MM-DD', () {
    final result = MetadataSheetResult(
      correspondentId: _base.correspondent,
      documentTypeId: _base.documentType,
      tagIds: _base.tags,
      created: DateTime(2026, 4, 15),
    );
    expect(buildMetadataPatch(_base, result), {'created': '2026-04-15'});
  });

  test('clearing the correspondent and type sends null for both', () {
    final result = MetadataSheetResult(
      tagIds: _base.tags,
      created: _base.created,
    );
    expect(buildMetadataPatch(_base, result),
        {'correspondent': null, 'document_type': null});
  });
}
