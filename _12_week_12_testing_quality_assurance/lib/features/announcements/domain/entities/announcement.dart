/// Entity murni milik domain.
///
/// Tanpa `toJson/fromJson` — mapping data luar adalah tugas
/// `AnnouncementModel` di layer `data`. Tanpa import framework apa pun,
/// sama seperti `AuthSession`.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
  });

  final String id;

  /// Judul pengumuman; satu-satunya field yang dicari oleh
  /// [SearchAnnouncements].
  final String title;
  final String body;

  /// Tanggal pengumuman diterbitkan.
  final DateTime date;
}
