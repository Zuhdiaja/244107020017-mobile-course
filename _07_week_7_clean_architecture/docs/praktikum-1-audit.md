# Praktikum 1 — Audit Layer Project Lama

Dokumen ini adalah bukti (evidence) pelaksanaan Praktikum 1 codelab
[#07 | Clean Architecture](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/).

- Project asal: Minggu 6 `campus_notify`
- Folder : `_07_week_7_clean_architecture/`
- Baseline: `flutter analyze` → `No issues found!`

---

## 1. Pemetaan file ke layer

| File | Layer saat ini | Masalah |
| --- | --- | --- |
| `lib/pages/login_page.dart` | presentation | Tidak menyentuh jaringan/DB (OK). Namun menampilkan `'Login gagal: ${state.error}'` mentah, belum berupa pesan `Failure` yang ramah. |
| `lib/pages/home_page.dart` | presentation (**kotor**) | Mengimpor `package:firebase_messaging` langsung; memanggil `FirebaseMessaging.instance.getToken()`; membaca secure storage lewat `ref.read(tokenStoreProvider)`. Presentation menembus data & framework. |
| `lib/pages/announcement_page.dart` | presentation | OK — hanya UI statis dari `id` deep link, tidak mengambil data. |
| `lib/providers/auth_provider.dart` | presentation (state) + DI tercampur | Mengimpor `package:dio` dan membangun `Dio` (`apiClientProvider`) di lapisan presentasi. Composition root bercampur dengan state UI. |
| `lib/data/auth_repository.dart` | data (**kontrak tercampur**) | `AuthSession` (entity) + `AuthRepository` (kontrak) + implementasi mock berada di satu file. Belum ada interface. |
| `lib/data/token_store.dart` | data | OK — akses `flutter_secure_storage` memang tugas data layer. Catatan: hanya dipakai provider, tetapi juga dibaca langsung oleh halaman. |
| `lib/data/api_client.dart` | data | Lokasi OK, tetapi `buildApiClient` bergantung pada `AuthRepository` **konkret**, bukan abstraksi (melanggar Dependency Inversion). |
| `lib/data/api_errors.dart` | data | Berisi pemetaan `DioException` → pesan. Seharusnya menjadi `Failure` di `core/`, bukan detail Dio. |
| `lib/messaging/push_service.dart` | data / infrastruktur | Mencampur Firebase + notifikasi lokal + **navigasi UI** (`_navigate`). Infrastruktur tahu tentang rute UI. Sisi baik: `routeFromMessage()` sudah fungsi murni. |
| `lib/main.dart` | composition root | Mengimpor Dio, Firebase, GoRouter; melakukan `dio.post('/devices')` langsung di `main()` — akses jaringan di luar data layer. |
| `lib/routes.dart` | core (routing) | OK — konstanta rute sudah terpusat. |

---

## 2. Tiga pelanggaran (hasil grep)

### Pencarian 1 — widget menyentuh jaringan / database langsung

```bash
rg "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets
```

Hasil: **nol hasil** (tidak ada folder `lib/widgets`).

### Pencarian 2 — logika bisnis di dalam `build()`

```bash
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
```

Hasil: **nol hasil**.

### Pencarian 3 — instansiasi manual (DI bocor)

```bash
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
```

Hasil: **1 hasil**

```text
lib/providers/auth_provider.dart:13:
    Provider<AuthRepository>((ref) => AuthRepository());
```

Penilaian: ini **wiring DI yang sah** (berada di composition root, bukan di
widget), sehingga bukan pelanggaran. Namun baris ini membuktikan `AuthRepository`
masih kelas konkret tanpa interface, sehingga belum bisa diganti fake saat test.

---

## 3. Struktur target

Feature-first, satu fitur punya tiga layer. Fitur yang direfactor mengikuti
fitur yang benar-benar ada di project (auth + deep link pengumuman + FCM):

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
│       └── presentation/providers/notification_providers.dart
├── routes.dart
└── main.dart
```
---

## 5. Daftar item refactor (hasil audit)

1. Pecah `lib/data/auth_repository.dart` → entity `AuthSession` (domain),
   interface `AuthRepository` (domain), dan `AuthRepositoryImpl` (data).
2. Pindahkan `TokenStore` ke `features/auth/data/datasources/`.
3. Buat `Failure` di `core/failures.dart`; ubah `api_errors.dart` menjadi
   pemetaan ke `Failure` yang ramah pengguna.
4. Pindahkan `push_service.dart` ke fitur `notifications` (data), dan keluarkan
   logika navigasi darinya.
5. Bersihkan `home_page.dart`: hapus import `firebase_messaging` dan akses
   `tokenStoreProvider`; halaman hanya membaca state dari provider.
6. Pisahkan wiring DI dari state: `auth_providers.dart` menjadi satu-satunya
   tempat `new` repository/Dio.
7. Tambahkan use case `Login` sebagai operasi bisnis auth.
8. Ekstrak parsing rute (sudah ada: `routeFromMessage`) dan format tanggal ke
   `core/format.dart` sebagai fungsi murni.
