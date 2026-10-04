import 'package:flutter/foundation.dart' show setEquals;

import '../../core/models/document.dart';
import '../../shared/widgets/metadata_sheet.dart';

/// The PATCH body for a metadata-sheet save: only the fields that differ from
/// [base], the document the sheet was opened with.
///
/// Diffing against [base] (not a copy fetched at save time) is what keeps a
/// concurrent edit to a field the user didn't touch from being overwritten.
/// [title] is the AI's title when the user ticked "Use this title"; it is
/// checked first, so a title-only change still produces a PATCH.
Map<String, dynamic> buildMetadataPatch(
  Document base,
  MetadataSheetResult result, {
  String? title,
}) {
  final patch = <String, dynamic>{};
  if (title != null && title != base.title) patch['title'] = title;
  if (result.correspondentId != base.correspondent) {
    patch['correspondent'] = result.correspondentId;
  }
  if (result.documentTypeId != base.documentType) {
    patch['document_type'] = result.documentTypeId;
  }
  // A cleared date means "leave as is" here — Paperless requires created.
  final created = result.created;
  if (created != null) {
    final newDate = created.toIso8601String().split('T').first;
    final oldDate = base.created?.toIso8601String().split('T').first;
    if (newDate != oldDate) patch['created'] = newDate;
  }
  if (!setEquals(result.tagIds.toSet(), base.tags.toSet())) {
    patch['tags'] = result.tagIds;
  }
  return patch;
}
