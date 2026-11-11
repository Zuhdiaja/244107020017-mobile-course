import 'package:flutter_test/flutter_test.dart';

import 'package:week11_performance_optimization/features/announcements/data/repositories/announcement_repository_impl.dart';

/// Bukti verifikasi optimasi Minggu 11: cache-first pada repository.
///
/// Metric yang dibuktikan di sini: parsing JSON seed hanya berjalan SATU
/// kali, pemanggilan `fetchAll()` berikutnya membaca cache (instans daftar
/// yang sama persis). Ini menjawab temuan baseline: setiap pembukaan halaman
/// daftar dulu mengulang parsing yang sama.
void main() {
  setUp(() {
    AnnouncementRepositoryImpl.debugResetCache();
  });

  test('parsing seed hanya berjalan sekali lalu dibaca dari cache', () async {
    final repo = const AnnouncementRepositoryImpl();

    final first = await repo.fetchAll();
    expect(AnnouncementRepositoryImpl.parseRuns, 1);

    final second = await repo.fetchAll();
    expect(AnnouncementRepositoryImpl.parseRuns, 1);

    // Cache-first: instans daftar yang sama persis, bukan hasil parsing baru.
    expect(identical(first.announcements, second.announcements), isTrue);
    expect(second.failure, isNull);
    expect(first.announcements.length, 5);
  });

  test('instance repository berbeda tetap berbagi cache yang sama', () async {
    // Provider Riverpod memegang satu instance, tetapi cache disimpan pada
    // static field sehingga instance baru pun menghemat parsing.
    final a = const AnnouncementRepositoryImpl();
    final b = const AnnouncementRepositoryImpl();

    await a.fetchAll();
    await b.fetchAll();

    expect(AnnouncementRepositoryImpl.parseRuns, 1);
  });
}
