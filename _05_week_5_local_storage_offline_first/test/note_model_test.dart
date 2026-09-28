import 'package:flutter_test/flutter_test.dart';
import 'package:week5_local_storage_offline_first/data/local/note.dart';

void main() {
  test('Note converts to and from a SQLite map', () {
    final original = Note(
      id: 7,
      title: 'Belanja',
      body: 'Beli susu',
      updatedAt: DateTime.parse('2026-09-28T10:00:00.000Z'),
      dirty: true,
    );

    final restored = Note.fromMap(original.toMap());

    expect(restored.id, 7);
    expect(restored.title, 'Belanja');
    expect(restored.body, 'Beli susu');
    expect(restored.updatedAt, original.updatedAt);
    expect(restored.dirty, isTrue);
  });
}
