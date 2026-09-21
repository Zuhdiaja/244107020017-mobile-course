import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/post.dart';
import 'providers.dart';

/// Memakai post dari list yang sudah ada, lalu mengambil endpoint detail bila perlu.
final postDetailProvider = FutureProvider.family<Post, int>((
  ref,
  postId,
) async {
  final listState = ref.watch(postListProvider);
  Post? cachedPost;
  if (listState.hasValue) {
    for (final post in listState.requireValue) {
      if (post.id == postId) {
        cachedPost = post;
        break;
      }
    }
  }
  if (cachedPost != null) return cachedPost;
  return ref.watch(postRepositoryProvider).fetchPost(postId);
});
