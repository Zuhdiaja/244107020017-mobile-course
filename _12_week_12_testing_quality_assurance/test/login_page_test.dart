import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:week12_testing_quality_assurance/core/failures.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/entities/auth_session.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/repositories/auth_repository.dart';
import 'package:week12_testing_quality_assurance/features/auth/presentation/pages/login_page.dart';
import 'package:week12_testing_quality_assurance/features/auth/presentation/providers/auth_providers.dart';

/// Repository palsu untuk widget test halaman login.
///
/// Halaman login butuh `authRepositoryProvider` untuk membaca status sesi
/// awal. Dengan fake ini, widget bisa diuji tanpa Firebase, tanpa secure
/// storage, dan tanpa jaringan — jadi validator form tetap punya bukti uji
/// meski aplikasi tidak dijalankan manual di perangkat.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure, this.gate});

  /// Bila diisi, `login` mengembalikan kegagalan ini.
  final Failure? failure;

  /// Bila diisi, `login` menunggu sampai completer selesai — dipakai untuk
  /// membuktikan loading state (spinner + tombol disabled) benar-benar tampil.
  final Completer<void>? gate;

  int loginCalls = 0;
  String? lastEmail;

  @override
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    if (gate != null) await gate!.future;
    if (failure != null) return (session: null, failure: failure);
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

/// Memasang [LoginPage] di dalam ProviderScope dengan repository palsu.
///
/// Rute `/` sengaja diganti placeholder: tujuannya hanya membuktikan bahwa
/// input valid benar-benar berpindah halaman, tanpa ikut membangun
/// `HomePage` yang butuh Firebase Messaging.
Future<void> _pumpLoginPage(
  WidgetTester tester, {
  AuthRepository? repository,
}) async {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/', builder: (_, _) => const Text('halaman-beranda')),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          repository ?? _FakeAuthRepository(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  // Tunggu authStateProvider selesai membaca sesi awal agar tombol aktif.
  await tester.pumpAndSettle();
}

Future<void> _tapMasuk(WidgetTester tester) async {
  await tester.tap(find.text('Masuk'));
  await tester.pumpAndSettle();
}

void main() {
  group('LoginPage — validator form', () {
    testWidgets('email kosong menampilkan "Email wajib diisi"', (tester) async {
      await _pumpLoginPage(tester);
      await _tapMasuk(tester);

      expect(find.text('Email wajib diisi'), findsOneWidget);
      // Validator password ikut berjalan pada submit yang sama.
      expect(find.text('Minimal 6 karakter'), findsOneWidget);
      // Tetap di halaman login, tidak berpindah.
      expect(find.text('halaman-beranda'), findsNothing);
    });

    testWidgets('email berisi spasi saja dianggap kosong', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      await _tapMasuk(tester);

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(find.text('halaman-beranda'), findsNothing);
    });

    testWidgets('email tanpa "@" tetap "Email tidak valid"', (tester) async {
      await _pumpLoginPage(tester);

      await tester.enterText(find.byType(TextFormField).first, 'budi');
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      await _tapMasuk(tester);

      expect(find.text('Email tidak valid'), findsOneWidget);
      expect(find.text('Email wajib diisi'), findsNothing);
      expect(find.text('halaman-beranda'), findsNothing);
    });

    testWidgets('input valid lolos validasi dan berpindah halaman', (
      tester,
    ) async {
      await _pumpLoginPage(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'budi@polinema.ac.id',
      );
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      await _tapMasuk(tester);

      expect(find.text('Email wajib diisi'), findsNothing);
      expect(find.text('Email tidak valid'), findsNothing);
      expect(find.text('Minimal 6 karakter'), findsNothing);
      expect(find.text('halaman-beranda'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------
  // Kasus tambahan Minggu 12: input tak valid tidak menyentuh repository,
  // kegagalan login, dan loading state.
  // ---------------------------------------------------------------------

  group('LoginPage — alur submit', () {
    testWidgets('form tidak valid tidak memanggil repository', (tester) async {
      final repo = _FakeAuthRepository();
      await _pumpLoginPage(tester, repository: repo);
      await _tapMasuk(tester);

      expect(repo.loginCalls, 0);
    });

    testWidgets('email dengan domain tanpa titik ditolak sebelum submit', (
      tester,
    ) async {
      final repo = _FakeAuthRepository();
      await _pumpLoginPage(tester, repository: repo);

      await tester.enterText(
        find.byType(TextFormField).first,
        'budi@localhost',
      );
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      await _tapMasuk(tester);

      expect(find.text('Email tidak valid'), findsOneWidget);
      expect(repo.loginCalls, 0);
      expect(find.text('halaman-beranda'), findsNothing);
    });

    testWidgets('login gagal dari repository menampilkan pesan dan tetap '
        'di halaman login', (tester) async {
      await _pumpLoginPage(
        tester,
        repository: _FakeAuthRepository(
          failure: const AuthFailure('Kredensial ditolak'),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'budi@polinema.ac.id',
      );
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      await _tapMasuk(tester);

      expect(find.textContaining('Login gagal'), findsOneWidget);
      expect(find.textContaining('Kredensial ditolak'), findsOneWidget);
      expect(find.text('halaman-beranda'), findsNothing);
    });

    testWidgets('selama menunggu respons tombol disabled + spinner tampil', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _FakeAuthRepository(gate: gate);
      await _pumpLoginPage(tester, repository: repo);

      await tester.enterText(
        find.byType(TextFormField).first,
        'budi@polinema.ac.id',
      );
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      await tester.tap(find.text('Masuk'));
      await tester.pump();

      // Loading: teks tombol diganti spinner dan tombol tidak bisa ditekan.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Masuk'), findsNothing);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('login-submit-button')),
      );
      expect(button.onPressed, isNull);

      // Selesaikan "permintaan" -> halaman berpindah.
      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('halaman-beranda'), findsOneWidget);
      expect(repo.loginCalls, 1);
    });
  });
}
