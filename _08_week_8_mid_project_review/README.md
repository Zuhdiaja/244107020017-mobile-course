# Week 8 — Mid Project Review & Code Review

Paruh semester: review project Minggu 5–7 (`campus_notify`) dengan disiplin
kolaborasi Git, bukan menambah fitur baru. Aplikasi yang dinilai tetap
`_07_week_7_clean_architecture`; folder ini berisi bukti proses review-nya.

## Identitas

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |
| Repository | `Zuhdiaja/244107020017-mobile-course` |
| Project yang direview | `_07_week_7_clean_architecture` |

## Status paruh semester

| Aspek | Status | Bukti |
| --- | --- | --- |
| Aplikasi berjalan identik dengan akhir Minggu 7 | ✅ | hanya 1 perubahan perilaku, yaitu pesan validasi email kosong ([PR #2](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/2)) |
| `flutter analyze` | ✅ `No issues found!` | [§5.1](docs/review-checklist.md#51-tiga-pemeriksaan-mesin) |
| `dart format --set-exit-if-changed lib test` | ✅ `0 changed` | [§5.1](docs/review-checklist.md#51-tiga-pemeriksaan-mesin) |
| `flutter test` | ✅ 28 test | [§5.1](docs/review-checklist.md#51-tiga-pemeriksaan-mesin) |
| Struktur feature-first (tiga grep sterilitas) | ✅ 0 / 0 / 0 | [§5.3](docs/review-checklist.md#53-tiga-grep-sterilitas-dijalankan-ulang-bukan-disalin) |
| PR kecil di-merge lewat review | ✅ 2 PR | peta di bawah |
| CI menolak PR kotor | ✅ | [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) |

## Peta issue dan Pull Request

| # | Jenis | Judul | Status |
| --- | --- | --- | --- |
| [#1](https://github.com/Zuhdiaja/244107020017-mobile-course/issues/1) | Issue | Validasi email kosong menampilkan pesan yang salah | closed / completed |
| [#2](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/2) | PR `feat/email-validation` → `develop` | feat(auth): pesan validasi email kosong + test | merged (`26f4e1f`), approve `oninonins` |
| [#3](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/3) | PR `docs/week8-praktikum2` → `develop` | docs(week8): laporan Praktikum 2 | merged (`4ba1c19`) |
| — | PR `chore/week8-format` → `develop` | style: dart format seluruh lib dan test + blok pada if api_client | menunggu merge |
| — | PR `ci/week8-pipeline` → `develop` | chore(week8): workflow CI, README paruh semester, hasil Praktikum 3 | menunggu merge |

Review timbal balik yang saya berikan:
[oninonins/244107020122-mobile-course#3](https://github.com/oninonins/244107020122-mobile-course/pull/3)
— 5 temuan (1 blocker, 4 saran), approve, sudah merged.

## Fitur utama aplikasi

| Fitur | Isi |
| --- | --- |
| `auth` | Login, sesi, penyimpanan access/refresh token di secure storage, logout, refresh token otomatis saat `401`. |
| `notifications` | Permission, token lifecycle FCM, tiga app state (foreground, background, terminated), deep link. |
| `announcements` | Halaman tujuan deep link `/pengumuman/:id` dari payload notifikasi. |

## Stack

| | |
| --- | --- |
| Language | Dart 3.13.4 |
| Framework | Flutter 3.47.5 |
| State | Riverpod 3.4.3 |
| Routing | GoRouter |
| Jaringan | Dio |
| Penyimpanan | flutter_secure_storage |
| Notifikasi | firebase_messaging + flutter_local_notifications |
| Backend | Firebase (email/password auth) |
| CI | GitHub Actions (`subosito/flutter-action@v2`) |

## Cara menjalankan

Butuh Flutter SDK dan Android SDK.

```bash
cd _07_week_7_clean_architecture
flutter pub get

# isi credential Firebase dulu
# android/app/google-services.json
# service-account.json (tidak di-commit, sudah masuk .gitignore)

flutter run
```

Verifikasi tanpa perangkat (yang juga dijalankan CI):

```bash
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

## Alur Git yang dipakai

```text
main      -> selalu bisa dirilis, dilindungi ruleset `protect-main`
develop   -> integrasi mingguan, target default semua Pull Request
feat/*    -> kerja satu fitur, dihapus setelah merge
docs/*    -> dokumen laporan, dipertahankan sebagai bukti proses
```

Aturan yang ditegakkan: tidak ada commit langsung ke `main` (wajib PR +
review + resolve komentar), pesan commit `tipe(scope): deskripsi`,
satu PR satu tujuan dan < 300 baris.

## Hasil yang dicapai

- 1 issue ditutup otomatis oleh PR (`Closes #1`).
- 2 PR di-merge ke `develop` lewat review, masing-masing < 300 baris.
- 1 PR review timbal balik untuk repository teman.
- `flutter analyze`, `dart format`, dan `flutter test` hijau, dijaga CI.
- 12 file sisa Minggu 5–7 diformat; satu lint `curly_braces_in_flow_control_structures` muncul akibat formatter dan diperbaiki.

## Dokumentasi

- [docs/review-checklist.md](docs/review-checklist.md) — audit riwayat, perbaikan pesan commit, checklist Praktikum 2, hasil Praktikum 3
- [docs/peer-review.md](docs/peer-review.md) — laporan Praktikum 2: PR, review sejawat, tindak lanjut
- [screenshots/](screenshots/) — bukti visual
