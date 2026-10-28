import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/features/notes/domain/entities/note.dart';
import 'package:week5_offline_notes/features/notes/domain/usecases/search_notes.dart';

void main() {
  final notes = [
    Note(title: 'Belanja mingguan', updatedAt: DateTime(2026, 10, 28)),
    Note(title: 'belanja bulanan', updatedAt: DateTime(2026, 10, 28)),
    Note(title: 'Rapat proyek', updatedAt: DateTime(2026, 10, 28)),
  ];
  const search = SearchNotes();

  test('filter judul mengabaikan huruf besar/kecil', () {
    expect(search(notes, 'belanja'), hasLength(2));
  });

  test('query tidak cocok mengembalikan daftar kosong', () {
    expect(search(notes, 'zzz-tidak-ada'), isEmpty);
  });

  test('query kosong atau spasi mengembalikan semua catatan', () {
    expect(search(notes, ''), hasLength(3));
    expect(search(notes, '   '), hasLength(3));
  });
}
