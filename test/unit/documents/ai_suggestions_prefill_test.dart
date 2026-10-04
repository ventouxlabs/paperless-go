// Pre-fill rules for "Suggest with AI" (native AI #44, Phase 1).
//
// Inputs are the REAL 3.2.1 fixtures (test/fixtures/api/ai/): the two 200
// suggestion bodies and the admin document-detail body. The local maps use the
// object IDs that server had: tags Invoice=1, Utilities=2, Insurance=3,
// Tax=4; correspondents Acme Energy=1, Northwind Insurance=2; types Bill=1,
// Letter=2.
//
// Rules (docs/prp/native-ai-44-2026-10-03.md, "Phase 1: UX decisions"):
// correspondent/type pre-filled only when unset; tags additive; only IDs that
// resolve locally are pre-filled; suggested IDs the app doesn't know are
// "not loaded yet" (kept apart from the AI's new names, which are "not in your
// library"); dates and storage paths are info only; created is never touched.
//
// Run: flutter test test/unit/documents/ai_suggestions_prefill_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_go/core/models/ai_suggestions.dart';
import 'package:paperless_go/core/models/correspondent.dart';
import 'package:paperless_go/core/models/document.dart';
import 'package:paperless_go/core/models/document_type.dart';
import 'package:paperless_go/core/models/storage_path.dart';
import 'package:paperless_go/core/models/tag.dart';
import 'package:paperless_go/features/documents/ai_suggestions/ai_suggestions_prefill.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('test/fixtures/api/ai/$name').readAsStringSync())
        as Map<String, dynamic>;

final _bill = AiSuggestions.fromJson(_json('ai_suggestions_bill.json'));
final _taxLetter =
    AiSuggestions.fromJson(_json('ai_suggestions_new_correspondent.json'));

/// The real admin detail response: no correspondent, no type, no tags.
final _blankDoc = Document.fromJson(_json('document_detail_admin.json'));

final _tags = {
  for (final (id, name) in [
    (1, 'Invoice'),
    (2, 'Utilities'),
    (3, 'Insurance'),
    (4, 'Tax'),
  ])
    id: Tag(id: id, name: name, slug: name.toLowerCase()),
};
final _correspondents = {
  1: const Correspondent(id: 1, name: 'Acme Energy', slug: 'acme-energy'),
  2: const Correspondent(
      id: 2, name: 'Northwind Insurance', slug: 'northwind-insurance'),
};
final _types = {
  1: const DocumentType(id: 1, name: 'Bill', slug: 'bill'),
  2: const DocumentType(id: 2, name: 'Letter', slug: 'letter'),
};
final _storagePaths = {
  5: const StoragePath(id: 5, name: 'Utilities', slug: 'utilities'),
};

AiSuggestionsPrefill _prefill(
  Document doc,
  AiSuggestions suggestions, {
  Map<int, Tag>? tags,
  Map<int, Correspondent>? correspondents,
  Map<int, DocumentType>? documentTypes,
  Map<int, StoragePath>? storagePaths,
}) =>
    buildAiSuggestionsPrefill(
      document: doc,
      suggestions: suggestions,
      tags: tags ?? _tags,
      correspondents: correspondents ?? _correspondents,
      documentTypes: documentTypes ?? _types,
      storagePaths: storagePaths ?? _storagePaths,
    );

