/// Aturan validasi yang dipakai bersama oleh domain dan presentation.
///
/// Alasan dipisah ke `core/` (Minggu 12): sebelumnya aturan email hidup di
/// dua tempat — `Login` (domain) hanya mengecek `contains('@')`, sementara
/// validator `LoginPage` mengecek hal yang sama dengan cara berbeda. Saat
/// menulis test kasus tepi, dua perilaku ini bisa menyimpang tanpa ketahuan.
/// Sekarang keduanya memanggil fungsi murni yang sama, dan fungsi murni bisa
/// diuji tanpa widget.
library;

/// Memeriksa apakah [value] berbentuk email yang wajar.
///
/// Aturan yang dipakai (sengaja sederhana, bukan RFC 5322 lengkap):
/// - tepat satu `@`
/// - bagian sebelum `@` tidak kosong
/// - bagian sesudah `@` tidak kosong dan mengandung titik
/// - tidak ada spasi di mana pun
///
/// Nilai dipangkas lebih dulu, jadi `" budi@polinema.ac.id "` diterima.
bool isValidEmail(String value) {
  final email = value.trim();
  if (email.isEmpty || email.contains(' ')) return false;

  final at = email.indexOf('@');
  // Harus ada `@`, bukan karakter pertama, dan hanya satu.
  if (at <= 0 || at != email.lastIndexOf('@')) return false;

  final domain = email.substring(at + 1);
  if (domain.isEmpty) return false;
  // Domain harus punya titik dan tidak diawali/diakhiri titik.
  if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
    return false;
  }
  return true;
}

/// Panjang minimal kata sandi yang diterima.
const int minPasswordLength = 6;

/// Memeriksa panjang kata sandi. Aturan panjang sengaja tidak dipangkas:
/// spasi adalah karakter yang sah di dalam kata sandi.
bool isValidPassword(String value) => value.length >= minPasswordLength;
