import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/document.dart';
import '../../core/api/api_error_mapper.dart';

part 'trash_notifier.g.dart';

class TrashState {
  final List<Document> documents;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? loadMoreError;

  const TrashState({
    this.documents = const [],
    this.totalCount = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.loadMoreError,
  });

  TrashState copyWith({
    List<Document>? documents,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) {
    return TrashState(
      documents: documents ?? this.documents,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

@riverpod
class TrashNotifier extends _$TrashNotifier {
  static const _pageSize = 25;

  @override
  Future<TrashState> build() async {
    // Watched so a build that races the session restore rebuilds once auth
    // lands, instead of sticking in NotAuthenticatedException (see
    // DocumentsNotifier.build).
    ref.watch(paperlessApiProvider);
    return _fetchPage(1);
  }

  Future<TrashState> _fetchPage(int page) async {
    final api = ref.read(paperlessApiProvider);
    final response = await api.getTrashedDocuments(
      page: page,
      pageSize: _pageSize,
    );
    return TrashState(
      documents: response.results,
      totalCount: response.count,
      hasMore: response.next != null,
      currentPage: page,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    final loadingState = current.copyWith(isLoadingMore: true);
    state = AsyncData(loadingState);

    try {
      final api = ref.read(paperlessApiProvider);
      final nextPage = current.currentPage + 1;
      final response = await api.getTrashedDocuments(
        page: nextPage,
        pageSize: _pageSize,
      );

      // A concurrent refresh replaced the list while this page was in flight —
      // discard the stale page instead of appending to a fresh list.
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1));
  }

  Future<bool> restoreDocuments(List<int> ids) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.restoreFromTrash(ids);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> permanentlyDelete(List<int> ids) async {
    try {
      final api = ref.read(paperlessApiProvider);
      await api.emptyTrash(ids);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}
