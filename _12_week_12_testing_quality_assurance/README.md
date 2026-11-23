# Week 12: Testing & Quality Assurance


## Identitas

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

## Ringkasan hasil

| Pemeriksaan | Sebelum (Minggu 11) | Sesudah (Minggu 12) |
| --- | --- | --- |
| `flutter analyze` | bersih | bersih |
| `dart format` | 0 changed | 0 changed |
| `flutter test` | 69 lulus | **130 lulus** |
| Integration test | tidak ada | 1 alur utama, **lulus di Chrome** |
| Cakupan baris | tidak diukur | **78,0%** (676/867) |
| Bug ditemukan saat menulis test | – | **1** (aturan email terlalu longgar), diperbaiki |
| Uji mutasi | tidak ada | 3 mutasi, 3 kali merah |

## Skenario yang diuji

### Login

| Skenario | Jenis | Hasil |
| --- | --- | --- |
| Email + sandi valid membuat sesi | Unit + Widget | Lulus |
| Spasi di awal/akhir email dipangkas | Unit + Widget | Lulus |
| `"@"` saja ditolak | Unit | Lulus |
| `"budi@localhost"` (domain tanpa titik) ditolak | Unit + Widget | Lulus |
| Sandi tepat 6 karakter diterima | Unit | Lulus |
| Kredensial ditolak repository -> pesan "Login gagal" | Unit + Widget | Lulus |
| Jaringan mati saat login | Unit | Lulus |
| Selama menunggu: spinner tampil, tombol disabled | Widget | Lulus |

### Pencarian pengumuman

| Skenario | Jenis | Hasil |
| --- | --- | --- |
| Query "ujian" menyaring daftar | Unit + Widget | Lulus |
| Case-insensitive ("ujian" menemukan "Ujian ...") | Unit | Lulus |
| Query tidak cocok -> empty state | Widget | Lulus |
| Sumber data kosong -> "Belum ada pengumuman" | Widget | Lulus |
| Data belum siap -> indikator loading | Widget | Lulus |
| Repository gagal -> "Gagal memuat pengumuman" | Widget | Lulus |
| Ketuk kartu -> halaman `/pengumuman/:id` | Widget | Lulus |
| 5 ketikan beruntun -> 1 pembaruan state (debounce) | Unit | Lulus |

### Asisten AI

| Skenario | Jenis | Hasil |
| --- | --- | --- |
| Pertanyaan kirim -> gelembung user + jawaban | Widget | Lulus |
| Pertanyaan tepat 500 karakter diterima | Unit | Lulus |
| Pertanyaan 501 karakter ditolak | Unit | Lulus |
| Konteks dibatasi 5 baris | Unit | Lulus |
| Batas pertanyaan per sesi ditegakkan | Unit | Lulus |
| Error 429 -> pesan kuota + tombol coba lagi | Unit + Widget | Lulus |
| API key kosong ditolak, tidak disimpan | Widget | Lulus |
| API key tersimpan -> banner hilang | Widget | Lulus |

### Alur utama (integrasi)

Satu test: guard login -> login -> beranda -> daftar pengumuman -> cari
"ujian" (melewati debounce 250 ms) -> buka detail lewat rute.

## Perubahan kode agar mudah diuji


| # | Perubahan | Alasan |
| --- | --- | --- |
| 1 | `lib/app.dart` diekstrak dari `main.dart` | Integration test perlu menyuntikkan container sendiri; `main()` menyalakan Firebase dan secure storage |
| 2 | `lib/core/validators.dart` sebagai satu sumber aturan | `Login` dan validator `LoginPage` sama-sama hanya memakai `contains('@')`, sehingga `"@"` dianggap sah. Bug ini ditemukan oleh test kasus tepi |

Perubahan pertama **tidak mengubah perilaku aplikasi**: `main.dart` tetap
memegang Firebase/FCM, dan `CampusNotifyApp` hanya menerima container + router
dari luar.

## Bukti test bisa gagal (uji mutasi)

Angka "130 lulus" tidak berarti apa-apa kalau test tidak bisa merah. Karena itu
tiga mutasi dijalankan sungguhan, lalu dipulihkan:

| Mutasi | Hasil |
| --- | --- |
| Filter dibuat case-sensitive lagi | **7 test merah**, tepat pada kasus huruf besar/kecil dan pemangkasan spasi |
| Debounce dihapus (`state = value` langsung) | **2 test merah** pada "lima ketikan -> satu pembaruan" dan "ketikan baru mereset jeda" |
| Validasi API key kosong dihapus | **2 test merah** pada "key kosong ditolak" dan "spasi saja ditolak" |

