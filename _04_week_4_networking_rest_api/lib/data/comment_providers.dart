import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/comment.dart';
import 'providers.dart';
import 'repositories/comment_repository.dart';

/// Menyediakan repository komentar dengan Dio client terpusat.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

/// Mengelola loading, data, dan error komentar untuk satu post.
class CommentNotifier extends AsyncNotifier<List<Comment>> {
  /// Riverpod meneruskan postId family ke constructor notifier.
  CommentNotifier(this.postId);

  final int postId;

  /// Memuat komentar pertama kali saat provider mulai digunakan.
  @override
  Future<List<Comment>> build() {
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }

  /// Memuat ulang komentar dan mengubah exception menjadi AsyncError.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(commentRepositoryProvider).fetchComments(postId),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

/// Family provider membuat state terpisah untuk setiap postId.
final commentProvider =
    AsyncNotifierProvider.family<CommentNotifier, List<Comment>, int>(
      CommentNotifier.new,
      // Error ditampilkan langsung agar tidak menunggu retry otomatis saat gagal.
      retry: (retryCount, error) => null,
    );
