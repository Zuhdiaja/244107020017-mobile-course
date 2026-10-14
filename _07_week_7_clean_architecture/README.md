# Week 7: Clean Architecture

Refactor project Minggu 6 (`campus_notify`: auth + secure storage + FCM +
deep link) menjadi struktur feature-first. Aplikasi tidak berubah
perilaku, yang dipindah adalah strukturnya.

## Identitas

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

## Fitur utama

| Fitur | Isi |
| --- | --- |
| `auth` | Login, sesi, penyimpanan access/refresh token di secure storage, logout, refresh token otomatis `401`. |
| `notifications` | Permission, token lifecycle FCM, tiga app state (foreground, background, terminated), deep link. |
| `announcements` | Halaman tujuan deep link `/pengumuman/:id` dari payload notifikasi. |

## Stack

| | |
| --- | --- |
| Language | Dart 3.13.4 |
| Framework | Flutter 3.47.5 |
| State | Riverpod 3.4.3 |
| Routing | GoRouter |
| Jaringan | Dio |
| Penyimpanan | flutter_secure_storage |
| Notifikasi | firebase_messaging + flutter_local_notifications |
| Backend | Firebase (email/password auth) |

## Cara menjalankan

Butuh Flutter SDK dan Android SDK. Device HP juga bisa dipakai langsung
lewat USB debugging.

```bash
flutter pub get

# isi credential Firebase dulu
# android/app/google-services.json
# service-account.json  (tidak di-commit, sudah masuk .gitignore)

flutter run
```

Untuk pengujian:

```bash
flutter analyze
flutter test
```

## Struktur

```text
lib/
├── core/
│   ├── failures.dart
│   └── format.dart
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/auth_session.dart
│   │   │   ├── repositories/auth_repository.dart
│   │   │   └── usecases/login.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── api_errors.dart
│   │   │   │   └── token_store.dart
│   │   │   ├── models/auth_session_model.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── pages/login_page.dart
│   │       └── providers/auth_providers.dart
│   ├── announcements/
│   │   └── presentation/pages/announcement_page.dart
│   └── notifications/
│       ├── data/push_service.dart
│       └── presentation/providers/notifications_providers.dart
├── pages/home_page.dart
├── routes.dart
└── main.dart
```

## Arah dependensi

```text
presentation  ──►  domain  ◄──  data
```

Domain tidak mengimpor apa pun dari Flutter, Dio, atau Firebase, jadi
logika bisnisnya bisa diuji tanpa device. Arah panah di atas bisa digambar
tanpa membuka kode.

`home_page.dart` tetap di `lib/pages/` karena isinya lintas fitur: status
sesi dari `auth` dan token FCM dari `notifications`.

---

# Praktikum 1: Audit

Sebelum refactor, tiap file dipetakan ke layer dan dicari tiga pelanggaran
klasik.

Struktur lama:

```text
lib/
├── main.dart
├── routes.dart
├── data/          # api_client, api_errors, auth_repository, token_store
├── messaging/     # push_service
├── pages/         # login_page, home_page, announcement_page
└── providers/     # auth_provider
```

Pemetaan file ke layer:

| File | Layer | Masalah |
| --- | --- | --- |
| `pages/login_page.dart` | presentation | Menampilkan `state.error` mentah, belum pesan ramah |
| `pages/home_page.dart` | presentation | Impor `firebase_messaging`, panggil `getToken()`, baca secure storage |
| `pages/announcement_page.dart` | presentation | Tidak ambil data, tidak bermasalah |
| `providers/auth_provider.dart` | presentation | Bangun `Dio` di lapisan presentasi |
| `data/auth_repository.dart` | data | Entity, kontrak, dan implementasi dalam satu file |
| `data/token_store.dart` | data | Akses secure storage memang tugas data layer |
| `data/api_client.dart` | data | Bergantung pada `AuthRepository` konkret |
| `data/api_errors.dart` | data | Berisi detail Dio, belum berupa `Failure` |
| `messaging/push_service.dart` | data | Mencampur Firebase, notifikasi lokal, dan navigasi UI |
| `main.dart` | composition root | `dio.post('/devices')` langsung di `main()` |
| `routes.dart` | core | Sudah rapi |

Tiga pencarian:

```bash
# 1
rg "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets
# -> nol hasil

# 2
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
# -> nol hasil

# 3
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
# -> 1 hasil: providers/auth_provider.dart:13
```

Hasil ke-3 sebenarnya wiring DI yang sah karena ada di composition root,
tapi baris itu membuktikan `AuthRepository` masih kelas konkret tanpa
interface.