Setelah dipulihkan: `flutter analyze` bersih, `flutter test` kembali 130 lulus.
Detail dan keluaran perintah ada di
[docs/testing-report.md](docs/testing-report.md).

## Cara menjalankan

```bash
cd _12_week_12_testing_quality_assurance
flutter pub get

flutter analyze
flutter test
flutter test --coverage
```

Integration test:

```bash
# Chrome (jalur yang terbukti bekerja di mesin ini)
chromedriver --port=4444
flutter drive -d web-server --web-port=5555 \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart

# Android (emulator/perangkat aktif)
flutter test integration_test/app_test.dart -d <device_id>

# Windows desktop (butuh Developer Mode Windows: plugin Flutter butuh symlink)
flutter test integration_test/app_test.dart -d windows
```


Untuk menjalankan aplikasi seperti biasa: isi dulu
`android/app/google-services.json`, lalu `flutter run`.

## Cara memeriksa sendiri 

| Cara | Waktu | Kapan dipakai |
| --- | --- | --- |
| `flutter test` | **~12 detik** | setiap kali mengubah kode |
| `flutter test test/login_page_test.dart` | **~3 detik** | saat menyentuh satu bagian |
| Cek manual di Chrome (`tool\run_app_web.cmd`) | ~60 detik pertama, lalu **hot reload ~2 detik** | ingin melihat sendiri aplikasinya |
| Integration test (`tool\run_integration_web.cmd`) | **~2 menit** | **sekali saja**, sebelum mengumpulkan |

ini bisa Anda buktikan ulang sendiri. Urutannya dari yang
paling cepat.

### 1. Pastikan test memang lulus

```bash
cd _12_week_12_testing_quality_assurance
flutter test
```

Yang harus muncul di baris terakhir: `All tests passed!` dengan angka `+130`.
Kalau angkanya berbeda, jumlah test berubah — bukan laporan ini yang benar.

Mau lebih cepat dan lebih fokus? Jalankan satu berkas saja:

```bash
flutter test test/login_page_test.dart
flutter test test/search_announcements_test.dart
```

### 2. Pastikan test bisa GAGAL (paling penting)

Ini bagian yang membedakan test berguna dan test hiasan. Rusak satu aturan
dengan sengaja, jalankan test, lalu kembalikan.

Contoh termudah — buka
`lib/features/announcements/domain/usecases/search_announcements.dart`,
ubah baris:

```dart
announcements.where((a) => a.title.toLowerCase().contains(lowered)),
```

menjadi (hapus `toLowerCase`):

```dart
announcements.where((a) => a.title.contains(trimmed)),
```

lalu:

```bash
flutter test test/search_announcements_test.dart
```

Harus **merah**, minimal pada test `filter abaikan huruf besar/kecil`. Setelah
dipulihkan, harus hijau lagi. Kalau tetap hijau saat dirusak, test-nya tidak
memeriksa apa pun.

Cara mengembalikan: `git checkout -- lib/features/announcements/domain/usecases/search_announcements.dart`

### 3. Lihat cakupan sendiri

```bash
flutter test --coverage
dart run tool/coverage_summary.dart
```

Keluaran yang diharapkan:

```text
TOTAL: 676/867 baris = 78.0%
(tambahkan --files untuk rincian per berkas)
```

Untuk melihat rincian per berkas (urut dari cakupan terendah):

```bash
dart run tool/coverage_summary.dart --files
```

Skrip ini dibaca langsung dari `coverage/lcov.info`, jadi angkanya tidak saya
ketik manual. Ia sengaja dibuat sebagai skrip Dart — bukan satu baris
PowerShell — karena terminal Windows bisa berupa PowerShell **atau** cmd, dan
perintah penjumlahan satu baris gagal di salah satunya.

### 4. Cari sendiri bagian yang tidak tercakup

```bash
dart run tool/coverage_summary.dart --files
```

Berkas 0% seharusnya hanya Dio, secure storage, FCM, dan `auth_repository_impl`
(lihat tabel di bawah). Kalau ada berkas `domain/` yang 0%, itu berarti ada test
yang hilang.

### 5. Pastikan arsitektur tidak bocor

Domain tidak boleh mengimpor Flutter/Dio/Firebase. Buktikan dengan grep
(PowerShell, cmd, maupun Git Bash sama-sama bisa):

