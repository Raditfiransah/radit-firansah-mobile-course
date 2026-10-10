import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/db.dart';
import '../../../../shared/providers.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/load_posts_cache_first.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(openNotesDb);
});

final loadPostsCacheFirstProvider = Provider<LoadPostsCacheFirst>((ref) {
  return LoadPostsCacheFirst(ref.watch(postRepositoryProvider));
});

final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<Post>>(PostsNotifier.new);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final isOffline = ref.watch(forceOfflineProvider);
    final result = await ref.watch(loadPostsCacheFirstProvider).call(
          forceOffline: isOffline,
          onBackgroundUpdated: () => ref.invalidateSelf(),
        );
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    return result.posts;
  }

  Future<void> refresh() async {
    final repo = ref.read(postRepositoryProvider);
    final isOffline = ref.read(forceOfflineProvider);

    if (isOffline) {
      final cached = await repo.readCachedPosts();
      state = AsyncValue.data(cached.posts);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await repo.fetchFromApi();
      if (fresh.failure != null) {
        throw Exception(fresh.failure!.message);
      }
      await repo.savePostsToCache(fresh.posts);
      return fresh.posts;
    });
  }
}
