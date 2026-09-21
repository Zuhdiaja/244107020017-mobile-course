import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/comment_providers.dart';
import '../data/providers.dart';

/// Menampilkan komentar untuk satu post melalui provider, bukan Dio langsung.
class CommentPage extends ConsumerWidget {
  const CommentPage({super.key, this.postId = 1});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(commentProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Komentar Post $postId'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang komentar',
            onPressed: () => ref.read(commentProvider(postId).notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: comments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyErrorMessage(error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(commentProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Belum ada komentar.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final comment = items[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${comment.id}')),
                    title: Text(comment.name),
                    subtitle: Text('${comment.email}\n${comment.body}'),
                    isThreeLine: true,
                  );
                },
              ),
      ),
    );
  }
}