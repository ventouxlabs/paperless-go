import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/models/ai_suggestions.dart';
import '../../../core/models/correspondent.dart';
import '../../../core/models/document.dart';
import '../../../core/models/document_type.dart';
import '../../../core/models/storage_path.dart';
import '../../../core/models/tag.dart';
import '../document_detail_notifier.dart';
import 'ai_suggestions_error.dart';
import 'ai_suggestions_prefill.dart';

part 'ai_suggestions_notifier.g.dart';

/// Where one "Suggest with AI" request is.
sealed class AiSuggestionsState {
  const AiSuggestionsState();
}

/// Nothing asked yet, or the user cancelled.
final class AiSuggestionsIdle extends AiSuggestionsState {
  const AiSuggestionsIdle();
}

final class AiSuggestionsLoading extends AiSuggestionsState {
  const AiSuggestionsLoading();
}

final class AiSuggestionsSuccess extends AiSuggestionsState {
  const AiSuggestionsSuccess({required this.document, required this.prefill});

  /// The document as re-read after the AI answered. The prefill was built on
  /// it, and a save must diff against it.
  final Document document;
  final AiSuggestionsPrefill prefill;
}

final class AiSuggestionsFailure extends AiSuggestionsState {
  const AiSuggestionsFailure(this.kind, {this.cause});

  final AiSuggestionsErrorKind kind;

  /// The underlying error, for [AiSuggestionsErrorKind.other]'s app-wide
  /// message. Never shown raw.
  final Object? cause;
}

typedef _Library = ({
  Map<int, Tag> tags,
  Map<int, Correspondent> correspondents,
  Map<int, DocumentType> documentTypes,
  Map<int, StoragePath> storagePaths,
});

/// One document's native AI suggestions request.
///
/// Never fetches on its own: every call is a paid model call and the server
/// has no rate limit, so only [request] (an explicit tap) asks. The request is
/// cancelled when the last listener goes away (auto-dispose), e.g. when the
/// progress dialog closes.
@riverpod
class AiSuggestionsController extends _$AiSuggestionsController {
  CancelToken? _cancelToken;

  @override
  AiSuggestionsState build(int documentId) {
    ref.onDispose(() => _cancelToken?.cancel());
    return const AiSuggestionsIdle();
  }

  /// [snapshot] is the document as the screen showed it; it is only used if
  /// re-reading the document after the AI answers fails.
  Future<void> request(Document snapshot) async {
    if (state is AiSuggestionsLoading) return;
    // A cancelled token stays cancelled: one per request. Once it's cancelled
    // (cancel() or dispose) this request must not touch state again.
    final token = CancelToken();
    _cancelToken = token;
    state = const AiSuggestionsLoading();

    // The app's lists first and apart from the AI: if they can't load, the
    // error isn't the AI's and no model call is made.
    final _Library? library;
    try {
      library = await _loadLibrary(token);
    } on Exception catch (e) {
      if (token.isCancelled) return;
      _forgetFailedLists();
      state = AiSuggestionsFailure(_libraryFailureKind(e), cause: e);
      return;
    }
    if (library == null || token.isCancelled) return;

    final suggestions = await _ask(token);
    if (suggestions == null || token.isCancelled) return;

    final document = await _freshDocument(snapshot);
    if (token.isCancelled) return;
    _refreshScreenIfStale(snapshot, document);
    final resolved = await _reloadForUnknownIds(library, suggestions, token);
    if (token.isCancelled) return;

    state = AiSuggestionsSuccess(
      document: document,
      prefill: buildAiSuggestionsPrefill(
        document: document,
        suggestions: suggestions,
        tags: resolved.tags,
        correspondents: resolved.correspondents,
        documentTypes: resolved.documentTypes,
        storagePaths: resolved.storagePaths,
      ),
    );
  }

  void cancel() {
    _cancelToken?.cancel();
    if (state is AiSuggestionsLoading) state = const AiSuggestionsIdle();
  }

  /// The lists are keepAlive: one that failed would keep failing from its
  /// cache, so "try again" could never work. Drop the failed ones; the next
  /// tap (or whoever watches them) fetches them again.
  void _forgetFailedLists() {
    if (ref.read(tagsProvider).hasError) ref.invalidate(tagsProvider);
    if (ref.read(correspondentsProvider).hasError) {
      ref.invalidate(correspondentsProvider);
    }
    if (ref.read(documentTypesProvider).hasError) {
      ref.invalidate(documentTypesProvider);
    }
  }

