// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DocumentImpl _$$DocumentImplFromJson(
  Map<String, dynamic> json,
) => _$DocumentImpl(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  correspondent: (json['correspondent'] as num?)?.toInt(),
  documentType: (json['document_type'] as num?)?.toInt(),
  storagePath: (json['storage_path'] as num?)?.toInt(),
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [],
  created: json['created'] == null
      ? null
      : DateTime.parse(json['created'] as String),
  createdDate: json['created_date'] as String?,
  modified: json['modified'] == null
      ? null
      : DateTime.parse(json['modified'] as String),
  added: json['added'] == null ? null : DateTime.parse(json['added'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  archiveSerialNumber: (json['archive_serial_number'] as num?)?.toInt(),
  originalFileName: json['original_file_name'] as String?,
  archivedFileName: json['archived_file_name'] as String?,
  content: json['content'] as String?,
  customFields:
      (json['custom_fields'] as List<dynamic>?)
          ?.map((e) => CustomFieldInstance.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  notes:
      (json['notes'] as List<dynamic>?)
          ?.map((e) => Note.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$DocumentImplToJson(_$DocumentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'correspondent': instance.correspondent,
      'document_type': instance.documentType,
      'storage_path': instance.storagePath,
      'tags': instance.tags,
      'created': instance.created?.toIso8601String(),
      'created_date': instance.createdDate,
      'modified': instance.modified?.toIso8601String(),
      'added': instance.added?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'archive_serial_number': instance.archiveSerialNumber,
      'original_file_name': instance.originalFileName,
      'archived_file_name': instance.archivedFileName,
      'content': instance.content,
      'custom_fields': instance.customFields.map((e) => e.toJson()).toList(),
      'notes': instance.notes.map((e) => e.toJson()).toList(),
    };
