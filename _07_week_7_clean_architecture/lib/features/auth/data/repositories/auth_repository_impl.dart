import '../../../../core/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/token_store.dart';
import '../models/auth_session_model.dart';

/// Implementasi kontrak [AuthRepository] memakai penyimpanan aman.
///
/// Tugas kelas ini hanya dua: memenuhi kontrak dan memetakan data luar
/// menjadi entity. Ia tidak menyimpan aturan validasi (itu milik use case
/// `Login`) dan tidak tahu apa pun tentang widget.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    try {
      final json = await _signInRequest(email: email, password: password);
      final session = AuthSessionModel.fromJson(json).toEntity();
      await _tokenStore.save(access: session.access, refresh: session.refresh);
      return (session: session, failure: null);
    } catch (e) {
      // Saat Dio dipakai, tangkap DioException lebih dulu dan petakan ke
      // NetworkFailure (lihat api_errors.dart). Sisa kegagalan di sini adalah
      // kegagalan penyimpanan lokal.
      return (
        session: null,
        failure: LocalFailure('Gagal menyimpan sesi: $e'),
      );
    }
  }

  @override
  Future<({String? access, Failure? failure})> refresh(
    String refreshToken,
  ) async {
    try {
      if (refreshToken.isEmpty) {
        return (
          access: null,
          failure: const AuthFailure('Refresh token hilang'),
        );
      }
      await Future.delayed(const Duration(milliseconds: 300));
      final renewed =
          'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
      await _tokenStore.save(access: renewed, refresh: refreshToken);
      return (access: renewed, failure: null);
    } catch (e) {
      return (
        access: null,
        failure: UnknownFailure('Gagal memperbarui sesi: $e'),
      );
    }
  }

  @override
  Future<({AuthSession? session, Failure? failure})> currentSession() async {
    try {
      final access = await _tokenStore.readAccess();
      final refresh = await _tokenStore.readRefresh();
      if (access == null || access.isEmpty) {
        return (session: null, failure: null);
      }
      return (
        session: AuthSession(access: access, refresh: refresh ?? ''),
        failure: null,
      );
    } catch (e) {
      return (
        session: null,
        failure: LocalFailure('Gagal membaca sesi: $e'),
      );
    }
  }

  @override
  Future<Failure?> logout() async {
    try {
      await _tokenStore.clear();
      return null;
    } catch (e) {
      return LocalFailure('Gagal keluar: $e');
    }
  }

  /// Mock "request" ke backend auth. Mengembalikan Map yang menyerupai
  /// respons JSON, sehingga jalur mapping `AuthSessionModel.fromJson` benar
  /// benar terpakai.
  ///
  /// GANTI dengan `FirebaseAuth.instance.signInWithEmailAndPassword` atau
  /// `POST /auth/login` lewat Dio saat backend siap. Kontrak dan pemetaan
  /// Failure di atas tidak perlu berubah.
  Future<Map<String, dynamic>> _signInRequest({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'access_token': 'mock-access-for-$email',
      'refresh_token': 'mock-refresh-for-$email',
    };
  }
}
