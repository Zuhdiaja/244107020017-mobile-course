# Review Checklist — Minggu 8 (Mid Project Review)

Dokumen ini diisi bertahap mengikuti tiga praktikum Minggu 8. Praktikum 1
mengisi bagian **audit riwayat** dan **tabel perbaikan pesan commit**.

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |
| Repository | `244107020017-mobile-course` |
| Project yang direview | `_07_week_7_clean_architecture` (hasil Minggu 5–7) |

---

## 1. Hasil audit riwayat Git

Perintah yang dijalankan:

```bash
git log --oneline -15
git branch -a
git status
```

### Temuan

| No | Temuan | Bukti | Dampak | Rencana tindakan |
| --- | --- | --- | --- | --- |
| 1 | Tidak ada branch `develop`; semua kerja langsung ke `main` | `git branch -a` hanya menampilkan `main` + `origin/main` | Tidak ada tempat integrasi; `main` tidak bisa dijadikan branch rilis yang dilindungi | Buat `develop` dari `main`, push, lalu jadikan default branch PR |
| 2 | Seluruh commit Minggu 1–7 masuk langsung ke `main` | `git log` menunjukkan riwayat linear tanpa merge commit | Tidak ada review sebelum kode masuk branch rilis | Mulai Minggu 8 semua perubahan lewat `feature/*` → `develop` |
| 3 | Sebagian pesan commit lama tidak menjelaskan isi perubahan | `praktikum 1 done`, `Praktikum 2 done`, `praktikum 3 done`, `all done dan rapikan readme`, `refactoring dan testing`, `ai challenge dan refactoring testing` | Sulit tahu perubahan apa yang bisa di-revert; tidak bisa dibaca dari `git log` | Ditulis ulang pada tabel bagian 2 |
| 4 | Beberapa commit mencampur beberapa tujuan | `ba4382a ai challenge dan refactoring testing` menyentuh README, `api_errors.dart`, `push_service.dart`, `main.dart`, dan dua file test | Satu commit tidak bisa di-revert sebagian; review jadi lebih lambat | Dipecah per tujuan pada commit berikutnya |
| 5 | `.vscode/` tidak terlacak dan tidak di-ignore | `git status` menampilkan `?? .vscode/` | Muncul sebagai noise di setiap `git status`; pengaturan editor bersama tidak ikut tersimpan | Di-commit sebagai `chore(vscode)` karena berisi pengaturan exclude folder hasil generate |
| 6 | `dart format .` gagal di Windows | `PathNotFoundException` pada `build\firebase_messaging\...` (path > 260 karakter) | Format tidak bisa diverifikasi dengan perintah persis | Jalankan `dart format --set-exit-if-changed lib test`, dan pakai perintah itu di CI |

Catatan lingkungan: `flutter test` gagal dengan `Building native assets failed`
bila dijalankan dari path yang mengandung spasi (`D:\Semester 5\...`). Test
dijalankan lewat junction tanpa spasi (`D:\mc-link`) dan hasilnya hijau. Ini
masalah path Windows, bukan kode project.

### Riwayat 15 commit terakhir (sebelum Minggu 8)

```text
7973263 refactor(core): fungsi murni, Failure di presentation, test use case dengan fake repository
6e2d611 docs: AI challenge, usulan AI vs keputusan final, dan verifikasi grep
337f4ac refactor(features): layer presentation per fitur (Praktikum 3)
23a485a feat(auth): layer domain dan data fitur auth (Praktikum 2)
7bba7be docs: hapus ai-challenge Minggu 6 dan bersihkan tautan README
5b8d752 chore: ignore service-account.json di project Minggu 6
e952b90 docs: README Minggu 7 (buang sisa Minggu 6, jelaskan struktur target)
7547739 docs: laporan audit Praktikum 1 (pemetaan layer + tiga grep)
3a14c88 chore: snapshot before clean architecture
ba4382a ai challenge dan refactoring testing
22fadee praktikum 3 done
498365d Praktikum 2 done
3008b5c praktikum 1 done
bf9677b all done dan rapikan readme
a2f9b09 refactoring dan testing
```

Commit Minggu 7 sudah memakai format konvensional. Yang perlu diperbaiki
adalah commit Minggu 5–6 (baris 6 dari bawah dan sebelumnya).

---

## 2. Tabel perbaikan pesan commit (sebelum → sesudah)

Format yang dipakai: `tipe(scope): deskripsi singkat`, dengan tipe `feat`,
`fix`, `refactor`, `test`, `docs`, `chore`.

