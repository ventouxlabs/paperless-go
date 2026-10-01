// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Document _$DocumentFromJson(Map<String, dynamic> json) {
  return _Document.fromJson(json);
}

/// @nodoc
mixin _$Document {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int? get correspondent => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_type')
  int? get documentType => throw _privateConstructorUsedError;
  @JsonKey(name: 'storage_path')
  int? get storagePath => throw _privateConstructorUsedError;
  List<int> get tags => throw _privateConstructorUsedError;
  DateTime? get created => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_date')
  String? get createdDate => throw _privateConstructorUsedError;
  DateTime? get modified => throw _privateConstructorUsedError;
  DateTime? get added => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'archive_serial_number')
  int? get archiveSerialNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_file_name')
  String? get originalFileName => throw _privateConstructorUsedError;
  @JsonKey(name: 'archived_file_name')
  String? get archivedFileName => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_fields')
  List<CustomFieldInstance> get customFields =>
      throw _privateConstructorUsedError;
  List<Note> get notes => throw _privateConstructorUsedError;

  /// Serializes this Document to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocumentCopyWith<Document> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocumentCopyWith<$Res> {
  factory $DocumentCopyWith(Document value, $Res Function(Document) then) =
      _$DocumentCopyWithImpl<$Res, Document>;
  @useResult
  $Res call({
    int id,
    String title,
    int? correspondent,
    @JsonKey(name: 'document_type') int? documentType,
    @JsonKey(name: 'storage_path') int? storagePath,
    List<int> tags,
    DateTime? created,
    @JsonKey(name: 'created_date') String? createdDate,
    DateTime? modified,
    DateTime? added,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'archive_serial_number') int? archiveSerialNumber,
    @JsonKey(name: 'original_file_name') String? originalFileName,
    @JsonKey(name: 'archived_file_name') String? archivedFileName,
    String? content,
    @JsonKey(name: 'custom_fields') List<CustomFieldInstance> customFields,
    List<Note> notes,
  });
}

/// @nodoc
class _$DocumentCopyWithImpl<$Res, $Val extends Document>
    implements $DocumentCopyWith<$Res> {
  _$DocumentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? correspondent = freezed,
    Object? documentType = freezed,
    Object? storagePath = freezed,
    Object? tags = null,
    Object? created = freezed,
    Object? createdDate = freezed,
    Object? modified = freezed,
    Object? added = freezed,
    Object? deletedAt = freezed,
    Object? archiveSerialNumber = freezed,
    Object? originalFileName = freezed,
    Object? archivedFileName = freezed,
    Object? content = freezed,
    Object? customFields = null,
    Object? notes = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            correspondent: freezed == correspondent
                ? _value.correspondent
                : correspondent // ignore: cast_nullable_to_non_nullable
                      as int?,
            documentType: freezed == documentType
                ? _value.documentType
                : documentType // ignore: cast_nullable_to_non_nullable
                      as int?,
            storagePath: freezed == storagePath
                ? _value.storagePath
                : storagePath // ignore: cast_nullable_to_non_nullable
                      as int?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<int>,
            created: freezed == created
                ? _value.created
                : created // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdDate: freezed == createdDate
                ? _value.createdDate
                : createdDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            modified: freezed == modified
                ? _value.modified
                : modified // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            added: freezed == added
                ? _value.added
                : added // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            deletedAt: freezed == deletedAt
                ? _value.deletedAt
                : deletedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            archiveSerialNumber: freezed == archiveSerialNumber
                ? _value.archiveSerialNumber
                : archiveSerialNumber // ignore: cast_nullable_to_non_nullable
                      as int?,
            originalFileName: freezed == originalFileName
                ? _value.originalFileName
                : originalFileName // ignore: cast_nullable_to_non_nullable
                      as String?,
            archivedFileName: freezed == archivedFileName
                ? _value.archivedFileName
                : archivedFileName // ignore: cast_nullable_to_non_nullable
                      as String?,
            content: freezed == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String?,
            customFields: null == customFields
                ? _value.customFields
                : customFields // ignore: cast_nullable_to_non_nullable
                      as List<CustomFieldInstance>,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as List<Note>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DocumentImplCopyWith<$Res>
    implements $DocumentCopyWith<$Res> {
  factory _$$DocumentImplCopyWith(
    _$DocumentImpl value,
    $Res Function(_$DocumentImpl) then,
  ) = __$$DocumentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String title,
    int? correspondent,
    @JsonKey(name: 'document_type') int? documentType,
    @JsonKey(name: 'storage_path') int? storagePath,
    List<int> tags,
    DateTime? created,
    @JsonKey(name: 'created_date') String? createdDate,
    DateTime? modified,
    DateTime? added,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'archive_serial_number') int? archiveSerialNumber,
    @JsonKey(name: 'original_file_name') String? originalFileName,
    @JsonKey(name: 'archived_file_name') String? archivedFileName,
    String? content,
    @JsonKey(name: 'custom_fields') List<CustomFieldInstance> customFields,
    List<Note> notes,
  });
}

