// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedDocumentsTable extends CachedDocuments
    with TableInfo<$CachedDocumentsTable, CachedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedDocumentsTable createAlias(String alias) {
    return $CachedDocumentsTable(attachedDatabase, alias);
  }
}

class CachedDocument extends DataClass implements Insertable<CachedDocument> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedDocument({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocument(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedDocument copyWith({int? id, String? jsonData, DateTime? cachedAt}) =>
      CachedDocument(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedDocument copyWithCompanion(CachedDocumentsCompanion data) {
    return CachedDocument(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocument(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocument &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedDocumentsCompanion extends UpdateCompanion<CachedDocument> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedDocumentsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedDocumentsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedDocument> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedDocumentsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedDocumentsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedTagsTable extends CachedTags
    with TableInfo<$CachedTagsTable, CachedTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedTagsTable createAlias(String alias) {
    return $CachedTagsTable(attachedDatabase, alias);
  }
}

class CachedTag extends DataClass implements Insertable<CachedTag> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedTag({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedTagsCompanion toCompanion(bool nullToAbsent) {
    return CachedTagsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTag(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedTag copyWith({int? id, String? jsonData, DateTime? cachedAt}) =>
      CachedTag(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedTag copyWithCompanion(CachedTagsCompanion data) {
    return CachedTag(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTag(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTag &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedTagsCompanion extends UpdateCompanion<CachedTag> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedTagsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedTagsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedTag> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedTagsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedTagsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTagsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedCorrespondentsTable extends CachedCorrespondents
    with TableInfo<$CachedCorrespondentsTable, CachedCorrespondent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCorrespondentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_correspondents';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCorrespondent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCorrespondent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCorrespondent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCorrespondentsTable createAlias(String alias) {
    return $CachedCorrespondentsTable(attachedDatabase, alias);
  }
}

class CachedCorrespondent extends DataClass
    implements Insertable<CachedCorrespondent> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedCorrespondent({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCorrespondentsCompanion toCompanion(bool nullToAbsent) {
    return CachedCorrespondentsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCorrespondent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCorrespondent(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCorrespondent copyWith({
    int? id,
    String? jsonData,
    DateTime? cachedAt,
  }) => CachedCorrespondent(
    id: id ?? this.id,
    jsonData: jsonData ?? this.jsonData,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCorrespondent copyWithCompanion(CachedCorrespondentsCompanion data) {
    return CachedCorrespondent(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCorrespondent(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCorrespondent &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedCorrespondentsCompanion
    extends UpdateCompanion<CachedCorrespondent> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedCorrespondentsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedCorrespondentsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCorrespondent> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedCorrespondentsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedCorrespondentsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCorrespondentsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedDocumentTypesTable extends CachedDocumentTypes
    with TableInfo<$CachedDocumentTypesTable, CachedDocumentType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedDocumentTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_document_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedDocumentType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedDocumentType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedDocumentType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedDocumentTypesTable createAlias(String alias) {
    return $CachedDocumentTypesTable(attachedDatabase, alias);
  }
}

class CachedDocumentType extends DataClass
    implements Insertable<CachedDocumentType> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedDocumentType({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedDocumentTypesCompanion toCompanion(bool nullToAbsent) {
    return CachedDocumentTypesCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedDocumentType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedDocumentType(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedDocumentType copyWith({
    int? id,
    String? jsonData,
    DateTime? cachedAt,
  }) => CachedDocumentType(
    id: id ?? this.id,
    jsonData: jsonData ?? this.jsonData,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedDocumentType copyWithCompanion(CachedDocumentTypesCompanion data) {
    return CachedDocumentType(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentType(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedDocumentType &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedDocumentTypesCompanion extends UpdateCompanion<CachedDocumentType> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedDocumentTypesCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedDocumentTypesCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedDocumentType> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedDocumentTypesCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedDocumentTypesCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedDocumentTypesCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedStoragePathsTable extends CachedStoragePaths
    with TableInfo<$CachedStoragePathsTable, CachedStoragePath> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStoragePathsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_storage_paths';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStoragePath> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedStoragePath map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStoragePath(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedStoragePathsTable createAlias(String alias) {
    return $CachedStoragePathsTable(attachedDatabase, alias);
  }
}

class CachedStoragePath extends DataClass
    implements Insertable<CachedStoragePath> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedStoragePath({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedStoragePathsCompanion toCompanion(bool nullToAbsent) {
    return CachedStoragePathsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedStoragePath.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStoragePath(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedStoragePath copyWith({int? id, String? jsonData, DateTime? cachedAt}) =>
      CachedStoragePath(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedStoragePath copyWithCompanion(CachedStoragePathsCompanion data) {
    return CachedStoragePath(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStoragePath(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStoragePath &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedStoragePathsCompanion extends UpdateCompanion<CachedStoragePath> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedStoragePathsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedStoragePathsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedStoragePath> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedStoragePathsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedStoragePathsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStoragePathsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedSavedViewsTable extends CachedSavedViews
    with TableInfo<$CachedSavedViewsTable, CachedSavedView> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSavedViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_saved_views';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSavedView> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSavedView map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSavedView(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedSavedViewsTable createAlias(String alias) {
    return $CachedSavedViewsTable(attachedDatabase, alias);
  }
}

class CachedSavedView extends DataClass implements Insertable<CachedSavedView> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedSavedView({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedSavedViewsCompanion toCompanion(bool nullToAbsent) {
    return CachedSavedViewsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedSavedView.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSavedView(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedSavedView copyWith({int? id, String? jsonData, DateTime? cachedAt}) =>
      CachedSavedView(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedSavedView copyWithCompanion(CachedSavedViewsCompanion data) {
    return CachedSavedView(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSavedView(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSavedView &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedSavedViewsCompanion extends UpdateCompanion<CachedSavedView> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedSavedViewsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedSavedViewsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedSavedView> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedSavedViewsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedSavedViewsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSavedViewsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedCustomFieldsTable extends CachedCustomFields
    with TableInfo<$CachedCustomFieldsTable, CachedCustomField> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCustomFieldsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_custom_fields';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCustomField> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCustomField map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCustomField(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCustomFieldsTable createAlias(String alias) {
    return $CachedCustomFieldsTable(attachedDatabase, alias);
  }
}

class CachedCustomField extends DataClass
    implements Insertable<CachedCustomField> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedCustomField({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCustomFieldsCompanion toCompanion(bool nullToAbsent) {
    return CachedCustomFieldsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCustomField.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCustomField(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCustomField copyWith({int? id, String? jsonData, DateTime? cachedAt}) =>
      CachedCustomField(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedCustomField copyWithCompanion(CachedCustomFieldsCompanion data) {
    return CachedCustomField(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCustomField(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCustomField &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedCustomFieldsCompanion extends UpdateCompanion<CachedCustomField> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedCustomFieldsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedCustomFieldsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedCustomField> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedCustomFieldsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedCustomFieldsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCustomFieldsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedWorkflowsTable extends CachedWorkflows
    with TableInfo<$CachedWorkflowsTable, CachedWorkflow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWorkflowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_workflows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWorkflow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedWorkflow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWorkflow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedWorkflowsTable createAlias(String alias) {
    return $CachedWorkflowsTable(attachedDatabase, alias);
  }
}

class CachedWorkflow extends DataClass implements Insertable<CachedWorkflow> {
  final int id;
  final String jsonData;
  final DateTime cachedAt;
  const CachedWorkflow({
    required this.id,
    required this.jsonData,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedWorkflowsCompanion toCompanion(bool nullToAbsent) {
    return CachedWorkflowsCompanion(
      id: Value(id),
      jsonData: Value(jsonData),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedWorkflow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWorkflow(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedWorkflow copyWith({int? id, String? jsonData, DateTime? cachedAt}) =>
      CachedWorkflow(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedWorkflow copyWithCompanion(CachedWorkflowsCompanion data) {
    return CachedWorkflow(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkflow(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWorkflow &&
          other.id == this.id &&
          other.jsonData == this.jsonData &&
          other.cachedAt == this.cachedAt);
}

class CachedWorkflowsCompanion extends UpdateCompanion<CachedWorkflow> {
  final Value<int> id;
  final Value<String> jsonData;
  final Value<DateTime> cachedAt;
  const CachedWorkflowsCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  CachedWorkflowsCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
    required DateTime cachedAt,
  }) : jsonData = Value(jsonData),
       cachedAt = Value(cachedAt);
  static Insertable<CachedWorkflow> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  CachedWorkflowsCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
    Value<DateTime>? cachedAt,
  }) {
    return CachedWorkflowsCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWorkflowsCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingUploadsTable extends PendingUploads
    with TableInfo<$PendingUploadsTable, PendingUpload> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filenameMeta = const VerificationMeta(
    'filename',
  );
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
    'filename',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correspondentMeta = const VerificationMeta(
    'correspondent',
  );
  @override
  late final GeneratedColumn<int> correspondent = GeneratedColumn<int>(
    'correspondent',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentTypeMeta = const VerificationMeta(
    'documentType',
  );
  @override
  late final GeneratedColumn<int> documentType = GeneratedColumn<int>(
    'document_type',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFailedMeta = const VerificationMeta(
    'isFailed',
  );
  @override
  late final GeneratedColumn<bool> isFailed = GeneratedColumn<bool>(
    'is_failed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_failed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiredAtMeta = const VerificationMeta(
    'expiredAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiredAt = GeneratedColumn<DateTime>(
    'expired_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    filePath,
    filename,
    title,
    correspondent,
    documentType,
    tagsJson,
    created,
    queuedAt,
    retryCount,
    lastError,
    isFailed,
    serverUrl,
    expiredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_uploads';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingUpload> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('filename')) {
      context.handle(
        _filenameMeta,
        filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta),
      );
    } else if (isInserting) {
      context.missing(_filenameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('correspondent')) {
      context.handle(
        _correspondentMeta,
        correspondent.isAcceptableOrUnknown(
          data['correspondent']!,
          _correspondentMeta,
        ),
      );
    }
    if (data.containsKey('document_type')) {
      context.handle(
        _documentTypeMeta,
        documentType.isAcceptableOrUnknown(
          data['document_type']!,
          _documentTypeMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('is_failed')) {
      context.handle(
        _isFailedMeta,
        isFailed.isAcceptableOrUnknown(data['is_failed']!, _isFailedMeta),
      );
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    }
    if (data.containsKey('expired_at')) {
      context.handle(
        _expiredAtMeta,
        expiredAt.isAcceptableOrUnknown(data['expired_at']!, _expiredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingUpload map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingUpload(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      filename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filename'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      correspondent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correspondent'],
      ),
      documentType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_type'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      ),
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      isFailed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_failed'],
      )!,
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      ),
      expiredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expired_at'],
      ),
    );
  }

  @override
  $PendingUploadsTable createAlias(String alias) {
    return $PendingUploadsTable(attachedDatabase, alias);
  }
}

class PendingUpload extends DataClass implements Insertable<PendingUpload> {
  final int id;
  final String filePath;
  final String filename;
  final String? title;
  final int? correspondent;
  final int? documentType;
  final String? tagsJson;
  final DateTime? created;
  final DateTime queuedAt;
  final int retryCount;
  final String? lastError;
  final bool isFailed;

  /// The server this upload was queued for.
  ///
  /// Without it the drain sends every pending row to whatever server happens to
  /// be active. Switching profiles emits an unauthenticated->authenticated edge,
  /// which triggers a drain, so documents queued for account A were uploaded to
  /// account B. Nullable only because rows predating this column exist; the
  /// drain refuses to send those rather than guess.
  final String? serverUrl;

  /// When the retention sweep first observed this row past its window, or null
  /// if it never has been.
  ///
  /// Deliberately separate from `queuedAt`: the file is not released the
  /// moment a row is first seen expired, only on a later sweep once this
  /// timestamp itself is far enough in the past. See
  /// `UploadQueueService._giveUpIfExpired` for why — in short, a single bad
  /// `DateTime.now()` read must not be enough to destroy a document.
  final DateTime? expiredAt;
  const PendingUpload({
    required this.id,
    required this.filePath,
    required this.filename,
    this.title,
    this.correspondent,
    this.documentType,
    this.tagsJson,
    this.created,
    required this.queuedAt,
    required this.retryCount,
    this.lastError,
    required this.isFailed,
    this.serverUrl,
    this.expiredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_path'] = Variable<String>(filePath);
    map['filename'] = Variable<String>(filename);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || correspondent != null) {
      map['correspondent'] = Variable<int>(correspondent);
    }
    if (!nullToAbsent || documentType != null) {
      map['document_type'] = Variable<int>(documentType);
    }
    if (!nullToAbsent || tagsJson != null) {
      map['tags_json'] = Variable<String>(tagsJson);
    }
    if (!nullToAbsent || created != null) {
      map['created'] = Variable<DateTime>(created);
    }
    map['queued_at'] = Variable<DateTime>(queuedAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['is_failed'] = Variable<bool>(isFailed);
    if (!nullToAbsent || serverUrl != null) {
      map['server_url'] = Variable<String>(serverUrl);
    }
    if (!nullToAbsent || expiredAt != null) {
      map['expired_at'] = Variable<DateTime>(expiredAt);
    }
    return map;
  }

  PendingUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingUploadsCompanion(
      id: Value(id),
      filePath: Value(filePath),
      filename: Value(filename),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      correspondent: correspondent == null && nullToAbsent
          ? const Value.absent()
          : Value(correspondent),
      documentType: documentType == null && nullToAbsent
          ? const Value.absent()
          : Value(documentType),
      tagsJson: tagsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(tagsJson),
      created: created == null && nullToAbsent
          ? const Value.absent()
          : Value(created),
      queuedAt: Value(queuedAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      isFailed: Value(isFailed),
      serverUrl: serverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUrl),
      expiredAt: expiredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiredAt),
    );
  }

  factory PendingUpload.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingUpload(
      id: serializer.fromJson<int>(json['id']),
      filePath: serializer.fromJson<String>(json['filePath']),
      filename: serializer.fromJson<String>(json['filename']),
      title: serializer.fromJson<String?>(json['title']),
      correspondent: serializer.fromJson<int?>(json['correspondent']),
      documentType: serializer.fromJson<int?>(json['documentType']),
      tagsJson: serializer.fromJson<String?>(json['tagsJson']),
      created: serializer.fromJson<DateTime?>(json['created']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      isFailed: serializer.fromJson<bool>(json['isFailed']),
      serverUrl: serializer.fromJson<String?>(json['serverUrl']),
      expiredAt: serializer.fromJson<DateTime?>(json['expiredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filePath': serializer.toJson<String>(filePath),
      'filename': serializer.toJson<String>(filename),
      'title': serializer.toJson<String?>(title),
      'correspondent': serializer.toJson<int?>(correspondent),
      'documentType': serializer.toJson<int?>(documentType),
      'tagsJson': serializer.toJson<String?>(tagsJson),
      'created': serializer.toJson<DateTime?>(created),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'isFailed': serializer.toJson<bool>(isFailed),
      'serverUrl': serializer.toJson<String?>(serverUrl),
      'expiredAt': serializer.toJson<DateTime?>(expiredAt),
    };
  }

  PendingUpload copyWith({
    int? id,
    String? filePath,
    String? filename,
    Value<String?> title = const Value.absent(),
    Value<int?> correspondent = const Value.absent(),
    Value<int?> documentType = const Value.absent(),
    Value<String?> tagsJson = const Value.absent(),
    Value<DateTime?> created = const Value.absent(),
    DateTime? queuedAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    bool? isFailed,
    Value<String?> serverUrl = const Value.absent(),
    Value<DateTime?> expiredAt = const Value.absent(),
  }) => PendingUpload(
    id: id ?? this.id,
    filePath: filePath ?? this.filePath,
    filename: filename ?? this.filename,
    title: title.present ? title.value : this.title,
    correspondent: correspondent.present
        ? correspondent.value
        : this.correspondent,
    documentType: documentType.present ? documentType.value : this.documentType,
    tagsJson: tagsJson.present ? tagsJson.value : this.tagsJson,
    created: created.present ? created.value : this.created,
    queuedAt: queuedAt ?? this.queuedAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    isFailed: isFailed ?? this.isFailed,
    serverUrl: serverUrl.present ? serverUrl.value : this.serverUrl,
    expiredAt: expiredAt.present ? expiredAt.value : this.expiredAt,
  );
  PendingUpload copyWithCompanion(PendingUploadsCompanion data) {
    return PendingUpload(
      id: data.id.present ? data.id.value : this.id,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      filename: data.filename.present ? data.filename.value : this.filename,
      title: data.title.present ? data.title.value : this.title,
      correspondent: data.correspondent.present
          ? data.correspondent.value
          : this.correspondent,
      documentType: data.documentType.present
          ? data.documentType.value
          : this.documentType,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      created: data.created.present ? data.created.value : this.created,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      isFailed: data.isFailed.present ? data.isFailed.value : this.isFailed,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      expiredAt: data.expiredAt.present ? data.expiredAt.value : this.expiredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingUpload(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('filename: $filename, ')
          ..write('title: $title, ')
          ..write('correspondent: $correspondent, ')
          ..write('documentType: $documentType, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('created: $created, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('isFailed: $isFailed, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('expiredAt: $expiredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filePath,
    filename,
    title,
    correspondent,
    documentType,
    tagsJson,
    created,
    queuedAt,
    retryCount,
    lastError,
    isFailed,
    serverUrl,
    expiredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingUpload &&
          other.id == this.id &&
          other.filePath == this.filePath &&
          other.filename == this.filename &&
          other.title == this.title &&
          other.correspondent == this.correspondent &&
          other.documentType == this.documentType &&
          other.tagsJson == this.tagsJson &&
          other.created == this.created &&
          other.queuedAt == this.queuedAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.isFailed == this.isFailed &&
          other.serverUrl == this.serverUrl &&
          other.expiredAt == this.expiredAt);
}

class PendingUploadsCompanion extends UpdateCompanion<PendingUpload> {
  final Value<int> id;
  final Value<String> filePath;
  final Value<String> filename;
  final Value<String?> title;
  final Value<int?> correspondent;
  final Value<int?> documentType;
  final Value<String?> tagsJson;
  final Value<DateTime?> created;
  final Value<DateTime> queuedAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<bool> isFailed;
  final Value<String?> serverUrl;
  final Value<DateTime?> expiredAt;
  const PendingUploadsCompanion({
    this.id = const Value.absent(),
    this.filePath = const Value.absent(),
    this.filename = const Value.absent(),
    this.title = const Value.absent(),
    this.correspondent = const Value.absent(),
    this.documentType = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.created = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.isFailed = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.expiredAt = const Value.absent(),
  });
  PendingUploadsCompanion.insert({
    this.id = const Value.absent(),
    required String filePath,
    required String filename,
    this.title = const Value.absent(),
    this.correspondent = const Value.absent(),
    this.documentType = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.created = const Value.absent(),
    required DateTime queuedAt,
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.isFailed = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.expiredAt = const Value.absent(),
  }) : filePath = Value(filePath),
       filename = Value(filename),
       queuedAt = Value(queuedAt);
  static Insertable<PendingUpload> custom({
    Expression<int>? id,
    Expression<String>? filePath,
    Expression<String>? filename,
    Expression<String>? title,
    Expression<int>? correspondent,
    Expression<int>? documentType,
    Expression<String>? tagsJson,
    Expression<DateTime>? created,
    Expression<DateTime>? queuedAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<bool>? isFailed,
    Expression<String>? serverUrl,
    Expression<DateTime>? expiredAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filePath != null) 'file_path': filePath,
      if (filename != null) 'filename': filename,
      if (title != null) 'title': title,
      if (correspondent != null) 'correspondent': correspondent,
      if (documentType != null) 'document_type': documentType,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (created != null) 'created': created,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (isFailed != null) 'is_failed': isFailed,
      if (serverUrl != null) 'server_url': serverUrl,
      if (expiredAt != null) 'expired_at': expiredAt,
    });
  }

  PendingUploadsCompanion copyWith({
    Value<int>? id,
    Value<String>? filePath,
    Value<String>? filename,
    Value<String?>? title,
    Value<int?>? correspondent,
    Value<int?>? documentType,
    Value<String?>? tagsJson,
    Value<DateTime?>? created,
    Value<DateTime>? queuedAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<bool>? isFailed,
    Value<String?>? serverUrl,
    Value<DateTime?>? expiredAt,
  }) {
    return PendingUploadsCompanion(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      filename: filename ?? this.filename,
      title: title ?? this.title,
      correspondent: correspondent ?? this.correspondent,
      documentType: documentType ?? this.documentType,
      tagsJson: tagsJson ?? this.tagsJson,
      created: created ?? this.created,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      isFailed: isFailed ?? this.isFailed,
      serverUrl: serverUrl ?? this.serverUrl,
      expiredAt: expiredAt ?? this.expiredAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (correspondent.present) {
      map['correspondent'] = Variable<int>(correspondent.value);
    }
    if (documentType.present) {
      map['document_type'] = Variable<int>(documentType.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (isFailed.present) {
      map['is_failed'] = Variable<bool>(isFailed.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (expiredAt.present) {
      map['expired_at'] = Variable<DateTime>(expiredAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadsCompanion(')
          ..write('id: $id, ')
          ..write('filePath: $filePath, ')
          ..write('filename: $filename, ')
          ..write('title: $title, ')
          ..write('correspondent: $correspondent, ')
          ..write('documentType: $documentType, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('created: $created, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('isFailed: $isFailed, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('expiredAt: $expiredAt')
          ..write(')'))
        .toString();
  }
}

class $AiEditsTable extends AiEdits with TableInfo<$AiEditsTable, AiEdit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiEditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    fieldName,
    oldValue,
    newValue,
    source,
    appliedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_edits';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiEdit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiEdit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiEdit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      )!,
    );
  }

  @override
  $AiEditsTable createAlias(String alias) {
    return $AiEditsTable(attachedDatabase, alias);
  }
}

class AiEdit extends DataClass implements Insertable<AiEdit> {
  final int id;
  final int documentId;
  final String fieldName;
  final String? oldValue;
  final String? newValue;

  /// Source: 'ocr_suggestion' or 'chat'
  final String source;
  final DateTime appliedAt;
  const AiEdit({
    required this.id,
    required this.documentId,
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.source,
    required this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['field_name'] = Variable<String>(fieldName);
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    map['source'] = Variable<String>(source);
    map['applied_at'] = Variable<DateTime>(appliedAt);
    return map;
  }

  AiEditsCompanion toCompanion(bool nullToAbsent) {
    return AiEditsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      fieldName: Value(fieldName),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      source: Value(source),
      appliedAt: Value(appliedAt),
    );
  }

  factory AiEdit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiEdit(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      fieldName: serializer.fromJson<String>(json['fieldName']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      source: serializer.fromJson<String>(json['source']),
      appliedAt: serializer.fromJson<DateTime>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'fieldName': serializer.toJson<String>(fieldName),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'source': serializer.toJson<String>(source),
      'appliedAt': serializer.toJson<DateTime>(appliedAt),
    };
  }

  AiEdit copyWith({
    int? id,
    int? documentId,
    String? fieldName,
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    String? source,
    DateTime? appliedAt,
  }) => AiEdit(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    fieldName: fieldName ?? this.fieldName,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    source: source ?? this.source,
    appliedAt: appliedAt ?? this.appliedAt,
  );
  AiEdit copyWithCompanion(AiEditsCompanion data) {
    return AiEdit(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      source: data.source.present ? data.source.value : this.source,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiEdit(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('source: $source, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    fieldName,
    oldValue,
    newValue,
    source,
    appliedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiEdit &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.fieldName == this.fieldName &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.source == this.source &&
          other.appliedAt == this.appliedAt);
}

class AiEditsCompanion extends UpdateCompanion<AiEdit> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<String> fieldName;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String> source;
  final Value<DateTime> appliedAt;
  const AiEditsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.source = const Value.absent(),
    this.appliedAt = const Value.absent(),
  });
  AiEditsCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required String fieldName,
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    required String source,
    required DateTime appliedAt,
  }) : documentId = Value(documentId),
       fieldName = Value(fieldName),
       source = Value(source),
       appliedAt = Value(appliedAt);
  static Insertable<AiEdit> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<String>? fieldName,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? source,
    Expression<DateTime>? appliedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (fieldName != null) 'field_name': fieldName,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (source != null) 'source': source,
      if (appliedAt != null) 'applied_at': appliedAt,
    });
  }

  AiEditsCompanion copyWith({
    Value<int>? id,
    Value<int>? documentId,
    Value<String>? fieldName,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<String>? source,
    Value<DateTime>? appliedAt,
  }) {
    return AiEditsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      fieldName: fieldName ?? this.fieldName,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      source: source ?? this.source,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiEditsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('source: $source, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }
}

class $LockedDocumentsTable extends LockedDocuments
    with TableInfo<$LockedDocumentsTable, LockedDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LockedDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'locked_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<LockedDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  LockedDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LockedDocument(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
    );
  }

  @override
  $LockedDocumentsTable createAlias(String alias) {
    return $LockedDocumentsTable(attachedDatabase, alias);
  }
}

class LockedDocument extends DataClass implements Insertable<LockedDocument> {
  final int documentId;
  const LockedDocument({required this.documentId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<int>(documentId);
    return map;
  }

  LockedDocumentsCompanion toCompanion(bool nullToAbsent) {
    return LockedDocumentsCompanion(documentId: Value(documentId));
  }

  factory LockedDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LockedDocument(
      documentId: serializer.fromJson<int>(json['documentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'documentId': serializer.toJson<int>(documentId)};
  }

  LockedDocument copyWith({int? documentId}) =>
      LockedDocument(documentId: documentId ?? this.documentId);
  LockedDocument copyWithCompanion(LockedDocumentsCompanion data) {
    return LockedDocument(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LockedDocument(')
          ..write('documentId: $documentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => documentId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LockedDocument && other.documentId == this.documentId);
}

class LockedDocumentsCompanion extends UpdateCompanion<LockedDocument> {
  final Value<int> documentId;
  const LockedDocumentsCompanion({this.documentId = const Value.absent()});
  LockedDocumentsCompanion.insert({this.documentId = const Value.absent()});
  static Insertable<LockedDocument> custom({Expression<int>? documentId}) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
    });
  }

  LockedDocumentsCompanion copyWith({Value<int>? documentId}) {
    return LockedDocumentsCompanion(documentId: documentId ?? this.documentId);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LockedDocumentsCompanion(')
          ..write('documentId: $documentId')
          ..write(')'))
        .toString();
  }
}

class $DocumentTemplatesTable extends DocumentTemplates
    with TableInfo<$DocumentTemplatesTable, DocumentTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jsonDataMeta = const VerificationMeta(
    'jsonData',
  );
  @override
  late final GeneratedColumn<String> jsonData = GeneratedColumn<String>(
    'json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, jsonData];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json_data')) {
      context.handle(
        _jsonDataMeta,
        jsonData.isAcceptableOrUnknown(data['json_data']!, _jsonDataMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonDataMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      jsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json_data'],
      )!,
    );
  }

  @override
  $DocumentTemplatesTable createAlias(String alias) {
    return $DocumentTemplatesTable(attachedDatabase, alias);
  }
}

class DocumentTemplateRow extends DataClass
    implements Insertable<DocumentTemplateRow> {
  final int id;
  final String jsonData;
  const DocumentTemplateRow({required this.id, required this.jsonData});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json_data'] = Variable<String>(jsonData);
    return map;
  }

  DocumentTemplatesCompanion toCompanion(bool nullToAbsent) {
    return DocumentTemplatesCompanion(id: Value(id), jsonData: Value(jsonData));
  }

  factory DocumentTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentTemplateRow(
      id: serializer.fromJson<int>(json['id']),
      jsonData: serializer.fromJson<String>(json['jsonData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'jsonData': serializer.toJson<String>(jsonData),
    };
  }

  DocumentTemplateRow copyWith({int? id, String? jsonData}) =>
      DocumentTemplateRow(
        id: id ?? this.id,
        jsonData: jsonData ?? this.jsonData,
      );
  DocumentTemplateRow copyWithCompanion(DocumentTemplatesCompanion data) {
    return DocumentTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      jsonData: data.jsonData.present ? data.jsonData.value : this.jsonData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentTemplateRow(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, jsonData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentTemplateRow &&
          other.id == this.id &&
          other.jsonData == this.jsonData);
}

class DocumentTemplatesCompanion extends UpdateCompanion<DocumentTemplateRow> {
  final Value<int> id;
  final Value<String> jsonData;
  const DocumentTemplatesCompanion({
    this.id = const Value.absent(),
    this.jsonData = const Value.absent(),
  });
  DocumentTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String jsonData,
  }) : jsonData = Value(jsonData);
  static Insertable<DocumentTemplateRow> custom({
    Expression<int>? id,
    Expression<String>? jsonData,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jsonData != null) 'json_data': jsonData,
    });
  }

  DocumentTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? jsonData,
  }) {
    return DocumentTemplatesCompanion(
      id: id ?? this.id,
      jsonData: jsonData ?? this.jsonData,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (jsonData.present) {
      map['json_data'] = Variable<String>(jsonData.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('jsonData: $jsonData')
          ..write(')'))
        .toString();
  }
}

class $PendingEditsTable extends PendingEdits
    with TableInfo<$PendingEditsTable, PendingEdit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingEditsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<int> documentId = GeneratedColumn<int>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    field,
    value,
    queuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_edits';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingEdit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingEdit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingEdit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  $PendingEditsTable createAlias(String alias) {
    return $PendingEditsTable(attachedDatabase, alias);
  }
}

class PendingEdit extends DataClass implements Insertable<PendingEdit> {
  final int id;
  final int documentId;
  final String field;
  final String value;
  final DateTime queuedAt;
  const PendingEdit({
    required this.id,
    required this.documentId,
    required this.field,
    required this.value,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['document_id'] = Variable<int>(documentId);
    map['field'] = Variable<String>(field);
    map['value'] = Variable<String>(value);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingEditsCompanion toCompanion(bool nullToAbsent) {
    return PendingEditsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      field: Value(field),
      value: Value(value),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingEdit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingEdit(
      id: serializer.fromJson<int>(json['id']),
      documentId: serializer.fromJson<int>(json['documentId']),
      field: serializer.fromJson<String>(json['field']),
      value: serializer.fromJson<String>(json['value']),
      queuedAt: serializer.fromJson<DateTime>(json['queuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'documentId': serializer.toJson<int>(documentId),
      'field': serializer.toJson<String>(field),
      'value': serializer.toJson<String>(value),
      'queuedAt': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingEdit copyWith({
    int? id,
    int? documentId,
    String? field,
    String? value,
    DateTime? queuedAt,
  }) => PendingEdit(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    field: field ?? this.field,
    value: value ?? this.value,
    queuedAt: queuedAt ?? this.queuedAt,
  );
  PendingEdit copyWithCompanion(PendingEditsCompanion data) {
    return PendingEdit(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      field: data.field.present ? data.field.value : this.field,
      value: data.value.present ? data.value.value : this.value,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingEdit(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('field: $field, ')
          ..write('value: $value, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, documentId, field, value, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingEdit &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.field == this.field &&
          other.value == this.value &&
          other.queuedAt == this.queuedAt);
}

class PendingEditsCompanion extends UpdateCompanion<PendingEdit> {
  final Value<int> id;
  final Value<int> documentId;
  final Value<String> field;
  final Value<String> value;
  final Value<DateTime> queuedAt;
  const PendingEditsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.field = const Value.absent(),
    this.value = const Value.absent(),
    this.queuedAt = const Value.absent(),
  });
  PendingEditsCompanion.insert({
    this.id = const Value.absent(),
    required int documentId,
    required String field,
    required String value,
    required DateTime queuedAt,
  }) : documentId = Value(documentId),
       field = Value(field),
       value = Value(value),
       queuedAt = Value(queuedAt);
  static Insertable<PendingEdit> custom({
    Expression<int>? id,
    Expression<int>? documentId,
    Expression<String>? field,
    Expression<String>? value,
    Expression<DateTime>? queuedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (field != null) 'field': field,
      if (value != null) 'value': value,
      if (queuedAt != null) 'queued_at': queuedAt,
    });
  }

  PendingEditsCompanion copyWith({
    Value<int>? id,
    Value<int>? documentId,
    Value<String>? field,
    Value<String>? value,
    Value<DateTime>? queuedAt,
  }) {
    return PendingEditsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      field: field ?? this.field,
      value: value ?? this.value,
      queuedAt: queuedAt ?? this.queuedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<int>(documentId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingEditsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('field: $field, ')
          ..write('value: $value, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedDocumentsTable cachedDocuments = $CachedDocumentsTable(
    this,
  );
  late final $CachedTagsTable cachedTags = $CachedTagsTable(this);
  late final $CachedCorrespondentsTable cachedCorrespondents =
      $CachedCorrespondentsTable(this);
  late final $CachedDocumentTypesTable cachedDocumentTypes =
      $CachedDocumentTypesTable(this);
  late final $CachedStoragePathsTable cachedStoragePaths =
      $CachedStoragePathsTable(this);
  late final $CachedSavedViewsTable cachedSavedViews = $CachedSavedViewsTable(
    this,
  );
  late final $CachedCustomFieldsTable cachedCustomFields =
      $CachedCustomFieldsTable(this);
  late final $CachedWorkflowsTable cachedWorkflows = $CachedWorkflowsTable(
    this,
  );
  late final $PendingUploadsTable pendingUploads = $PendingUploadsTable(this);
  late final $AiEditsTable aiEdits = $AiEditsTable(this);
  late final $LockedDocumentsTable lockedDocuments = $LockedDocumentsTable(
    this,
  );
  late final $DocumentTemplatesTable documentTemplates =
      $DocumentTemplatesTable(this);
  late final $PendingEditsTable pendingEdits = $PendingEditsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedDocuments,
    cachedTags,
    cachedCorrespondents,
    cachedDocumentTypes,
    cachedStoragePaths,
    cachedSavedViews,
    cachedCustomFields,
    cachedWorkflows,
    pendingUploads,
    aiEdits,
    lockedDocuments,
    documentTemplates,
    pendingEdits,
  ];
}

typedef $$CachedDocumentsTableCreateCompanionBuilder =
    CachedDocumentsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedDocumentsTableUpdateCompanionBuilder =
    CachedDocumentsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDocumentsTable> {
  $$CachedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDocumentsTable,
          CachedDocument,
          $$CachedDocumentsTableFilterComposer,
          $$CachedDocumentsTableOrderingComposer,
          $$CachedDocumentsTableAnnotationComposer,
          $$CachedDocumentsTableCreateCompanionBuilder,
          $$CachedDocumentsTableUpdateCompanionBuilder,
          (
            CachedDocument,
            BaseReferences<
              _$AppDatabase,
              $CachedDocumentsTable,
              CachedDocument
            >,
          ),
          CachedDocument,
          PrefetchHooks Function()
        > {
  $$CachedDocumentsTableTableManager(
    _$AppDatabase db,
    $CachedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedDocumentsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedDocumentsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDocumentsTable,
      CachedDocument,
      $$CachedDocumentsTableFilterComposer,
      $$CachedDocumentsTableOrderingComposer,
      $$CachedDocumentsTableAnnotationComposer,
      $$CachedDocumentsTableCreateCompanionBuilder,
      $$CachedDocumentsTableUpdateCompanionBuilder,
      (
        CachedDocument,
        BaseReferences<_$AppDatabase, $CachedDocumentsTable, CachedDocument>,
      ),
      CachedDocument,
      PrefetchHooks Function()
    >;
typedef $$CachedTagsTableCreateCompanionBuilder =
    CachedTagsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedTagsTableUpdateCompanionBuilder =
    CachedTagsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedTagsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTagsTable> {
  $$CachedTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTagsTable> {
  $$CachedTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTagsTable> {
  $$CachedTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTagsTable,
          CachedTag,
          $$CachedTagsTableFilterComposer,
          $$CachedTagsTableOrderingComposer,
          $$CachedTagsTableAnnotationComposer,
          $$CachedTagsTableCreateCompanionBuilder,
          $$CachedTagsTableUpdateCompanionBuilder,
          (
            CachedTag,
            BaseReferences<_$AppDatabase, $CachedTagsTable, CachedTag>,
          ),
          CachedTag,
          PrefetchHooks Function()
        > {
  $$CachedTagsTableTableManager(_$AppDatabase db, $CachedTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedTagsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedTagsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTagsTable,
      CachedTag,
      $$CachedTagsTableFilterComposer,
      $$CachedTagsTableOrderingComposer,
      $$CachedTagsTableAnnotationComposer,
      $$CachedTagsTableCreateCompanionBuilder,
      $$CachedTagsTableUpdateCompanionBuilder,
      (CachedTag, BaseReferences<_$AppDatabase, $CachedTagsTable, CachedTag>),
      CachedTag,
      PrefetchHooks Function()
    >;
typedef $$CachedCorrespondentsTableCreateCompanionBuilder =
    CachedCorrespondentsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedCorrespondentsTableUpdateCompanionBuilder =
    CachedCorrespondentsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedCorrespondentsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCorrespondentsTable> {
  $$CachedCorrespondentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCorrespondentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCorrespondentsTable> {
  $$CachedCorrespondentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCorrespondentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCorrespondentsTable> {
  $$CachedCorrespondentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCorrespondentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCorrespondentsTable,
          CachedCorrespondent,
          $$CachedCorrespondentsTableFilterComposer,
          $$CachedCorrespondentsTableOrderingComposer,
          $$CachedCorrespondentsTableAnnotationComposer,
          $$CachedCorrespondentsTableCreateCompanionBuilder,
          $$CachedCorrespondentsTableUpdateCompanionBuilder,
          (
            CachedCorrespondent,
            BaseReferences<
              _$AppDatabase,
              $CachedCorrespondentsTable,
              CachedCorrespondent
            >,
          ),
          CachedCorrespondent,
          PrefetchHooks Function()
        > {
  $$CachedCorrespondentsTableTableManager(
    _$AppDatabase db,
    $CachedCorrespondentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCorrespondentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCorrespondentsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedCorrespondentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedCorrespondentsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedCorrespondentsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCorrespondentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCorrespondentsTable,
      CachedCorrespondent,
      $$CachedCorrespondentsTableFilterComposer,
      $$CachedCorrespondentsTableOrderingComposer,
      $$CachedCorrespondentsTableAnnotationComposer,
      $$CachedCorrespondentsTableCreateCompanionBuilder,
      $$CachedCorrespondentsTableUpdateCompanionBuilder,
      (
        CachedCorrespondent,
        BaseReferences<
          _$AppDatabase,
          $CachedCorrespondentsTable,
          CachedCorrespondent
        >,
      ),
      CachedCorrespondent,
      PrefetchHooks Function()
    >;
typedef $$CachedDocumentTypesTableCreateCompanionBuilder =
    CachedDocumentTypesCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedDocumentTypesTableUpdateCompanionBuilder =
    CachedDocumentTypesCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedDocumentTypesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedDocumentTypesTable> {
  $$CachedDocumentTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedDocumentTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedDocumentTypesTable> {
  $$CachedDocumentTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedDocumentTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedDocumentTypesTable> {
  $$CachedDocumentTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedDocumentTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedDocumentTypesTable,
          CachedDocumentType,
          $$CachedDocumentTypesTableFilterComposer,
          $$CachedDocumentTypesTableOrderingComposer,
          $$CachedDocumentTypesTableAnnotationComposer,
          $$CachedDocumentTypesTableCreateCompanionBuilder,
          $$CachedDocumentTypesTableUpdateCompanionBuilder,
          (
            CachedDocumentType,
            BaseReferences<
              _$AppDatabase,
              $CachedDocumentTypesTable,
              CachedDocumentType
            >,
          ),
          CachedDocumentType,
          PrefetchHooks Function()
        > {
  $$CachedDocumentTypesTableTableManager(
    _$AppDatabase db,
    $CachedDocumentTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedDocumentTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedDocumentTypesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedDocumentTypesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedDocumentTypesCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedDocumentTypesCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedDocumentTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedDocumentTypesTable,
      CachedDocumentType,
      $$CachedDocumentTypesTableFilterComposer,
      $$CachedDocumentTypesTableOrderingComposer,
      $$CachedDocumentTypesTableAnnotationComposer,
      $$CachedDocumentTypesTableCreateCompanionBuilder,
      $$CachedDocumentTypesTableUpdateCompanionBuilder,
      (
        CachedDocumentType,
        BaseReferences<
          _$AppDatabase,
          $CachedDocumentTypesTable,
          CachedDocumentType
        >,
      ),
      CachedDocumentType,
      PrefetchHooks Function()
    >;
typedef $$CachedStoragePathsTableCreateCompanionBuilder =
    CachedStoragePathsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedStoragePathsTableUpdateCompanionBuilder =
    CachedStoragePathsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedStoragePathsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStoragePathsTable> {
  $$CachedStoragePathsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStoragePathsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStoragePathsTable> {
  $$CachedStoragePathsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStoragePathsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStoragePathsTable> {
  $$CachedStoragePathsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedStoragePathsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStoragePathsTable,
          CachedStoragePath,
          $$CachedStoragePathsTableFilterComposer,
          $$CachedStoragePathsTableOrderingComposer,
          $$CachedStoragePathsTableAnnotationComposer,
          $$CachedStoragePathsTableCreateCompanionBuilder,
          $$CachedStoragePathsTableUpdateCompanionBuilder,
          (
            CachedStoragePath,
            BaseReferences<
              _$AppDatabase,
              $CachedStoragePathsTable,
              CachedStoragePath
            >,
          ),
          CachedStoragePath,
          PrefetchHooks Function()
        > {
  $$CachedStoragePathsTableTableManager(
    _$AppDatabase db,
    $CachedStoragePathsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStoragePathsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStoragePathsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStoragePathsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedStoragePathsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedStoragePathsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStoragePathsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStoragePathsTable,
      CachedStoragePath,
      $$CachedStoragePathsTableFilterComposer,
      $$CachedStoragePathsTableOrderingComposer,
      $$CachedStoragePathsTableAnnotationComposer,
      $$CachedStoragePathsTableCreateCompanionBuilder,
      $$CachedStoragePathsTableUpdateCompanionBuilder,
      (
        CachedStoragePath,
        BaseReferences<
          _$AppDatabase,
          $CachedStoragePathsTable,
          CachedStoragePath
        >,
      ),
      CachedStoragePath,
      PrefetchHooks Function()
    >;
typedef $$CachedSavedViewsTableCreateCompanionBuilder =
    CachedSavedViewsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedSavedViewsTableUpdateCompanionBuilder =
    CachedSavedViewsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedSavedViewsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSavedViewsTable> {
  $$CachedSavedViewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSavedViewsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSavedViewsTable> {
  $$CachedSavedViewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSavedViewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSavedViewsTable> {
  $$CachedSavedViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedSavedViewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSavedViewsTable,
          CachedSavedView,
          $$CachedSavedViewsTableFilterComposer,
          $$CachedSavedViewsTableOrderingComposer,
          $$CachedSavedViewsTableAnnotationComposer,
          $$CachedSavedViewsTableCreateCompanionBuilder,
          $$CachedSavedViewsTableUpdateCompanionBuilder,
          (
            CachedSavedView,
            BaseReferences<
              _$AppDatabase,
              $CachedSavedViewsTable,
              CachedSavedView
            >,
          ),
          CachedSavedView,
          PrefetchHooks Function()
        > {
  $$CachedSavedViewsTableTableManager(
    _$AppDatabase db,
    $CachedSavedViewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSavedViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSavedViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSavedViewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedSavedViewsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedSavedViewsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSavedViewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSavedViewsTable,
      CachedSavedView,
      $$CachedSavedViewsTableFilterComposer,
      $$CachedSavedViewsTableOrderingComposer,
      $$CachedSavedViewsTableAnnotationComposer,
      $$CachedSavedViewsTableCreateCompanionBuilder,
      $$CachedSavedViewsTableUpdateCompanionBuilder,
      (
        CachedSavedView,
        BaseReferences<_$AppDatabase, $CachedSavedViewsTable, CachedSavedView>,
      ),
      CachedSavedView,
      PrefetchHooks Function()
    >;
typedef $$CachedCustomFieldsTableCreateCompanionBuilder =
    CachedCustomFieldsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedCustomFieldsTableUpdateCompanionBuilder =
    CachedCustomFieldsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedCustomFieldsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCustomFieldsTable> {
  $$CachedCustomFieldsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCustomFieldsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCustomFieldsTable> {
  $$CachedCustomFieldsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCustomFieldsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCustomFieldsTable> {
  $$CachedCustomFieldsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCustomFieldsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCustomFieldsTable,
          CachedCustomField,
          $$CachedCustomFieldsTableFilterComposer,
          $$CachedCustomFieldsTableOrderingComposer,
          $$CachedCustomFieldsTableAnnotationComposer,
          $$CachedCustomFieldsTableCreateCompanionBuilder,
          $$CachedCustomFieldsTableUpdateCompanionBuilder,
          (
            CachedCustomField,
            BaseReferences<
              _$AppDatabase,
              $CachedCustomFieldsTable,
              CachedCustomField
            >,
          ),
          CachedCustomField,
          PrefetchHooks Function()
        > {
  $$CachedCustomFieldsTableTableManager(
    _$AppDatabase db,
    $CachedCustomFieldsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCustomFieldsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCustomFieldsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCustomFieldsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedCustomFieldsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedCustomFieldsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCustomFieldsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCustomFieldsTable,
      CachedCustomField,
      $$CachedCustomFieldsTableFilterComposer,
      $$CachedCustomFieldsTableOrderingComposer,
      $$CachedCustomFieldsTableAnnotationComposer,
      $$CachedCustomFieldsTableCreateCompanionBuilder,
      $$CachedCustomFieldsTableUpdateCompanionBuilder,
      (
        CachedCustomField,
        BaseReferences<
          _$AppDatabase,
          $CachedCustomFieldsTable,
          CachedCustomField
        >,
      ),
      CachedCustomField,
      PrefetchHooks Function()
    >;
typedef $$CachedWorkflowsTableCreateCompanionBuilder =
    CachedWorkflowsCompanion Function({
      Value<int> id,
      required String jsonData,
      required DateTime cachedAt,
    });
typedef $$CachedWorkflowsTableUpdateCompanionBuilder =
    CachedWorkflowsCompanion Function({
      Value<int> id,
      Value<String> jsonData,
      Value<DateTime> cachedAt,
    });

class $$CachedWorkflowsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWorkflowsTable> {
  $$CachedWorkflowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWorkflowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWorkflowsTable> {
  $$CachedWorkflowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWorkflowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWorkflowsTable> {
  $$CachedWorkflowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedWorkflowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWorkflowsTable,
          CachedWorkflow,
          $$CachedWorkflowsTableFilterComposer,
          $$CachedWorkflowsTableOrderingComposer,
          $$CachedWorkflowsTableAnnotationComposer,
          $$CachedWorkflowsTableCreateCompanionBuilder,
          $$CachedWorkflowsTableUpdateCompanionBuilder,
          (
            CachedWorkflow,
            BaseReferences<
              _$AppDatabase,
              $CachedWorkflowsTable,
              CachedWorkflow
            >,
          ),
          CachedWorkflow,
          PrefetchHooks Function()
        > {
  $$CachedWorkflowsTableTableManager(
    _$AppDatabase db,
    $CachedWorkflowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWorkflowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWorkflowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedWorkflowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => CachedWorkflowsCompanion(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
                required DateTime cachedAt,
              }) => CachedWorkflowsCompanion.insert(
                id: id,
                jsonData: jsonData,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWorkflowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWorkflowsTable,
      CachedWorkflow,
      $$CachedWorkflowsTableFilterComposer,
      $$CachedWorkflowsTableOrderingComposer,
      $$CachedWorkflowsTableAnnotationComposer,
      $$CachedWorkflowsTableCreateCompanionBuilder,
      $$CachedWorkflowsTableUpdateCompanionBuilder,
      (
        CachedWorkflow,
        BaseReferences<_$AppDatabase, $CachedWorkflowsTable, CachedWorkflow>,
      ),
      CachedWorkflow,
      PrefetchHooks Function()
    >;
typedef $$PendingUploadsTableCreateCompanionBuilder =
    PendingUploadsCompanion Function({
      Value<int> id,
      required String filePath,
      required String filename,
      Value<String?> title,
      Value<int?> correspondent,
      Value<int?> documentType,
      Value<String?> tagsJson,
      Value<DateTime?> created,
      required DateTime queuedAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<bool> isFailed,
      Value<String?> serverUrl,
      Value<DateTime?> expiredAt,
    });
typedef $$PendingUploadsTableUpdateCompanionBuilder =
    PendingUploadsCompanion Function({
      Value<int> id,
      Value<String> filePath,
      Value<String> filename,
      Value<String?> title,
      Value<int?> correspondent,
      Value<int?> documentType,
      Value<String?> tagsJson,
      Value<DateTime?> created,
      Value<DateTime> queuedAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<bool> isFailed,
      Value<String?> serverUrl,
      Value<DateTime?> expiredAt,
    });

class $$PendingUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correspondent => $composableBuilder(
    column: $table.correspondent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFailed => $composableBuilder(
    column: $table.isFailed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiredAt => $composableBuilder(
    column: $table.expiredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filename => $composableBuilder(
    column: $table.filename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correspondent => $composableBuilder(
    column: $table.correspondent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFailed => $composableBuilder(
    column: $table.isFailed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiredAt => $composableBuilder(
    column: $table.expiredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get correspondent => $composableBuilder(
    column: $table.correspondent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get documentType => $composableBuilder(
    column: $table.documentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get isFailed =>
      $composableBuilder(column: $table.isFailed, builder: (column) => column);

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get expiredAt =>
      $composableBuilder(column: $table.expiredAt, builder: (column) => column);
}

class $$PendingUploadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingUploadsTable,
          PendingUpload,
          $$PendingUploadsTableFilterComposer,
          $$PendingUploadsTableOrderingComposer,
          $$PendingUploadsTableAnnotationComposer,
          $$PendingUploadsTableCreateCompanionBuilder,
          $$PendingUploadsTableUpdateCompanionBuilder,
          (
            PendingUpload,
            BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUpload>,
          ),
          PendingUpload,
          PrefetchHooks Function()
        > {
  $$PendingUploadsTableTableManager(
    _$AppDatabase db,
    $PendingUploadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> filename = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int?> correspondent = const Value.absent(),
                Value<int?> documentType = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<DateTime?> created = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> isFailed = const Value.absent(),
                Value<String?> serverUrl = const Value.absent(),
                Value<DateTime?> expiredAt = const Value.absent(),
              }) => PendingUploadsCompanion(
                id: id,
                filePath: filePath,
                filename: filename,
                title: title,
                correspondent: correspondent,
                documentType: documentType,
                tagsJson: tagsJson,
                created: created,
                queuedAt: queuedAt,
                retryCount: retryCount,
                lastError: lastError,
                isFailed: isFailed,
                serverUrl: serverUrl,
                expiredAt: expiredAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String filePath,
                required String filename,
                Value<String?> title = const Value.absent(),
                Value<int?> correspondent = const Value.absent(),
                Value<int?> documentType = const Value.absent(),
                Value<String?> tagsJson = const Value.absent(),
                Value<DateTime?> created = const Value.absent(),
                required DateTime queuedAt,
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> isFailed = const Value.absent(),
                Value<String?> serverUrl = const Value.absent(),
                Value<DateTime?> expiredAt = const Value.absent(),
              }) => PendingUploadsCompanion.insert(
                id: id,
                filePath: filePath,
                filename: filename,
                title: title,
                correspondent: correspondent,
                documentType: documentType,
                tagsJson: tagsJson,
                created: created,
                queuedAt: queuedAt,
                retryCount: retryCount,
                lastError: lastError,
                isFailed: isFailed,
                serverUrl: serverUrl,
                expiredAt: expiredAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingUploadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingUploadsTable,
      PendingUpload,
      $$PendingUploadsTableFilterComposer,
      $$PendingUploadsTableOrderingComposer,
      $$PendingUploadsTableAnnotationComposer,
      $$PendingUploadsTableCreateCompanionBuilder,
      $$PendingUploadsTableUpdateCompanionBuilder,
      (
        PendingUpload,
        BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUpload>,
      ),
      PendingUpload,
      PrefetchHooks Function()
    >;
typedef $$AiEditsTableCreateCompanionBuilder =
    AiEditsCompanion Function({
      Value<int> id,
      required int documentId,
      required String fieldName,
      Value<String?> oldValue,
      Value<String?> newValue,
      required String source,
      required DateTime appliedAt,
    });
typedef $$AiEditsTableUpdateCompanionBuilder =
    AiEditsCompanion Function({
      Value<int> id,
      Value<int> documentId,
      Value<String> fieldName,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String> source,
      Value<DateTime> appliedAt,
    });

class $$AiEditsTableFilterComposer
    extends Composer<_$AppDatabase, $AiEditsTable> {
  $$AiEditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiEditsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiEditsTable> {
  $$AiEditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiEditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiEditsTable> {
  $$AiEditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);
}

class $$AiEditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiEditsTable,
          AiEdit,
          $$AiEditsTableFilterComposer,
          $$AiEditsTableOrderingComposer,
          $$AiEditsTableAnnotationComposer,
          $$AiEditsTableCreateCompanionBuilder,
          $$AiEditsTableUpdateCompanionBuilder,
          (AiEdit, BaseReferences<_$AppDatabase, $AiEditsTable, AiEdit>),
          AiEdit,
          PrefetchHooks Function()
        > {
  $$AiEditsTableTableManager(_$AppDatabase db, $AiEditsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiEditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiEditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiEditsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> documentId = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> appliedAt = const Value.absent(),
              }) => AiEditsCompanion(
                id: id,
                documentId: documentId,
                fieldName: fieldName,
                oldValue: oldValue,
                newValue: newValue,
                source: source,
                appliedAt: appliedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int documentId,
                required String fieldName,
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                required String source,
                required DateTime appliedAt,
              }) => AiEditsCompanion.insert(
                id: id,
                documentId: documentId,
                fieldName: fieldName,
                oldValue: oldValue,
                newValue: newValue,
                source: source,
                appliedAt: appliedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiEditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiEditsTable,
      AiEdit,
      $$AiEditsTableFilterComposer,
      $$AiEditsTableOrderingComposer,
      $$AiEditsTableAnnotationComposer,
      $$AiEditsTableCreateCompanionBuilder,
      $$AiEditsTableUpdateCompanionBuilder,
      (AiEdit, BaseReferences<_$AppDatabase, $AiEditsTable, AiEdit>),
      AiEdit,
      PrefetchHooks Function()
    >;
typedef $$LockedDocumentsTableCreateCompanionBuilder =
    LockedDocumentsCompanion Function({Value<int> documentId});
typedef $$LockedDocumentsTableUpdateCompanionBuilder =
    LockedDocumentsCompanion Function({Value<int> documentId});

class $$LockedDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $LockedDocumentsTable> {
  $$LockedDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LockedDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LockedDocumentsTable> {
  $$LockedDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LockedDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LockedDocumentsTable> {
  $$LockedDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );
}

class $$LockedDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LockedDocumentsTable,
          LockedDocument,
          $$LockedDocumentsTableFilterComposer,
          $$LockedDocumentsTableOrderingComposer,
          $$LockedDocumentsTableAnnotationComposer,
          $$LockedDocumentsTableCreateCompanionBuilder,
          $$LockedDocumentsTableUpdateCompanionBuilder,
          (
            LockedDocument,
            BaseReferences<
              _$AppDatabase,
              $LockedDocumentsTable,
              LockedDocument
            >,
          ),
          LockedDocument,
          PrefetchHooks Function()
        > {
  $$LockedDocumentsTableTableManager(
    _$AppDatabase db,
    $LockedDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LockedDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LockedDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LockedDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({Value<int> documentId = const Value.absent()}) =>
                  LockedDocumentsCompanion(documentId: documentId),
          createCompanionCallback:
              ({Value<int> documentId = const Value.absent()}) =>
                  LockedDocumentsCompanion.insert(documentId: documentId),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LockedDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LockedDocumentsTable,
      LockedDocument,
      $$LockedDocumentsTableFilterComposer,
      $$LockedDocumentsTableOrderingComposer,
      $$LockedDocumentsTableAnnotationComposer,
      $$LockedDocumentsTableCreateCompanionBuilder,
      $$LockedDocumentsTableUpdateCompanionBuilder,
      (
        LockedDocument,
        BaseReferences<_$AppDatabase, $LockedDocumentsTable, LockedDocument>,
      ),
      LockedDocument,
      PrefetchHooks Function()
    >;
typedef $$DocumentTemplatesTableCreateCompanionBuilder =
    DocumentTemplatesCompanion Function({
      Value<int> id,
      required String jsonData,
    });
typedef $$DocumentTemplatesTableUpdateCompanionBuilder =
    DocumentTemplatesCompanion Function({
      Value<int> id,
      Value<String> jsonData,
    });

class $$DocumentTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentTemplatesTable> {
  $$DocumentTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentTemplatesTable> {
  $$DocumentTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jsonData => $composableBuilder(
    column: $table.jsonData,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentTemplatesTable> {
  $$DocumentTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jsonData =>
      $composableBuilder(column: $table.jsonData, builder: (column) => column);
}

class $$DocumentTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentTemplatesTable,
          DocumentTemplateRow,
          $$DocumentTemplatesTableFilterComposer,
          $$DocumentTemplatesTableOrderingComposer,
          $$DocumentTemplatesTableAnnotationComposer,
          $$DocumentTemplatesTableCreateCompanionBuilder,
          $$DocumentTemplatesTableUpdateCompanionBuilder,
          (
            DocumentTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $DocumentTemplatesTable,
              DocumentTemplateRow
            >,
          ),
          DocumentTemplateRow,
          PrefetchHooks Function()
        > {
  $$DocumentTemplatesTableTableManager(
    _$AppDatabase db,
    $DocumentTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> jsonData = const Value.absent(),
              }) => DocumentTemplatesCompanion(id: id, jsonData: jsonData),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String jsonData,
              }) =>
                  DocumentTemplatesCompanion.insert(id: id, jsonData: jsonData),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentTemplatesTable,
      DocumentTemplateRow,
      $$DocumentTemplatesTableFilterComposer,
      $$DocumentTemplatesTableOrderingComposer,
      $$DocumentTemplatesTableAnnotationComposer,
      $$DocumentTemplatesTableCreateCompanionBuilder,
      $$DocumentTemplatesTableUpdateCompanionBuilder,
      (
        DocumentTemplateRow,
        BaseReferences<
          _$AppDatabase,
          $DocumentTemplatesTable,
          DocumentTemplateRow
        >,
      ),
      DocumentTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$PendingEditsTableCreateCompanionBuilder =
    PendingEditsCompanion Function({
      Value<int> id,
      required int documentId,
      required String field,
      required String value,
      required DateTime queuedAt,
    });
typedef $$PendingEditsTableUpdateCompanionBuilder =
    PendingEditsCompanion Function({
      Value<int> id,
      Value<int> documentId,
      Value<String> field,
      Value<String> value,
      Value<DateTime> queuedAt,
    });

class $$PendingEditsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingEditsTable> {
  $$PendingEditsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingEditsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingEditsTable> {
  $$PendingEditsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingEditsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingEditsTable> {
  $$PendingEditsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $$PendingEditsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingEditsTable,
          PendingEdit,
          $$PendingEditsTableFilterComposer,
          $$PendingEditsTableOrderingComposer,
          $$PendingEditsTableAnnotationComposer,
          $$PendingEditsTableCreateCompanionBuilder,
          $$PendingEditsTableUpdateCompanionBuilder,
          (
            PendingEdit,
            BaseReferences<_$AppDatabase, $PendingEditsTable, PendingEdit>,
          ),
          PendingEdit,
          PrefetchHooks Function()
        > {
  $$PendingEditsTableTableManager(_$AppDatabase db, $PendingEditsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingEditsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingEditsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingEditsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> documentId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
              }) => PendingEditsCompanion(
                id: id,
                documentId: documentId,
                field: field,
                value: value,
                queuedAt: queuedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int documentId,
                required String field,
                required String value,
                required DateTime queuedAt,
              }) => PendingEditsCompanion.insert(
                id: id,
                documentId: documentId,
                field: field,
                value: value,
                queuedAt: queuedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingEditsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingEditsTable,
      PendingEdit,
      $$PendingEditsTableFilterComposer,
      $$PendingEditsTableOrderingComposer,
      $$PendingEditsTableAnnotationComposer,
      $$PendingEditsTableCreateCompanionBuilder,
      $$PendingEditsTableUpdateCompanionBuilder,
      (
        PendingEdit,
        BaseReferences<_$AppDatabase, $PendingEditsTable, PendingEdit>,
      ),
      PendingEdit,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedDocumentsTableTableManager get cachedDocuments =>
      $$CachedDocumentsTableTableManager(_db, _db.cachedDocuments);
  $$CachedTagsTableTableManager get cachedTags =>
      $$CachedTagsTableTableManager(_db, _db.cachedTags);
  $$CachedCorrespondentsTableTableManager get cachedCorrespondents =>
      $$CachedCorrespondentsTableTableManager(_db, _db.cachedCorrespondents);
  $$CachedDocumentTypesTableTableManager get cachedDocumentTypes =>
      $$CachedDocumentTypesTableTableManager(_db, _db.cachedDocumentTypes);
  $$CachedStoragePathsTableTableManager get cachedStoragePaths =>
      $$CachedStoragePathsTableTableManager(_db, _db.cachedStoragePaths);
  $$CachedSavedViewsTableTableManager get cachedSavedViews =>
      $$CachedSavedViewsTableTableManager(_db, _db.cachedSavedViews);
  $$CachedCustomFieldsTableTableManager get cachedCustomFields =>
      $$CachedCustomFieldsTableTableManager(_db, _db.cachedCustomFields);
  $$CachedWorkflowsTableTableManager get cachedWorkflows =>
      $$CachedWorkflowsTableTableManager(_db, _db.cachedWorkflows);
  $$PendingUploadsTableTableManager get pendingUploads =>
      $$PendingUploadsTableTableManager(_db, _db.pendingUploads);
  $$AiEditsTableTableManager get aiEdits =>
      $$AiEditsTableTableManager(_db, _db.aiEdits);
  $$LockedDocumentsTableTableManager get lockedDocuments =>
      $$LockedDocumentsTableTableManager(_db, _db.lockedDocuments);
  $$DocumentTemplatesTableTableManager get documentTemplates =>
      $$DocumentTemplatesTableTableManager(_db, _db.documentTemplates);
  $$PendingEditsTableTableManager get pendingEdits =>
      $$PendingEditsTableTableManager(_db, _db.pendingEdits);
}