  static AiSuggestionsErrorKind _libraryFailureKind(Exception e) =>
      switch (e is DioException ? e.response?.statusCode : null) {
        403 => AiSuggestionsErrorKind.libraryForbidden,
        401 => AiSuggestionsErrorKind.other, // the app's "sign in again"
        _ => AiSuggestionsErrorKind.libraryUnavailable,
      };

  /// The model call. Null when it failed (state already says why) or was
  /// cancelled.
  Future<AiSuggestions?> _ask(CancelToken token) async {
    try {
      return await ref
          .read(paperlessApiProvider)
          .getAiSuggestions(documentId, cancelToken: token);
    } on DioException catch (e) {
      if (token.isCancelled) return null;
      final kind = aiSuggestionsErrorKind(e);
      state = kind == null
          ? const AiSuggestionsIdle()
          : AiSuggestionsFailure(kind, cause: e);
      return null;
    }
  }

  /// Null when cancelled meanwhile. Storage paths are info only, so a failure
  /// there (e.g. no permission to view them) just means "none".
  Future<_Library?> _loadLibrary(CancelToken token) async {
    final tags = await ref.read(tagsProvider.future);
    if (token.isCancelled) return null;
    final correspondents = await ref.read(correspondentsProvider.future);
    if (token.isCancelled) return null;
    final documentTypes = await ref.read(documentTypesProvider.future);
    if (token.isCancelled) return null;
    Map<int, StoragePath> storagePaths;
    try {
      storagePaths = await ref.read(storagePathsProvider.future);
    } on Exception catch (e) {
      debugPrint('AI suggestions: storage paths unavailable '
          '(${e.runtimeType}); showing none.');
      storagePaths = const {};
    }
    if (token.isCancelled) return null;
    return (
      tags: tags,
      correspondents: correspondents,
      documentTypes: documentTypes,
      storagePaths: storagePaths,
    );
  }

  /// The screen shows [snapshot]. Only if the server's copy moved on, have the
  /// open screen re-read it too, so it's never older than the sheet. Never
  /// creates the screen's provider (invalidating a missing one would).
  void _refreshScreenIfStale(Document snapshot, Document fresh) {
    final screen = documentDetailProvider(documentId);
    if (fresh != snapshot && ref.exists(screen)) ref.invalidate(screen);
  }

  /// The model can take minutes; someone may have edited the document
  /// meanwhile. The unset-only rule and the save's base must see that edit.
  /// If the re-read fails, the AI's (paid) answer is kept on [snapshot].
  Future<Document> _freshDocument(Document snapshot) async {
    try {
      return await ref.read(paperlessApiProvider).getDocument(documentId);
    } on DioException catch (e) {
      debugPrint('AI suggestions: re-reading the document failed '
          '(${e.type.name}); using the copy on screen.');
      return snapshot;
    }
  }

  /// A suggested ID the app doesn't know usually means its list was loaded
  /// before the object was created: re-load THAT list, once.
  Future<_Library> _reloadForUnknownIds(
    _Library library,
    AiSuggestions s,
    CancelToken token,
  ) async =>
      (
        tags: await _reloadIfUnknown(
            library.tags, s.tagIds, tagsProvider.future, token),
        correspondents: await _reloadIfUnknown(library.correspondents,
            s.correspondentIds, correspondentsProvider.future, token),
        documentTypes: await _reloadIfUnknown(library.documentTypes,
            s.documentTypeIds, documentTypesProvider.future, token),
        storagePaths: await _reloadIfUnknown(library.storagePaths,
            s.storagePathIds, storagePathsProvider.future, token),
      );

  Future<Map<int, T>> _reloadIfUnknown<T>(
    Map<int, T> current,
    List<int> suggestedIds,
    Refreshable<Future<Map<int, T>>> list,
    CancelToken token,
  ) async {
    if (token.isCancelled || suggestedIds.every(current.containsKey)) {
      return current;
    }
    try {
      return await ref.refresh(list);
    } on Exception catch (e) {
      debugPrint('AI suggestions: re-loading a list failed '
          '(${e.runtimeType}); unknown IDs stay unknown.');
      return current;
    }
  }
}
