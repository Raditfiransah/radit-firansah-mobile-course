import 'package:flutter/foundation.dart';
import 'local/post.dart';
import 'repositories/post_repository.dart';

// Logika Cache-First Read & Refresh Background untuk Posts
Future<List<Post>> loadPostsCacheFirst(
  PostRepository repo, {
  bool forceOffline = false,
  VoidCallback? onBackgroundUpdated,
}) async {
  final cached = await repo.readCachedPosts(); // dari tabel cached_posts
  // 1. Segera kembalikan cache agar UI tidak blank saat offline.
  // 2. Di background: fetch Dio -> simpan ke cached_posts -> invalidate provider.
  if (!forceOffline && onBackgroundUpdated != null) {
    refreshPostsInBackground(repo, onBackgroundUpdated);
  }
  return cached;
}

// Background refresh posts
void refreshPostsInBackground(PostRepository repo, VoidCallback onDone) {
  Future(() async {
    try {
      final posts = await repo.fetchFromApi();
      await repo.savePostsToCache(posts);
      onDone();
    } catch (e) {
      debugPrint('Background refresh posts error: $e');
    }
  });
}
