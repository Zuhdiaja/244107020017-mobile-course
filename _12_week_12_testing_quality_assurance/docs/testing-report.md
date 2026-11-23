# Laporan Pengujian — Minggu 12



---

## 1. Ringkasan hasil

| Pemeriksaan | Perintah | Hasil |
| --- | --- | --- |
| Analisis statis | `flutter analyze` | No issues found! |
| Format | `dart format --set-exit-if-changed lib test integration_test test_driver` | 61 berkas, 0 changed |
| Unit + widget test | `flutter test` | **130 lulus, 0 gagal** |
| Integration test (web) | `flutter drive -d web-server ...` | **All tests passed** |
| Cakupan | `flutter test --coverage` + `dart run tool/coverage_summary.dart` | **676/867 baris = 78,0%** |

---

## 2. Sebaran test per berkas

| Berkas | Jenis | Fokus |
| --- | --- | --- |
| `validators_test.dart` | Unit | Aturan email & sandi bersama |
| `announcement_model_test.dart` | Unit | Mapping JSON -> entity, payload rusak |
| `auth_session_model_test.dart` | Unit | `fromJson`/`toJson`/`toEntity` |
| `login_usecase_test.dart` | Unit | Validasi fail-fast, kasus tepi, kegagalan |
| `search_announcements_test.dart` | Unit | Filter judul, case-insensitive |
| `ask_assistant_test.dart` | Unit | Batas panjang, kuota sesi, prompt |
| `assistant_repository_test.dart` | Unit | Pemetaan error 429/401/koneksi |
| `gemini_response_model_test.dart` | Unit | Penggabungan parts kandidat |
| `api_errors_test.dart` | Unit | `DioException` -> `Failure` |
| `format_test.dart` | Unit | `routeFromMessage`, `maskSecret` |
| `announcement_repository_cache_test.dart` | Unit | Cache-first (warisan Minggu 11) |
| `search_debounce_test.dart` | Unit | Debounce 250 ms (warisan Minggu 11) |
| `login_page_test.dart` | Widget | Validator, loading, login gagal |
| `announcements_page_test.dart` | Widget | Loading, error, filter, navigasi |
| `home_page_test.dart` | Widget | Sesi, token terpotong, logout |
| `api_key_page_test.dart` | Widget | Simpan/hapus key, validasi |
| `announcement_page_test.dart` | Widget | Deep link `/pengumuman/:id` |
| `assistant_page_test.dart` | Widget | Empty state, indikator, error |
| `integration_test/app_test.dart` | Integrasi | Login -> cari -> detail |

Sebaran per jenis: 12 berkas unit, 6 berkas widget, 1 berkas integrasi.

---

## 3. Bukti test benar-benar bisa gagal (uji mutasi)

Test yang selalu hijau tidak membuktikan apa pun. Karena itu setiap klaim
utama diverifikasi dengan merusak implementasi sementara, menjalankan test,
lalu memulihkannya. Ketiga mutasi di bawah dijalankan sungguhan di mesin ini.

### 3.1 Mutasi: filter dibuat case-sensitive lagi

`SearchAnnouncements` dikembalikan ke versi awal Minggu 9
(`a.title.contains(trimmed)` tanpa `toLowerCase`).

```text
flutter test test/search_announcements_test.dart test/announcements_page_test.dart
-> +12 -7 : Some tests failed
```

Tujuh test merah, dan semuanya tepat pada klaim yang dipegang filter:

| Test yang merah |
| --- |
| `filter abaikan huruf besar/kecil` |
| `query dipangkas spasi sebelum dicocokkan` |
| `kecocokan di tengah judul ditemukan (bukan hanya awalan)` |
| `query huruf besar tetap menemukan judul huruf besar` |
| `kecocokan hanya dicek pada judul, bukan isi pengumuman` |
| `hasil tidak bisa dimodifikasi pemanggil` |
| `announcements_page: query cocok memfilter daftar yang tampil` |

### 3.2 Mutasi: debounce dihapus

`SearchQueryNotifier.set()` diubah agar langsung `state = value` (tanpa timer).

```text
flutter test test/search_debounce_test.dart
-> +2 -2 : Some tests failed
```

Gagal pada `lima ketikan beruntun menghasilkan satu pembaruan state` dan
`ketikan baru mereset jeda debounce` — dua klaim yang memang dipegang debounce.
Dua test lain tetap hijau (memang tidak bergantung pada jeda), yang berarti
test tidak sekadar "semua merah".

