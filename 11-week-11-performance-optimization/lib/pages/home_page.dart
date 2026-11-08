import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/post.dart';
import '../providers/app_providers.dart';
import '../widgets/note_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(forceOfflineProvider);
    final dirtyCount = ref.watch(
      dirtyCountProvider.select((v) => v.value ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline-First Demo'),
        actions: [
          // 3. Toggle forceOffline pada provider
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilterChip(
              avatar: Icon(
                isOffline ? Icons.wifi_off : Icons.wifi,
                size: 16,
                color: isOffline ? Colors.red : Colors.green,
              ),
              label: Text(
                isOffline ? 'Offline' : 'Online',
                style: TextStyle(
                  color: isOffline ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isOffline,
              onSelected: (val) {
                ref.read(forceOfflineProvider.notifier).setOffline(val);
              },
            ),
          ),
          const SizedBox(width: 4),

          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Tanya AI',
            onPressed: () {
              context.push('/chat');
            },
          ),

          // 2. Tombol Sinkronisasi dengan Badge Dirty
          Badge(
            isLabelVisible: dirtyCount > 0,
            label: Text('$dirtyCount'),
            backgroundColor: Colors.amber[900],
            child: IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync Notes',
              onPressed: () => _performSync(context),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: _tabIndex == 0 ? const _NotesView() : const _PostsView(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: dirtyCount > 0,
              label: Text('$dirtyCount'),
              child: const Icon(Icons.edit_note),
            ),
            label: 'Catatan (Sync)',
          ),
          const NavigationDestination(
            icon: Icon(Icons.cloud_download),
            label: 'Posts (Cache-First)',
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _performSync(BuildContext context) async {
    final isOffline = ref.read(forceOfflineProvider);
    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat sync saat forceOffline aktif!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final count = await ref.read(notesProvider.notifier).sync();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? '$count catatan berhasil disinkronkan!'
              : 'Semua catatan sudah bersih (0 dirty).',
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catatan Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(
                labelText: 'Isi Catatan',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              if (title.isNotEmpty) {
                ref
                    .read(notesProvider.notifier)
                    .addNote(title: title, body: bodyCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// View 1: Catatan Lokal menggunakan NoteTile & Navigasi Detail GoRouter
// -----------------------------------------------------------------------------
class _NotesView extends ConsumerWidget {
  const _NotesView();

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
            return RepaintBoundary(
              child: NoteTile(
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
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// -----------------------------------------------------------------------------
// View 2: Cache-First Read API Posts (GET /posts JSONPlaceholder)
// Pagination: hanya 10 item pertama yang dibangun, sisanya menyusul saat scroll.
// -----------------------------------------------------------------------------
class _PostsView extends ConsumerStatefulWidget {
  const _PostsView();

  @override
  ConsumerState<_PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends ConsumerState<_PostsView> {
  static const _pageSize = 10;

  final _scrollController = ScrollController();
  var _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreOnScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMoreOnScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = ref.read(postsProvider).value?.length ?? 0;
    if (_visibleCount >= total) return;
    setState(() => _visibleCount += _pageSize);
  }

  Future<void> _refresh() async {
    setState(() => _visibleCount = _pageSize);
    await ref.read(postsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Data cache kosong.\nPastikan mode online aktif lalu tarik ke bawah untuk refresh.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final visible = posts.take(_visibleCount).toList();

          return ListView.builder(
            controller: _scrollController,
            itemCount: visible.length,
            itemBuilder: (context, index) => RepaintBoundary(
              child: _PostTile(post: visible[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${post.id}')),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