Urutan pengerjaan: `auth` dulu karena paling lengkap dan punya semua lapis,
lalu `announcements`, lalu `notifications`.

# Praktikum 2: Domain dan data

File yang dibuat:

```text
lib/core/failures.dart                                    # BARU

lib/features/auth/
├── domain/
│   ├── entities/auth_session.dart                       # BARU
│   ├── repositories/auth_repository.dart                # BARU (interface)
│   └── usecases/login.dart                              # BARU
└── data/
    ├── models/auth_session_model.dart                   # BARU
    ├── datasources/token_store.dart                     # PINDAH dari lib/data/
    └── repositories/auth_repository_impl.dart           # BARU
```

Entity dan model dibedakan begini:

| | `AuthSession` | `AuthSessionModel` |
| --- | --- | --- |
| Layer | `domain` | `data` |
| Isi | dua field | dua field + mapping JSON |
| Import | tidak ada | mengimpor entity |

`Login` dibuat sebagai use case karena ia memegang aturan validasi format:
email harus mengandung `@`, password minimal 6 karakter. Validasi begitu
memang gagal sebelum repository dipanggil, jadi layak ada di domain.

`refresh` tidak diberi use case. Panggilannya cuma meneruskan ke repository
tanpa aturan sendiri, jadi dari notifier langsung ke repository sudah cukup.

# Praktikum 3: Presentation dan DI

Semua file sudah di tempatnya. `lib/data`, `lib/providers`, dan
`lib/messaging` tidak ada lagi.

Seluruh provider ada di satu file,
`features/auth/presentation/providers/auth_providers.dart`:

```dart
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(tokenStoreProvider));
});

final apiClientProvider = Provider((ref) {
  return buildApiClient(
    ref.watch(tokenStoreProvider),
    ref.watch(authRepositoryProvider),
  );
});

final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

final sessionProvider = FutureProvider<AuthSession?>((ref) async {
  ref.watch(authStateProvider);
  final result = await ref.watch(authRepositoryProvider).currentSession();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.session;
});
```

`authRepositoryProvider` sekarang mengembalikan interface, bukan
`AuthRepositoryImpl`. Kontraknya ditambah dua method, `currentSession()` dan
`logout()`, supaya halaman dan notifier tidak perlu pegang secure storage.

`home_page.dart` dibersihkan dari dua temuan audit. Import
`firebase_messaging` dan `FirebaseMessaging.instance.getToken()` diganti
`ref.watch(fcmTokenProvider)`, dan `ref.read(tokenStoreProvider)` diganti
`ref.watch(sessionProvider)`.

Dulu kedua nilai itu diambil sekali di `initState` lalu disimpan di state
lokal. Sekarang dari provider, jadi ikut berubah sendiri begitu login atau
logout. Tampilannya sama persis.

`login_page.dart` dan `announcement_page.dart` hanya pindah lokasi, isinya
tidak disentuh.

# Praktikum 4: Refactoring challenge dan testing

Pengujian use case memakai `FakeAuthRepository`:

```dart
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failWith});

  final Failure? failWith;
  String? lastEmail;
  String? lastPassword;
  int loginCalls = 0;
  ...
}
```

`loginCalls` dipakai untuk memastikan validasi berhenti sebelum repository
dipanggil:

```dart
final result = await Login(repo)(email: 'budi', password: 'rahasia123');

expect(result.failure, isA<ValidationFailure>());
expect(repo.loginCalls, 0);
```


Lima kasus yang diuji:

| Kasus | Yang dicek |
| --- | --- |
| input valid | sesi balik dari repository |
| email tanpa `@` | `ValidationFailure`, repository tidak dipanggil |
| password pendek | `ValidationFailure`, repository tidak dipanggil |
| email berspasi | repository dapat email yang sudah dipangkas |
| repository gagal | `AuthFailure` diteruskan, tidak melempar |


File test dipecah per lapisan:

```text
test/
├── format_test.dart        # fungsi core/format.dart (10 test)
├── api_errors_test.dart    # pemetaan DioException -> Failure (7 test)
└── login_usecase_test.dart # use case Login + fake (5 test)
```

# Hasil akhir

```text
flutter analyze            No issues found!
flutter test               22 tests passed
```

# Dokumentasi

- [docs/ai-challenge.md](docs/ai-challenge.md)
- Screenshot: folder `screenshots/`
  - `week7-after-clean-architecture.png` — beranda setelah refactor