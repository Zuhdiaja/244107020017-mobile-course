# Week 13: CI/CD Automation

Pipeline GitHub Actions untuk project Minggu 7–12 (`campus_notify`): setiap
push dan pull request menjalankan format, analisis, test, lalu membangun APK dan
AAB yang bisa diunduh sebagai artefak.

Folder ini berisi **dokumentasi dan skrip paritas lokal**, bukan salinan kode
aplikasi. Workflow-nya ada di root repository karena GitHub Actions hanya membaca
`.github/workflows/` di root.

## Identitas

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |
| Repository | `Zuhdiaja/244107020017-mobile-course` |
| Project yang diuji | `_12_week_12_testing_quality_assurance` |

## Ringkasan hasil

| Pemeriksaan | Sebelum (Minggu 12) | Sesudah (Minggu 13) |
| --- | --- | --- |
| Pipeline otomatis | hanya Minggu 7 (`ci.yml`) | Minggu 12: format + analyze + test + build |
| Format & analisis | manual di laptop | dijaga CI, `--fatal-infos` |
| Test | manual | 130 test otomatis tiap push/PR |
| Artefak | tidak ada | APK 51,16 MB + AAB 50,16 MB |
| Cakupan | diukur lokal | `lcov.info` diunggah sebagai artefak |
| Versi | `1.0.0+1` | `1.0.0+2` |
| Build release di mesin ini | belum pernah dicoba | **berhasil** (setelah 1 kegagalan diperbaiki) |

## Workflow

`.github/workflows/flutter-ci.yml`

```text
push / pull_request (main, develop) / workflow_dispatch
  |
  +-- permissions: contents: read          (minimum)
  +-- concurrency: cancel run lama pada branch yang sama
  |
  test-and-build (ubuntu-latest, timeout 30 mnt)
     checkout -> JDK 21 -> Flutter 3.47.5 (cache)
     flutter pub get
     dart format --output=none --set-exit-if-changed lib test integration_test test_driver
     flutter analyze --fatal-infos
     flutter test --coverage
     upload coverage-lcov           (if: always)
     flutter build apk --release
     flutter build appbundle --release
     upload android-builds          (if-no-files-found: error)
```

Artefak disimpan 7 hari dan dapat diunduh dari tab **Actions** -> pilih run ->
bagian **Artifacts**.

## Cara menjalankan

### Di CI (setelah commit)

```bash
git switch -c ci/week13-pipeline
git add .github/workflows/flutter-ci.yml _13_week_13_ci_cd_automation _12_week_12_testing_quality_assurance
git commit -m "ci(week13): pipeline format, analyze, test, build APK+AAB"
git push -u origin ci/week13-pipeline
# buka tautan "Create pull request", target: develop
```

### Di laptop, perintah yang sama dengan CI

```powershell
# dari root repository
powershell -ExecutionPolicy Bypass -File _13_week_13_ci_cd_automation\tool\check_ci_locally.ps1
powershell -ExecutionPolicy Bypass -File _13_week_13_ci_cd_automation\tool\build_artifacts.ps1
```

Skrip pertama berhenti pada pemeriksaan pertama yang gagal, sama seperti job CI.
Skrip kedua membangun APK + AAB lalu **memastikan kedua berkas ada di path yang
dirujuk `upload-artifact`** - kesalahan path tidak akan lolos sampai CI.

> **Catatan Windows:** di mesin tanpa Developer Mode, `flutter pub get` keluar
> dengan exit 1 pada pembuatan symlink plugin desktop, padahal paket sudah
> ter-resolve (`Got dependencies!`). Skrip menandainya sebagai catatan, bukan
> kegagalan, karena target project ini Android dan CI berjalan di Linux. Detail:
> [docs/ci-cd-report.md](docs/ci-cd-report.md) 4.3.

### Manual, satu per satu

```bash
cd _12_week_12_testing_quality_assurance
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test test_driver
flutter analyze --fatal-infos
flutter test --coverage
flutter build apk --release
flutter build appbundle --release
```

## Hasil verifikasi lokal

