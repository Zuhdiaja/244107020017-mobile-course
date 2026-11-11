import '../entities/announcement.dart';

/// Use case murni: memfilter pengumuman berdasarkan query pada judul.
///
/// Dipindah dari widget (hasil awal AI meletakkan filter di build method)
/// ke sini supaya aturan pencarian bisa diuji tanpa widget — pola yang sama
/// dengan [Login] pada fitur `auth`.
class SearchAnnouncements {
  const SearchAnnouncements();

  List<Announcement> call(List<Announcement> announcements, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return List.unmodifiable(announcements);
    // Perbaikan bug hasil awal AI (bukti: test merah 3 kasus di
    // search_announcements_test.dart): `String.contains` membedakan huruf
    // besar/kecil, sehingga query "ujian" meleset dari judul "Ujian ...".
    // Kedua sisi dinormalkan ke huruf kecil sebelum dicocokkan.
    final lowered = trimmed.toLowerCase();
    return List.unmodifiable(
      announcements.where((a) => a.title.toLowerCase().contains(lowered)),
    );
  }
}
