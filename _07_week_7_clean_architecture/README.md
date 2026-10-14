# Week 7: Clean Architecture

Refactor project Minggu 6 (`campus_notify`: auth + secure storage + FCM + deep
link) menjadi struktur **feature-first Clean Architecture**.

Perilaku aplikasi tidak berubah — yang berubah adalah **pemisahan tanggung
jawab** dan **arah dependensi**. Bukan sekadar memindahkan file ke folder baru.

## Identitas

| Keterangan | Detail |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

## Tujuan

- Menjelaskan prinsip SOLID dan separation of concerns pada kode Flutter.
- Membedakan struktur feature-first vs layer-first beserta trade-off-nya.
- Menjelaskan tiga layer (presentation, domain, data) dan aturan dependensi.
- Membedakan entity vs model, serta peran repository, use case, dan DI.
- Merefactor project Minggu 6 menjadi struktur feature-first yang terpisah
  layer-nya.
- Menguji use case dengan repository palsu tanpa database atau jaringan.

## Fitur utama

Fitur yang direfactor adalah fitur yang **benar-benar ada** di aplikasi:

| Fitur | Isi |
| --- | --- |
| `auth` | Login, sesi, penyimpanan access/refresh token di secure storage, logout, refresh token otomatis saat `401`. |
| `announcements` | Halaman tujuan deep link `/pengumuman/:id` dari payload notifikasi. |
| `notifications` | Permission, token lifecycle FCM, tiga app state (foreground, background, terminated), deep link. |

## Stack teknologi

- Flutter
- Flutter Riverpod
- GoRouter
- Dio
- flutter_secure_storage
- firebase_core, firebase_messaging
- flutter_local_notifications

## Diagram layer dan arah dependensi

```text
presentation (widget, notifier, router)
      |
      v  bergantung ke
domain (entity, repository interface, use case, failure)
      ^
      |  diimplementasikan oleh
data (model, repository impl, Dio, SQLite, secure storage)
```

Aturan emas (**dependency rule**): dependensi hanya mengarah ke dalam. `domain`
tidak tahu apa pun tentang Flutter, Dio, atau Firebase — sehingga logika bisnis
dapat diuji murni.

```text
presentation ──> domain <── data
     │                        │
     └── tidak boleh ─────────┘
         menyentuh Dio / secure storage / Firebase
```

---

# Praktikum 1: Audit layer project lama

Audit dilakukan **sebelum** refactor. Bukti mentah (perintah `rg` beserta
hasilnya) tersimpan di [docs/praktikum-1-audit.md](docs/praktikum-1-audit.md).

Baseline: `flutter analyze` → `No issues found!`

## Struktur sebelum refactor

Layer-first, belum dipisah per fitur:

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
| `pages/login_page.dart` | presentation | Tidak menyentuh jaringan/DB. Namun menampilkan `state.error` mentah, belum `Failure` ramah pengguna. |
| `pages/home_page.dart` | presentation (**kotor**) | Impor `package:firebase_messaging` langsung, panggil `FirebaseMessaging.instance.getToken()`, dan baca secure storage lewat `ref.read(tokenStoreProvider)`. |
| `pages/announcement_page.dart` | presentation | OK — UI statis dari `id` deep link, tidak mengambil data. |
| `providers/auth_provider.dart` | presentation (state) + DI tercampur | Impor `package:dio` dan membangun `Dio` (`apiClientProvider`) di lapisan presentasi. |
| `data/auth_repository.dart` | data (**kontrak tercampur**) | `AuthSession` + kontrak + implementasi mock dalam satu file; belum ada interface. |
| `data/token_store.dart` | data | OK — akses secure storage memang tugas data layer. |
| `data/api_client.dart` | data | Lokasi OK, tetapi bergantung pada `AuthRepository` **konkret**, bukan abstraksi. |
| `data/api_errors.dart` | data | Seharusnya menjadi `Failure` di `core/`, bukan detail Dio. |
| `messaging/push_service.dart` | data / infrastruktur | Mencampur Firebase + notifikasi lokal + navigasi UI (`_navigate`). |
| `main.dart` | composition root | Melakukan `dio.post('/devices')` langsung di `main()`. |
| `routes.dart` | core (routing) | OK — konstanta rute sudah terpusat. |

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
bukan di widget). Meski begitu, baris tersebut membuktikan `AuthRepository`
masih konkret tanpa interface.

## 3. Temuan tambahan di luar pola grep

Pola grep resmi tidak menangkap kebocoran berikut karena halaman mengakses
melalui provider/framework, bukan package mentah:

| Lokasi | Temuan |
| --- | --- |
| `pages/home_page.dart:1` | `import 'package:firebase_messaging/...'` → presentation ke framework |
| `pages/home_page.dart:49` | `FirebaseMessaging.instance.getToken()` di halaman |
| `pages/home_page.dart:34` | `ref.read(tokenStoreProvider)` → presentation langsung ke data |
| `providers/auth_provider.dart:1` | `import 'package:dio/dio.dart'` di lapisan presentasi |
| `main.dart:87` | `dio.post('/devices', ...)` di luar data layer |
| `data/auth_repository.dart` | entity + kontrak + implementasi menyatu |

