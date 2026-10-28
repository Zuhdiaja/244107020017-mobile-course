import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/announcement_repository_impl.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/search_announcements.dart';

// ---------------------------------------------------------------------------
// Data layer: satu-satunya tempat presentation bersentuhan dengan data,
// hanya untuk MEMBANGUN objek — pemanggilan lewat interface domain.
// ---------------------------------------------------------------------------

/// Repository pengumuman berupa interface, implementasi lokal dari `data`.
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return const AnnouncementRepositoryImpl();
});

// ---------------------------------------------------------------------------
// Domain layer: use case murni, tanpa import Riverpod di domain-nya sendiri.
// ---------------------------------------------------------------------------

/// Use case pencarian — aturan filter hidup di domain, bukan di widget.
final searchAnnouncementsProvider = Provider<SearchAnnouncements>((ref) {
  return const SearchAnnouncements();
});

// ---------------------------------------------------------------------------
// Presentation layer: state untuk UI.
// ---------------------------------------------------------------------------

/// Query pencarian yang diketik pengguna; string kosong berarti tanpa filter.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;

  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Daftar pengumuman dari repository.
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  final result = await ref.watch(announcementRepositoryProvider).fetchAll();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.announcements;
});

/// Hasil pencarian: use case domain diterapkan pada daftar pengumuman.
///
/// Widget hanya membaca provider ini — tidak ada logika filter di UI.
final filteredAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(announcementsProvider)
      .maybeWhen(
        data: (list) => ref.watch(searchAnnouncementsProvider)(list, query),
        orElse: () => const <Announcement>[],
      );
});
