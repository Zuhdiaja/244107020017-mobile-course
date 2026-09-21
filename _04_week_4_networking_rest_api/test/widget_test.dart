import 'package:flutter_test/flutter_test.dart';
import 'package:week4_networking_rest_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson uses safe defaults for missing fields', () {
    final comment = Comment.fromJson({});

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  test('Comment.fromJson converts numeric ids and keeps text fields', () {
    final comment = Comment.fromJson({
      'postId': 4.0,
      'id': 9,
      'name': 'Ari',
      'email': 'ari@example.com',
      'body': 'Isi komentar',
    });

    expect(comment.postId, 4);
    expect(comment.id, 9);
    expect(comment.name, 'Ari');
    expect(comment.email, 'ari@example.com');
    expect(comment.body, 'Isi komentar');
  });
}