### 3.3 Mutasi: validasi API key dilonggarkan

Pemeriksaan `value.isEmpty` di `ApiKeyPage._save` dihapus.

```text
flutter test test/api_key_page_test.dart
-> +4 -2 : Some tests failed
```

Gagal persis pada `key kosong ditolak dengan pesan` dan `key berisi spasi saja
juga ditolak`. Empat test lain tetap hijau.

### 3.4 Kesimpulan uji mutasi

Tiga mutasi, tiga kali merah, semuanya pada test yang tepat, dan tidak pernah
membuat seluruh berkas merah. Ini alasan laporan ini tidak menjadikan angka
cakupan sebagai bukti utama: cakupan tidak berubah sedikit pun saat perilaku
dirusak dengan cara di atas.

Setelah ketiga mutasi dipulihkan, `flutter analyze` kembali bersih dan
`flutter test` kembali 130 lulus.

---

## 4. Integration test di Chrome - catatan eksekusi

Target codelab adalah perangkat/emulator Android, tetapi mesin ini tidak punya
perangkat aktif dan Developer Mode Windows mati (dibutuhkan `flutter test -d
windows` karena plugin butuh symlink). Karena itu integration test dijalankan
di **Chrome**.

Dua jalur dicoba, dan hasilnya berbeda — ini dicatat apa adanya karena penting
untuk siapa pun yang mengulang:

| Jalur | Hasil |
| --- | --- |
| `flutter drive -d chrome` | **Gagal / menggantung.** Berhenti di "Waiting for connection from debug service on Chrome", proses `dart` berhenti memakai CPU (beku), dan tidak ada satu pun proses `chrome.exe` yang lahir. Chrome sendiri sehat: diluncurkan manual dengan `--headless=new --remote-debugging-port=9222` merespons HTTP 200. Jadi masalahnya ada di cara Flutter meluncurkan Chrome, bukan di Chrome. |
| `flutter drive -d web-server` + ChromeDriver | **Berhasil.** Server menyajikan aplikasi di `http://localhost:5555`, ChromeDriver membuka Chrome, debug service tersambung, test berjalan, `All tests passed.` |

Perintah yang benar-benar dipakai:

