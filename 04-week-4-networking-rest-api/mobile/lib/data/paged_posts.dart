import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/post.dart';
import 'providers.dart';

class PagedPostsState {
  const PagedPostsState({
    this.items = const [],
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
}

class PagedPostsNotifier extends Notifier<PagedPostsState> {
  @override
  PagedPostsState build() {
    Future.microtask(loadFirstPage);
    return const PagedPostsState(isLoading: true);
  }

  Future<void> loadFirstPage() async {
    state = const PagedPostsState(isLoading: true);
    final repository = ref.read(postRepositoryProvider);
    try {
      final items = await repository.fetchPostsPage(page: 1, limit: 10);
      state = PagedPostsState(
        items: items,
        page: 1,
        isLoading: false,
        hasMore: items.length == 10,
      );
    } catch (e) {
      state = PagedPostsState(
        isLoading: false,
        error: e,
      );
    }
  }

  Future<void> loadNextPage() async {
    // Guard request ganda & cek apakah masih ada data
    if (state.isLoadingMore || state.isLoading || !state.hasMore) return;

    final repo = ref.read(postRepositoryProvider);
    final currentItems = state.items;
    final currentPage = state.page;
    state = PagedPostsState(
      items: currentItems,
      page: currentPage,
      isLoadingMore: true,
      hasMore: state.hasMore,
    );
    try {
      final next = currentPage + 1;
      final items = await repo.fetchPostsPage(page: next, limit: 10);
      state = PagedPostsState(
        items: [...currentItems, ...items],
        page: next,
        isLoadingMore: false,
        hasMore: items.length == 10,
      );
    } catch (e) {
      state = PagedPostsState(
        items: currentItems,
        page: currentPage,
        isLoadingMore: false,
        error: e,
      );
    }
  }
}

final pagedPostsProvider =
    NotifierProvider<PagedPostsNotifier, PagedPostsState>(
  PagedPostsNotifier.new,
);
