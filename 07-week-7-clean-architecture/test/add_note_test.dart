import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/add_note.dart';

class _FakeNoteRepository implements NoteRepository {
  final List<({String title, String body})> saved = [];

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    saved.add((title: title, body: body));
    return (
      note: Note(
        id: saved.length,
        title: title,
        body: body,
        updatedAt: DateTime(2026, 10, 28),
        dirty: true,
      ),
      failure: null,
    );
  }

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: const <Note>[], failure: null);

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) async =>
      (note: null, failure: null);

  @override
  Future<Failure?> deleteNote(int id) async => null;

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  Future<Failure?> markAllSynced() async => null;
}

void main() {
  test('AddNote menolak judul kosong tanpa menyentuh repository', () async {
    final repo = _FakeNoteRepository();
    final result = await AddNote(repo).call(title: '   ');

    expect(result.failure, isA<ValidationFailure>());
    expect(result.note, isNull);
    expect(repo.saved, isEmpty);
  });

  test('AddNote menyimpan judul yang sudah di-trim', () async {
    final repo = _FakeNoteRepository();
    final result = await AddNote(repo).call(title: '  Beli kopi  ', body: '2x');

    expect(result.failure, isNull);
    expect(result.note?.title, 'Beli kopi');
    expect(repo.saved.single.title, 'Beli kopi');
    expect(repo.saved.single.body, '2x');
  });
}
