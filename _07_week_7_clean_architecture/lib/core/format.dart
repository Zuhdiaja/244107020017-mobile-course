/// Fungsi-fungsi murni untuk memformat nilai yang akan ditampilkan.
///
/// Berada di `core/` karena dipakai lebih dari satu fitur dan tidak punya
/// keadaan: tidak menyentuh widget, provider, jaringan, atau penyimpanan.
///
/// Fungsi yang tersedia:
/// - [routeFromMessage] — payload FCM menjadi rute deep link
/// - [maskSecret] — memotong nilai rahasia agar tidak tampil utuh
///
/// Semua fungsi di sini bisa diuji tanpa `flutter_test` — cukup `test()`
/// biasa. Itulah tujuannya: logika yang sebelumnya tersebar di dalam widget
/// atau di tengah file data sekarang bisa diuji langsung.
library;

/// Parsing `data` payload FCM menjadi rute deep link.
///
/// Dipisah dari `push_service.dart` (Refactoring Challenge #2) supaya aturan
/// pembentukan rute bisa diuji tanpa harus menyalakan Firebase.
///
/// Aturannya:
/// - `route` tidak ada atau kosong → fallback `/`
/// - `route` tanpa slash di depan → ditambahkan
/// - `route` yang sudah punya slash → dipakai apa adanya
String routeFromMessage(Map<String, dynamic> data) {
  final route = (data['route'] as String?) ?? '/';
  if (route.isEmpty) return '/';
  return route.startsWith('/') ? route : '/$route';
}

/// Memotong nilai rahasia agar tidak tampil utuh di layar.
///
/// Dipakai untuk access token dan token FCM. Nilai asli tidak pernah
/// ditampilkan penuh, dan jumlah karakter yang terlihat bisa diatur
/// terpisah dari aturan pemotongannya.
String maskSecret(String? value, {int visible = 12}) {
  if (value == null || value.isEmpty) return '-';
  final take = visible.clamp(0, value.length);
  return '${value.substring(0, take)}...';
}
