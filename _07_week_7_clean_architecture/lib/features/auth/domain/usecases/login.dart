import '../../../../core/failures.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Satu operasi bisnis: login pengguna.
///
/// Use case ini **bukan sekadar meneruskan** panggilan repository. Ia memegang
/// aturan bisnis validasi format yang harus gagal cepat (fail fast) sebelum
/// menyentuh repository:
///
/// - email wajib mengandung `@`
/// - kata sandi minimal 6 karakter
///
/// Validasi ini sengaja tidak ditaruh di widget (presentation) maupun di
/// repository (data), supaya dapat diuji murni dan dipakai ulang oleh klien
/// lain.
class Login {
  const Login(this._repository);
  final AuthRepository _repository;

  Future<({AuthSession? session, Failure? failure})> call({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();

    if (!trimmedEmail.contains('@')) {
      return Future.value((
        session: null,
        failure: const ValidationFailure('Email tidak valid'),
      ));
    }

    if (password.length < 6) {
      return Future.value((
        session: null,
        failure: const ValidationFailure('Kata sandi minimal 6 karakter'),
      ));
    }

    return _repository.login(email: trimmedEmail, password: password);
  }
}
