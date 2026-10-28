import 'package:flutter_test/flutter_test.dart';

import 'package:week7_clean_architecture/features/announcements/domain/entities/announcement.dart';
import 'package:week7_clean_architecture/features/announcements/domain/usecases/search_announcements.dart';

/// Data uji: lima pengumuman, campuran huruf besar/kecil di judulnya.
List<Announcement> get _sample => [
  Announcement(
    id: '1',
    title: 'Ujian Akhir Semester Ganjil',
    body: '...',
    date: DateTime(2026, 11, 10),
  ),
  Announcement(
    id: '2',
    title: 'Bebas Laboratorium',
    body: '...',
    date: DateTime(2026, 11, 5),
  ),
  Announcement(
    id: '3',
    title: 'Wisuda dan Yudisium',
    body: '...',
    date: DateTime(2026, 10, 28),
  ),
  Announcement(
    id: '4',
    title: 'Kelas Pengganti Jaringan Komputer',
    body: '...',
    date: DateTime(2026, 10, 20),
  ),
  Announcement(
    id: '5',
    title: 'Beasiswa BPP-TI 2026',
    body: '...',
    date: DateTime(2026, 10, 15),
  ),
];

void main() {
  const search = SearchAnnouncements();

  group('SearchAnnouncements (use case murni, tanpa widget)', () {
    test('filter abaikan huruf besar/kecil', () {
      // Test ini adalah pembuktian bug hasil awal AI (Minggu 9):
      // versi awal memakai `title.contains(query)` tanpa normalisasi huruf,
      // sehingga query "ujian" TIDAK menemukan judul "Ujian Akhir ...".
      final hasil = search(_sample, 'ujian');
      expect(hasil, hasLength(1));
      expect(hasil.first.title, 'Ujian Akhir Semester Ganjil');
    });

    test('query kosong mengembalikan seluruh pengumuman', () {
      expect(search(_sample, ''), hasLength(5));
    });

    test('query spasi saja dianggap kosong', () {
      expect(search(_sample, '   '), hasLength(5));
    });

    test('query tak cocok mengembalikan daftar kosong', () {
      expect(search(_sample, 'zzz-tak-ada'), isEmpty);
    });

    test('query dipangkas spasi sebelum dicocokkan', () {
      expect(search(_sample, '  ujian  '), hasLength(1));
    });

    test('kecocokan di tengah judul ditemukan (bukan hanya awalan)', () {
      final hasil = search(_sample, 'akhir');
      expect(hasil, hasLength(1));
      expect(hasil.first.id, '1');
    });

    test('hasil berupa daftar baru, bukan mutasi daftar masukan', () {
      final masukan = _sample;
      final hasil = search(masukan, 'beasiswa');
      expect(hasil, isNot(same(masukan)));
      expect(masukan, hasLength(5));
    });
  });
}
