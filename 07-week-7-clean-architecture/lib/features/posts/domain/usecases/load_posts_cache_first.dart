import '../../../../core/failures.dart';
import '../entities/post.dart';
import '../repositories/post_repository.dart';

class LoadPostsCacheFirst {
  const LoadPostsCacheFirst(this._repository);
  final PostRepository _repository;

  /// Baca cache segera, lalu (bila online) refresh dari API di background.
  Future<({List<Post> posts, Failure? failure})> call({
    bool forceOffline = false,
    void Function()? onBackgroundUpdated,
  }) async {
    final cached = await _repository.readCachedPosts();
    if (!forceOffline && onBackgroundUpdated != null) {
      _refreshInBackground(onBackgroundUpdated);
    }
    return cached;
  }

  void _refreshInBackground(void Function() onDone) {
    Future(() async {
      final fresh = await _repository.fetchFromApi();
      if (fresh.failure != null) return;
      final saveFailure = await _repository.savePostsToCache(fresh.posts);
      if (saveFailure == null) onDone();
    });
  }
}
