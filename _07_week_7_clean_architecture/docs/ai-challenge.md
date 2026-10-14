# AI Challenge — prompt, usulan, dan keputusan

Dokumen ini menyimpan material AI Challenge dari codelab
[#07 | Clean Architecture](https://jti-polinema.github.io/flutter-codelab/07-minggu-7-clean-architecture/):
prompt yang dipakai, usulan awal yang keluar, tabel usulan versus keputusan
final, serta hasil verifikasi grep.

Bagian yang tidak sama dengan usulan awal adalah keputusan saya sendiri, bukan
hasil prompt ulang. Alasannya saya tulis di tabel dan di bagian
[Refleksi](#refleksi).

---

## 1. Prompt

Prompt diambil dari bagian *AI Prompt Challenge* codelab:

```text
Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging},
repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

Prompt dikirim beserta isi `lib/` project Minggu 6 supaya usulan tidak
mengarang nama file.

---

## 2. Ringkasan usulan awal AI

Usulan awal kembali ke pola umum Clean Architecture. Ringkasnya:

| Poin | Usulan awal AI |
| --- | --- |
| Struktur | `lib/features/{auth,announcements}/{domain,data,presentation}` plus `lib/core/` |
| `auth` | Pecah `auth_repository.dart` jadi entity + interface + impl; `Login` dijadikan use case |
| `announcements` | entity + interface + impl + use case `GetAnnouncements` + provider, sama seperti `auth` |
| `notifications` | `push_service.dart` masuk fitur sendiri, navigasi dikeluarkan |
| `core/` | `failures.dart` dan `format.dart` |
| Wiring | Satu file provider per fitur, Riverpod `Provider` |
| Test | `FakeAuthRepository` untuk menguji use case `Login` |

---

## 3. Usulan versus keputusan final

| No | Usulan awal AI | Keputusan final | Alasan teknis |
| --- | --- | --- | --- |
| 1 | `announcements` diberi entity + repository interface + impl + use case, sejajar dengan `auth` | **Ditolak.** `announcements` hanya punya satu halaman UI statis yang membaca `id` dari route argument. Repository-nya tidak ada, sumber datanya juga tidak ada. | Membuat repository tanpa implementasi berarti menambah interface kosong. Kalau tidak ada yang mengimplementasikan dan tidak ada data yang diambil, lapisan itu tidak menambah apa pun selain variasi nama file. Aturan codelab
sendiri: jangan buat fitur baru. |
| 2 | `home_page.dart` dipindahkan ke `features/auth/presentation/pages/` | **Ditolak.** Tetap di `lib/pages/` | Halaman itu membaca data dari `auth` (sesi) *dan* `notifications` (token FCM). Kalau ditaruh di `auth`, maka `auth`
mengimpor presentation `notifications` — persis yang disebut codelab di
*Error umum*: fitur berkomunikasi lewat import widget. Halaman lintas fitur
bukan milik satu fitur. |
| 3 | `GetAnnouncements` sebagai use case, dan use case untuk tiap operasi auth | **Sebagian diterima.** Use case `Login` dibuat; `refresh` tidak | `Login` memegang aturan bisnis (email mengandung `@`, password minimal 6 karakter) sehingga layak dipakai. `refresh` hanya meneruskan panggilan, tanpa aturan apa pun — membuat use case untuk itu persis over-engineering yang ditandai codelab. |
| 4 | `AuthRepository` kontrak tetap seperti aslinya | **Diperluas** dengan `currentSession()` dan `logout()` | Tanpa dua method ini, `home_page.dart` dan `AuthNotifier` harus membaca `TokenStore` sendiri. Itu berarti presentation menembus ke `flutter_secure_storage`, dan grep sterilitas presentation tidak akan nol. Kontrak repository adalah tempat yang benar untuk itu. |
| 5 | Semua provider dikumpulkan per fitur, tanpa catatan bahwa antar-presentation tidak boleh saling import | **Diterima, dengan satu file saja** | Semua dependensi runtime di aplikasi ini nyatanya milik `auth` dan `notifications`. Memecah file provider per fitur yang isinya cuma meneruskan tidak menambah kejelasan. `auth_providers.dart` menjadi satu-satunya tempat presentation menyentuh `data`, dan hanya untuk membangun objek. |
| 6 | `api_errors.dart` dipindahkan ke `core/` sebagai `Failure` | **Belum** — masih `String` (lihat `Praktikum 4`) | Pada tahap ini pemetaan error belum disentuh supaya test yang sudah ada tetap hijau. Sudah tercatat sebagai item terbuka. |
| 7 | Tambah `format.dart` berisi parsing rute dan format tanggal | **Belum** — `routeFromMessage` masih di `push_service.dart` | Bagian Refactoring Challenge, dikerjakan di tahap Praktikum 4. |
| 8 | `AuthRepositoryImpl({required TokenStore tokenStore})` | **Diubah** menjadi `AuthRepositoryImpl(this._tokenStore)` | Bentuk named parameter memicu lint `prefer_initializing_formals`, dan `flutter analyze` harus tetap `No issues found!`. |

---

## 4. Hasil verifikasi grep

Tiga pencarian sterilitas dari codelab dijalankan pada folder presentation
dan domain. Semuanya harus nol.

```bash
# 1. Presentation steril dari data mentah
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" \
   lib/features/*/presentation lib/pages

# 2. Domain steril dari framework & package
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" \
   lib/features/*/domain lib/core

# 3. Widget tidak menginstansiasi repository sendiri
rg "Repository\(|Dio\(BaseOptions" lib/pages
```

Hasil:

```text
Pencarian 1: 0 hasil
Pencarian 2: 0 hasil
Pencarian 3: 0 hasil
```

Karena `rg` tidak tersedia di shell yang dipakai, ketiga perintah di atas
dijalankan dengan `Select-String` pada pola yang sama persis, dengan cakupan
folder yang sama. Hasilnya identik: nol untuk ketiganya.

Dua temuan yang hilang setelah refactor:

- `pages/home_page.dart` mengimpor `package:firebase_messaging` dan memanggil
  `FirebaseMessaging.instance.getToken()` langsung.
- `providers/auth_provider.dart` membangun `Dio` dan
  `Provider<AuthRepository>((ref) => AuthRepository())` di lapisan presentasi.

---

## 5. Checklist verifikasi

| Item codelab | Status | Catatan |
| --- | --- | --- |
| Interface di `domain`, implementasi di `data` | ✅ | `AuthRepository` di domain, `AuthRepositoryImpl` di data |
| `domain` bebas Flutter/Dio/SQLite/Firebase | ✅ | grep 2 nol |
| Entity bebas mapping | ✅ | `AuthSession` tidak punya `toMap`/`fromJson`/`toJson`; mapping hanya di `AuthSessionModel` |
| Widget tidak `new Repository()` | ✅ | grep 3 nol; widget hanya `ref.watch` |
| Tidak ada use case untuk CRUD satu-baris | ✅ | hanya `Login`, dan dia punya aturan bisnis |
| Aplikasi berjalan identik | ✅ | diuji manual di `CPH2363`, Android 14 |
| `flutter analyze` bersih | ✅ | `No issues found!` |
| Test hijau | ✅ | 9 test |

---

## Refleksi

**Kenapa interface repository harus di `domain`, bukan `data`?**

Arah dependensinya. Kalau interface-nya ada di `data`, maka `domain` harus
mengimpor `data` untuk tahu bentuk kontrak — padahal aturan emas Clean
Architecture justru sebaliknya: dependensi hanya mengarah ke dalam. Yang
terjadi kalau dibalik: `domain` tidak bisa diuji tanpa ikut menarik `data`,
dan logika bisnis ikut kena perubahan format JSON dari backend.

**Kapan use case benar-benar dibutuhkan?**

Kalau operasinya menggabungkan lebih dari satu repository, atau punya aturan
bisnis sendiri. `Login` masuk kategori kedua — validasi format harus gagal
cepat sebelum menyentuh jaringan, dan itu bukan urusan repository. `refresh`
tidak masuk kategori mana pun, jadi repository langsung dari notifier sudah
cukup.

**Berapa biaya over-engineering?**

Use case yang cuma meneruskan panggilan menambah satu file dan satu provider
per operasi. Untuk tim kecil, biayanya baru terasa waktu operasinya terduplikasi
di beberapa tempat: saat aturannya berubah, ada banyak file yang harus disentuh
dan tidak ada satu tempat yang jelas jadi tempat aturan itu ditulis.

**Bagian mana yang saya tolak dari usulan AI?**

Nomor 1 dan 2 di tabel: pembuatan repository `announcements`, dan pemindahan
`home_page.dart` ke dalam fitur `auth`. Keduanya supaya struktur terlihat
simetris, tapi simetri bukan alasan arsitektur. Saya lebih suka tiga fitur
dengan kedalaman berbeda yang jujur mencerminkan complexidade masing-masing
daripada tiga fitur dengan tiga lapis kosong yang sama.