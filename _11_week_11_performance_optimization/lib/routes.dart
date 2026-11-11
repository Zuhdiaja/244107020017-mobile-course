/// Konstanta rute tunggal (Refactoring Challenge).
/// Dipakai GoRouter dan deep link FCM agar string rute tidak tersebar.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String home = '/';
  static const String announcements = '/pengumuman';
  static const String announcementPattern = '/pengumuman/:id';

  /// Chat asisten AI (Minggu 10) + pengaturan API key-nya.
  static const String assistant = '/asisten';
  static const String assistantSettings = '/asisten/pengaturan';

  /// Bangun path pengumuman dari id (mis. id "3" -> "/pengumuman/3").
  static String announcement(String id) => '/pengumuman/$id';
}