void main() {
  group('bill fixture on the real blank document', () {
    final p = _prefill(_blankDoc, _bill);

    test('pre-fills the unset correspondent and type, marked as suggested', () {
      expect(p.correspondentId, 1); // Acme Energy
      expect(p.suggestedCorrespondent, isTrue);
      expect(p.documentTypeId, 1); // Bill
      expect(p.suggestedDocumentType, isTrue);
    });

    test('adds the existing tag, marked as suggested', () {
      expect(p.tagIds, [2]); // Utilities
      expect(p.suggestedTagIds, {2});
    });

    test('offers the new title (it differs from the current one)', () {
      expect(_blankDoc.title, 'Acme Energy electricity bill March 2026');
      expect(p.suggestedTitle, 'Electricity Bill - March 2026');
    });

    test('dates are info only', () {
      expect(p.dates, [DateTime(2026, 3, 31), DateTime(2026, 4, 15)]);
    });

    test('names with no match are "not in your library", grouped by kind', () {
      expect(p.newTagNames, ['Electricity', 'Energy']);
      expect(p.newCorrespondentNames, isEmpty);
      // "Invoice" exists as a TAG, not as a type: it still belongs here.
      expect(p.newDocumentTypeNames, ['Electricity Bill', 'Invoice']);
      expect(p.newStoragePathNames, ['Utilities/Electricity', 'Finance/Bills']);
    });

    test('nothing disagrees with a blank document', () {
      expect(p.correspondentDisagreement, isNull);
      expect(p.documentTypeDisagreement, isNull);
      expect(p.storagePathNames, isEmpty);
      expect(p.hasChanges, isTrue);
    });
  });

  group('tax-letter fixture (suggests a correspondent that does not exist)',
      () {
    final p = _prefill(_blankDoc, _taxLetter);

    test('no existing correspondent: nothing pre-filled, name listed as new',
        () {
      expect(p.correspondentId, isNull);
      expect(p.suggestedCorrespondent, isFalse);
      expect(p.newCorrespondentNames, ['City Tax Office']);
    });

    test('type Letter and tag Tax are pre-filled', () {
      expect(p.documentTypeId, 2);
      expect(p.suggestedDocumentType, isTrue);
      expect(p.tagIds, [4]);
      expect(p.suggestedTagIds, {4});
      expect(p.newTagNames, ['Property Tax']);
      expect(p.newDocumentTypeNames, ['Notice']);
    });

    test('title and the single date', () {
      expect(p.suggestedTitle, 'Property Tax Assessment Notice 2025');
      expect(p.dates, [DateTime(2026, 1, 20)]);
      expect(p.hasChanges, isTrue);
    });
  });

  group('pre-fill only what is empty', () {
    test('a correspondent/type already set is kept; a different AI pick '
        'becomes an "AI suggests" line, not a pre-fill', () {
      final doc = _blankDoc.copyWith(correspondent: 2, documentType: 2);
      final p = _prefill(doc, _bill);

      expect(p.correspondentId, 2);
      expect(p.suggestedCorrespondent, isFalse);
      expect(p.correspondentDisagreement, 'Acme Energy');
      expect(p.documentTypeId, 2);
      expect(p.suggestedDocumentType, isFalse);
      expect(p.documentTypeDisagreement, 'Bill');
    });

    test('a set value that agrees with the AI is neither marked nor reported',
        () {
      final doc = _blankDoc.copyWith(correspondent: 1, documentType: 1);
      final p = _prefill(doc, _bill);

      expect(p.correspondentId, 1);
      expect(p.suggestedCorrespondent, isFalse);
      expect(p.correspondentDisagreement, isNull);
      expect(p.documentTypeId, 1);
      expect(p.suggestedDocumentType, isFalse);
      expect(p.documentTypeDisagreement, isNull);
    });

    test('no "AI suggests" line when the current value is anywhere in the '
        'AI\'s list', () {
      final doc = _blankDoc.copyWith(correspondent: 2, documentType: 2);
      const s = AiSuggestions(
        correspondentIds: [1, 2], // Acme first, but Northwind is listed too
        documentTypeIds: [1, 2],
      );
      final p = _prefill(doc, s);

      expect(p.correspondentId, 2);
      expect(p.correspondentDisagreement, isNull);
      expect(p.documentTypeId, 2);
      expect(p.documentTypeDisagreement, isNull);
    });

    test('tags are additive: current tags stay, in order, never removed', () {
      final doc = _blankDoc.copyWith(tags: [3, 1]);
      final p = _prefill(doc, _bill);

      expect(p.tagIds, [3, 1, 2]);
      expect(p.suggestedTagIds, {2});
    });

    test('a suggested tag the document already has is not re-marked', () {
      final doc = _blankDoc.copyWith(tags: [2]);
      final p = _prefill(doc, _bill);

      expect(p.tagIds, [2]);
      expect(p.suggestedTagIds, isEmpty);
    });

    test('the same title (ignoring surrounding space) is not offered', () {
      final doc = _blankDoc.copyWith(title: ' Electricity Bill - March 2026 ');
      expect(_prefill(doc, _bill).suggestedTitle, isNull);
    });
  });

  group('only IDs that resolve in the local maps are pre-filled', () {
    test('a stale local cache never pre-fills an unknown ID', () {
      final p = _prefill(
        _blankDoc,
        _bill,
        tags: {1: const Tag(id: 1, name: 'Invoice', slug: 'invoice')},
        // ^ no Utilities=2
        correspondents: const {},
        documentTypes: const {},
      );

      expect(p.tagIds, isEmpty);
      expect(p.suggestedTagIds, isEmpty);
      expect(p.correspondentId, isNull);
      expect(p.suggestedCorrespondent, isFalse);
      expect(p.documentTypeId, isNull);
      expect(p.suggestedDocumentType, isFalse);
      // ...they're "not loaded yet", apart from the AI's new names.
      expect(p.unknownTagIds, [2]);
      expect(p.unknownCorrespondentIds, [1]);
      expect(p.unknownDocumentTypeIds, [1]);
      expect(p.newTagNames, ['Electricity', 'Energy']);
      expect(p.newCorrespondentNames, isEmpty);
      expect(p.newDocumentTypeNames, ['Electricity Bill', 'Invoice']);
    });

    test('the first ID that resolves wins; unknown ones are listed', () {
      const s = AiSuggestions(correspondentIds: [99, 2, 1]);
      final p = _prefill(_blankDoc, s);

      expect(p.correspondentId, 2);
      expect(p.suggestedCorrespondent, isTrue);
      expect(p.unknownCorrespondentIds, [99]);
      expect(p.newCorrespondentNames, isEmpty);
    });

    test('an unknown ID never becomes an "AI suggests" line either', () {
      final doc = _blankDoc.copyWith(correspondent: 2);
      final p = _prefill(doc, const AiSuggestions(correspondentIds: [99]));

      expect(p.correspondentId, 2);
      expect(p.correspondentDisagreement, isNull);
      expect(p.unknownCorrespondentIds, [99]);
    });
  });

  group('storage paths are info only', () {
    test('existing paths are named, unknown and new ones are listed', () {
      const s = AiSuggestions(
        storagePathIds: [5, 77],
        suggestedStoragePathNames: ['Finance/Bills'],
      );
      final p = _prefill(_blankDoc, s);

      expect(p.storagePathNames, ['Utilities']);
      expect(p.unknownStoragePathIds, [77]);
      expect(p.newStoragePathNames, ['Finance/Bills']);
      expect(p.hasChanges, isFalse);
      expect(p.hasInfo, isTrue);
    });
  });

  group('hasChanges / hasInfo', () {
    test('both false for an empty response', () {
      final p = _prefill(_blankDoc, const AiSuggestions());
      expect(p.hasChanges, isFalse);
      expect(p.hasInfo, isFalse);
    });

    test('bill fixture vs a document that already has corr 1, type 1, tag 2 '
        'and the AI title: no changes, but info (dates, new names)', () {
      final doc = _blankDoc.copyWith(
        title: 'Electricity Bill - March 2026',
        correspondent: 1,
        documentType: 1,
        tags: [2],
      );
      final p = _prefill(doc, _bill);

      expect(p.hasChanges, isFalse);
      expect(p.suggestedCorrespondent, isFalse);
      expect(p.suggestedDocumentType, isFalse);
      expect(p.suggestedTagIds, isEmpty);
      expect(p.suggestedTitle, isNull);
      expect(p.hasInfo, isTrue);
    });

    test('tax-letter fixture vs a document that already has type 2, tag 4 '
        'and the AI title: no changes, but info', () {
      final doc = _blankDoc.copyWith(
        title: 'Property Tax Assessment Notice 2025',
        documentType: 2,
        tags: [4],
      );
      final p = _prefill(doc, _taxLetter);

      expect(p.hasChanges, isFalse);
      expect(p.hasInfo, isTrue); // City Tax Office, Notice, a date
    });

    test('both fixtures on the blank document: changes', () {
      expect(_prefill(_blankDoc, _bill).hasChanges, isTrue);
      expect(_prefill(_blankDoc, _taxLetter).hasChanges, isTrue);
    });

    test('a title change alone is a change', () {
      const s = AiSuggestions(title: 'Something else');
      final p = _prefill(_blankDoc, s);
      expect(p.hasChanges, isTrue);
      expect(p.hasInfo, isFalse);
    });

    test('a disagreement alone is info, not a change', () {
      final doc = _blankDoc.copyWith(correspondent: 2);
      final p = _prefill(doc, const AiSuggestions(correspondentIds: [1]));
      expect(p.hasChanges, isFalse);
      expect(p.hasInfo, isTrue);
    });

    test('a date alone is info', () {
      final s = AiSuggestions(dates: [DateTime(2026, 3, 31)]);
      final p = _prefill(_blankDoc, s);
      expect(p.hasChanges, isFalse);
      expect(p.hasInfo, isTrue);
    });

    test('an unknown ID alone is info', () {
      final p = _prefill(_blankDoc, const AiSuggestions(tagIds: [99]));
      expect(p.hasChanges, isFalse);
      expect(p.hasInfo, isTrue);
    });
  });

  test('result lists are unmodifiable', () {
    final p = _prefill(_blankDoc, _bill);
    expect(() => p.tagIds.add(9), throwsUnsupportedError);
    expect(() => p.suggestedTagIds.add(9), throwsUnsupportedError);
    expect(() => p.newTagNames.add('x'), throwsUnsupportedError);
    expect(() => p.unknownTagIds.add(9), throwsUnsupportedError);
  });
}
