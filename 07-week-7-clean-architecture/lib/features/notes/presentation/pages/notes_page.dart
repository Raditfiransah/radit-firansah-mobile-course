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
    final query = ref.watch(searchQueryProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari judul catatan…',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) =>
                ref.read(searchQueryProvider.notifier).state = value,
          ),
        ),
        Expanded(
          child: notesAsync.when(
            data: (notes) {
              if (notes.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada catatan. Tekan tombol + untuk menambah.',
                  ),
                );
              }

              final filtered = ref
                  .watch(searchNotesProvider)
                  .call(notes, query);
              if (filtered.isEmpty) {
                return Center(
                  child: Text('Tidak ada catatan yang cocok dengan "$query".'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final note = filtered[index];
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
          ),
        ),
      ],
    );
  }
}
