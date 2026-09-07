import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../../core/api/api_error_mapper.dart';

part 'documents_notifier.g.dart';

class DocumentsFilter {
  final String? query;
  final String ordering;
  final List<int>? tagIds;
  final int? correspondentId;
  final int? documentTypeId;
  final DateTime? createdDateFrom;
  final DateTime? createdDateTo;

  const DocumentsFilter({
    this.query,
    this.ordering = '-created',
    this.tagIds,
    this.correspondentId,
    this.documentTypeId,
    this.createdDateFrom,
    this.createdDateTo,
  });

  DocumentsFilter copyWith({
    String? query,
    String? ordering,
    List<int>? tagIds,
    int? correspondentId,
    int? documentTypeId,
    DateTime? createdDateFrom,
    DateTime? createdDateTo,
    bool clearQuery = false,
    bool clearCorrespondent = false,
    bool clearDocumentType = false,
    bool clearTags = false,
    bool clearDateRange = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return DocumentsFilter(
      query: clearQuery ? null : (query ?? this.query),
      ordering: ordering ?? this.ordering,
      tagIds: clearTags ? null : (tagIds ?? this.tagIds),
      correspondentId: clearCorrespondent ? null : (correspondentId ?? this.correspondentId),
      documentTypeId: clearDocumentType ? null : (documentTypeId ?? this.documentTypeId),
      createdDateFrom: (clearDateRange || clearDateFrom) ? null : (createdDateFrom ?? this.createdDateFrom),
      createdDateTo: (clearDateRange || clearDateTo) ? null : (createdDateTo ?? this.createdDateTo),
    );
  }
}

class DocumentsState {
  final List<Document> documents;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final DocumentsFilter filter;
  final String? loadMoreError;

  const DocumentsState({
    this.documents = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.filter = const DocumentsFilter(),
    this.loadMoreError,
  });

  DocumentsState copyWith({
    List<Document>? documents,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    DocumentsFilter? filter,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filter: filter ?? this.filter,
      loadMoreError: clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

@riverpod
class DocumentsNotifier extends _$DocumentsNotifier {
  static const _pageSize = 25;

  @override
  Future<DocumentsState> build() async {
    // Watched, not read: on a cold start this builds while the session is
    // still being restored from the keystore, and the client provider throws
    // NotAuthenticatedException until it lands. A read would leave this
    // notifier in that error for good; a watch rebuilds it once auth resolves.
    ref.watch(paperlessApiProvider);
    return _fetchPage(1, const DocumentsFilter());
  }

  Future<DocumentsState> _fetchPage(int page, DocumentsFilter filter) async {
    final api = ref.read(paperlessApiProvider);
    final response = await api.getDocuments(
      page: page,
      pageSize: _pageSize,
      query: filter.query,
      ordering: filter.ordering,
      tagIds: filter.tagIds,
      correspondentId: filter.correspondentId,
      documentTypeId: filter.documentTypeId,
      createdDateFrom: filter.createdDateFrom,
      createdDateTo: filter.createdDateTo,
    );
    return DocumentsState(
      documents: response.results,
      totalCount: response.count,
      hasMore: response.next != null,
      currentPage: page,
      filter: filter,
    );
  }

  Future<void> applyFilter(DocumentsFilter filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1, filter));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    final loadingState = current.copyWith(isLoadingMore: true);
    state = AsyncData(loadingState);

    try {
      final api = ref.read(paperlessApiProvider);
      final nextPage = current.currentPage + 1;
      final response = await api.getDocuments(
        page: nextPage,
        pageSize: _pageSize,
        query: current.filter.query,
        ordering: current.filter.ordering,
        tagIds: current.filter.tagIds,
        correspondentId: current.filter.correspondentId,
        documentTypeId: current.filter.documentTypeId,
        createdDateFrom: current.filter.createdDateFrom,
        createdDateTo: current.filter.createdDateTo,
      );

      // A concurrent refresh/applyFilter replaced the list while this page was
      // in flight — discard the stale page instead of appending to a new filter.
      // identical() relies on AsyncData(x).valueOrNull returning the same
      // instance; do NOT weaken to == (a refresh yields an equal-by-value state
      // and the guard would stop firing).
      if (!identical(state.valueOrNull, loadingState)) return;
      state = AsyncData(loadingState.copyWith(
        documents: [...loadingState.documents, ...response.results],
        isLoadingMore: false,
        hasMore: response.next != null,
        currentPage: nextPage,
      ));
    } catch (e) {
      if (!identical(state.valueOrNull, loadingState)) return;
      state = AsyncData(loadingState.copyWith(
        isLoadingMore: false,
        loadMoreError: 'Failed to load more: ${friendlyApiMessage(e)}',
      ));
    }
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.filter ?? const DocumentsFilter();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1, filter));
  }
}
