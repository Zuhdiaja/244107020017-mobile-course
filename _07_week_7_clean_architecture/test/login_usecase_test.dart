import 'package:flutter_test/flutter_test.dart';

import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/auth/domain/entities/auth_session.dart';
import 'package:week7_clean_architecture/features/auth/domain/repositories/auth_repository.dart';
import 'package:week7_clean_architecture/features/auth/domain/usecases/login.dart';

/// Repository palsu yang mencatat argument yang diterimanya.
///
/// Ini adalah kunci pengujian domain: `Login` diuji tanpa
/// `AuthRepositoryImpl`, tanpa `flutter_secure_storage`, tanpa Dio, tanpa
/// Firebase. Kalau nanti repository aslinya diganti ke Firebase Auth, test
/// ini tetap hijau karena ia hanya bergantung pada kontrak di `domain`.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failWith});

  /// Kalau diisi, `login` mengembalikan kegagalan ini tanpa succeeds.
  final Failure? failWith;

  /// Argument terakhir yang diterima `login`, supaya test bisa memastikan
  /// use case meneruskan nilai yang sudah dibersihkan.
  String? lastEmail;
  String? lastPassword;

  /// Berapa kali `login` dipanggil. Dipakai untuk membuktikan validasi
  /// berhenti sebelum repository kalau input tidak valid.
  int loginCalls = 0;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    if (failWith != null) {
      return (session: null, failure: failWith);
    }
    return (
      session: AuthSession(access: 'access-$email', refresh: 'refresh-$email'),
      failure: null,
    );
  }

  @override
  Future<({AuthSession? session, Failure? failure})> currentSession() async {
    return (session: null, failure: null);
  }

  @override
  Future<({String? access, Failure? failure})> refresh(String refreshToken) {
    throw UnimplementedError();
  }

  @override
  Future<Failure?> logout() async => null;
}

void main() {
  group('Login (use case) dengan repository palsu', () {
    test(
      'input valid meneruskan ke repository dan mengembalikan sesi',
      () async {
        final repo = FakeAuthRepository();
        final result = await Login(repo)(
          email: 'budi@polinema.ac.id',
          password: 'rahasia123',
        );

        expect(result.failure, isNull);
        expect(result.session, isNotNull);
        expect(result.session!.access, 'access-budi@polinema.ac.id');
        expect(repo.loginCalls, 1);
      },
    );

    test('email tanpa "@" gagal tanpa menyentuh repository', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo)(email: 'budi', password: 'rahasia123');

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure!.message, contains('Email'));
      // Bukti fail-fast: repository tidak boleh dipanggil sama sekali.
      expect(repo.loginCalls, 0);
    });

    test('email kosong ditolak dengan pesan wajib diisi', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo)(email: '', password: 'rahasia123');

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure!.message, contains('wajib diisi'));
      expect(repo.loginCalls, 0);
    });

    test('email berisi spasi saja dianggap kosong', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo)(email: '   ', password: 'rahasia123');

      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure!.message, contains('wajib diisi'));
      expect(repo.loginCalls, 0);
    });

    test('password pendek gagal tanpa menyentuh repository', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo)(
        email: 'budi@polinema.ac.id',
        password: '123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure!.message, contains('6 karakter'));
      expect(repo.loginCalls, 0);
    });

    test('email dipangkas spasi sebelum divalidasi', () async {
      final repo = FakeAuthRepository();
      final result = await Login(repo)(
        email: '  budi@polinema.ac.id  ',
        password: 'rahasia123',
      );

      expect(result.failure, isNull);
      expect(repo.lastEmail, 'budi@polinema.ac.id');
    });

    test('kegagalan dari repository diteruskan tanpa melempar', () async {
      final repo = FakeAuthRepository(
        failWith: const AuthFailure('Sesi berakhir'),
      );
      final result = await Login(repo)(
        email: 'budi@polinema.ac.id',
        password: 'rahasia123',
      );

      expect(result.session, isNull);
      expect(result.failure, isA<AuthFailure>());
      expect(result.failure!.message, 'Sesi berakhir');
    });
  });
}
