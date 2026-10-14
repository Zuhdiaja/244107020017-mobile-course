# Week 7: Clean Architecture

Refactor project Minggu 6 (`campus_notify`: auth + secure storage + FCM + deep
link) menjadi struktur **feature-first Clean Architecture**. Perilaku aplikasi
tidak berubah — yang berubah adalah pemisahan tanggung jawab dan arah
dependensi.

Dokumentasi fitur asli Minggu 6 tetap dipertahankan di bagian bawah README ini
sebagai kondisi *before*.

## Identitas

| Keterangan | Detail |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

## Teknologi

- Flutter
- Flutter Riverpod
- GoRouter
- Dio
- flutter_secure_storage
- firebase_core, firebase_messaging
- flutter_local_notifications

---

# Praktikum 1: Audit layer project lama

Audit dilakukan **sebelum** refactor, sesuai codelab. Bukti mentah (perintah
`rg` + hasilnya) tersimpan di
[docs/praktikum-1-audit.md](docs/praktikum-1-audit.md).

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

Arah dependensi yang harus dibuktikan:

```text
presentation ──> domain <── data
     │                        │
     └── tidak boleh ─────────┘
         menyentuh Dio / secure storage / Firebase
```

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

# Lampiran: dokumentasi fitur Minggu 6 (kondisi *before*)

# Minggu 6 — Praktikum 1: Login, Secure Storage, dan Token Refresh

## Penyimpanan token yang aman

```dart
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() => _storage.deleteAll();
}
```

## Refresh otomatis dengan Dio

`lib/data/api_client.dart` menambahkan interceptor yang:

1. Menyisipkan header `Authorization: Bearer <access>` pada setiap request.
2. Saat menerima `401`, menukar refresh token menjadi access token baru,
   menyimpannya kembali ke secure storage, lalu mengulang request sekali.
3. Jika refresh ikut kedaluwarsa, membersihkan sesi (`clear()`) sehingga
   pengguna dipaksa login ulang.

## Hasil Praktikum

### Halaman Login

![Halaman login](screanshoot/prak1-login.png)

### Validasi form

Email tanpa `@` atau kata sandi kurang dari 6 karakter ditolak sebelum request
dikirim.

![Validasi form login](screanshoot/prak1-validasi.png)

### Halaman Beranda setelah login

![Halaman beranda](screanshoot/prak1-home.png)

---

# Minggu 6 — Praktikum 2: FCM, Permission, dan Token Lifecycle

## Inisialisasi Firebase

`Firebase.initializeApp()` dipanggil di `main()` sebelum `runApp`, kemudian
service FCM dijalankan:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await initLocalNotifications();
  await requestNotificationPermission();

  final dio = container.read(apiClientProvider);
  await initFcmToken(onToken: (token) async {
    // kirim token ke backend (POST /devices)
  });

  runApp(...);
}
```

## Permission notifikasi

Izin `POST_NOTIFICATIONS` ditambahkan di `AndroidManifest.xml`, lalu dialog
runtime diminta lewat `requestPermission()`.

## Token lifecycle

```dart
Future<void> initFcmToken({required Future<void> Function(String token) onToken}) async {
  // 1. Ambil token saat ini dan kirim ke backend.
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  //    Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // 3. Langganan topik kampus.
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}
```

## Hasil Praktikum

### Dialog izin notifikasi

![Dialog izin notifikasi](screanshoot/prak2-permission.png)

### Token FCM tampil terpotong

![Token FCM terpotong](screanshoot/prak2-token-fcm.png)

### Pengiriman token ke backend (POST /devices)

Pengiriman ke `example-campus-api.test` menghasilkan `connectionError` karena
backend memang belum tersedia — hal ini didokumentasikan, sesuai codelab.

![Log POST /devices](screanshoot/prak2-post-devices.png)

### Notifikasi tes dari Firebase Console

![Notifikasi dari Console di tray](screanshoot/prak2-notif-console.png)

![Campaign di Firebase Console](screanshoot/prak2-console-campaign.png)

### Token refresh setelah clear data

- token lama: `cB8ZfbSKQLmr...`
- token baru: `f7ucvfOkReiJ...`

![Token lama](screanshoot/prak2-token-lama.png)

![Token baru setelah clear data](screanshoot/prak2-token-baru.png)

---

# Minggu 6 — Praktikum 3: Tiga App State dan Deep Link

## Background handler (top-level)

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan akses BuildContext / Riverpod di sini.
  debugPrint('[FCM background] id=${message.messageId} '
      'route=${message.data['route']}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}
```

## Tiga handler app state

