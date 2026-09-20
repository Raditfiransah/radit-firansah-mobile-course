import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../paged_posts.dart';
import '../providers.dart';

class PagedPostPage extends ConsumerStatefulWidget {
  const PagedPostPage({super.key});

  @override
  ConsumerState<PagedPostPage> createState() => _PagedPostPageState();
}

class _PagedPostPageState extends ConsumerState<PagedPostPage> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >=
          _controller.position.maxScrollExtent - 200) {
        ref.read(pagedPostsProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagedPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts REST API'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Builder(
        builder: (context) {
          // 1. State Loading (Initial)
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. State Error
          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      friendlyErrorMessage(state.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(pagedPostsProvider.notifier)
                          .loadFirstPage(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. State Empty
          if (state.items.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data postingan.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // 4. State Success + Infinite Scrolling (10 per page)
          return ListView.builder(
            controller: _controller,
            itemCount: state.items.length + 1,
            itemBuilder: (context, index) {
              if (index == state.items.length) {
                if (!state.hasMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Semua data termuat.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final post = state.items[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${post.id}')),
                title: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
    );
  }
}