**Kesimpulan audit:** pelanggaran utama ada di presentation (`home_page.dart`,
`auth_provider.dart`) dan pada pencampuran kontrak/implementasi repository.

## 4. Struktur target

### Catatan: `notes` hanyalah contoh dari codelab

Codelab menampilkan contoh struktur dengan nama fitur **`notes`**:

```text
lib/features/notes/{domain,data,presentation}
```

Itu **contoh generik**, bukan instruksi membuat fitur `notes`. Codelab ditulis
untuk dua kemungkinan project asal: Minggu 5 (`week5_offline_notes`) atau
Minggu 6 (`campus_notify`).

**Project ini tidak punya fitur `notes`.** Yang dikerjakan adalah versi project
ini sendiri, memakai fitur yang sudah ada. Codelab juga menegaskan *"Jangan buat
fitur baru"* — praktikum ini memindahkan dan memisahkan kode yang sudah jalan.

Padanan contoh codelab ke fitur di project ini:

| Contoh di codelab | Padanan di project ini |
| --- | --- |
| `features/notes/domain/entities/note.dart` | `features/auth/domain/entities/auth_session.dart` |
| `features/notes/domain/repositories/note_repository.dart` | `features/auth/domain/repositories/auth_repository.dart` |
| `features/notes/domain/usecases/get_notes.dart` | `features/auth/domain/usecases/login.dart` |
| `features/notes/data/models/note_model.dart` | tidak ada — data auth berupa token, bukan JSON/SQLite |
| `features/notes/data/repositories/note_repository_impl.dart` | `features/auth/data/repositories/auth_repository_impl.dart` |
| `features/notes/presentation/providers/notes_providers.dart` | `features/auth/presentation/providers/auth_providers.dart` |
| `features/notes/presentation/pages/notes_page.dart` | `features/auth/presentation/pages/login_page.dart` |
| `core/providers.dart` (opsional) | tidak perlu; `tokenStoreProvider` tetap di fitur auth |

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
│       └── presentation/providers/notification_providers.dart
├── routes.dart
└── main.dart
```

### Urutan pengerjaan

1. **`auth`** — dikerjakan lebih dulu dan paling lengkap, karena sudah punya
   repository, token store, session, dan state login. Ini yang memenuhi syarat
   "1 fitur penuh" (domain + data + presentation).
2. **`announcements`** — cukup halaman dan provider, karena
   `announcement_page.dart` masih UI statis dari `id` deep link. Tidak dibuat
   repository/API palsu hanya demi struktur.
3. **`notifications`** — `push_service.dart` dipindahkan, dan logika navigasi
   dikeluarkan darinya.

Pembagian `announcements` vs `notifications`: FCM masuk `notifications`,
sedangkan halaman tujuan deep link `/pengumuman/:id` masuk `announcements`.
Bila dinilai pemisahan itu over-engineering, keduanya boleh digabung menjadi
satu fitur `announcements` — keputusan ini bagian dari AI Challenge dan wajib
disertai alasan tertulis.

## 5. Item refactor

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

# Cara Menjalankan

```bash
flutter pub get
flutter run
```

Memeriksa kualitas kode:

```bash
flutter analyze
flutter test
```

> **Catatan (Windows) — path Flutter SDK mengandung spasi.**
> Build gagal dengan `'D:\Semester' is not recognized as an internal or
> external command` karena `hooks_runner` menjalankan executable Dart lewat
> `cmd.exe` tanpa mengutip path.
>
> Solusi yang dipakai: buat junction tanpa spasi ke Flutter SDK, lalu arahkan
> Gradle ke junction tersebut.
>
> ```powershell
> New-Item -ItemType Junction -Path "C:\Users\Zuhdi\flutter" -Target "D:\Semester 5\flutter"
> ```
>
> Ubah `android/local.properties`:
>
> ```properties
> flutter.sdk=C:\\Users\\Zuhdi\\flutter
> ```
>
> Tambahkan `C:\Users\Zuhdi\flutter\bin` ke PATH, lalu jalankan dari terminal
> baru:
>
> ```bash
> flutter run
> ```

---

# Status pengerjaan

| Tahap | Status |
| --- | --- |
| Praktikum 1 — audit layer project lama | Selesai |
| Praktikum 2 — domain dan data per fitur | Belum |
| Praktikum 3 — presentation, DI, dan verifikasi | Belum |
| AI Challenge | Belum |
| Refactoring Challenge | Belum |
| Testing use case dengan repository palsu | Belum |
| Mini project / Industry Challenge | Belum |

## Hasil validasi saat ini

```text
flutter analyze : No issues found!
flutter test    : 9 tests passed
```

## Bukti

- Audit mentah: [docs/praktikum-1-audit.md](docs/praktikum-1-audit.md)
- Screenshot kondisi awal: folder `screanshoot/`

> Catatan: folder screenshot masih bernama `screanshoot/` (bawaan project
> sebelumnya). Codelab mini project meminta nama `screenshots/`; folder akan
> dirapikan beserta pembaruan tautannya pada tahap dokumentasi akhir.