```dart
void listenForeground(void Function(String route) go) {
  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromMessage(message.data);
    const androidDetails = AndroidNotificationDetails(
      'pengumuman', 'Pengumuman Kampus',
      importance: Importance.high, priority: Priority.high,
    );
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  // Background -> diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(routeFromMessage(message.data));
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(routeFromMessage(initial.data));
  if (pendingDeepLink != null) go(pendingDeepLink!);
}
```

## Payload uji (notification + data)

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": {
      "route": "/pengumuman/3",
      "id": "3"
    }
  }
}
```

## Topic messaging

```dart
await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
```

Aturan: topik untuk broadcast (semua mahasiswa / satu kelas), token perangkat
untuk pesan personal (nilai, tagihan).

## Hasil Praktikum

### State Foreground

Banner ditampilkan manual lewat `flutter_local_notifications` pada `onMessage`.

![Banner foreground](screanshoot/prak3-fg-banner.png)

Klik banner menavigasi ke `data.route` (`/pengumuman/3`):

![Hasil klik foreground](screanshoot/prak3-fg-hasil.png)

### State Background

Banner sistem muncul otomatis, lalu klik memicu `onMessageOpenedApp`.

![Banner background](screanshoot/prak3-bg-banner.png)

![Hasil klik background](screanshoot/prak3-bg-hasil.png)

### Log handler

![Log handler FCM](screanshoot/prak3-log-handler.png)

### Tabel pengujian tiga app state

| State | Yang diharapkan | Hasil |
| --- | --- | --- |
| Foreground | Banner lokal muncul, klik masuk `/pengumuman/3` | Berhasil |
| Background | Banner sistem muncul, klik masuk `/pengumuman/3` | Berhasil |
| Terminated | Aplikasi terbuka ke `/pengumuman/3` via `getInitialMessage` | Tidak teruji (batasan OEM) |

> Catatan: pada perangkat OPPO/ColorOS, sistem membekukan aplikasi secara
> agresif saat aplikasi ditutup, sehingga notifikasi FCM tidak dikirimkan ke
> aplikasi dalam state terminated. Perilaku ini merupakan kebijakan manajemen
> baterai OEM, bukan kesalahan kode.

---

# Minggu 6 — AI Challenge

Dokumentasi prompt, output awal AI, daftar perbaikan manual, alasan teknis,
dan tabel hasil uji tiga app state tersedia di
[docs/ai-challenge.md](docs/ai-challenge.md).

Ringkasan verifikasi draf AI:

- Background handler berupa fungsi top-level dengan `@pragma('vm:entry-point')`.
- `onTokenRefresh` benar-benar mengirim token baru ke backend (`POST /devices`),
  bukan sekadar log.
- Foreground memakai local notification manual (`onMessage` + `_local.show`).
- Klik dari state foreground & background masuk ke `/pengumuman/3`.
- Token tidak di-hardcode dan hanya ditampilkan terpotong.
- Kredensial backend (`service-account.json`) tidak di-commit.

---

# Minggu 6 — Refactoring dan Testing

Refactoring yang dilakukan:

1. **Konstanta rute** dipusatkan di `lib/routes.dart` (`AppRoutes`) agar deep
   link FCM dan GoRouter memakai sumber yang sama.
2. **Parsing `RemoteMessage -> route`** diekstrak menjadi fungsi murni
   `routeFromMessage(Map<String, dynamic> data)` sehingga dapat diunit-test
   tanpa Firebase.
3. **Pemetaan `DioException -> pesan ramah pengguna`** dipindah ke
   `lib/data/api_errors.dart` (`friendlyErrorMessage`).

Hasil validasi:

```text
flutter analyze : No issues found!
flutter test    : 9 tests passed
```
---

# Minggu 6 — Struktur Project (sebelum refactor)

```text
lib/
├── main.dart                     # init Firebase, guard route, deep link handler
├── routes.dart                   # konstanta rute (Refactoring #1)
├── data/
│   ├── token_store.dart          # penyimpanan token di secure storage
│   ├── auth_repository.dart      # mock login & refresh
│   ├── api_client.dart           # Dio + interceptor refresh 401
│   └── api_errors.dart           # pemetaan error ramah pengguna (Refactoring #3)
├── messaging/
│   └── push_service.dart         # permission, token lifecycle, 3 state, routeFromMessage
├── providers/
│   └── auth_provider.dart        # provider auth + token store + Dio
└── pages/
    ├── login_page.dart
    ├── home_page.dart
    └── announcement_page.dart    # target deep link /pengumuman/:id
```

---

# Minggu 6 — Cara Menjalankan

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
