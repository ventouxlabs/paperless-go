import 'package:flutter/foundation.dart' show setEquals;

import '../../core/models/document.dart';
import '../../shared/widgets/metadata_sheet.dart';
import 'ai_edit_trail_notifier.dart';

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

/// The AI-trail entries for a native-AI save: one per field that differs from
/// [base] (mirrors [buildMetadataPatch]), with ids resolved to names.
EditMap buildAiEdits(
  Document base,
  MetadataSheetResult result, {
  String? title,
  required AiEditNames names,
}) {
  final edits = <String, ({String? oldValue, String? newValue})>{};
  if (title != null && title != base.title) {
    edits['title'] = (oldValue: base.title, newValue: title);
  }
  if (result.correspondentId != base.correspondent) {
    edits['correspondent'] = (
      oldValue: _single(names.correspondents, base.correspondent),
      newValue: _single(names.correspondents, result.correspondentId),
    );
  }
  if (result.documentTypeId != base.documentType) {
    edits['document_type'] = (
      oldValue: _single(names.documentTypes, base.documentType),
      newValue: _single(names.documentTypes, result.documentTypeId),
    );
  }
  final created = result.created;
  if (created != null) {
    final newDate = created.toIso8601String().split('T').first;
    final oldDate = base.created?.toIso8601String().split('T').first;
    if (newDate != oldDate) {
      edits['created'] = (oldValue: oldDate, newValue: newDate);
    }
  }
  if (!setEquals(result.tagIds.toSet(), base.tags.toSet())) {
    edits['tags'] = (
      oldValue: _tags(names.tags, base.tags),
      newValue: _tags(names.tags, result.tagIds),
    );
  }
  return edits;
}
