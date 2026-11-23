# Rencana Pipeline CI/CD - Minggu 13

Dokumen ini menjelaskan **mengapa** workflow disusun seperti ini. Bukti hasil
eksekusi ada di [ci-cd-report.md](ci-cd-report.md); risiko yang masih terbuka
ada di [security-review.md](security-review.md).

## 1. Ruang lingkup

| | |
| --- | --- |
| Workflow | [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml) |
| Project yang diuji | `_12_week_12_testing_quality_assurance` |
| Pemicu | `pull_request` + `push` ke `main` dan `develop`, serta `workflow_dispatch` |
| Hasil akhir | artefak `android-builds` (APK + AAB) dan `coverage-lcov` |

Repository ini berisi sepuluh snapshot mingguan di root, bukan satu project
Flutter. Yang diuji adalah **project terbaru** (Minggu 12, 130 test), karena
itulah aplikasi yang akan dirilis. Snapshot minggu lain hanya bukti historis dan
sengaja tidak diuji ulang: menguji tujuh salinan aplikasi yang sama akan
menghabiskan menit runner tanpa menambah keyakinan apa pun.

## 2. Workflow diletakkan di root, bukan di dalam folder minggu

GitHub Actions **hanya** membaca `.github/workflows/` di root repository.
Workflow tidak bisa diletakkan di `_13_week_13_ci_cd_automation/`.

Karena itu pembagiannya:

- `.github/workflows/flutter-ci.yml` - mesin yang menjalankan pemeriksaan;
- `_13_week_13_ci_cd_automation/` - dokumentasi, laporan, dan skrip paritas lokal.

Folder ini **tidak** menyalin kode aplikasi. Kalau disalin, akan ada dua salinan
`lib/` dan `test/` yang harus dijaga sinkron, dan CI akan menguji salinan yang
tidak pernah dipakai siapa pun. Snapshot Minggu 11/12 memang menyalin project
karena isinya berbeda (kode berubah); Minggu 13 tidak mengubah kode aplikasi.

## 3. Event dan permission

| Keputusan | Alasan |
| --- | --- |
| `pull_request` ke `main` dan `develop` | Menolak PR kotor sebelum dibaca manusia. `develop` adalah branch default repository ini dan target semua PR, jadi tanpa `develop` sebagian besar PR tidak terperiksa. |
| `push` ke `main` dan `develop` | Memastikan branch yang dipakai orang lain juga hijau, bukan hanya branch PR. |
| `workflow_dispatch` | Untuk menjalankan ulang tanpa commit baru (mis. setelah kuota runner pulih). |
| `permissions: contents: read` | Job ini hanya membaca kode. Tidak ada step yang menulis issue, komentar, atau paket. Izin tulis hanya menambah dampak bila sebuah action disusupi. |
| `concurrency` + `cancel-in-progress` | Push kedua pada branch yang sama membatalkan run pertama. Tanpa ini, run commit lama bisa selesai belakangan dan artefaknya tertukar dengan commit terbaru. |

Pull request dari fork tidak mendapat akses GitHub Secrets repository. Pipeline
ini tidak memakai secret sama sekali, sehingga PR dari fork tetap berjalan
lengkap - konsekuensi dari tidak adanya signing produksi (lihat
[security-review.md](security-review.md) 2).

## 4. Versi tool yang di-pin

| Tool | Versi | Alasan |
| --- | --- | --- |
| Flutter | `3.47.5` | Sama dengan `flutter --version` di mesin pengembang. Kalau hanya `channel: stable`, rilis Flutter baru bisa memerahkan pipeline tanpa satu baris kode berubah. |
| JDK | Temurin 21 | AGP 9.1.0 / Gradle 9.3.1 pada project ini butuh JDK 21. Runner memakai JDK default yang berbeda, dan kegagalan Gradle karena versi JDK sulit dilacak dari log. |
| Actions | `@v4` | Tag mayor, bukan SHA. Ini kompromi yang **dicatat sebagai risiko** di [security-review.md](security-review.md) 5: SHA lebih aman tetapi harus diperbarui manual setiap rilis. |

## 5. Urutan langkah

```text
checkout -> JDK -> Flutter -> pub get
  -> dart format        (gagal bila ada berkas tidak terformat)
  -> flutter analyze    (--fatal-infos: info pun menggagalkan)
  -> flutter test       (--coverage, 130 test)
  -> upload coverage    (if: always)
  -> build APK
  -> build AAB
  -> upload artefak     (if-no-files-found: error)
```

Prinsipnya: **pemeriksaan murah lebih dulu**. Format gagal dalam hitungan detik;
build butuh ~5 menit. Menjalankan build sebelum format berarti membuang menit
runner untuk kesalahan yang bisa diketahui lebih awal.

Build sengaja berada **setelah** test: artefak hanya dibuat dari commit yang
lulus test. Kalau build dijalankan lebih dulu, akan ada APK dari kode yang
gagal test - persis artefak yang tidak boleh dipakai.

