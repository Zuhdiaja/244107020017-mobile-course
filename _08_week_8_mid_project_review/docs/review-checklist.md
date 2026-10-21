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
| 6 | `dart format .` gagal di Windows | `PathNotFoundException` pada `build\firebase_messaging\...` (path > 260 karakter) | Format tidak bisa diverifikasi dengan perintah persis seperti codelab | Jalankan `dart format --set-exit-if-changed lib test`, dan pakai perintah itu di CI |

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

## 4. Kesiapan tengah semester (diisi pada Praktikum 3)

| Butir | Status | Bukti |
| --- | --- | --- |
| Struktur feature-first terbukti (tiga grep sterilitas Minggu 7) | _menyusul_ | `_07_week_7_clean_architecture/docs/ai-challenge.md` |
| `flutter analyze` bersih | _menyusul_ | output analyze |
| `dart format` rapi | _menyusul_ | output format |
| `flutter test` hijau | _menyusul_ | output test |
| PR kecil + commit jelas | _menyusul_ | tautan PR |
| README + screenshot + cara menjalankan | _menyusul_ | README Minggu 8 |
| Semua komentar review ditindaklanjuti | _menyusul_ | thread PR |
