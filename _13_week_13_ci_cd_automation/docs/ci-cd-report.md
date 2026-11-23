# Laporan CI/CD - Minggu 13

Dokumen ini memisahkan **apa yang sudah dibuktikan** dari **apa yang masih
terbuka**. Semua angka di bawah berasal dari eksekusi nyata: 23 November 2026
di mesin lokal dan di GitHub Actions, bukan perkiraan.

## 1. Ringkasan

| Aspek | Status | Bukti |
| --- | --- | --- |
| Workflow CI ditulis | ✅ | [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml) |
| YAML valid | ✅ | di-parse `pyyaml`: 1 job, 11 step, key `on/permissions/concurrency/defaults/jobs` terbaca |
| Format, analisis, test | ✅ lulus lokal dan di CI | bagian 2 dan 6 |
| Build APK | ✅ 51,16 MB (lokal) | bagian 3 |
| Build AAB | ✅ 50,16 MB (lokal) | bagian 3 |
| Path artefak cocok dengan hasil build | ✅ | bagian 3 |
| Versi dinaikkan | ✅ `1.0.0+1` -> `1.0.0+2` | `pubspec.yaml` |
| Run di GitHub Actions (pull request) | ✅ **success** 5 m 9 s | bagian 6, run `45219722318` |
| Run di GitHub Actions (push ke main) | ✅ **success** 7 m 26 s | bagian 6, run `45220748442` |
| Artefak terunggah | ✅ `android-builds` 73,64 MB + `coverage-lcov` | bagian 6 |

## 2. Pemeriksaan yang sama dengan CI, dijalankan lokal

Perintah di bawah identik dengan step di workflow (bukan "mirip"), dijalankan
dari `_12_week_12_testing_quality_assurance`:

```text
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze --fatal-infos
flutter test --coverage
dart run tool/coverage_summary.dart
```

| Langkah | Hasil | Waktu |
| --- | --- | --- |
| `dart format` | 58 berkas, **0 changed** | 0,5 s |
| `flutter analyze --fatal-infos` | **No issues found!** | ~12-15 s |
| `flutter test --coverage` | **130 lulus, 0 gagal** | 28-37 s |
| Cakupan | **676/867 baris = 78,0%** | - |

Perintah yang sama tersedia sebagai satu skrip:
`_13_week_13_ci_cd_automation/tool/check_ci_locally.ps1`.

## 3. Artefak

### 3.1 Hasil build lokal

| Berkas | Ukuran | Waktu build | Path (sama dengan workflow) |
| --- | --- | --- | --- |
| `app-release.apk` | **51,16 MB** | 105-180 s | `build/app/outputs/flutter-apk/app-release.apk` |
| `app-release.aab` | **50,16 MB** | 16-34 s | `build/app/outputs/bundle/release/app-release.aab` |

Kedua berkas berada di path yang persis dirujuk blok `path:` pada step
`Upload APK + AAB`. Ini diverifikasi otomatis oleh
`tool/build_artifacts.ps1`, yang menggagalkan dirinya bila salah satu berkas
tidak ada - kesalahan path artefak tidak akan lolos sampai CI.

Verifikasi isi artefak, dibaca dari `output-metadata.json` yang ditulis Gradle
(bukan dari `pubspec.yaml`):

```text
applicationId  com.example.u_06_week_6_authentication_security_fcm
versionName    1.0.0
versionCode    2
```

### 3.2 Hasil build di CI

| Artefak | Isi | Ukuran terkompresi |
| --- | --- | --- |
| `android-builds` | `app-release.apk` + `app-release.aab` | **73,64 MB** (77.213.475 byte) |
| `coverage-lcov` | `coverage/lcov.info` | 2,6 KB |

Angka 73,64 MB adalah ukuran zip yang diunggah, bukan jumlah APK+AAB mentah
(101 MB). Keduanya diunduh dari tab **Actions** -> run -> **Artifacts**.

Build ini ditandatangani **debug keystore** (lihat
[security-review.md](security-review.md) bagian 1): layak untuk uji internal,
bukan untuk Play Store.

## 4. Kegagalan nyata yang ditemukan sebelum push

Ini bagian yang membuat pipeline berguna: tiga masalah muncul saat menjalankan
perintah CI di lokal, dan semuanya akan memerahkan job.

### 4.1 `package dev.flutter.plugins.integration_test does not exist`

Build release pertama **gagal** setelah 4 m 34 s:

```text
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:39:
error: package dev.flutter.plugins.integration_test does not exist
      flutterEngine.getPlugins().add(new dev.flutter.plugins.integration_test.IntegrationTestPlugin());
1 error
FAILURE: Build failed with an exception.
> Execution failed for task ':app:compileReleaseJavaWithJavac'.
BUILD FAILED in 4m 34s
```

Penyebab: `integration_test` ada di `dev_dependencies`. Menjalankan `flutter test`
menulis ulang `GeneratedPluginRegistrant.java` **termasuk** plugin
`integration_test`, sedangkan varian release tidak mengompilasi plugin dev.

Di mesin ini kegagalan dipicu karena `flutter test --coverage` dijalankan
**bersamaan** dengan build release (dua proses pada satu project). Setelah build
release dijalankan sendiri, Flutter menulis ulang registrant tanpa plugin dev
dan build berhasil.

**Pelajaran untuk CI:** step `flutter test` dan `flutter build` dijalankan
berurutan dalam satu job (bukan paralel, bukan dua job pada working tree yang
sama). Workflow sudah disusun begitu, dan urutan itu terbukti benar di runner
(run `45219722318`: step 8 test lulus, step 10-11 build lulus).

Urutan itu juga diuji langsung, karena "berurutan" bisa saja tetap bermasalah
bila `flutter test` meninggalkan registrant yang tidak valid untuk build:

| Uji | Kondisi awal | Hasil |
| --- | --- | --- |
| A | registrant berisi 2 referensi `integration_test` (sisa `flutter test`) | build APK **berhasil** 11,8 s; setelah build, referensi `integration_test` menjadi **0** |
| B | `build/`, `.dart_tool/`, `coverage/`, registrant, `.flutter-plugins-dependencies` dihapus (menyerupai checkout bersih) | urutan CI penuh dijalankan: 5 langkah lulus, build APK 180 s dan AAB 34 s |

Kesimpulan: `flutter build` **menulis ulang** registrant sesuai varian yang
dibangun, jadi urutan test -> build aman. Yang berbahaya hanya menjalankannya
paralel, atau memakai berkas registrant lama dari build debug/test.

`GeneratedPluginRegistrant.java` **tidak di-commit** - sudah masuk
`android/.gitignore` baris 7 - sehingga kondisi ini tidak bisa "terbawa" ke
runner lewat repository.

### 4.2 Angka cakupan tidak stabil

Dua run pertama memberi angka berbeda dari laporan Minggu 12:

| Run | Cakupan | Berkas yang berbeda |
| --- | --- | --- |
| `flutter test --coverage` (bawaan, paralel) | 674/867 = **77,7%** | `lib/core/failures.dart` 2/8 |
| `flutter test --coverage` (bawaan, paralel) | 676/867 = **78,0%** | `lib/core/failures.dart` 4/8 |
| `flutter test --coverage --concurrency=1` | 676/867 = **78,0%** | 4/8 |
| `--concurrency=1`, diulang | 676/867 = **78,0%** | 4/8 |

Penyebabnya: `lib/core/failures.dart` punya konstruktor `const` satu baris
(`const AuthFailure(super.message);`). Konstruktor yang dipakai lintas isolate
test kadang sudah ter-compile sehingga barisnya terhitung, kadang belum. Dengan
`--concurrency=1` hasilnya **stabil 676/867** pada dua run berturut-turut.

Angka resmi yang dipakai tetap **676/867 (78,0%)**, sama dengan laporan Minggu
12, dan workflow memakai `flutter test --coverage` bawaan. Kalau angka cakupan
dijadikan gerbang mutu di masa depan, jalankan dengan `--concurrency=1` agar
tidak berfluktuasi 2 baris.

### 4.3 `flutter pub get` gagal di Windows tanpa Developer Mode

Pada kondisi bersih (`build/`, `.dart_tool/`, `.flutter-plugins-dependencies`
dihapus), `flutter pub get` di mesin ini keluar dengan **exit 1**:

```text
Got dependencies!
35 packages have newer versions incompatible with dependency constraints.
Building with plugins requires symlink support.

Please enable Developer Mode in your system settings. Run
  start ms-settings:developers
```

Yang gagal **bukan** resolusi paket: `Got dependencies!` sudah tercetak dan
`.dart_tool/package_config.json` sudah tertulis. Yang gagal adalah pembuatan
symlink plugin untuk platform desktop (`linux/`, `windows/`, `macos/`) - fitur
Windows yang butuh Developer Mode. Pada mesin ini
`AllowDevelopmentWithoutDevLicense = 0`.