| Langkah | Hasil |
| --- | --- |
| `dart format` | 58 berkas, 0 changed |
| `flutter analyze --fatal-infos` | No issues found! |
| `flutter test --coverage` | 130 lulus, 0 gagal |
| Cakupan | 676/867 baris = 78,0% (stabil dengan `--concurrency=1`) |
| `app-release.apk` | 51,16 MB, `versionCode 2`, `versionName 1.0.0` |
| `app-release.aab` | 50,16 MB |

Status run di GitHub Actions: **belum dijalankan** (tidak ada push). Tabel bukti
run sengaja dikosongkan di laporan, bukan diisi angka karangan - lihat
[docs/ci-cd-report.md](docs/ci-cd-report.md) 6.

## Dua masalah yang ditemukan sebelum push

1. **Build release gagal**: `package dev.flutter.plugins.integration_test does
   not exist`. Penyebabnya `GeneratedPluginRegistrant.java` ditulis ulang oleh
   `flutter test` (dev dependency ikut terdaftar) sementara build release
   berjalan bersamaan. Solusi: test dan build berurutan, tidak paralel.
2. **Angka cakupan tidak stabil**: 674 vs 676 baris, berasal dari konstruktor
   `const` di `lib/core/failures.dart` yang kadang belum ter-compile lintas
   isolate. Stabil dengan `--concurrency=1`.

Detail dan log ada di [docs/ci-cd-report.md](docs/ci-cd-report.md) 4.

## Risiko keamanan yang masih terbuka

| # | Risiko | Tingkat |
| --- | --- | --- |
| 1 | Release ditandatangani **debug keystore** - tidak layak Play Store | Tinggi |
| 2 | `google-services.json` ter-commit (API key client, perlu dibatasi per SHA-1) | Sedang |
| 3 | Belum ada pemindaian secret / dependensi | Sedang |
| 4 | Action dipin ke tag `@v4`, bukan commit SHA | Rendah–sedang |
| 5 | Artefak dapat diunduh publik selama 7 hari | Rendah |

Penjelasan dan langkah perbaikannya ada di
[docs/security-review.md](docs/security-review.md).

## Versi berikutnya

| Versi | Isi |
| --- | --- |
| `1.0.0+2` (sekarang) | build CI pertama, tidak ada perubahan perilaku |
| `1.0.1+N` | perbaikan bug |
| `1.1.0+N` | fitur baru (kompatibel) |
| `2.0.0+N` | perubahan tidak kompatibel |

Build number selalu naik dan tidak pernah diulang, karena Google Play menolak
build number yang sudah dipakai. Tag `v1.0.0` dibuat pada commit yang sudah lolos
CI agar source, log pipeline, dan artefak bisa dihubungkan.

## Struktur

```text
.github/workflows/
├── ci.yml              # Minggu 8: hanya project Minggu 7 (dibiarkan sebagai bukti)
└── flutter-ci.yml      # Minggu 13: format + analyze + test + build Android

_13_week_13_ci_cd_automation/
├── README.md
├── docs/
│   ├── ci-cd-plan.md       # alasan desain: trigger, permission, pin versi, yang tidak dipakai
│   ├── ci-cd-report.md     # hasil nyata, kegagalan yang ditemukan, refleksi
│   └── security-review.md  # risiko yang masih perlu ditangani
└── tool/
    ├── check_ci_locally.ps1  # perintah CI dijalankan lokal, berhenti saat gagal
    └── build_artifacts.ps1   # build APK+AAB, verifikasi path artefak
```

## Refleksi singkat

- **Yang tertangkap otomatis:** kode tidak terformat, peringatan analisis, dan
  perilaku yang rusak (130 test, termasuk kasus tepi yang dulu menemukan bug
  validasi email). Yang **tidak** tertangkap: build release yang gagal karena
  registrant basi - itu hanya ketahuan saat build dijalankan.
- **Yang dibutuhkan saat build gagal:** nama step, commit SHA, versi Flutter dan
  JDK, log Gradle lengkap, serta perintah persis untuk mereproduksi lokal.
- **Yang tetap manual:** signing rilis, unggah ke Play Store, uji di perangkat
  (FCM, secure storage), integration test, tinjauan desain, dan kenaikan versi.

Jawaban lengkap ada di [docs/ci-cd-report.md](docs/ci-cd-report.md) 7.
