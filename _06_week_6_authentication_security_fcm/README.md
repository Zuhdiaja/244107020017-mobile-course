# Week 6: Authentication, Security & FCM

## Identitas

| Keterangan | Detail |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

# Praktikum 1: Login, Secure Storage, dan Token Refresh

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

Form email dan kata sandi dengan validasi serta tombol **Masuk**.

![Halaman login](screanshoot/prak1-login.png)

### Validasi form

Email tanpa `@` atau kata sandi kurang dari 6 karakter ditolak sebelum request
dikirim.

![Validasi form login](screanshoot/prak1-validasi.png)

### Halaman Beranda setelah login

Login berhasil menyimpan token di secure storage, lalu pengguna diarahkan ke
halaman Beranda. Tombol logout di kanan atas akan membersihkan token dan
mengembalikan pengguna ke halaman Login.

![Halaman beranda](screanshoot/prak1-home.png)

---

# Praktikum 2: FCM, Permission, dan Token Lifecycle

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
    ...
  });

  runApp(...);
}
```

## Permission notifikasi

Izin `POST_NOTIFICATIONS` ditambahkan di `AndroidManifest.xml`, lalu dialog
runtime diminta lewat `requestPermission()`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

## Token lifecycle

`lib/messaging/push_service.dart`:

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

Saat aplikasi pertama kali dijalankan, dialog izin `POST_NOTIFICATIONS`
muncul (Android 13+).

![Dialog izin notifikasi](screanshoot/prak2-permission.png)

### Token FCM tampil terpotong

![Token FCM terpotong](screanshoot/prak2-token-fcm.png)

### Pengiriman token ke backend (POST /devices)

Log terminal menunjukkan token yang didaftarkan. Pengiriman ke
`example-campus-api.test` menghasilkan `connectionError` karena backend
memang belum tersedia — hal ini didokumentasikan, sesuai codelab.

![Log POST /devices](screanshoot/prak2-post-devices.png)

### Notifikasi tes dari Firebase Console

dari Firebase Console (Messaging) saat aplikasi berada di state background; banner masuk ke notification tray.

![Notifikasi dari Console di tray](screanshoot/prak2-notif-console.png)

![Campaign di Firebase Console](screanshoot/prak2-console-campaign.png)

### Token refresh setelah clear data

Setelah data aplikasi dihapus, FCM menerbitkan token baru dan `onTokenRefresh`/`getToken()` Perbandingan log:

- token lama: `cB8ZfbSKQLmr...`
- token baru: `f7ucvfOkReiJ...`

![Token lama](screanshoot/prak2-token-lama.png)

![Token baru setelah clear data](screanshoot/prak2-token-baru.png)

