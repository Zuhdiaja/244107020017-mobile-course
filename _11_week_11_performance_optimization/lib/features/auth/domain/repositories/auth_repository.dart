import '../../../../core/failures.dart';
import '../entities/auth_session.dart';

/// Kontrak yang dibutuhkan domain.
///
/// Interface tinggal di `domain`, implementasinya di `data`. Karena domain
/// hanya tahu abstraksi ini, logika bisnis dapat diuji dengan repository palsu
/// tanpa Firebase, Dio, atau secure storage sungguhan.
///
/// Memakai *record* Dart agar sukses/gagal eksplisit tanpa exception bocor
/// ke presentation.
abstract class AuthRepository {
  /// Login dan simpan sesi. Mengembalikan `session` atau `failure`.
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  /// Tukar refresh token menjadi access token baru.
  Future<({String? access, Failure? failure})> refresh(String refreshToken);

  /// Baca sesi yang tersimpan di penyimpanan aman.
  ///
  /// Diganti agar halaman cukup memanggil provider, bukan membaca
  /// secure storage langsung.
  Future<({AuthSession? session, Failure? failure})> currentSession();

  /// Hapus sesi dari penyimpanan aman.
  Future<Failure?> logout();
}