| # | Sebelum | Sesudah | Alasan |
| --- | --- | --- | --- |
| 1 | `22fadee praktikum 3 done` | `feat(notifications): handler foreground/background/terminated + deep link` | Isi commit adalah `push_service.dart` (handler tiga app state), `announcement_page.dart`, dan `routes.dart`. "Praktikum 3 done" tidak memberi tahu fitur apa yang lahir; versi baru menyebut perilaku yang bisa diuji. |
| 2 | `a2f9b09 refactoring dan testing` | `test(notes): unit test model catatan + catatan pengujian di README` | Commit ini hanya menambah `test/note_test.dart` dan README. Tipe `test` lebih tepat daripada "refactoring", karena tidak ada kode produksi yang diubah. |
| 3 | `bf9677b all done dan rapikan readme` | `docs(week5): rapikan README offline-first + tautan screenshot` | Perubahan hanya di `README.md` (62 baris tambah, 20 hapus). "all done" tidak bisa diverifikasi dan tidak menyebut dokumen mana. |
| 4 | `ba4382a ai challenge dan refactoring testing` | `refactor(auth): mapDioException mengembalikan Failure` + `test(auth): test pemetaan error dan push service` + `docs: AI challenge Minggu 6` | Satu commit ini mencampur tiga tujuan (kode, test, dokumen) dan 326 baris perubahan. Seharusnya dipecah tiga commit agar bisa direview dan di-revert terpisah. |

Aturan yang dipegang setelah perbaikan ini:

- Satu commit = satu perubahan logis yang bisa direview dan di-revert.
- Pesan commit menyebut **apa** yang berubah dan **di mana** (`scope`).
- Tidak ada lagi `update`, `fix bug`, atau `done` tanpa keterangan.
- Perubahan dokumen dipisah dari perubahan kode.

---

## 3. Branch kerja yang dipakai mulai Minggu 8

```text
main                    -> selalu bisa dirilis, dilindungi, tidak di-commit langsung
develop                 -> integrasi fitur mingguan, target default Pull Request
feat/email-validation   -> kerja satu fitur (validasi email kosong)
fix/*                   -> perbaikan cepat + test
```

Alur satu perubahan:

```bash
git checkout develop
git pull origin develop
git checkout -b feat/email-validation
# ... satu perubahan kecil + test ...
git add -p
git commit -m "feat(auth): pesan validasi email kosong + test"
git push -u origin feat/email-validation
```

---

## 4. Praktikum 2 — Pull Request & review sejawat

Rincian lengkap: [`peer-review.md`](peer-review.md).