/// @nodoc
class __$$DocumentImplCopyWithImpl<$Res>
    extends _$DocumentCopyWithImpl<$Res, _$DocumentImpl>
    implements _$$DocumentImplCopyWith<$Res> {
  __$$DocumentImplCopyWithImpl(
    _$DocumentImpl _value,
    $Res Function(_$DocumentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? correspondent = freezed,
    Object? documentType = freezed,
    Object? storagePath = freezed,
    Object? tags = null,
    Object? created = freezed,
    Object? createdDate = freezed,
    Object? modified = freezed,
    Object? added = freezed,
    Object? deletedAt = freezed,
    Object? archiveSerialNumber = freezed,
    Object? originalFileName = freezed,
    Object? archivedFileName = freezed,
    Object? content = freezed,
    Object? customFields = null,
    Object? notes = null,
  }) {
    return _then(
      _$DocumentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        correspondent: freezed == correspondent
            ? _value.correspondent
            : correspondent // ignore: cast_nullable_to_non_nullable
                  as int?,
        documentType: freezed == documentType
            ? _value.documentType
            : documentType // ignore: cast_nullable_to_non_nullable
                  as int?,
        storagePath: freezed == storagePath
            ? _value.storagePath
            : storagePath // ignore: cast_nullable_to_non_nullable
                  as int?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<int>,
        created: freezed == created
            ? _value.created
            : created // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdDate: freezed == createdDate
            ? _value.createdDate
            : createdDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        modified: freezed == modified
            ? _value.modified
            : modified // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        added: freezed == added
            ? _value.added
            : added // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        deletedAt: freezed == deletedAt
            ? _value.deletedAt
            : deletedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        archiveSerialNumber: freezed == archiveSerialNumber
            ? _value.archiveSerialNumber
            : archiveSerialNumber // ignore: cast_nullable_to_non_nullable
                  as int?,
        originalFileName: freezed == originalFileName
            ? _value.originalFileName
            : originalFileName // ignore: cast_nullable_to_non_nullable
                  as String?,
        archivedFileName: freezed == archivedFileName
            ? _value.archivedFileName
            : archivedFileName // ignore: cast_nullable_to_non_nullable
                  as String?,
        content: freezed == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String?,
        customFields: null == customFields
            ? _value._customFields
            : customFields // ignore: cast_nullable_to_non_nullable
                  as List<CustomFieldInstance>,
        notes: null == notes
            ? _value._notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as List<Note>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DocumentImpl implements _Document {
  const _$DocumentImpl({
    required this.id,
    required this.title,
    this.correspondent,
    @JsonKey(name: 'document_type') this.documentType,
    @JsonKey(name: 'storage_path') this.storagePath,
    final List<int> tags = const [],
    this.created,
    @JsonKey(name: 'created_date') this.createdDate,
    this.modified,
    this.added,
    @JsonKey(name: 'deleted_at') this.deletedAt,
    @JsonKey(name: 'archive_serial_number') this.archiveSerialNumber,
    @JsonKey(name: 'original_file_name') this.originalFileName,
    @JsonKey(name: 'archived_file_name') this.archivedFileName,
    this.content,
    @JsonKey(name: 'custom_fields')
    final List<CustomFieldInstance> customFields = const [],
    final List<Note> notes = const [],
  }) : _tags = tags,
       _customFields = customFields,
       _notes = notes;

  factory _$DocumentImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocumentImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final int? correspondent;
  @override
  @JsonKey(name: 'document_type')
  final int? documentType;
  @override
  @JsonKey(name: 'storage_path')
  final int? storagePath;
  final List<int> _tags;
  @override
  @JsonKey()
  List<int> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final DateTime? created;
  @override
  @JsonKey(name: 'created_date')
  final String? createdDate;
  @override
  final DateTime? modified;
  @override
  final DateTime? added;
  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'archive_serial_number')
  final int? archiveSerialNumber;
  @override
  @JsonKey(name: 'original_file_name')
  final String? originalFileName;
  @override
  @JsonKey(name: 'archived_file_name')
  final String? archivedFileName;
  @override
  final String? content;
  final List<CustomFieldInstance> _customFields;
  @override
  @JsonKey(name: 'custom_fields')
  List<CustomFieldInstance> get customFields {
    if (_customFields is EqualUnmodifiableListView) return _customFields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customFields);
  }

  final List<Note> _notes;
  @override
  @JsonKey()
  List<Note> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  @override
  String toString() {
    return 'Document(id: $id, title: $title, correspondent: $correspondent, documentType: $documentType, storagePath: $storagePath, tags: $tags, created: $created, createdDate: $createdDate, modified: $modified, added: $added, deletedAt: $deletedAt, archiveSerialNumber: $archiveSerialNumber, originalFileName: $originalFileName, archivedFileName: $archivedFileName, content: $content, customFields: $customFields, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocumentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.correspondent, correspondent) ||
                other.correspondent == correspondent) &&
            (identical(other.documentType, documentType) ||
                other.documentType == documentType) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.createdDate, createdDate) ||
                other.createdDate == createdDate) &&
            (identical(other.modified, modified) ||
                other.modified == modified) &&
            (identical(other.added, added) || other.added == added) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.archiveSerialNumber, archiveSerialNumber) ||
                other.archiveSerialNumber == archiveSerialNumber) &&
            (identical(other.originalFileName, originalFileName) ||
                other.originalFileName == originalFileName) &&
            (identical(other.archivedFileName, archivedFileName) ||
                other.archivedFileName == archivedFileName) &&
            (identical(other.content, content) || other.content == content) &&
            const DeepCollectionEquality().equals(
              other._customFields,
              _customFields,
            ) &&
            const DeepCollectionEquality().equals(other._notes, _notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    correspondent,
    documentType,
    storagePath,
    const DeepCollectionEquality().hash(_tags),
    created,
    createdDate,
    modified,
    added,
    deletedAt,
    archiveSerialNumber,
    originalFileName,
    archivedFileName,
    content,
    const DeepCollectionEquality().hash(_customFields),
    const DeepCollectionEquality().hash(_notes),
  );

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocumentImplCopyWith<_$DocumentImpl> get copyWith =>
      __$$DocumentImplCopyWithImpl<_$DocumentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DocumentImplToJson(this);
  }
}

