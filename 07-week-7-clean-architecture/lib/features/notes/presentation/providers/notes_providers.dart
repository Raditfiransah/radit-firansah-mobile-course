import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/local/db.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/sync_notes.dart';

// Data layer: database opener disuntikkan (mudah diganti fake saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final syncNotesProvider = Provider<SyncNotes>((ref) {
  return SyncNotes(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI (AsyncNotifier agar bisa mutasi)
final notesProvider =
    AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final result = await ref.watch(getNotesProvider).call();
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    return result.notes;
  }

  Future<void> addNote({required String title, String body = ''}) async {
    final result =
        await ref.read(noteRepositoryProvider).addNote(title: title, body: body);
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    ref.invalidateSelf();
  }

  Future<void> deleteNote(int id) async {
    final failure = await ref.read(noteRepositoryProvider).deleteNote(id);
    if (failure != null) {
      throw Exception(failure.message);
    }
    ref.invalidateSelf();
  }

  Future<int> sync() async {
    final result = await ref.read(syncNotesProvider).call();
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    ref.invalidateSelf();
    return result.synced;
  }
}

final dirtyCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notesProvider);
  final result = await ref.read(noteRepositoryProvider).countDirty();
  return result.count;
});

final noteDetailProvider = FutureProvider.family<Note?, int>((ref, id) async {
  final result = await ref.read(noteRepositoryProvider).fetchNoteById(id);
  return result.note;
});
