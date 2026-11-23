import 'dart:async';

import 'package:flutter/foundation.dart';
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

/// Jeda debounce input pencarian (Minggu 11).
///
/// Dulu setiap karakter yang diketik langsung mengubah state, sehingga
/// provider hasil filter menghitung ulang dan halaman rebuild per karakter.
/// Dengan debounce, lima ketikan beruntun hanya menghasilkan SATU pembaruan
/// state di akhir — recompute filter dan rebuild UI turun dari 5x ke 1x.
const searchDebounceDelay = Duration(milliseconds: 250);

/// Query pencarian yang diketik pengguna; string kosong berarti tanpa filter.
class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    // Timer yang masih berjalan dibatalkan saat provider dibuang agar tidak
    // mengubah state setelah dispose (pencegahan kebocoran).
    ref.onDispose(_cancelDebounce);
    return '';
  }

  /// Menunda pembaruan state sampai pengguna berhenti mengetik.
  void set(String value) {
    _cancelDebounce();
    _debounce = Timer(searchDebounceDelay, () => state = value);
  }

  /// Mengosongkan query SEGERA — dipakai tombol hapus, di mana jeda justru
  /// terasa lambat bagi pengguna.
  void clear() {
    _cancelDebounce();
    state = '';
  }

  void _cancelDebounce() => _debounce?.cancel();
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
///
/// Instrumen verifikasi Minggu 11: [filteredRecomputeCount] menghitung
/// berapa kali filter benar-benar menghitung ulang. Baseline (tanpa
/// debounce) = satu kali per karakter; hasil optimasi = satu kali per
/// seketik ketikan.
@visibleForTesting
int filteredRecomputeCount = 0;

final filteredAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(announcementsProvider)
      .maybeWhen(
        data: (list) {
          filteredRecomputeCount++;
          return ref.watch(searchAnnouncementsProvider)(list, query);
        },
        orElse: () => const <Announcement>[],
      );
});

/// Baris konteks (judul + tanggal) untuk konsumsi lintas fitur — dipakai
/// halaman asisten AI (Minggu 10) sebagai isi prompt.
///
/// Minggu 11: dulu baris ini dibentuk ulang SETIAP kali pengguna mengirim
/// chat (satu pemformatan string per kirim). Sekarang dihitung hanya saat
/// daftar pengumuman berubah; pengiriman chat cukup membaca hasil jadi.
final announcementContextLinesProvider = Provider<List<String>>((ref) {
  final announcements = ref.watch(announcementsProvider).value;
  if (announcements == null) return const [];
  return [
    for (final a in announcements)
      '${a.title} (${a.date.toIso8601String().substring(0, 10)})',
  ];
});
