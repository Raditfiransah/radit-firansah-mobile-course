import 'package:flutter/foundation.dart';
import 'local/post.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';

// 1. Logika Sinkronisasi Catatan Kotor (Dirty)
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();
  if (dirtyCount == 0) return 0;
  // Simulasi upload: pada project nyata, kirim tiap catatan dirty
  // ke REST API di sini, lalu tandai bersih bila server menjawab 2xx.
  await Future.delayed(const Duration(seconds: 1));
  await repo.markAllSynced();
  return dirtyCount;
}

// 2. Logika Cache-First Read & Refresh Background untuk Posts
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
