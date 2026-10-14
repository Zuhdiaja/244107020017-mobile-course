# AI Challenge — Authentication, Security & FCM

Dokumen ini mencatat prompt AI, output awal, perbaikan manual, alasan teknis,
dan hasil verifikasi untuk fitur autentikasi, penyimpanan token, dan FCM.

## Prompt yang digunakan

```text
Aplikasi Flutter Campus Notification App.
Stack: firebase_messaging, flutter_local_notifications,
flutter_secure_storage, go_router, Riverpod.
Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh (kirim ke POST /devices)
- onMessage (tampilkan local notification manual)
- onMessageOpenedApp + getInitialMessage (navigasi ke data.route)
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')
Tandai bagian yang BERBEDA untuk Android 13+ vs iOS,
dan bagian yang tidak boleh mengakses BuildContext.
```

## Output awal AI

AI menghasilkan draf service FCM dan boilerplate auth berdasarkan codelab.
Beberapa bagian berupa potongan kode yang belum bisa langsung dijalankan:

- `main.dart` masih berisi snippet `GoRouter(...)` tanpa `main()`,
  `MaterialApp`, dan import.
- `auth_provider.dart` memakai `tokenStoreProvider` dan
  `authRepositoryProvider` yang belum didefinisikan.
- `push_service.dart` memuat contoh `await initFcmToken(...)` di top-level
  (tidak valid di luar fungsi `main`).
- `_local.show(...)` memakai parameter posisional (API lama).
- Halaman UI (login, home, announcement) belum ada.

## Perbaikan manual

| # | Bagian | Perbaikan |
| --- | --- | --- |
| 1 | `main.dart` | Ditulis utuh: `main()`, `Firebase.initializeApp()`, `ProviderScope`, `MaterialApp.router`, guard route |
| 2 | `auth_provider.dart` | Menambah provider `tokenStoreProvider`, `authRepositoryProvider`, `apiClientProvider` |
| 3 | `push_service.dart` | Menghapus contoh top-level, memindahkannya ke `main()` |
| 4 | `_local.show` | Menyesuaikan ke API 22.x (named parameter `id`, `title`, `body`, `notificationDetails`, `payload`) |
| 5 | `_local.initialize` | Menyesuaikan ke `initialize(settings: ...)` |
| 6 | Guard route | `redirect` memakai `await container.read(authStateProvider.future)` agar cold start tidak salah diarahkan ke `/login` saat provider masih loading |
| 7 | Deep link foreground | Menambah `setDeepLinkNavigator` agar klik banner foreground benar-benar bernavigasi |
| 8 | Izin Android | Menambah `POST_NOTIFICATIONS` dan core library desugaring |
| 9 | Build | Menjalankan dari drive tanpa spasi (`subst M:`) karena path ber-spasi memecah native assets hook |

## AI Verification Checklist

- **Background handler top-level + `@pragma('vm:entry-point')`?** ✅ Ya —
  `firebaseMessagingBackgroundHandler` adalah fungsi top-level.
- **`onTokenRefresh` benar-benar mengirim token baru, bukan hanya log?** ✅ Ya —
  callback `onToken` memanggil `dio.post('/devices')`. Dibuktikan token berubah
  `cB8ZfbSKQLmr...` → `f7ucvfOkReiJ...` setelah clear data.
- **Foreground memakai local notification manual?** ✅ Ya — `onMessage`
  memanggil `_local.show`.
- **Klik dari ketiga state masuk rute benar?** ✅ Foreground & background
  terbukti masuk `/pengumuman/3`. Terminated tidak teruji (dibatasi kebijakan
  baterai ColorOS/OEM).
- **Token/secret tidak di-hardcode dan tidak di-log penuh?** ✅ Token sesi &
  token FCM ditampilkan terpotong (12 karakter). Kredensial backend
  (`service-account.json`) tidak di-commit (masuk `.gitignore`).
- **Keputusan final dan alasan teknis** — lihat bagian Alasan teknis.

## Alasan teknis

1. **`routeFromMessage` dipisah sebagai fungsi murni** agar dapat diuji tanpa
   Firebase dan dipakai konsisten oleh ketiga handler.
2. **`POST /devices` diarahkan ke `example-campus-api.test`** (server simulasi
   codelab). `connectionError` diharapkan dan didokumentasikan; saat backend
   kampus siap, cukup ganti `baseUrl`.
3. **`friendlyErrorMessage`** memisahkan pemetaan error Dio dari UI, sehingga
   widget hanya menerima pesan siap tampil.
4. **Guard route async** mencegah kedipan ke `/login` saat aplikasi baru dibuka.
5. **Konstanta rute** (`AppRoutes`) menyatukan string rute agar deep link FCM
   dan GoRouter tidak pernah tidak sinkron.

## Tabel hasil uji tiga app state

| State | Yang diharapkan | Hasil |
| --- | --- | --- |
| Foreground | Banner lokal muncul, klik → `/pengumuman/3` | ✅ Berhasil |
| Background | Banner sistem muncul, klik → `/pengumuman/3` | ✅ Berhasil |
| Terminated | Aplikasi terbuka ke `/pengumuman/3` via `getInitialMessage` | ⚠️ Tidak teruji (kebijakan baterai OEM ColorOS memblokir FCM ke app yang ditutup) |
