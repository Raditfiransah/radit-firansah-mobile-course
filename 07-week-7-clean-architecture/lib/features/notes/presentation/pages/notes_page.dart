import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const Center(
            child: Text('Belum ada catatan. Tekan tombol + untuk menambah.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return NoteTile(
              note: note,
              onTap: () {
                if (note.id != null) {
                  context.push('/note/${note.id}');
                }
              },
              onDelete: () {
                if (note.id != null) {
                  ref.read(notesProvider.notifier).deleteNote(note.id!);
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
