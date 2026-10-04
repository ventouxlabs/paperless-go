import 'package:freezed_annotation/freezed_annotation.dart';
import 'custom_field.dart';
import 'note.dart';

part 'document.freezed.dart';
part 'document.g.dart';

@freezed
class Document with _$Document {
  const factory Document({
    required int id,
    required String title,
    int? correspondent,
    @JsonKey(name: 'document_type') int? documentType,
    @JsonKey(name: 'storage_path') int? storagePath,
    @Default([]) List<int> tags,
    DateTime? created,
    @JsonKey(name: 'created_date') String? createdDate,
    DateTime? modified,
    DateTime? added,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'archive_serial_number') int? archiveSerialNumber,
    @JsonKey(name: 'original_file_name') String? originalFileName,
    @JsonKey(name: 'archived_file_name') String? archivedFileName,
    String? content,
    @JsonKey(name: 'custom_fields') @Default([]) List<CustomFieldInstance> customFields,
    @Default([]) List<Note> notes,
    // Whether the signed-in user may change THIS document (object-level
    // permission). Null when absent: `?full_perms=true` responses and older
    // servers omit it, and callers must treat null as "unknown", not "yes".
    @JsonKey(name: 'user_can_change') bool? userCanChange,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);
}
