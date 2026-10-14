# Week 7: Clean Architecture

Refactor project Minggu 6 (`campus_notify`: auth + secure storage + FCM + deep
link) menjadi struktur **feature-first Clean Architecture**.

## Identitas

| Keterangan | Detail |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

## Fitur utama

Fitur yang direfactor adalah fitur yang **benar-benar ada** di aplikasi:

| Fitur | Isi |
| --- | --- |
| `auth` | Login, sesi, penyimpanan access/refresh token di secure storage, logout, refresh token otomatis `401`. |
| `announcements` | Halaman tujuan deep link `/pengumuman/:id` dari payload notifikasi. |
| `notifications` | Permission, token lifecycle FCM, tiga app state (foreground, background, terminated), deep link. |


# Praktikum 1: Audit layer project lama

Audit dilakukan **sebelum** refactor. Bukti mentah (perintah `rg` beserta
hasilnya) tersimpan di [docs/praktikum-1-audit.md](docs/praktikum-1-audit.md).

`flutter analyze` → `No issues found!`

## Struktur sebelum refactor

```text
lib/
├── main.dart
├── routes.dart
├── data/          # api_client, api_errors, auth_repository, token_store
├── messaging/     # push_service
├── pages/         # login_page, home_page, announcement_page
└── providers/     # auth_provider
```

## 1. Pemetaan file ke layer

| File | Layer saat ini | Masalah |
| --- | --- | --- |
| `pages/login_page.dart` | presentation | Tidak menyentuh jaringan. Namun menampilkan `state.error` mentah, belum `Failure` ramah pengguna. |
| `pages/home_page.dart` | presentation| Impor `package:firebase_messaging` langsung, panggil `FirebaseMessaging.instance.getToken()`, dan baca secure storage lewat `ref.read(tokenStoreProvider)`. |
| `pages/announcement_page.dart` | presentation |UI statis dari `id` link, tidak mengambil data. |
| `providers/auth_provider.dart` | presentation (state) + DI tercampur | Impor `package:dio` dan membangun `Dio` (`apiClientProvider`) di  presentasi. |
| `data/auth_repository.dart` | data | `AuthSession` + kontrak + implementasi mock dalam satu file; belum ada interface. |
| `data/token_store.dart` | data | akses secure storage memang tugas data layer. |
| `data/api_client.dart` | data | Lokasi aman, tetapi bergantung pada `AuthRepository` bukan abstraksi. |
| `data/api_errors.dart` | data | Seharusnya menjadi `Failure` di `core/`, bukan detail Dio. |
| `messaging/push_service.dart` | data | Mencampur Firebase + notifikasi lokal + navigasi UI (`_navigate`). |
| `main.dart` | composition root | Melakukan `dio.post('/devices')` langsung di `main()`. |
| `routes.dart` | core (routing) | konstanta rute sudah terpusat. |

## 2. Tiga pelanggaran klasik

```bash
# 1. Widget menyentuh jaringan / database langsung
rg "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets
# -> nol hasil

# 2. Logika bisnis di dalam build()
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
# -> nol hasil

# 3. Instansiasi manual (DI bocor)
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
# -> 1 hasil: providers/auth_provider.dart:13 Provider<AuthRepository>((ref) => AuthRepository());
```

Hasil pencarian ke-3 dinilai **wiring DI yang sah** (berada di composition root,
bukan di widget).


### Struktur target project ini

```text
lib/
├── core/
│   ├── failures.dart              # Failure domain (murni Dart)
│   └── format.dart                # fungsi murni: parsing rute & format tanggal
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/auth_session.dart
│   │   │   ├── repositories/auth_repository.dart      # interface
│   │   │   └── usecases/login.dart
│   │   ├── data/
│   │   │   ├── datasources/token_store.dart
│   │   │   └── repositories/auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/auth_providers.dart          # DI + state
│   │       └── pages/login_page.dart
│   ├── announcements/
│   │   └── presentation/pages/announcement_page.dart
│   └── notifications/
│       ├── data/push_service.dart
│       └── presentation/providers/notifications_providers.dart
├── routes.dart
└── main.dart
```

### Urutan pengerjaan

1. **`auth`** - dikerjakan lebih dulu dan paling lengkap, karena sudah punya
   repository, token store, session, dan state login. Ini yang memenuhi syarat
   "1 fitur penuh" (domain + data + presentation).
2. **`announcements`** - cukup halaman dan provider, karena
   `announcement_page.dart` masih UI statis dari `id` deep link. Tidak dibuat
   repository/API palsu hanya demi struktur.
3. **`notifications`** -   `push_service.dart` dipindahkan, dan logika navigasi
   dikeluarkan darinya.

## 4. Item refactor

1. Pecah `data/auth_repository.dart` → entity `AuthSession` (domain), interface
   `AuthRepository` (domain), `AuthRepositoryImpl` (data).
2. Pindahkan `TokenStore` ke `features/auth/data/datasources/`.
3. Buat `core/failures.dart`; ubah `api_errors.dart` menjadi pemetaan `Failure`.
4. Pindahkan `push_service.dart` ke fitur `notifications`; keluarkan logika
   navigasi darinya.
5. Bersihkan `home_page.dart` dari import `firebase_messaging` dan akses
   `tokenStoreProvider`.
6. Pusatkan wiring DI di `auth_providers.dart`.
7. Tambahkan use case `Login`.
8. Ekstrak parsing rute dan format tanggal ke `core/format.dart`.

---

## Bukti

- Audit mentah: [docs/praktikum-1-audit.md](docs/praktikum-1-audit.md)
- Screenshot kondisi awal: folder `screanshoot/`

---

