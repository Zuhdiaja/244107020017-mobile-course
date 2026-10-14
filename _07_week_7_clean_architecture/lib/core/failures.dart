/// Kegagalan yang membawa pesan siap tampil untuk pengguna.
///
/// Murni Dart: tidak mengimpor Flutter, Dio, SQLite, maupun Firebase.
/// Inilah alasan `core/` bisa diuji tanpa framework apa pun.
///
/// Presentation cukup menampilkan `failure.message` — exception mentah
/// (mis. `DioException`) tidak pernah bocor ke UI.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Gagal membaca/menulis penyimpanan lokal (mis. secure storage).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Gagal berkomunikasi dengan jaringan.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Kredensial ditolak server, atau sesi/refresh token tidak valid.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Input pengguna tidak memenuhi aturan bisnis.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Kegagalan yang belum dikenali.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
