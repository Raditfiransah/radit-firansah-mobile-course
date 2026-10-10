import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/post.dart';
import '../data/repositories/post_repository.dart';
import '../data/sync.dart';

// Repository Providers
final postRepositoryProvider = Provider((ref) => PostRepository());

// 3. Simulasi offline deterministik (Toggle forceOffline pada provider)
final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void setOffline(bool value) => state = value;
}

// 1. Cache-first read untuk data API (GET /posts) dipindahkan ke sync.dart
final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<Post>>(PostsNotifier.new);

class PostsNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repo = ref.watch(postRepositoryProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return loadPostsCacheFirst(
      repo,
      forceOffline: isOffline,
      onBackgroundUpdated: () {
        ref.invalidateSelf();
      },
    );
  }

  Future<void> refresh() async {
    final repo = ref.read(postRepositoryProvider);
    final isOffline = ref.read(forceOfflineProvider);

    if (isOffline) {
      state = AsyncValue.data(await repo.readCachedPosts());
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await repo.fetchFromApi();
      await repo.savePostsToCache(fresh);
      return fresh;
    });
  }
}
