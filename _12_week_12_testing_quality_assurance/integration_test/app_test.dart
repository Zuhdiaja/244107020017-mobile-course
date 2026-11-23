import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:week12_testing_quality_assurance/app.dart';
import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/entities/auth_session.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/repositories/auth_repository.dart';
import 'package:week12_testing_quality_assurance/features/auth/presentation/providers/auth_providers.dart';
import 'package:week12_testing_quality_assurance/features/notifications/presentation/providers/notifications_providers.dart';

/// Integration test alur utama (Minggu 12).
///
/// Yang diuji adalah aplikasi utuh: router, guard login, halaman login,
/// beranda, halaman pengumuman, debounce pencarian, dan navigasi ke halaman
/// detail. Yang dipalsukan hanya dua batas terluar yang tidak tersedia di
/// test:
///
/// 1. [AuthRepository] — di perangkat asli ia memakai secure storage/Firebase.
/// 2. `fcmTokenProvider` — di perangkat asli ia memanggil Firebase Messaging.
///
/// Repository pengumuman, use case, provider Riverpod, dan seluruh widget
/// tetap yang asli, jadi kegagalan integrasi antar bagian masih akan terlihat.
///
/// Jalankan:
///   flutter test integration_test/app_test.dart -d windows
///   flutter drive -d chrome --driver=test_driver/integration_test.dart \
///     --target=integration_test/app_test.dart
class _FakeAuthRepository implements AuthRepository {
  AuthSession? _session;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    _session = AuthSession(access: 'access-$email', refresh: 'refresh-$email');
    return (session: _session, failure: null);
  }

  @override
  Future<({AuthSession? session, Failure? failure})> currentSession() async {
    return (session: _session, failure: null);
  }

  @override
  Future<({String? access, Failure? failure})> refresh(String refreshToken) {
    return Future.value((access: null, failure: null));
  }

  @override
  Future<Failure?> logout() async {
    _session = null;
    return null;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login -> pengumuman -> cari "ujian" -> buka detail', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        fcmTokenProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    final router = createRouter(container);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      CampusNotifyApp(container: container, router: router),
    );
    await tester.pumpAndSettle();

    // 1) Guard route: belum punya sesi -> halaman login.
    expect(find.text('Masuk'), findsOneWidget);

    // 2) Login dengan input valid.
    await tester.enterText(
      find.byKey(const Key('login-email-field')),
      'budi@polinema.ac.id',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'rahasia123',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    // 3) Beranda: sesi terbaca dan kartu fitur tersedia.
    expect(find.text('Login berhasil'), findsOneWidget);
    expect(find.byKey(const Key('home-announcements-card')), findsOneWidget);

    // 4) Buka daftar pengumuman; data dari repository asli (5 item).
    await tester.tap(find.byKey(const Key('home-announcements-card')));
    await tester.pumpAndSettle();

    expect(find.text('Ujian Akhir Semester Ganjil'), findsOneWidget);
    expect(find.text('Bebas Laboratorium'), findsOneWidget);

    // 5) Cari "ujian" huruf kecil -> hanya judul berhuruf kapital yang cocok.
    await tester.enterText(find.byKey(const Key('search-field')), 'ujian');
    // Debounce 250 ms berjalan dengan waktu nyata di integration test, jadi
    // tunggu eksplisit sebelum memeriksa hasil.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Ujian Akhir Semester Ganjil'), findsOneWidget);
    expect(find.text('Bebas Laboratorium'), findsNothing);

    // 6) Ketuk kartu -> halaman detail lewat rute /pengumuman/1.
    await tester.tap(find.text('Ujian Akhir Semester Ganjil'));
    await tester.pumpAndSettle();

    expect(find.text('Pengumuman #1'), findsOneWidget);
  });
}
