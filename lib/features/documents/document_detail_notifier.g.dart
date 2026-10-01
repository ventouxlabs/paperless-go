// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_detail_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$documentDownloadHash() => r'95e39883275ee3cb179b446992826eb885a792c8';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [documentDownload].
@ProviderFor(documentDownload)
const documentDownloadProvider = DocumentDownloadFamily();

/// See also [documentDownload].
class DocumentDownloadFamily extends Family<AsyncValue<String>> {
  /// See also [documentDownload].
  const DocumentDownloadFamily();

  /// See also [documentDownload].
  DocumentDownloadProvider call(int documentId, String title) {
    return DocumentDownloadProvider(documentId, title);
  }

  @override
  DocumentDownloadProvider getProviderOverride(
    covariant DocumentDownloadProvider provider,
  ) {
    return call(provider.documentId, provider.title);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'documentDownloadProvider';
}

/// See also [documentDownload].
class DocumentDownloadProvider extends AutoDisposeFutureProvider<String> {
  /// See also [documentDownload].
  DocumentDownloadProvider(int documentId, String title)
    : this._internal(
        (ref) =>
            documentDownload(ref as DocumentDownloadRef, documentId, title),
        from: documentDownloadProvider,
        name: r'documentDownloadProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$documentDownloadHash,
        dependencies: DocumentDownloadFamily._dependencies,
        allTransitiveDependencies:
            DocumentDownloadFamily._allTransitiveDependencies,
        documentId: documentId,
        title: title,
      );

  DocumentDownloadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.documentId,
    required this.title,
  }) : super.internal();

  final int documentId;
  final String title;

  @override
  Override overrideWith(
    FutureOr<String> Function(DocumentDownloadRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DocumentDownloadProvider._internal(
        (ref) => create(ref as DocumentDownloadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        documentId: documentId,
        title: title,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _DocumentDownloadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentDownloadProvider &&
        other.documentId == documentId &&
        other.title == title;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, documentId.hashCode);
    hash = _SystemHash.combine(hash, title.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DocumentDownloadRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `documentId` of this provider.
  int get documentId;

  /// The parameter `title` of this provider.
  String get title;
}

class _DocumentDownloadProviderElement
    extends AutoDisposeFutureProviderElement<String>
    with DocumentDownloadRef {
  _DocumentDownloadProviderElement(super.provider);

  @override
  int get documentId => (origin as DocumentDownloadProvider).documentId;
  @override
  String get title => (origin as DocumentDownloadProvider).title;
}

String _$documentDetailHash() => r'd85c95b692234c742386e964bdf2f55746aa8c2f';

abstract class _$DocumentDetail
    extends BuildlessAutoDisposeAsyncNotifier<Document> {
  late final int id;

  FutureOr<Document> build(int id);
}

/// See also [DocumentDetail].
@ProviderFor(DocumentDetail)
const documentDetailProvider = DocumentDetailFamily();

/// See also [DocumentDetail].
class DocumentDetailFamily extends Family<AsyncValue<Document>> {
  /// See also [DocumentDetail].
  const DocumentDetailFamily();

  /// See also [DocumentDetail].
  DocumentDetailProvider call(int id) {
    return DocumentDetailProvider(id);
  }

  @override
  DocumentDetailProvider getProviderOverride(
    covariant DocumentDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'documentDetailProvider';
}

/// See also [DocumentDetail].
class DocumentDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<DocumentDetail, Document> {
  /// See also [DocumentDetail].
  DocumentDetailProvider(int id)
    : this._internal(
        () => DocumentDetail()..id = id,
        from: documentDetailProvider,
        name: r'documentDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$documentDetailHash,
        dependencies: DocumentDetailFamily._dependencies,
        allTransitiveDependencies:
            DocumentDetailFamily._allTransitiveDependencies,
        id: id,
      );

  DocumentDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final int id;

  @override
  FutureOr<Document> runNotifierBuild(covariant DocumentDetail notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(DocumentDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: DocumentDetailProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<DocumentDetail, Document>
  createElement() {
    return _DocumentDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DocumentDetailRef on AutoDisposeAsyncNotifierProviderRef<Document> {
  /// The parameter `id` of this provider.
  int get id;
}

class _DocumentDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DocumentDetail, Document>
    with DocumentDetailRef {
  _DocumentDetailProviderElement(super.provider);

  @override
  int get id => (origin as DocumentDetailProvider).id;
}

String _$documentNotesHash() => r'da7229186b7b970e965f04c3ddf34dfd5b4d8804';

abstract class _$DocumentNotes
    extends BuildlessAutoDisposeAsyncNotifier<List<Note>> {
  late final int documentId;

  FutureOr<List<Note>> build(int documentId);
}

/// See also [DocumentNotes].
@ProviderFor(DocumentNotes)
const documentNotesProvider = DocumentNotesFamily();

/// See also [DocumentNotes].
class DocumentNotesFamily extends Family<AsyncValue<List<Note>>> {
  /// See also [DocumentNotes].
  const DocumentNotesFamily();

  /// See also [DocumentNotes].
  DocumentNotesProvider call(int documentId) {
    return DocumentNotesProvider(documentId);
  }

  @override
  DocumentNotesProvider getProviderOverride(
    covariant DocumentNotesProvider provider,
  ) {
    return call(provider.documentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'documentNotesProvider';
}

/// See also [DocumentNotes].
class DocumentNotesProvider
    extends AutoDisposeAsyncNotifierProviderImpl<DocumentNotes, List<Note>> {
  /// See also [DocumentNotes].
  DocumentNotesProvider(int documentId)
    : this._internal(
        () => DocumentNotes()..documentId = documentId,
        from: documentNotesProvider,
        name: r'documentNotesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$documentNotesHash,
        dependencies: DocumentNotesFamily._dependencies,
        allTransitiveDependencies:
            DocumentNotesFamily._allTransitiveDependencies,
        documentId: documentId,
      );

  DocumentNotesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.documentId,
  }) : super.internal();

  final int documentId;

  @override
  FutureOr<List<Note>> runNotifierBuild(covariant DocumentNotes notifier) {
    return notifier.build(documentId);
  }

  @override
  Override overrideWith(DocumentNotes Function() create) {
    return ProviderOverride(
      origin: this,
      override: DocumentNotesProvider._internal(
        () => create()..documentId = documentId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        documentId: documentId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<DocumentNotes, List<Note>>
  createElement() {
    return _DocumentNotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentNotesProvider && other.documentId == documentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, documentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DocumentNotesRef on AutoDisposeAsyncNotifierProviderRef<List<Note>> {
  /// The parameter `documentId` of this provider.
  int get documentId;
}

class _DocumentNotesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<DocumentNotes, List<Note>>
    with DocumentNotesRef {
  _DocumentNotesProviderElement(super.provider);

  @override
  int get documentId => (origin as DocumentNotesProvider).documentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
