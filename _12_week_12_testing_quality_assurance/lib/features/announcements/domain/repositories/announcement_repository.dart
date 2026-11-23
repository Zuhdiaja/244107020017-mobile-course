import '../../../../core/failures.dart';
import '../entities/announcement.dart';

/// Kontrak repository pengumuman.
///
/// Domain hanya mengenal kontrak ini. Dari mana daftar pengumuman berasal
/// (REST API, penyimpanan lokal, cache) adalah keputusan implementasi di
/// layer `data` — sama seperti `AuthRepository` pada fitur `auth`.
abstract class AnnouncementRepository {
  Future<({List<Announcement> announcements, Failure? failure})> fetchAll();
}
