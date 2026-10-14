import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/api_client.dart';
import '../../data/datasources/token_store.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login.dart';

// ---------------------------------------------------------------------------
// Data layer: sumber data disuntikkan lewat provider.
// Inilah satu-satunya tempat presentation boleh bersentuhan dengan data,
// hanya untuk MEMBANGUN objek — pemanggilan lewat interface di bawah.
// ---------------------------------------------------------------------------

/// Sumber TokenStore tunggal — seluruh token hanya keluar-masuk lewat kelas ini.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Repository auth berupa interface, implementasinya datang dari `data`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(tokenStoreProvider));
});

/// Dio dengan interceptor refresh otomatis saat 401.
final apiClientProvider = Provider((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Domain layer: use case menerima abstraksi, bukan implementasi.
// ---------------------------------------------------------------------------

/// Login — memegang aturan bisnis validasi format.
final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Presentation layer: state untuk UI.
// ---------------------------------------------------------------------------

/// Status login: true bila access token tersedia di secure storage.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

/// Sesi tersimpan, dipakai halaman untuk menampilkan token terpotong.
///
/// Ikut dibangun ulang tiap [authStateProvider] berubah, sehingga token yang
/// tampil selalu mengikuti login/logout terakhir.
final sessionProvider = FutureProvider<AuthSession?>((ref) async {
  ref.watch(authStateProvider);
  final result = await ref.watch(authRepositoryProvider).currentSession();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.session;
});

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result = await ref.watch(authRepositoryProvider).currentSession();
    return result.session != null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(loginProvider)(email: email, password: password);
      if (result.failure != null) {
        throw Exception(result.failure!.message);
      }
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidateSelf();
  }
}
