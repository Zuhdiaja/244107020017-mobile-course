# Week 9 — AI-Assisted Development / Vibe Coding

Minggu 9 menambah **satu fitur kecil hasil AI** pada aplikasi
`_07_week_7_clean_architecture` (campus_notify): **halaman daftar
pengumuman + pencarian judul + empty state**. Aplikasi yang dinilai
tetap `_07_week_7_clean_architecture`; folder ini berisi bukti proses
AI-assisted development-nya.

Kebijakan AI diikuti: AI boleh mengusulkan kode, tetapi setiap baris
dibaca, diverifikasi, diuji, di-refactor, dan keputusannya dijelaskan
tanpa membuka AI. Nilai ada pada kualitas verifikasi — bukan banyaknya
kode AI yang diterima.

## Identitas

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |
| Repository | `Zuhdiaja/244107020017-mobile-course` |
| Project | `_07_week_7_clean_architecture` (campus_notify) |
| Branch fitur | `feat/announcements-search` dari `develop` |

## Ringkasan proses

| Tahap | Hasil | Bukti |
| --- | --- | --- |
| Prompt 5 slot + konteks | ✅ tanpa secret | [`docs/ai-log.md` §1](docs/ai-log.md#1-prompt-formula-5-slot-mentah) |
| Output awal AI disimpan mentah | ✅ 3 cacat ditandai | [§2](docs/ai-log.md#2-output-awal-ai-mentah-sebelum-diverifikasi) |
| Verifikasi import (domain steril) | ✅ grep → 0 import framework | [§3.2](docs/ai-log.md#32-cek-import--domain-harus-steril) |
| Verifikasi API | ❌→✅ endpoint `/announcements` terbukti fiktif (grep) | [§3.3](docs/ai-log.md#33-cek-api--klaim-get-announcements-dibuktikan-tidak-ada) |
| Test merah pembuktian bug | ✅ 3 test gagal pada logika AI | [§3.5](docs/ai-log.md#35-test-merah--bukti-bug-case-sensitive) |
| Refactor ke Clean Architecture | ✅ filter di use case domain | [§5](docs/ai-log.md#5-refactor-ke-layer-yang-benar) |
| `flutter analyze` | ✅ `No issues found!` | [§7](docs/ai-log.md#7-bukti-mesin-hijau) |
| `dart format --set-exit-if-changed` | ✅ `0 changed` | [§7](docs/ai-log.md#7-bukti-mesin-hijau) |
| `flutter test` | ✅ 40 test (28 lama + 12 baru) | [§7](docs/ai-log.md#7-bukti-mesin-hijau) |
| Tabel usulan AI vs keputusan | ✅ 11 baris, terima/tolak + alasan | [§8](docs/ai-log.md#8-tabel-usulan-ai-vs-keputusan-final) |
| AI Prompt Challenge (review) | ✅ 1 diterima + diperbaiki, 1 ditolak, 1 sebagian | [§6](docs/ai-log.md#6-ai-prompt-challenge--ai-sebagai-reviewer) |

## Fitur: pencarian pengumuman + empty state

| Aspek | Isi |
| --- | --- |
| Halaman | `/pengumuman` — daftar pengumuman + kolom pencarian judul |
| Aturan filter | use case `SearchAnnouncements` (domain murni): query dipangkas, case-insensitive, cocok di mana pun di judul, query kosong = semua |
| Sumber data | `AnnouncementRepositoryImpl` lokal (backend pengumuman belum ada — usulan remote AI ditolak, bukti grep) |
| Empty state | dua varian: "Belum ada pengumuman" (daftar kosong) dan "Tidak ada pengumuman yang cocok" (query tak cocok) |
| Integrasi | kartu pintu masuk di Beranda; menekan kartu pengumuman membuka deep link `/pengumuman/:id` yang sudah ada sejak Minggu 6 |

### Temuan AI dan pembuktiannya

1. **API fiktif** — AI mengusulkan `dio.get('/announcements')`;
   dibuktikan tidak ada dengan grep endpoint seluruh `lib/`.
2. **Bug case-sensitive** — filter `title.contains(query)` gagal
   menemukan "Ujian" dengan query "ujian"; dibuktikan dengan 3 test
   merah, lalu diperbaiki.
3. **Pelanggaran dependency rule** — AI menaruh filter di widget dan
   mengimpor Riverpod di domain; ditolak dan ditulis ulang.

## Stack (tidak ada package baru)

Dart 3.13.4, Flutter 3.47.5, Riverpod 3.4.3, GoRouter, Dio,
flutter_secure_storage, Firebase (auth + FCM) — sama dengan Minggu 7.
Batas prompt "jangan tambah package" dipegang: usulan package fuzzy
search AI ditolak.

## Cara menjalankan

```bash
cd _07_week_7_clean_architecture
flutter pub get
# isi credential Firebase (android/app/google-services.json, service-account.json)
flutter run
```

Alur uji: login → Beranda → kartu **Pengumuman** → coba query kosong,
`ujian`, dan `zzz-tak-ada`.

Verifikasi tanpa perangkat (dijalankan juga oleh CI):

```bash
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

## Hasil yang dicapai

- 1 fitur kecil (search + empty state) ditambah lewat branch
  `feat/announcements-search` dengan commit konvensional
  `feat(...)` + `test(...)` — disiplin GitFlow Minggu 8 tetap jalan.
- 12 test baru (7 unit + 5 widget) tanpa merusak 28 test lama.
- 2 halusinasi AI terbukti dengan bukti mesin (grep + test merah),
  1 pelanggaran arsitektur ditolak.
- Tiga cek mesin hijau: analyze, format, test.

## Dokumentasi

- [docs/ai-log.md](docs/ai-log.md) — prompt mentah, output awal AI,
  verifikasi 6 langkah, test merah, tabel keputusan, refleksi
- [screenshots/](screenshots/) — bukti visual uji manual 3 kondisi query

## Refleksi singkat

Siklus *generate sampai explain* terasa: bagian cepat justru
meminta AI menulis kode; bagian mahal — dan yang dinilai — adalah
membuktikan klaimnya. Klaim "endpoint `/announcements`" terbukti
fiktif dalam satu grep; klaim "filter sudah benar" terbukti salah
dalam satu test merah. Tanpa langkah verify, keduanya akan lolos ke
production — itulah *vibe coding* yang mahal di akhir.