# Praktikum 2: Domain dan data per fitur

## File yang dibuat

```text
lib/
├── core/
│   └── failures.dart                                    # BARU
└── features/
    └── auth/
        ├── domain/
        │   ├── entities/auth_session.dart               # BARU
        │   ├── repositories/auth_repository.dart        # BARU (interface)
        │   └── usecases/login.dart                      # BARU
        └── data/
            ├── models/auth_session_model.dart           # BARU
            ├── datasources/token_store.dart             # PINDAH dari lib/data/
            └── repositories/auth_repository_impl.dart   # BARU
```

## 1. Entity vs model

| | `AuthSession` (entity) | `AuthSessionModel` (model) |
| --- | --- | --- |
| Layer | `domain` | `data` |
| Isi | dua field bisnis | dua field + `fromJson`/`toJson`/`toEntity` |
| Import | tidak ada | mengimpor entity |
| Alasan berubah | aturan bisnis berubah | format data luar berubah |

## 2. Use case dan justifikasinya

`Login` **bukan** use case pass-through. Ia memegang aturan bisnis validasi
format yang harus gagal cepat sebelum menyentuh repository:

- email wajib mengandung `@`
- kata sandi minimal 6 karakter

`refresh` **tidak** dibuatkan use case karena hanya meneruskan panggilan ke
repository dan tidak punya aturan bisnis sendiri, jadi cukup dipanggil
langsung dari notifier.


## Bukti

- Audit mentah: [docs/praktikum-1-audit.md](docs/praktikum-1-audit.md)
- Domain & data per fitur: [docs/praktikum-2-domain-data.md](docs/praktikum-2-domain-data.md)
- Screenshot kondisi awal: folder `screanshoot/`

---

# Praktikum 3: Presentation, DI, dan verifikasi

Semua file dipindahkan ke tempatnya masing-masing, wiring provider dipusatkan
di satu file, dan halaman dibersihkan dari akses data langsung. Setelah praktikum
ini folder `lib/data`, `lib/providers`, dan `lib/messaging` sudah tidak ada.

## Struktur akhir

```text
lib/
├── core/
│   └── failures.dart
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

File lama yang dihapus: `data/auth_repository.dart`, `data/api_client.dart`,
`data/api_errors.dart`, `data/token_store.dart`, `providers/auth_provider.dart`,
`pages/login_page.dart`, `pages/announcement_page.dart`,
`messaging/push_service.dart`.

## 1. Wiring DI dipusatkan di satu file

Seluruh pendaftaran provider ada di
`features/auth/presentation/providers/auth_providers.dart`, ditulis berurutan
dari data ke presentation:

```dart
// Data layer — disuntikkan dari luar, widget tidak pernah membuat sendiri
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

// Domain layer — use case menerima interface, bukan implementasi
final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});

// Presentation layer — state untuk UI
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

final sessionProvider = FutureProvider<AuthSession?>((ref) async {
  ref.watch(authStateProvider);
  final result = await ref.watch(authRepositoryProvider).currentSession();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.session;
});
```

Yang berubah dari sebelumnya, `authRepositoryProvider` sekarang mengembalikan
interface `AuthRepository`, bukan kelas konkret. `AuthNotifier` juga sudah tidak
membaca `TokenStore` sendiri — login lewat use case `Login`, logout lewat
`repository.logout()`. Kontrak repository dapat diperluas dengan dua method
baru, `currentSession()` dan `logout()`, supaya halaman tidak perlu membaca
secure storage.

## 2. Halaman hanya membaca state

Dua temuan Praktikum 1 di `home_page.dart` sudah dibersihkan:

- `import 'package:firebase_messaging'` dan `FirebaseMessaging.instance.getToken()`
  diganti jadi `ref.watch(fcmTokenProvider)`. Pembacaan token FCM-nya pindah ke
  `features/notifications/data/push_service.dart` lewat fungsi `getFcmToken()`.

- `ref.read(tokenStoreProvider)` diganti jadi `ref.watch(sessionProvider)`.
  Secure storage sekarang cuma diakses lewat `AuthRepository.currentSession()`.

Dulu kedua data itu diambil sekali di `initState` lalu disimpan ke state lokal.
Sekarang diambil dari provider sehingga ikut berubah sendiri saat login atau
logout. Tampilannya tetap sama: token 12 karakter pertama lalu titik-titik.

`login_page.dart` pindah ke `features/auth/presentation/pages/` dan
`announcement_page.dart` pindah ke
`features/announcements/presentation/pages/`. Isi kedua halaman tidak berubah.

## 3. Kenapa home_page.dart masih di lib/pages/

Halammenampilkan dua hal yang datang dari dua fitur berbeda: status
sesi dari `auth` dan token FCM dari `notifications`. Kalau halaman ini dimasukkan
ke fitur `auth`, berarti `an beranda auth` harus mengimpor presentation milik
`notifications`. Codelab menulis fitur berkomunikasi lewat rute, bukan lewat
import, dan halaman itu sendiri bukan widget milik satu fitur.

Karena itu home_page saya biarkan di `lib/pages/` sebagai halaman aplikasi.
Isinya tetap bersih, dibuktikan pada grep berikut.

# 4. Static analysis dan test
flutter analyze   # No issues found!
flutter test      # 9 tests passed

## Bukti

- Audit mentah: [docs/praktikum-1-audit.md](docs/praktikum-1-audit.md)
- Domain & data: [docs/praktikum-2-domain-data.md](docs/praktikum-2-domain-data.md)
- AI Challenge: [docs/ai-challenge.md](docs/ai-challenge.md)
- Screenshot kondisi awal: folder `screanshoot/`
