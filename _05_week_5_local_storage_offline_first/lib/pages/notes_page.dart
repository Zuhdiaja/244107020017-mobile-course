import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/note.dart';
import '../data/repositories/note_repository.dart';
import 'settings_page.dart';

final noteRepositoryProvider = Provider((ref) => NoteRepository());
final notesProvider =
		AsyncNotifierProvider<NotesNotifier, List<Note>>(NotesNotifier.new);

class NotesNotifier extends AsyncNotifier<List<Note>> {
	@override
	Future<List<Note>> build() {
		return ref.read(noteRepositoryProvider).fetchNotes();
	}

	Future<void> addNote({required String title, String body = ''}) async {
		state = const AsyncLoading();
		state = await AsyncValue.guard(() async {
			await ref.read(noteRepositoryProvider).addNote(title: title, body: body);
			return ref.read(noteRepositoryProvider).fetchNotes();
		});
	}

	Future<void> deleteNote(int id) async {
		state = const AsyncLoading();
		state = await AsyncValue.guard(() async {
			await ref.read(noteRepositoryProvider).deleteNote(id);
			return ref.read(noteRepositoryProvider).fetchNotes();
		});
	}

	Future<void> refreshNotes() async {
		state = await AsyncValue.guard(
			() => ref.read(noteRepositoryProvider).fetchNotes(),
		);
	}
}

class NotesPage extends ConsumerWidget {
	const NotesPage({super.key});

	@override
	Widget build(BuildContext context, WidgetRef ref) {
		final notes = ref.watch(notesProvider);

		return Scaffold(
			appBar: AppBar(
				title: const Text('Catatan Offline'),
				actions: [
					IconButton(
						tooltip: 'Pengaturan',
						icon: const Icon(Icons.settings_outlined),
						onPressed: () {
							Navigator.of(context).push(
								MaterialPageRoute<void>(
									builder: (_) => const SettingsPage(),
								),
							);
						},
					),
				],
			),
			body: notes.when(
				loading: () => const Center(child: CircularProgressIndicator()),
				error: (error, _) => Center(
					child: Text('Gagal memuat catatan: $error'),
				),
				data: (items) {
					if (items.isEmpty) {
						return RefreshIndicator(
							onRefresh: () => ref.read(notesProvider.notifier).refreshNotes(),
							child: ListView(
								children: const [
									SizedBox(height: 220),
									Center(child: Text('Belum ada catatan')),
								],
							),
						);
					}

					return RefreshIndicator(
						onRefresh: () => ref.read(notesProvider.notifier).refreshNotes(),
						child: ListView.separated(
							padding: const EdgeInsets.all(12),
							itemCount: items.length,
							  separatorBuilder: (_, _) => const SizedBox(height: 8),
							itemBuilder: (context, index) {
								final note = items[index];
								return Card(
									child: ListTile(
										title: Text(note.title),
										subtitle: Text(
											note.body.isEmpty
													? 'Tidak ada isi'
													: note.body,
											maxLines: 2,
											overflow: TextOverflow.ellipsis,
										),
										leading: Icon(
											note.dirty ? Icons.cloud_off : Icons.cloud_done,
										),
										trailing: IconButton(
											tooltip: 'Hapus catatan',
											icon: const Icon(Icons.delete_outline),
											onPressed: () => ref
													.read(notesProvider.notifier)
													.deleteNote(note.id!),
										),
									),
								);
							},
						),
					);
				},
			),
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () => _showAddNoteDialog(context, ref),
				icon: const Icon(Icons.add),
				label: const Text('Catatan'),
			),
		);
	}
}

Future<void> _showAddNoteDialog(BuildContext context, WidgetRef ref) async {
	final titleController = TextEditingController();
	final bodyController = TextEditingController();
	final formKey = GlobalKey<FormState>();

	final result = await showDialog<(String, String)?>(
		context: context,
		builder: (dialogContext) => AlertDialog(
			title: const Text('Tambah catatan'),
			content: Form(
				key: formKey,
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						TextFormField(
							controller: titleController,
							autofocus: true,
							decoration: const InputDecoration(labelText: 'Judul'),
							validator: (value) => value == null || value.trim().isEmpty
									? 'Judul wajib diisi'
									: null,
						),
						TextField(
							controller: bodyController,
							decoration: const InputDecoration(labelText: 'Isi catatan'),
							maxLines: 3,
						),
					],
				),
			),
			actions: [
				TextButton(
					onPressed: () => Navigator.pop(dialogContext),
					child: const Text('Batal'),
				),
				FilledButton(
					onPressed: () {
						if (formKey.currentState!.validate()) {
							Navigator.pop(
								dialogContext,
								(titleController.text.trim(), bodyController.text.trim()),
							);
						}
					},
					child: const Text('Simpan'),
				),
			],
		),
	);

	titleController.dispose();
	bodyController.dispose();

	if (result != null) {
		await ref.read(notesProvider.notifier).addNote(
					title: result.$1,
					body: result.$2,
				);
	}
}