## 6. Tiga jebakan yang ditangani secara eksplisit

### 6.1 `defaults.run.working-directory` tidak berlaku untuk `uses:`

`working-directory` hanya mengubah direktori untuk step `run:`. Step
`uses: actions/upload-artifact` tetap dijalankan dari root repository. Karena
itu `path:` ditulis lengkap dengan nama folder project:

```yaml
path: _12_week_12_testing_quality_assurance/build/app/outputs/flutter-apk/app-release.apk
```

Kalau ditulis `build/app/...` saja, upload akan "sukses" tanpa berkas - kecuali
`if-no-files-found: error` dipasang. Itu sebabnya opsi tersebut wajib ada:
artefak yang hilang harus memerahkan job, bukan menghasilkan run hijau tanpa isi.

### 6.2 Cakupan `dart format` dibatasi

Contoh codelab memakai `dart format .`. Di project ini perintah itu menyisir
`build/`, `.dart_tool/`, dan folder platform hasil generate, lalu gagal karena
berkas yang bukan tulisan manusia. Cakupan dibatasi ke kode manual:

```text
lib test integration_test test_driver
```

Daftar ini identik dengan yang dijalankan di lokal, sehingga "hijau di laptop"
benar-benar berarti "hijau di CI".

### 6.3 `integration_test` sebagai dev dependency dan build release

Menjalankan test menulis `GeneratedPluginRegistrant.java` yang ikut mendaftarkan
plugin `integration_test`. Plugin itu dev dependency dan tidak ikut dikompilasi
pada varian release, sehingga build release bisa gagal dengan
`package dev.flutter.plugins.integration_test does not exist`.

Berkas itu **tidak di-commit** (`android/.gitignore`), dan `flutter build`
menuliskannya ulang tanpa dev dependency. Namun kegagalan ini benar-benar
terjadi di mesin ini saat build release berjalan bersamaan dengan `flutter test`
- lihat [ci-cd-report.md](ci-cd-report.md) 4. Pelajarannya: jangan menjalankan
test dan build release serentak di satu project.

## 7. Yang sengaja tidak dimasukkan

| Tidak dilakukan | Alasan |
| --- | --- |
| Integration test di CI | Butuh ChromeDriver yang versinya harus cocok dengan Chrome runner, plus `flutter drive` dan server web. Menambah ~2 menit dan satu titik gagal rapuh. Dijalankan lokal lewat `tool/run_integration_web.cmd`; dicatat sebagai pekerjaan lanjutan. |
| Unggah ke Play Store | Butuh service account Google Play, signing produksi, dan kebijakan rilis. Di luar cakupan codelab dan tidak boleh dilakukan tanpa persetujuan manual. |
| Notifikasi Slack/email | Belum ada penerima yang jelas; status run sudah terlihat di tab Actions dan di badge PR. |
| Matriks multi-platform | Aplikasi targetnya Android. Build iOS butuh macOS dan sertifikat Apple. |
| Cache `pub` tambahan | `subosito/flutter-action@v2` dengan `cache: true` sudah meng-cache SDK dan `~/.pub-cache`. |

## 8. Paritas lokal ↔ CI

Dua skrip di `tool/` menjalankan perintah yang sama dengan workflow:

| Skrip | Isi |
| --- | --- |
| `check_ci_locally.ps1` | pub get → format → analyze → test → ringkasan cakupan, berhenti pada kegagalan pertama |
| `build_artifacts.ps1` | build APK + AAB, lalu **memverifikasi** kedua berkas ada di path yang dirujuk `upload-artifact` |

Skrip kedua ada karena kesalahan path artefak tidak terlihat sampai job CI
gagal. Memeriksanya lokal lebih cepat daripada satu putaran push.

Keduanya memanggil perintah lewat `cmd /c` dengan keluaran dialihkan ke berkas.
Ini bukan gaya penulisan: PowerShell 5.1 tidak menangkap stderr `flutter.bat`
lewat `2>&1`, dan `$ErrorActionPreference = 'Stop'` membuat stderr perintah
native dianggap error fatal. Tanpa penanganan itu, `flutter pub get` yang
berhasil akan dilaporkan gagal. Bukti dan detailnya di
[ci-cd-report.md](ci-cd-report.md) 4.3.

## 9. Versioning

`pubspec.yaml` Minggu 12 naik dari `1.0.0+1` menjadi `1.0.0+2`:

- **versi aplikasi tetap `1.0.0`** - tidak ada perubahan perilaku sejak Minggu 9;
- **build number naik** - artefak CI harus bisa dibedakan dari snapshot Minggu 12
  yang dibuat tanpa pipeline.

Skema berikutnya: `1.1.0+N` untuk fitur baru (minor), `1.0.1+N` untuk perbaikan,
`2.0.0+N` untuk perubahan tidak kompatibel. Build number selalu naik, tidak
pernah diulang, karena Google Play menolak unggahan dengan build number yang
sudah dipakai.
