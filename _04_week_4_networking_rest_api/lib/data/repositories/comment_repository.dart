import 'package:dio/dio.dart';

import '../models/comment.dart';

/// Satu-satunya lapisan yang mengetahui detail endpoint komentar.
class CommentRepository {
  /// Repository menerima client terpusat agar konfigurasi konsisten.
  CommentRepository(this._dio);

  final Dio _dio;

  /// Mengambil semua komentar untuk post tertentu dari JSONPlaceholder.
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
    );
    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
