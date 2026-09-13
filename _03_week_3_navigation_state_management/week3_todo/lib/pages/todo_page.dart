import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';
import '../widgets/todo_tile.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo'),
      ),
      body: todos.isEmpty
          ? const Center(
              child: Text('Belum ada tugas'),
            )
          : ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];

                return TodoTile(
                  todo: todo,
                  onToggle: () {
                    ref
                        .read(todoListProvider.notifier)
                        .toggle(index);
                  },
                  onDelete: () {
                    ref
                        .read(todoListProvider.notifier)
                        .remove(index);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        tooltip: 'Tambah tugas',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tugas baru'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Masukkan tugas',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final title = controller.text.trim();

                if (title.isNotEmpty) {
                  ref
                      .read(todoListProvider.notifier)
                      .add(title);
                }

                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}