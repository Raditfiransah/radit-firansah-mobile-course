import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/failures.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/repositories/note_repository.dart';
import 'package:week5_offline_notes/features/notes/presentation/pages/notes_page.dart';
import 'package:week5_offline_notes/features/notes/presentation/providers/notes_providers.dart';

class _FakeNoteRepository implements NoteRepository {
  _FakeNoteRepository(this.notes);

  final List<Note> notes;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async =>
      (notes: notes, failure: null);

  @override
  Future<({Note? note, Failure? failure})> fetchNoteById(int id) async =>
      (note: null, failure: null);

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (note: null, failure: null);

  @override
  Future<Failure?> deleteNote(int id) async => null;

  @override
  Future<({int count, Failure? failure})> countDirty() async =>
      (count: 0, failure: null);

  @override
  Future<Failure?> markAllSynced() async => null;
}

Widget _wrap(NoteRepository repository) {
  return ProviderScope(
    overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: Scaffold(body: NotesPage())),
  );
}

void main() {
  final notes = [
    Note(id: 1, title: 'Belanja mingguan', updatedAt: DateTime(2026, 10, 28)),
    Note(id: 2, title: 'Rapat proyek', updatedAt: DateTime(2026, 10, 28)),
  ];

  testWidgets('pencarian tanpa hasil menampilkan empty state', (tester) async {
    await tester.pumpWidget(_wrap(_FakeNoteRepository(notes)));
    await tester.pumpAndSettle();

    expect(find.text('Belanja mingguan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz-tidak-ada');
    await tester.pump();

    expect(
      find.text('Tidak ada catatan yang cocok dengan "zzz-tidak-ada".'),
      findsOneWidget,
    );
    expect(find.text('Belanja mingguan'), findsNothing);
  });

  testWidgets('pencarian judul mengabaikan huruf besar/kecil', (tester) async {
    await tester.pumpWidget(_wrap(_FakeNoteRepository(notes)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'BELANJA');
    await tester.pump();

    expect(find.text('Belanja mingguan'), findsOneWidget);
    expect(find.text('Rapat proyek'), findsNothing);
  });
}