Dampaknya untuk pipeline: **tidak ada**, karena runner memakai `ubuntu-latest`
(Linux, symlink selalu tersedia) dan project ini targetnya Android. `flutter test`
dan `flutter build apk` berjalan normal setelah paket ter-resolve - dibuktikan
dengan 130 test lulus dan APK terbangun pada kondisi yang sama.

Yang perlu dicatat justru **jebakan skrip**, karena ini nyaris membuat laporan
salah:

1. `$ErrorActionPreference = 'Stop'` di PowerShell 5.1 mengubah setiap tulisan
   stderr perintah native menjadi error terminating. `flutter pub get` yang
   berhasil dilaporkan gagal.
2. PowerShell 5.1 **tidak menangkap stderr** dari `flutter.bat` lewat `2>&1`,
   sehingga pesan `requires symlink support` tidak terlihat dan deteksi berbasis
   teks tidak bekerja.

Perbaikan di `tool/check_ci_locally.ps1`: perintah dijalankan lewat
`cmd /c "... > log 2>&1"`, exit code dan keluaran dibaca dari berkas, dan satu
pengecualian sempit hanya untuk pesan symlink tersebut (dengan syarat
`package_config.json` sudah ada). Kegagalan lain tetap memerahkan skrip.

Pelajaran yang bisa dibawa ke CI: skrip pembungkus yang **menelan** stderr lebih
berbahaya daripada tidak ada skrip, karena ia memberi rasa aman palsu.

## 5. Struktur workflow

| Bagian | Isi |
| --- | --- |
| Nama | `Flutter CI` |
| Job | 1 job `test-and-build` (11 step) |
| Pemicu | `push` + `pull_request` ke `main`/`develop`, `workflow_dispatch` |
| Permission | `contents: read` |
| Concurrency | `${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: true` |
| Runner | `ubuntu-latest`, `timeout-minutes: 30` |
| Flutter | `3.47.5`, channel stable, cache aktif |
| JDK | Temurin 21 |
| Artefak | `android-builds` (APK+AAB, `if-no-files-found: error`), `coverage-lcov` (`if: always()`) |
| Retensi | 7 hari |

Alasan tiap keputusan ada di [ci-cd-plan.md](ci-cd-plan.md).

## 6. Bukti eksekusi di GitHub Actions

Dua run dijalankan sungguhan, keduanya **hijau**.

### 6.1 Run pada pull request

