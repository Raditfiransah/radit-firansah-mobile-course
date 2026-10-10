import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/posts_providers.dart';

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(postsProvider.notifier).refresh(),
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

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${post.id}')),
                title: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
