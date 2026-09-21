import 'package:flutter/material.dart';

import '../data/models/post.dart';

/// Widget baris post yang dapat dipakai ulang oleh list biasa dan pagination.
class PostTile extends StatelessWidget {
  const PostTile({required this.post, this.onTap, super.key});

  final Post post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(post.id.toString())),
      title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
