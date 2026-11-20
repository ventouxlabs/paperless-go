import 'package:flutter/foundation.dart';

import '../../core/models/document.dart';
import '../../shared/widgets/metadata_sheet.dart';
import 'ai_edit_diff.dart';
import 'ai_edit_trail_notifier.dart';
import 'ai_suggestions/ai_suggestions_prefill.dart';
import 'metadata_patch.dart';

/// What a native-AI save needs to write its trail rows.
class AiSaveContext {
  const AiSaveContext({
    required this.source,
    required this.prefill,
    required this.names,
  });

  final String source;
  final AiSuggestionsPrefill prefill;
  final AiEditNames names;
}

/// Persists only the fields the sheet changed, in one PATCH. When [ai] is
/// given and the PATCH succeeds, records the AI-suggested fields in the trail
/// (best effort: a trail failure is only logged). A PATCH failure goes to
/// [onError] and writes no rows.
Future<void> saveMetadata({
  required Document doc,
  required MetadataSheetResult result,
  String? title,
  AiSaveContext? ai,
  required Future<void> Function(Map<String, dynamic> patch) patchDocument,
  required Future<void> Function(EditMap edits, String source) recordEdits,
  required void Function(Object error) onError,
}) async {
  final patch = buildMetadataPatch(doc, result, title: title);
  if (patch.isEmpty) return;
  try {
    await patchDocument(patch);
  } catch (e) {
    onError(e);
    return;
  }
  if (ai == null) return;
  try {
    final edits = buildAiEdits(
      doc,
      result,
      title: title,
      prefill: ai.prefill,
      names: ai.names,
    );
    if (edits.isEmpty) return;
    await recordEdits(edits, ai.source);
  } catch (e) {
    debugPrint('Failed to record AI edit trail: $e');
  }
}
