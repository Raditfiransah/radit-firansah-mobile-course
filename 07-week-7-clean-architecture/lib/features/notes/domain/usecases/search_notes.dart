import '../entities/note.dart';

class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return notes;
    return notes
        .where((note) => note.title.toLowerCase().contains(normalized))
        .toList();
  }
}
