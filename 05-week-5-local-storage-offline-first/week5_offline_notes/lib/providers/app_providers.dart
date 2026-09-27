import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/note.dart';
import '../data/local/post.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/post_repository.dart';
import '../data/sync.dart';

// Repository Providers
final noteRepositoryProvider = Provider((ref) => NoteRepository());
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

// Provider untuk List Notes
final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() {
    final repo = ref.watch(noteRepositoryProvider);
    return repo.fetchNotes();
  }

  Future<void> addNote({required String title, String body = ''}) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.addNote(title: title, body: body);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(int id) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.deleteNote(id);
    ref.invalidateSelf();
  }

  // 2. Sinkronisasi catatan kotor (dirty) via sync.dart
  Future<int> sync() async {
    final repo = ref.read(noteRepositoryProvider);
    final count = await syncNotes(repo);
    ref.invalidateSelf();
    return count;
  }
}

// Provider untuk menghitung jumlah dirty notes
final dirtyCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notesProvider);
  final repo = ref.read(noteRepositoryProvider);
  return repo.countDirty();
});

// Provider detail catatan membaca langsung dari repository lokal
final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final repo = ref.read(noteRepositoryProvider);
  return repo.fetchNoteById(id);
});
