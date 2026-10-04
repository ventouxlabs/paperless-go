// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_suggestions_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$aiSuggestionsControllerHash() =>
    r'c3f6bca3b7cbfbe4d81c8354a7ce0a84e644e668';

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

abstract class _$AiSuggestionsController
    extends BuildlessAutoDisposeNotifier<AiSuggestionsState> {
  late final int documentId;

  AiSuggestionsState build(int documentId);
}

/// One document's native AI suggestions request.
///
/// Never fetches on its own: every call is a paid model call and the server
/// has no rate limit, so only [request] (an explicit tap) asks. The request is
/// cancelled when the last listener goes away (auto-dispose), e.g. when the
/// progress dialog closes.
///
/// Copied from [AiSuggestionsController].
@ProviderFor(AiSuggestionsController)
const aiSuggestionsControllerProvider = AiSuggestionsControllerFamily();

/// One document's native AI suggestions request.
///
/// Never fetches on its own: every call is a paid model call and the server
/// has no rate limit, so only [request] (an explicit tap) asks. The request is
/// cancelled when the last listener goes away (auto-dispose), e.g. when the
/// progress dialog closes.
///
/// Copied from [AiSuggestionsController].
class AiSuggestionsControllerFamily extends Family<AiSuggestionsState> {
  /// One document's native AI suggestions request.
  ///
  /// Never fetches on its own: every call is a paid model call and the server
  /// has no rate limit, so only [request] (an explicit tap) asks. The request is
  /// cancelled when the last listener goes away (auto-dispose), e.g. when the
  /// progress dialog closes.
  ///
  /// Copied from [AiSuggestionsController].
  const AiSuggestionsControllerFamily();

  /// One document's native AI suggestions request.
  ///
  /// Never fetches on its own: every call is a paid model call and the server
  /// has no rate limit, so only [request] (an explicit tap) asks. The request is
  /// cancelled when the last listener goes away (auto-dispose), e.g. when the
  /// progress dialog closes.
  ///
  /// Copied from [AiSuggestionsController].
  AiSuggestionsControllerProvider call(int documentId) {
    return AiSuggestionsControllerProvider(documentId);
  }

  @override
  AiSuggestionsControllerProvider getProviderOverride(
    covariant AiSuggestionsControllerProvider provider,
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
  String? get name => r'aiSuggestionsControllerProvider';
}

/// One document's native AI suggestions request.
///
/// Never fetches on its own: every call is a paid model call and the server
/// has no rate limit, so only [request] (an explicit tap) asks. The request is
/// cancelled when the last listener goes away (auto-dispose), e.g. when the
/// progress dialog closes.
///
/// Copied from [AiSuggestionsController].
class AiSuggestionsControllerProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AiSuggestionsController,
          AiSuggestionsState
        > {
  /// One document's native AI suggestions request.
  ///
  /// Never fetches on its own: every call is a paid model call and the server
  /// has no rate limit, so only [request] (an explicit tap) asks. The request is
  /// cancelled when the last listener goes away (auto-dispose), e.g. when the
  /// progress dialog closes.
  ///
  /// Copied from [AiSuggestionsController].
  AiSuggestionsControllerProvider(int documentId)
    : this._internal(
        () => AiSuggestionsController()..documentId = documentId,
        from: aiSuggestionsControllerProvider,
        name: r'aiSuggestionsControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$aiSuggestionsControllerHash,
        dependencies: AiSuggestionsControllerFamily._dependencies,
        allTransitiveDependencies:
            AiSuggestionsControllerFamily._allTransitiveDependencies,
        documentId: documentId,
      );

  AiSuggestionsControllerProvider._internal(
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
  AiSuggestionsState runNotifierBuild(
    covariant AiSuggestionsController notifier,
  ) {
    return notifier.build(documentId);
  }

  @override
  Override overrideWith(AiSuggestionsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: AiSuggestionsControllerProvider._internal(
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
  AutoDisposeNotifierProviderElement<
    AiSuggestionsController,
    AiSuggestionsState
  >
  createElement() {
    return _AiSuggestionsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AiSuggestionsControllerProvider &&
        other.documentId == documentId;
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
mixin AiSuggestionsControllerRef
    on AutoDisposeNotifierProviderRef<AiSuggestionsState> {
  /// The parameter `documentId` of this provider.
  int get documentId;
}

class _AiSuggestionsControllerProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AiSuggestionsController,
          AiSuggestionsState
        >
    with AiSuggestionsControllerRef {
  _AiSuggestionsControllerProviderElement(super.provider);

  @override
  int get documentId => (origin as AiSuggestionsControllerProvider).documentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