| Butir | Status | Bukti |
| --- | --- | --- |
| Issue dibuat sebelum PR | ✅ | [#1](https://github.com/Zuhdiaja/244107020017-mobile-course/issues/1) |
| PR kecil satu fitur ke `develop` | ✅ | [#2](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/2) — 4 file, +193/−18 |
| Body PR memuat masalah, solusi, cara uji | ✅ | body PR #2 |
| Issue ditutup otomatis via `Closes #1` | ✅ | Linked issues di sidebar PR #2 |
| Review sejawat ≥ 3 komentar bermakna | ✅ | 5 temuan: 2 kebenaran, 1 arsitektur, 1 test, 1 keterbacaan |
| Keputusan reviewer | ✅ Approve | catatan: temuan 2–5 menjadi issue lanjutan |
| Review timbal balik untuk PR teman | ✅ | [oninonins/244107020122-mobile-course#3](https://github.com/oninonins/244107020122-mobile-course/pull/3) — saya approve, sudah merged |
| Merge | ✅ | Squash and merge → `26f4e1f` di `develop` (22 Okt 2026 01:16 WIB) |
| Issue tertutup otomatis | ✅ | issue #1 berstatus `closed / completed` pada detik yang sama |


Keputusan atas 5 temuan review:

| # | Temuan | Keputusan | Alasan |
| --- | --- | --- | --- |
| 1 | Klaim `dart format` tidak bisa direproduksi | Diterima | Body PR diperbaiki: perintah ditulis untuk 4 file PR, 12 file sisa dijadwalkan Praktikum 3 |
| 2 | Pesan error menampilkan prefix `Exception:` | Ditunda | Menyentuh kontrak `AuthNotifier` + `sessionProvider`, di luar tujuan PR → backlog A |
| 3 | `Padding(24)` ganda pada form login | Ditunda | Kosmetik layout, tidak mengubah perilaku validasi → backlog B |
| 4 | Composition root (`data/`) ada di presentation | Ditunda | Perlu memindahkan `tokenStore`/`apiClient`/`pushService`, PR akan melewati 300 baris → backlog C |
| 5 | Kasus tepi `budi@` belum diuji + fake duplikat | Diterima sebagian | Backlog D: putuskan aturan kasus tepi + tambah test. Backlog E: pindahkan fake ke `test/helpers/`, pakai `AppRoutes.home` |

---

## 5. Praktikum 3 — Static analysis, CI, dan kesiapan tengah semester

### 5.1 Tiga pemeriksaan mesin

Dijalankan di `_07_week_7_clean_architecture` pada branch `chore/week8-ci`:

```text
flutter analyze
  -> No issues found! (ran in 2.3s)

dart format --set-exit-if-changed lib test
  -> Formatted 22 files (0 changed), exit 0

flutter test
  -> 00:02 +28: All tests passed!
```

Perbaikan yang diperlukan agar ketiganya hijau:

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| 12 file berubah saat `dart format --set-exit-if-changed` | Kode Minggu 5–7 ditulis sebelum ada cek format di PR | `dart format lib test` sekali, lalu dijaga oleh CI |
| `curly_braces_in_flow_control_structures` di `api_client.dart:24` | Formatter memecah `if` satu baris, sementara lint mewajibkan blok | Tambahkan `{ }` pada `if (renewed.access == null)` |
| `dart format .` gagal `PathNotFoundException` | Formatter ikut menyisir `build/` yang path-nya > 260 karakter | Batasi cakupan: `dart format lib test` (dipakai juga di CI) |

### 5.2 CI menolak PR kotor

File: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml)

```yaml
on:
  pull_request:
    branches: [develop, main]
  push:
    branches: [develop]
defaults:
  run:
    working-directory: _07_week_7_clean_architecture
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - actions/checkout@v4
      - subosito/flutter-action@v2 (3.47.5, stable, cache)
      - flutter pub get
      - flutter analyze
      - dart format --set-exit-if-changed lib test
      - flutter test
```

`working-directory` wajib diisi karena Flutter project berada di subfolder
`_07_week_7_clean_architecture`, bukan di root repository.

### 5.3 Tiga grep sterilitas (dijalankan ulang, bukan disalin)

```text
1. Presentation steril dari data mentah   -> 0 hasil
   (Dio(|openDatabase|getDatabasesPath|FlutterSecureStorage|
    SharedPreferences.getInstance|jsonDecode) pada lib/features/*/presentation, lib/pages)
2. Domain & core steril dari framework    -> 0 hasil
   (import package:flutter|dio|sqflite|firebase pada lib/features/*/domain, lib/core)
3. Widget tidak instansiasi repository    -> 0 hasil
   (Repository(|Dio(BaseOptions pada lib/pages)
```

### 5.4 Penilaian kesiapan

| Butir | Status | Bukti |
| --- | --- | --- |
| Struktur feature-first terbukti (tiga grep sterilitas) | ✅ | §5.3 — ketiganya 0 hasil |
| `flutter analyze` bersih | ✅ | `No issues found!` |
| `dart format` rapi | ✅ | `Formatted 22 files (0 changed)` |
| `flutter test` hijau | ✅ | 28 test |
| PR kecil + commit jelas | ✅ | [#2](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/2) — 4 file, 3 commit konvensional |
| README + screenshot + cara menjalankan | ✅ | [`../README.md`](../README.md) + bukti visual ada di [`../screenshots/`](../screenshots/) |
| Semua komentar review ditindaklanjuti | ✅ | 1 diterima & dikerjakan, 3 ditunda dengan alasan, 1 diterima sebagian |
| CI menolak PR kotor | ✅ | PR #4 gagal di step `dart format` ([run 39656242167](https://github.com/Zuhdiaja/244107020017-mobile-course/actions/runs/39656242167)), lalu hijau setelah sinkronisasi ([39657414147](https://github.com/Zuhdiaja/244107020017-mobile-course/actions/runs/39657414147)) |
| Review AI diverifikasi, bukan ditempel | ✅ | [`ai-review-vs-keputusan.md`](ai-review-vs-keputusan.md) — 4 diterima, 1 diterima sebagian, 1 ditolak, 1 ditunda |

### 5.5 Satu PR besar dipecah jadi dua

Rencana awal Praktikum 3 menumpuk format 12 file, CI, README, dan laporan dalam
satu branch. Perkiraan ukurannya ±470 baris — melanggar aturan < 300.

Dipecah berdasarkan tujuan:

| PR | Branch | Isi | Baris |
| --- | --- | --- | --- |
| [#5](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/5) | `chore/week8-format` | hasil `dart format` + satu perbaikan lint | 194 |
| [#4](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/4) | `ci/week8-pipeline` | workflow CI, README, laporan Praktikum 3 | 276 |

Konsekuensi yang harus diterima: PR #4 bergantung pada #5, jadi #5 harus
di-merge lebih dulu. Itu terbukti dari run merah `39656242167`.

**Definisi selesai mid review:** aplikasi berjalan identik dengan akhir Minggu 7,
tiga pemeriksaan mesin hijau, minimal 1 PR kecil per pasangan sudah di-merge
via review, dan README memuat status paruh semester + peta issue/PR. Keempatnya
terpenuhi: perilaku hanya berubah di pesan validasi email, §5.1 hijau, CI aktif
(§5.2), dan PR #2 di-merge lewat review sejawat.