```bash
# 1) ChromeDriver harus jalan lebih dulu
chromedriver --port=4444

# 2) Jalankan test lewat web-server, bukan -d chrome
flutter drive -d web-server --web-port=5555 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

Keluaran akhir:

```text
integration_test/app_test.dart is being served at http://localhost:5555
Debug service listening on ws://127.0.0.1:63621/.../ws
A Dart VM Service on Web Server is available at: http://127.0.0.1:63621/.../
All tests passed.
Application finished.
```

Yang diuji test ini (lulus di Chrome):

1. Guard route: belum punya sesi -> diarahkan ke `/login`.
2. Login dengan email + sandi valid.
3. Beranda menampilkan "Login berhasil" dan kartu fitur.
4. Kartu Pengumuman membuka daftar; data dari repository asli (5 item).
5. Cari "ujian" huruf kecil -> hanya "Ujian Akhir Semester Ganjil" tersisa
   (debounce 250 ms berjalan dengan waktu nyata, bukan waktu palsu).
6. Ketuk kartu -> halaman "Pengumuman #1" lewat rute.

Catatan: `-d web-server` di web **tidak** identik dengan perangkat Android
(integrasi FCM dan secure storage tidak ikut diuji). Keterbatasan ini sama
dengan Minggu 9 dan Minggu 11 yang juga memakai web saat emulator tidak stabil.

---

## 5. Temuan saat menulis test

Menulis test menemukan dua bug nyata yang tidak terlihat saat uji manual.

### 5.1 Aturan email terlalu longgar (diperbaiki)

`Login` (domain) memakai `trimmedEmail.contains('@')`, dan validator
`LoginPage` memakai aturan yang sama. Akibatnya:

- `"@"` dianggap email sah,
- `"budi@localhost"` dianggap sah,
- `"a@b@c"` dianggap sah.

Ditemukan karena test kasus tepi menulis `"@"` sebagai input tidak valid, dan
test-nya merah. Perbaikannya bukan di test, tetapi di kode: aturan dipindah ke
`core/validators.dart` ([`isValidEmail`](../lib/core/validators.dart)) dan
dipakai oleh domain maupun widget. Setelah itu 6 test baru (domain) dan 1 test
baru (widget) hijau.

### 5.2 Widget FCM tidak pernah dirender di layar kecil (bukan bug kode)

Test beranda sempat gagal menemukan teks `fcm : mengambil...`. Penyebabnya
bukan logika, tetapi `ListView` yang hanya membangun anak di dalam viewport:
pada ukuran layar test bawaan (800x600), kartu FCM berada di luar layar.
Perbaikannya di test (`tester.view.physicalSize`), bukan di aplikasi. Ini
contoh kegagalan test yang **bukan** regresi — dibedakan dengan membaca pesan
gagalnya, bukan dengan melonggarkan assertion.

### 5.3 Dua aturan ganda yang belum disatukan (dibiarkan, dicatat)

`Login` memakai `isValidPassword` (minimal 6 karakter) dan `LoginPage` memakai
fungsi yang sama, tetapi pesan yang tampil sengaja berbeda:
`"Kata sandi minimal 6 karakter"` (domain) versus `"Minimal 6 karakter"`
(widget). Ini disengaja agar pesan di form tetap ringkas; keduanya diuji
terpisah supaya perubahan salah satu tidak diam-diam merusak yang lain.

---

## 6. Cakupan kode

`flutter test --coverage` menghasilkan `coverage/lcov.info`. Angka di bawah
dibaca langsung dari file itu lewat `dart run tool/coverage_summary.dart`,
bukan diketik manual:

```text
TOTAL: 676/867 baris = 78,0%
```

Sebaran per folder:

| Area | Cakupan | Isi |
| --- | --- | --- |
| `lib/core/` | 100% untuk `format.dart`, `validators.dart` | fungsi murni |
| `lib/features/*/domain/` | 100% seluruh berkas | entity + use case |
| `lib/features/*/presentation/pages/` | 96–100% | login, pengumuman, detail, chat, API key |
| `lib/pages/home_page.dart` | 98,7% | beranda |
| `lib/app.dart` | 79,2% | pembuatan router (dipakai integration test) |
| `lib/features/*/data/datasources/` | 0–54% | Dio, secure storage, Gemini client |
| `lib/features/notifications/data/push_service.dart` | 0% | FCM + notifikasi lokal |

Berkas 0% dan alasannya:

| Berkas | Alasan tidak tercakup |
| --- | --- |
| `gemini_api_client.dart` | butuh HTTP nyata + API key |
| `api_client.dart` | interceptor Dio, hanya dipakai di jalur jaringan |
| `auth_repository_impl.dart` | `Future.delayed` + secure storage; kontraknya diuji via fake |
| `token_store.dart` | plugin platform (`flutter_secure_storage`) |
| `push_service.dart` | Firebase Messaging + notifikasi lokal, butuh perangkat |

Cara membaca angka ini:

- Cakupan mengukur **baris yang dijalankan**, bukan perilaku yang diperiksa.
- Seluruh logika bisnis (`domain/`) dan seluruh aturan tampilan (`presentation/`)
  berada di 96–100%.
- Tidak ada test tambahan yang ditulis hanya untuk menaikkan persentase. Sisa
  22% adalah kode yang secara teknis tidak bisa dijalankan `flutter test`, bukan
  kode yang dilewatkan karena malas.

---

## 7. Temuan yang belum terselesaikan

| Temuan | Dampak | Rencana |
| --- | --- | --- |
| `push_service.dart` tanpa test otomatis | Perubahan pada deep link FCM hanya terdeteksi saat uji manual | Diuji manual di perangkat; bisa diuji dengan fake `FirebaseMessaging` bila platform interface-nya disuntikkan |
| `main.dart` bootstrap tidak diuji | Kesalahan urutan inisialisasi Firebase tidak tertangkap test | `app.dart` sudah dipisah sehingga bagian yang berisiko kecil; bootstrap tetap manual |
| Belum ada golden test | Perubahan visual tidak tertangkap | Belum diprioritaskan: tampilan masih berubah cepat |
| Cache pengumuman tanpa invalidasi (warisan Minggu 11) | Data bisa basi bila sumber diganti remote | Tambah TTL saat data source remote dipakai |
| Integration test hanya satu alur | Alur chat asisten belum diuji end-to-end | Kandidat berikutnya; butuh fake Gemini di level container |

---