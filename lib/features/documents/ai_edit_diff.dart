import '../../core/models/document.dart';
import '../../shared/widgets/metadata_sheet.dart';
import 'ai_edit_trail_notifier.dart';
import 'ai_suggestions/ai_suggestions_prefill.dart';

/// Id-to-name lookups used to write readable AI-trail values.
class AiEditNames {
  const AiEditNames({
    this.tags = const {},
    this.correspondents = const {},
    this.documentTypes = const {},
  });

  final Map<int, String> tags;
  final Map<int, String> correspondents;
  final Map<int, String> documentTypes;
}

String _name(Map<int, String> map, int id) => map[id] ?? '#$id';

String? _single(Map<int, String> map, int? id) =>
    id == null ? null : _name(map, id);

String? _tags(Map<int, String> map, List<int> ids) =>
    ids.isEmpty ? null : ids.map((i) => _name(map, i)).join(', ');

String _day(DateTime d) => d.toIso8601String().split('T').first;

/// The AI-trail entries for a native-AI save: only fields the AI actually
/// suggested ([prefill]) and the user kept, with ids resolved to names.
/// A field the user overrode or changed by hand gets no row.
EditMap buildAiEdits(
  Document base,
  MetadataSheetResult result, {
  String? title,
  required AiSuggestionsPrefill prefill,
  required AiEditNames names,
}) {
  final edits = <String, ({String? oldValue, String? newValue})>{};
  // [title] is only non-null when "Use this title" was ticked.
  if (title != null && title != base.title) {
    edits['title'] = (oldValue: base.title, newValue: title);
  }
  if (prefill.suggestedCorrespondent &&
      result.correspondentId == prefill.correspondentId &&
      result.correspondentId != base.correspondent) {
    edits['correspondent'] = (
      oldValue: _single(names.correspondents, base.correspondent),
      newValue: _single(names.correspondents, result.correspondentId),
    );
  }
  if (prefill.suggestedDocumentType &&
      result.documentTypeId == prefill.documentTypeId &&
      result.documentTypeId != base.documentType) {
    edits['document_type'] = (
      oldValue: _single(names.documentTypes, base.documentType),
      newValue: _single(names.documentTypes, result.documentTypeId),
    );
  }
  final created = result.created;
  if (created != null &&
      created != base.created &&
      prefill.dates.any((d) => _day(d) == _day(created))) {
    edits['created'] = (
      oldValue: base.created == null ? null : _day(base.created!),
      newValue: _day(created),
    );
  }
  final keptTags = [
    for (final id in result.tagIds)
      if (prefill.suggestedTagIds.contains(id) && !base.tags.contains(id)) id,
  ];
  if (keptTags.isNotEmpty) {
    edits['tags'] = (
      oldValue: _tags(names.tags, base.tags),
      newValue: _tags(names.tags, [...base.tags, ...keptTags]),
    );
  }
  return edits;
}
