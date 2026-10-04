import 'package:flutter/foundation.dart';

import '../../../core/models/ai_suggestions.dart';
import '../../../core/models/correspondent.dart';
import '../../../core/models/document.dart';
import '../../../core/models/document_type.dart';
import '../../../core/models/storage_path.dart';
import '../../../core/models/tag.dart';

/// What the metadata sheet opens with after "Suggest with AI", plus the
/// information-only lines shown above its fields.
///
/// Built by [buildAiSuggestionsPrefill]. There is deliberately no `created`
/// here: the AI's dates can be due dates, so they're only shown, never
/// pre-filled.
@immutable
class AiSuggestionsPrefill {
  const AiSuggestionsPrefill({
    required this.correspondentId,
    required this.documentTypeId,
    required this.tagIds,
    required this.suggestedCorrespondent,
    required this.suggestedDocumentType,
    required this.suggestedTagIds,
    required this.suggestedTitle,
    required this.dates,
    required this.correspondentDisagreement,
    required this.documentTypeDisagreement,
    required this.storagePathNames,
    required this.newTagNames,
    required this.newCorrespondentNames,
    required this.newDocumentTypeNames,
    required this.newStoragePathNames,
    required this.unknownTagIds,
    required this.unknownCorrespondentIds,
    required this.unknownDocumentTypeIds,
    required this.unknownStoragePathIds,
  });

  /// Initial sheet values: the document's own, or the AI's pick when unset.
  final int? correspondentId;
  final int? documentTypeId;

  /// The document's tags, then the AI's existing tags it doesn't have yet.
  final List<int> tagIds;

  /// Sheet markers: true / non-empty only for values the AI filled in.
  final bool suggestedCorrespondent;
  final bool suggestedDocumentType;
  final Set<int> suggestedTagIds;

  /// The AI's title, or null when it matches the current one.
  final String? suggestedTitle;

  /// Dates found in the document. Info only.
  final List<DateTime> dates;

  /// Name of the AI's correspondent / type when the document already has a
  /// different one (kept as is; shown as "AI suggests …").
  final String? correspondentDisagreement;
  final String? documentTypeDisagreement;

  /// Existing storage paths the AI picked. Info only: the sheet has no
  /// storage-path field.
  final List<String> storagePathNames;

  /// "Not in your library", by kind: names the AI proposed that match
  /// nothing on the server.
  final List<String> newTagNames;
  final List<String> newCorrespondentNames;
  final List<String> newDocumentTypeNames;
  final List<String> newStoragePathNames;

  /// Suggested IDs that exist on the server but not in this app's lists
  /// (even after re-loading them): "not loaded yet". Never pre-filled.
  final List<int> unknownTagIds;
  final List<int> unknownCorrespondentIds;
  final List<int> unknownDocumentTypeIds;
  final List<int> unknownStoragePathIds;

  bool get hasNewNames =>
      newTagNames.isNotEmpty ||
      newCorrespondentNames.isNotEmpty ||
      newDocumentTypeNames.isNotEmpty ||
      newStoragePathNames.isNotEmpty;

  bool get hasUnknownIds =>
      unknownTagIds.isNotEmpty ||
      unknownCorrespondentIds.isNotEmpty ||
      unknownDocumentTypeIds.isNotEmpty ||
      unknownStoragePathIds.isNotEmpty;

  /// Something in the sheet would differ from the document: a pre-filled
  /// correspondent / type, an added tag, or a different title.
  bool get hasChanges =>
      suggestedCorrespondent ||
      suggestedDocumentType ||
      suggestedTagIds.isNotEmpty ||
      suggestedTitle != null;

  /// Something worth reading even when nothing would change.
  bool get hasInfo =>
      dates.isNotEmpty ||
      correspondentDisagreement != null ||
      documentTypeDisagreement != null ||
      storagePathNames.isNotEmpty ||
      hasNewNames ||
      hasUnknownIds;
}

/// Applies the Phase 1 rules to [suggestions] for [document]:
/// - correspondent / type: the first suggested ID that resolves locally, and
///   only when the document has none ("pre-fill only what's empty");
/// - tags: additive, never removing one;
/// - only IDs present in the local maps are ever pre-filled, so a stale cache
///   can't PATCH an unknown ID; the rest are reported as not loaded yet.
AiSuggestionsPrefill buildAiSuggestionsPrefill({
  required Document document,
  required AiSuggestions suggestions,
  required Map<int, Tag> tags,
  required Map<int, Correspondent> correspondents,
  required Map<int, DocumentType> documentTypes,
  required Map<int, StoragePath> storagePaths,
}) {
  final correspondent = _single(
    current: document.correspondent,
    suggestedIds: suggestions.correspondentIds,
    names: {for (final c in correspondents.values) c.id: c.name},
  );
  final documentType = _single(
    current: document.documentType,
    suggestedIds: suggestions.documentTypeIds,
    names: {for (final t in documentTypes.values) t.id: t.name},
  );

  final addedTagIds = <int>{
    for (final id in suggestions.tagIds)
      if (tags.containsKey(id) && !document.tags.contains(id)) id,
  };

  final title = suggestions.title;
  final titleChanged = title != null && title.trim() != document.title.trim();

  return AiSuggestionsPrefill(
    correspondentId: correspondent.value,
    documentTypeId: documentType.value,
    tagIds: List.unmodifiable([...document.tags, ...addedTagIds]),
    suggestedCorrespondent: correspondent.prefilled,
    suggestedDocumentType: documentType.prefilled,
    suggestedTagIds: Set.unmodifiable(addedTagIds),
    suggestedTitle: titleChanged ? title : null,
    dates: List.unmodifiable(suggestions.dates),
    correspondentDisagreement: correspondent.disagreement,
    documentTypeDisagreement: documentType.disagreement,
    storagePathNames: List.unmodifiable([
      for (final id in suggestions.storagePathIds)
        if (storagePaths[id] case final path?) path.name,
    ]),
    newTagNames: suggestions.suggestedTagNames,
    newCorrespondentNames: suggestions.suggestedCorrespondentNames,
    newDocumentTypeNames: suggestions.suggestedDocumentTypeNames,
    newStoragePathNames: suggestions.suggestedStoragePathNames,
    unknownTagIds: _unknown(suggestions.tagIds, tags),
    unknownCorrespondentIds:
        _unknown(suggestions.correspondentIds, correspondents),
    unknownDocumentTypeIds:
        _unknown(suggestions.documentTypeIds, documentTypes),
    unknownStoragePathIds: _unknown(suggestions.storagePathIds, storagePaths),
  );
}

/// One single-valued field (correspondent or document type).
({int? value, bool prefilled, String? disagreement}) _single({
  required int? current,
  required List<int> suggestedIds,
  required Map<int, String> names,
}) {
  final pick = suggestedIds.where(names.containsKey).firstOrNull;
  if (pick == null) {
    return (value: current, prefilled: false, disagreement: null);
  }
  if (current == null) {
    return (value: pick, prefilled: true, disagreement: null);
  }
  // The AI listing the current value anywhere counts as agreeing with it.
  return (
    value: current,
    prefilled: false,
    disagreement: suggestedIds.contains(current) ? null : names[pick],
  );
}

List<int> _unknown(List<int> suggestedIds, Map<int, Object> known) =>
    List.unmodifiable(suggestedIds.where((id) => !known.containsKey(id)));
