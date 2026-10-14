# Praktikum 2 — Domain dan Data per Fitur


- Fitur yang dikerjakan: `auth` (login, sesi, refresh token)
- Prasyarat: Praktikum 1 selesai (`docs/praktikum-1-audit.md`)

---

## 1. Entity murni (domain)

`lib/features/auth/domain/entities/auth_session.dart`

```dart
class AuthSession {
  const AuthSession({required this.access, required this.refresh});

  final String access;
  final String refresh;
}
```

## 2. Failure (core)

`lib/core/failures.dart`

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}
```

| Failure | Kapan dipakai |
| --- | --- |
| `LocalFailure` | Gagal baca/tulis penyimpanan lokal (secure storage). |
| `NetworkFailure` | Gagal berkomunikasi dengan jaringan (Dio). |
| `AuthFailure` | Kredensial ditolak server, atau refresh token tidak valid. |
| `ValidationFailure` | Input pengguna melanggar aturan bisnis. |
| `UnknownFailure` | Kegagalan yang belum dikenali. |



- kredensial ditolak server berbeda dari koneksi putus;
- validasi format berbeda dari penolakan server;
- perlu jalur fallback agar tidak ada exception mentah yang lolos.


## 3. Kontrak repository (domain)

`lib/features/auth/domain/repositories/auth_repository.dart`

```dart
abstract class AuthRepository {
  Future<({AuthSession? session, Failure? failure})> login({
    required String email,
    required String password,
  });

  Future<({String? access, Failure? failure})> refresh(String refreshToken);
}
```


## 4. Model dan implementasi (data)

### Model

`lib/features/auth/data/models/auth_session_model.dart`

```dart
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.access, required super.refresh});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      access: json['access_token'] as String? ?? '',
      refresh: json['refresh_token'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
        'access_token': access,
        'refresh_token': refresh,
      };

  AuthSession toEntity() => AuthSession(access: access, refresh: refresh);
}
```

Mapping JSON hanya hidup di sini. `toEntity()` adalah batas data → domain.

### Sumber data

`lib/features/auth/data/datasources/token_store.dart`

Dipindahkan dari `lib/data/token_store.dart`. Berada di `data` karena tahu
detail teknis `flutter_secure_storage`. Method-nya sengaja melempar exception;
repository yang menangkap dan mengubahnya menjadi `Failure`.

### Implementasi repository

`lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
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
      return (session: null, failure: LocalFailure('Gagal menyimpan sesi: $e'));
    }
  }
}
```

`_signInRequest` adalah mock yang mengembalikan `Map` menyerupai respons JSON,
sehingga jalur `AuthSessionModel.fromJson` benar-benar terpakai. Saat backend
Firebase siap, hanya method itu yang diganti — kontrak dan pemetaan `Failure`
tidak berubah.

## 5. Use case: satu operasi bisnis

`lib/features/auth/domain/usecases/login.dart`

```dart
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
```