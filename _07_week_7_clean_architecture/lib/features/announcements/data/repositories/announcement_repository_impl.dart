import '../../../../core/failures.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../models/announcement_model.dart';

/// Implementasi repository pengumuman dari sumber data lokal.
///
/// Keputusan (lihat docs Minggu 9): usulan awal AI memanggil
/// `GET /announcements` via Dio, padahal backend `example-campus-api.test`
/// tidak memiliki endpoint itu — terbukti dari grep kontrak API di repo.
/// Endpoint fiktif itu ditolak; sementara backend belum ada, daftar
/// pengumuman dipasok dari data lokal berbentuk JSON mentah agar model
/// tetap memegang tanggung jawab mapping, dan implementasi ini mudah
/// ditukar dengan remote data source tanpa menyentuh domain.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl();

  /// Payload mentah — sengaja `Map<String, dynamic>`, bukan entity,
  /// supaya `AnnouncementModel.fromJson` benar-benar dipakai.
  static const List<Map<String, dynamic>> _seed = [
    {
      'id': '1',
      'title': 'Ujian Akhir Semester Ganjil',
      'body':
          'Ujian akhir semester digelar 8-19 Desember. Harap cek kartu '
          'ujian dan ruang masing-masing di portal akademik.',
      'date': '2026-11-10T08:00:00.000',
    },
    {
      'id': '2',
      'title': 'Bebas Laboratorium',
      'body':
          'Mahasiswa TI wajib melunasi bebas laboratorium sebelum '
          'mengambil ujian akhir. Cek sisa tagihan di bagian akademik.',
      'date': '2026-11-05T09:00:00.000',
    },
    {
      'id': '3',
      'title': 'Wisuda dan Yudisium',
      'body':
          'Pendaftaran yudisium dibuka sampai akhir bulan. Berkas '
          'diunggah melalui portal kemahasiswaan.',
      'date': '2026-10-28T13:00:00.000',
    },
    {
      'id': '4',
      'title': 'Kelas Pengganti Jaringan Komputer',
      'body':
          'Kelas pengganti Jaringan Komputer diadakan Sabtu pukul 08.00 '
          'di lab komputer 3.',
      'date': '2026-10-20T10:00:00.000',
    },
    {
      'id': '5',
      'title': 'Beasiswa BPP-TI 2026',
      'body':
          'Pengajuan beasiswa BPP-TI dibuka untuk mahasiswa semester 5 '
          'dengan IPK minimal 3.25. Batas unggah dokumen: 30 November.',
      'date': '2026-10-15T14:00:00.000',
    },
  ];

  @override
  Future<({List<Announcement> announcements, Failure? failure})>
  fetchAll() async {
    final announcements = _seed
        .map(AnnouncementModel.fromJson)
        .map((model) => model.toEntity())
        .toList(growable: false);
    return (announcements: announcements, failure: null);
  }
}
