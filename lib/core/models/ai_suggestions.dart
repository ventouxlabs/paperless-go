import 'package:flutter/foundation.dart';

/// Paperless-ngx 3.x native AI suggestions for one document, from
/// `GET api/documents/<id>/ai_suggestions/`.
///
/// The `*Ids` lists are objects that already exist on the server (matched by
/// name, permission-filtered). The `suggested*Names` lists are names the model
/// proposed that matched nothing; the server never creates them. Correspondent,
/// document type and storage path arrive as lists, best match first.
@immutable
class AiSuggestions {
  const AiSuggestions({
    this.title,
    this.tagIds = const [],
    this.correspondentIds = const [],
    this.documentTypeIds = const [],
    this.storagePathIds = const [],
    this.suggestedTagNames = const [],
    this.suggestedCorrespondentNames = const [],
    this.suggestedDocumentTypeNames = const [],
    this.suggestedStoragePathNames = const [],
    this.dates = const [],
  });

  /// Parses the response. Never throws on an odd shape: a missing key or a
  /// value of the wrong type is treated as "no suggestion", item by item.
  /// Text is clamped (title 128 characters, the server's own cap; at most
  /// [maxItems] names of [maxNameLength] characters) so an odd or hostile
  /// reply can't flood the sheet.
  factory AiSuggestions.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'];
    final title = rawTitle is String ? _clamp(rawTitle.trim(), 128) : '';
    return AiSuggestions(
      title: title.isEmpty ? null : title,
      tagIds: _ids(json['tags']),
      correspondentIds: _ids(json['correspondents']),
      documentTypeIds: _ids(json['document_types']),
      storagePathIds: _ids(json['storage_paths']),
      suggestedTagNames: _names(json['suggested_tags']),
      suggestedCorrespondentNames: _names(json['suggested_correspondents']),
      suggestedDocumentTypeNames: _names(json['suggested_document_types']),
      suggestedStoragePathNames: _names(json['suggested_storage_paths']),
      dates: List.unmodifiable(
        _strings(json['dates']).map(_parseDate).whereType<DateTime>(),
      ),
    );
  }

  final String? title;
  final List<int> tagIds;
  final List<int> correspondentIds;
  final List<int> documentTypeIds;
  final List<int> storagePathIds;
  final List<String> suggestedTagNames;
  final List<String> suggestedCorrespondentNames;
  final List<String> suggestedDocumentTypeNames;
  final List<String> suggestedStoragePathNames;

  /// Dates the model found in the document (statement date, due date, …).
  /// Raw model output on the server; only real `YYYY-MM-DD` dates survive.
  final List<DateTime> dates;

  static List<int> _ids(Object? raw) => raw is List
      ? List<int>.unmodifiable(raw.whereType<int>())
      : const <int>[];

  static const maxItems = 10;
  static const maxNameLength = 100;

  /// Trimmed, non-blank strings; at most [maxItems].
  static Iterable<String> _strings(Object? raw) => raw is List
      ? raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(maxItems)
      : const <String>[];

  static List<String> _names(Object? raw) => List<String>.unmodifiable(
      _strings(raw).map((s) => _clamp(s, maxNameLength)));

  /// At most [max] characters (Unicode code points, so a character made of
  /// two UTF-16 units is never cut in half).
  static String _clamp(String s, int max) =>
      s.runes.length <= max ? s : String.fromCharCodes(s.runes.take(max));

  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// `YYYY-MM-DD` only. [DateTime.tryParse] alone would roll `2026-02-30`
  /// over to March 2 and accept datetimes, so the components are checked.
  static DateTime? _parseDate(String raw) {
    if (!_isoDate.hasMatch(raw)) return null;
    final [year, month, day] = raw.split('-').map(int.parse).toList();
    final date = DateTime(year, month, day);
    final isRealDate =
        date.year == year && date.month == month && date.day == day;
    return isRealDate ? date : null;
  }
}