abstract class _Document implements Document {
  const factory _Document({
    required final int id,
    required final String title,
    final int? correspondent,
    @JsonKey(name: 'document_type') final int? documentType,
    @JsonKey(name: 'storage_path') final int? storagePath,
    final List<int> tags,
    final DateTime? created,
    @JsonKey(name: 'created_date') final String? createdDate,
    final DateTime? modified,
    final DateTime? added,
    @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
    @JsonKey(name: 'archive_serial_number') final int? archiveSerialNumber,
    @JsonKey(name: 'original_file_name') final String? originalFileName,
    @JsonKey(name: 'archived_file_name') final String? archivedFileName,
    final String? content,
    @JsonKey(name: 'custom_fields')
    final List<CustomFieldInstance> customFields,
    final List<Note> notes,
  }) = _$DocumentImpl;

  factory _Document.fromJson(Map<String, dynamic> json) =
      _$DocumentImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  int? get correspondent;
  @override
  @JsonKey(name: 'document_type')
  int? get documentType;
  @override
  @JsonKey(name: 'storage_path')
  int? get storagePath;
  @override
  List<int> get tags;
  @override
  DateTime? get created;
  @override
  @JsonKey(name: 'created_date')
  String? get createdDate;
  @override
  DateTime? get modified;
  @override
  DateTime? get added;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @override
  @JsonKey(name: 'archive_serial_number')
  int? get archiveSerialNumber;
  @override
  @JsonKey(name: 'original_file_name')
  String? get originalFileName;
  @override
  @JsonKey(name: 'archived_file_name')
  String? get archivedFileName;
  @override
  String? get content;
  @override
  @JsonKey(name: 'custom_fields')
  List<CustomFieldInstance> get customFields;
  @override
  List<Note> get notes;

  /// Create a copy of Document
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocumentImplCopyWith<_$DocumentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