| Yang dicatat | Nilai |
| --- | --- |
| PR | [#14](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/14) `ci/week13-pipeline` -> `main` |
| Run ID | **45219722318** |
| Commit SHA | `c080cc5ef35d8c73956c873dddf44083f71b2ec4` |
| Pemicu | `pull_request` |
| Job | `format + analyze + test + build android` |
| Mulai | 2026-11-23 16:43:35 UTC |
| Durasi | **5 m 9 s** |
| Hasil | **success** |

Status per step:

| # | Step | Hasil |
| --- | --- | --- |
| 1-4 | Set up job, Checkout, Set up JDK, Set up Flutter | success |
| 5 | `flutter pub get` | success |
| 6 | `dart format` | success |
| 7 | `flutter analyze --fatal-infos` | success |
| 8 | `flutter test --coverage` | success |
| 9 | Upload laporan cakupan | success |
| 10 | `flutter build apk --release` | success |
| 11 | `flutter build appbundle --release` | success |
| 12 | Upload APK + AAB | success |

### 6.2 Run pada push ke main (setelah merge)

| Yang dicatat | Nilai |
| --- | --- |
| Run ID | **45220748442** |
| Commit SHA | `20395b288d4d3cd88d5f81d3a59e683f1dff8696` |
| Pemicu | `push` ke `main` |
| Mulai | 2026-11-23 16:49 UTC |
| Durasi | **7 m 26 s** |
| Hasil | **success** |
| Artefak | `android-builds` 73,64 MB, `coverage-lcov` 2,6 KB |
| Kedaluwarsa artefak | 2026-11-30 (retensi 7 hari) |

Run kedua ini membuktikan bagian **delivery** dari pipeline: setiap commit yang
masuk ke `main` menghasilkan APK dan AAB yang bisa diunduh, dari kode yang sudah
lolos pemeriksaan di PR.

Tautan run:
`https://github.com/Zuhdiaja/244107020017-mobile-course/actions/runs/45220748442`

### 6.3 Workflow lama tetap berjalan

PR #14 juga memicu `.github/workflows/ci.yml` (Minggu 8, menguji project Minggu 7)
pada run `45219722119` - juga **success**. Konsekuensinya setiap PR menjalankan
dua pipeline. `ci.yml` sengaja dibiarkan sebagai bukti Minggu 8; bila ingin
dihemat, workflow itu bisa dipensiunkan menjadi `workflow_dispatch` saja.

### 6.4 Catatan operasional

- Push ke branch fitur **tidak** memicu workflow, karena `on.push` hanya
  mendengarkan `main` dan `develop`. Pada PR #13 hal ini sempat membingungkan:
  run baru muncul setelah PR di-close lalu di-reopen. Untuk run pertama pada
  branch baru, buat PR lebih dulu.
- Repository ini menerima rilis lewat PR ke `main`. PR ke `develop` akan
  memunculkan konflik palsu, karena `develop` tertinggal dan berbeda garis
  sejarah dengan `main`.
- Setiap commit berikutnya, termasuk pembaruan dokumen ini, melewati pipeline
  yang sama. Dua run di atas adalah bukti utama; run dokumentasi tidak dicatat
  satu per satu agar laporan ini tidak mengejar dirinya sendiri.

## 7. Refleksi

### 7.1 Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?

Tiga kelas masalah, dan semuanya terbukti tertangkap:

1. **Kode tidak terformat** - `dart format --set-exit-if-changed` gagal dalam
   hitungan detik. Tanpa gerbang ini, diff PR dipenuhi perubahan spasi yang
   menyulitkan review.
2. **Peringatan analisis** - `--fatal-infos` membuat info pun memerahkan job.
   Ini yang menjaga ambang mutu tidak turun diam-diam.
3. **Perilaku yang rusak** - 130 test, termasuk kasus tepi yang dulu menemukan
   bug validasi email (`"@"` dianggap sah). Bug seperti itu tidak terlihat dari
   membaca diff, hanya dari test.

Yang **tidak** tertangkap: build release gagal karena registrant basi (4.1) baru
ketahuan saat build dijalankan, bukan saat test. Karena itu build tetap menjadi
step CI, bukan pekerjaan manual sesekali.

### 7.2 Informasi apa yang dibutuhkan untuk menyelidiki build yang gagal?

Dari pengalaman 4.1, yang benar-benar dipakai:

| Informasi | Mengapa perlu |
| --- | --- |
| Nama step yang merah | Menentukan apakah masalahnya format, test, atau Gradle |
| Commit SHA | Memastikan build diuji dari kode yang dimaksud, bukan cache |
| Versi Flutter + JDK | Kegagalan Gradle sering disebabkan versi JDK, bukan kode |
| Log Gradle lengkap (`--stacktrace`) | Pesan `1 error` saja tidak menunjukkan task mana |
| Daftar berkas hasil generate | `GeneratedPluginRegistrant.java` adalah tersangka pertama bila error menyebut plugin |
| Perintah persis yang dijalankan | Untuk mereproduksi lokal; ini alasan `check_ci_locally.ps1` ada |

### 7.3 Bagian mana yang masih perlu persetujuan atau pemeriksaan manual?

| Bagian | Mengapa tidak bisa otomatis |
| --- | --- |
| Signing rilis | Keystore produksi tidak boleh ada di CI PR; butuh keputusan pemilik kunci |
| Unggah ke Play Store | Tidak dapat dibatalkan; butuh persetujuan manusia dan kebijakan rilis |
| Uji di perangkat nyata | FCM, notifikasi lokal, dan secure storage tidak berjalan di runner |
| Integration test | Butuh ChromeDriver yang cocok dengan Chrome runner; dijalankan lokal |
| Tinjauan kode | Test membuktikan perilaku yang diuji, bukan bahwa desainnya tepat |
| Pemeriksaan tampilan | Layout dan aksesibilitas tidak dinilai `flutter analyze` |
| Versi rilis | Kenaikan versi adalah keputusan produk, bukan hasil test |

## 8. Langkah berikutnya

1. Tag `v1.0.0` pada commit yang lolos CI (`20395b2` atau sesudahnya), agar
   source, log pipeline, dan artefak bisa dihubungkan.
2. Naikkan build number di setiap unggahan baru; jangan pernah mengulang nomor.
3. Tangani risiko 1 di [security-review.md](security-review.md): signing rilis
   lewat secret, hanya pada workflow tag.
4. Sinkronkan `develop` dari `main` sekali, agar PR yang salah arah tidak lagi
   memunculkan konflik palsu.
5. Pertimbangkan integration test di CI setelah ChromeDriver dipin ke versi
   Chrome runner.
