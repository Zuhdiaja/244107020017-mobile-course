import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_local_storage_offline_first/data/local/note.dart';
import 'package:week5_local_storage_offline_first/data/repositories/note_repository.dart';
import 'package:week5_local_storage_offline_first/pages/notes_page.dart';

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository() : super(openDb: () async => throw StateError('unused'));

  final List<Note> _notes = [];

  @override
  Future<List<Note>> fetchNotes() async => List.unmodifiable(_notes);

  @override
  Future<Note> addNote({required String title, String body = ''}) async {
    final note = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime(2026, 9, 28),
      dirty: true,
    );
    _notes.add(note);
    return note;
  }

  @override
  Future<void> deleteNote(int id) async {
    _notes.removeWhere((note) => note.id == id);
  }

  @override
  Future<int> countDirty() async =>
      _notes.where((note) => note.dirty).length;

  @override
  Future<int> syncPending() async {
    final pending = await countDirty();
    for (var index = 0; index < _notes.length; index++) {
      final note = _notes[index];
      _notes[index] = Note(
        id: note.id,
        title: note.title,
        body: note.body,
        updatedAt: note.updatedAt,
        dirty: false,
      );
    }
    return pending;
  }
}

void main() {
  test('NotesNotifier loads and adds notes through a fake repository', () async {
    final repository = FakeNoteRepository();
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(notesProvider.future), isEmpty);

    await container.read(notesProvider.notifier).addNote(
          title: 'Catatan test',
          body: 'Disimpan tanpa database sungguhan',
        );

    final notes = await container.read(notesProvider.future);
    expect(notes, hasLength(1));
    expect(notes.single.title, 'Catatan test');
    expect(notes.single.dirty, isTrue);
  });
}