```bash
findstr /S /N "package:flutter/ package:dio/ package:firebase" lib\features\announcements\domain\*.dart lib\features\auth\domain\*.dart lib\features\assistant\domain\*.dart
```

Hasil yang benar: **tidak ada keluaran sama sekali**. Kalau ada, berarti ada
pelanggaran dependency rule.

### 6. Jalankan integration test sendiri

Satu perintah saja (mencari ChromeDriver, menyalakannya, menjalankan test, lalu
mematikannya lagi):

```bash
tool\run_integration_web.cmd
```

Atau manual kalau ingin melihat prosesnya satu per satu:

```bash
# Terminal 1 - nyalakan ChromeDriver
tool\chromedriver.exe --port=4444

# Terminal 2 - jalankan test
flutter drive -d web-server --web-port=5555 --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

> Perintah di atas **satu baris penuh** dengan sengaja. Jangan dipecah dengan
> `` ` `` (backtick) — itu lanjutan baris PowerShell dan akan error di cmd.
> Kalau tetap ingin dipecah di cmd, gunakan `^`.

Yang harus muncul: `All tests passed.` dan `Application finished.`
(Jangan pakai `-d chrome` di mesin ini — penyebabnya dijelaskan di atas.)

### 7. Baca kode test-nya, bukan hanya hasilnya

Test yang paling perlu Anda periksa sendiri adalah yang mengklaim paling
banyak:

| Berkas | Pertanyaan yang perlu Anda jawab |
| --- | --- |
| `test/validators_test.dart` | Apakah kasus `"@"` dan `"budi@localhost"` benar-benar diuji? |
| `test/search_announcements_test.dart` | Apakah ada test huruf besar/kecil, atau hanya huruf kecil? |
| `test/login_page_test.dart` | Apakah "login gagal" memeriksa pesan error, atau hanya "tidak pindah halaman"? |
| `test/announcements_page_test.dart` | Apakah error state diuji terpisah dari empty state? |
| `integration_test/app_test.dart` | Apakah benar-benar melewati lebih dari satu halaman? |

Kalau sebuah test tidak akan gagal saat fitur dirusak, test itu tidak
melindungi apa pun — meskipun ia lulus.

## Cek manual aplikasi

Kalau lebih percaya mata sendiri daripada hasil test — wajar, dan codelab
memang menyebut uji manual. Ini cara tercepatnya.

```bash
tool\run_app_web.cmd
```

Chrome terbuka otomatis. Login memakai backend mock, jadi **tidak perlu**
`google-services.json`.

Daftar periksa (5 menit, semuanya sudah punya test otomatis — jadi kalau ada
yang tidak sesuai, berarti ada test yang tidak menangkapnya):

| # | Lakukan ini | Yang seharusnya terjadi |
| --- | --- | --- |
| 1 | Kosongkan email dan sandi, klik **Masuk** | Muncul "Email wajib diisi" dan "Minimal 6 karakter", tetap di halaman login |
| 2 | Isi email `@` saja, sandi `rahasia123`, klik Masuk | Muncul "Email tidak valid" — **ini bug yang ditemukan Minggu 12** |
| 3 | Isi email `budi@polinema.ac.id`, sandi `rahasia123`, klik Masuk | Masuk ke beranda, muncul "Login berhasil" |
| 4 | Klik kartu **Pengumuman** | 5 pengumuman tampil |
| 5 | Ketik `ujian` (huruf kecil) di kolom cari | Tersisa 1 kartu: "Ujian Akhir Semester Ganjil" |
| 6 | Ketik `zzz` | Empty state "Tidak ada pengumuman yang cocok" |
| 7 | Klik ikon ✕ lalu klik kartu pertama | Halaman "Pengumuman #1" |
| 8 | Kembali, klik ikon logout | Kembali ke halaman login |
| 9 | Klik kartu **Asisten Kampus (AI)** | Banner "API key belum diatur"; kirim pertanyaan -> pesan error ramah, bukan crash |
| 10 | Klik ikon kunci, isi API key kosong, klik Simpan | Snackbar "API key tidak boleh kosong." |


## Cakupan kode

```text
flutter test --coverage
TOTAL: 676/867 baris = 78,0%
```


## Dokumentasi

- [docs/testing-plan.md](docs/testing-plan.md) — rencana: skenario, jenis test, cara dependensi dipalsukan, batas cakupan
- [docs/testing-report.md](docs/testing-report.md) — hasil: angka nyata, uji mutasi, temuan, refleksi
