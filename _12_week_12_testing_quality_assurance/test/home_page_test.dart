import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week12_testing_quality_assurance/app.dart';
import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/entities/auth_session.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/repositories/auth_repository.dart';
import 'package:week12_testing_quality_assurance/features/auth/presentation/providers/auth_providers.dart';
import 'package:week12_testing_quality_assurance/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:week12_testing_quality_assurance/pages/home_page.dart';

/// Repository auth palsu yang menyimpan sesi di memori.
///
/// `currentSession()` mengikuti nilai [session], sehingga logout benar-benar
/// terlihat oleh provider — bukan sekadar mengembalikan nilai tetap.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.session});

  AuthSession? session;
  int logoutCalls = 0;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    session = AuthSession(access: 'access-$email', refresh: 'refresh-$email');
    return (session: session, failure: null);
  }

  @override
  Future<({AuthSession? session, Failure? failure})> currentSession() async {
    return (session: session, failure: null);
  }

  @override
  Future<({String? access, Failure? failure})> refresh(String refreshToken) {
    throw UnimplementedError();
  }

  @override
  Future<Failure?> logout() async {
    logoutCalls++;
    session = null;
    return null;
  }
}

/// Override bersama tidak dipisah ke variabel bertipe `Override` (tipe itu
/// tidak diekspor `flutter_riverpod.dart`), cukup disusun di tiap helper.

/// Beranda tanpa router: cukup untuk memeriksa teks/kartu. `HomePage` hanya
/// memakai `context.go` pada tombol logout, yang diuji terpisah di bawah.
Future<void> _pumpHome(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  // Layar tinggi: beranda berisi banyak kartu, dan ListView tidak membangun
  // anak di luar viewport. Tanpa ini kartu FCM tidak pernah ter-render.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        fcmTokenProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Beranda lewat komposisi aplikasi asli (`CampusNotifyApp` + router) —
/// dipakai untuk menguji logout sampai berpindah halaman.
Future<void> _pumpApp(
  WidgetTester tester,
  _FakeAuthRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
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
}

void main() {
  const session = AuthSession(
    access: 'access-abcdefghijklmnop',
    refresh: 'refresh-xyz',
  );

  group('HomePage — tampilan', () {
    testWidgets('sesi aktif menampilkan "Login berhasil" dan dua kartu fitur', (
      tester,
    ) async {
      await _pumpHome(tester, _FakeAuthRepository(session: session));

      expect(find.text('Login berhasil'), findsOneWidget);
      expect(find.text('Belum login'), findsNothing);
      expect(find.byKey(const Key('home-announcements-card')), findsOneWidget);
      expect(find.byKey(const Key('home-assistant-card')), findsOneWidget);
      expect(find.text('Pengumuman'), findsOneWidget);
      expect(find.text('Asisten Kampus (AI)'), findsOneWidget);
    });

    testWidgets('tanpa sesi menampilkan "Belum login"', (tester) async {
      await _pumpHome(tester, _FakeAuthRepository());

      expect(find.text('Belum login'), findsOneWidget);
      expect(find.text('Login berhasil'), findsNothing);
    });

    testWidgets('token sesi ditampilkan terpotong, bukan utuh', (tester) async {
      await _pumpHome(tester, _FakeAuthRepository(session: session));

      expect(find.text('access : access-abcde...'), findsOneWidget);
      expect(find.text('refresh: ada'), findsOneWidget);
      // Token asli tidak boleh muncul di layar.
      expect(find.textContaining('access-abcdefghijklmnop'), findsNothing);
    });

    testWidgets('token FCM null ditampilkan sebagai "mengambil..."', (
      tester,
    ) async {
      await _pumpHome(tester, _FakeAuthRepository(session: session));

      expect(find.text('fcm : mengambil...'), findsOneWidget);
    });
  });

  group('HomePage — logout', () {
    testWidgets('logout memanggil repository dan kembali ke halaman login', (
      tester,
    ) async {
      final repository = _FakeAuthRepository(session: session);
      await _pumpApp(tester, repository);

      expect(find.text('Login berhasil'), findsOneWidget);

      await tester.tap(find.byTooltip('Logout'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 1);
      expect(find.text('Login berhasil'), findsNothing);
      // Halaman login punya tombol "Masuk".
      expect(find.text('Masuk'), findsOneWidget);
    });
  });
}
