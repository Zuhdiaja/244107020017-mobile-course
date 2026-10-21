# Praktikum 2 — Pull Request & Peer Code Review

Laporan pelaksanaan Praktikum 2 Minggu 8 pada repository
`244107020017-mobile-course`. Semua tautan di bawah dapat diverifikasi
langsung di GitHub.

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |
| Repository | `Zuhdiaja/244107020017-mobile-course` |
| Project yang direview | `_07_week_7_clean_architecture` |
| Branch kerja | `feat/email-validation` |
| Commit terakhir | `54ea748` |
| Tanggal | 21–22 Oktober 2026 |

---

## 1. Alur kerja yang dijalankan

```text
issue #1  →  branch feat/email-validation  →  3 commit kecil  →  PR #2
          →  review sejawat  →  approve  →  squash merge  →  issue tertutup
```

| Tahap | Bukti |
| --- | --- |
| Issue dibuat lebih dulu | [#1 Validasi email kosong menampilkan pesan yang salah](https://github.com/Zuhdiaja/244107020017-mobile-course/issues/1) |
| Branch dari `develop` | `feat/email-validation`, bukan dari `main` |
| PR ke `develop` (bukan `main`) | [#2 feat(auth): pesan validasi email kosong + test](https://github.com/Zuhdiaja/244107020017-mobile-course/pull/2) |
| Commit kecil & konvensional | `fd8bcf5` `feat(auth)`, `701e17a` `test(auth)`, `54ea748` `style(test)` |
| Ukuran PR | 4 file, +193 / −18 baris (batas codelab < 300) |
| Issue ditutup otomatis | `Closes #1` di body PR → GitHub menautkan *Linked issues* |

### Isi PR

| File | Layer | Perubahan |
| --- | --- | --- |
| `login.dart` | domain | Cek `trimmedEmail.isEmpty` sebelum cek `@`, gagal cepat sebelum repository dipanggil |
| `login_page.dart` | presentation | Validator form memakai pesan yang sama: "Email wajib diisi" |
| `login_usecase_test.dart` | test | 2 test baru: email kosong dan email berisi spasi saja |
| `login_page_test.dart` | test | 4 widget test: memasang `LoginPage` dengan repository palsu, tanpa Firebase/secure storage/jaringan |

---

## 2. Hasil review sejawat

Reviewer: teman sekelas (satu kelas TI-3H), dijadwalkan submit pada
22 Oktober 2026 pagi. Kelima temuan di bawah sudah diverifikasi ulang
terhadap kode di branch `feat/email-validation` @ `54ea748`.

| # | Kategori | Level | Temuan | Bukti |
| --- | --- | --- | --- | --- |
| 1 | Kebenaran dokumen | Blocker | Body PR mengklaim `dart format --set-exit-if-changed lib test` → `0 changed`, padahal di branch ini keluar **exit 1** dengan 12 file berubah | `dart format --set-exit-if-changed lib test` → `Formatted 22 files (12 changed)` |
| 2 | Kebenaran (error path) | Saran | `login_page.dart:42` menampilkan `state.error` mentah; `auth_providers.dart:73` melempar `Exception(...)` sehingga pesan jadi `Login gagal: Exception: ...` | `state.error` bertipe `Object?`, `Exception.toString()` menambah prefix |
| 3 | Kebenaran (layout) | Saran | `login_page.dart:58` dan `:60` dua `Padding(24)` bersarang → padding efektif 48 | kode `SingleChildScrollView(padding: 24) > Padding(padding: 24)` |
| 4 | Arsitektur | Saran | `auth_providers.dart:3-5` (layer presentation) mengimpor `data/` dan menginstansiasi `AuthRepositoryImpl`, `TokenStore`, `buildApiClient` di `:17-30` → composition root bocor ke presentation | tiga import `../../data/...` di file presentation |
| 5 | Test & keterbacaan | Saran | Kasus tepi `budi@`, `@polinema.ac.id`, `budi @polinema.ac.id` lolos validasi dan belum diuji; `_FakeAuthRepository` terduplikasi di dua file test; `context.go('/')` hardcoded | `login_page_test.dart:15`, `login_usecase_test.dart:14`, `login_page.dart:40` |

Keputusan reviewer: **Approve**, dengan catatan temuan 2–5 layak menjadi
issue lanjutan, bukan blocker PR ini.

---

## 3. Tindak lanjut per temuan

| # | Keputusan | Alasan teknis | Tindakan |
| --- | --- | --- | --- |
| 1 | **Diterima** | Klaim di dokumen harus bisa direproduksi persis oleh reviewer. Yang benar-benar bersih hanya 4 file milik PR ini; 12 file lain adalah sisa Minggu 7 yang belum diformat dan sengaja tidak dimasukkan agar PR tetap < 300 baris. | Body PR diperbaiki: perintah `dart format` ditulis eksplisit untuk 4 file PR, ditambah catatan bahwa 12 file sisa dikerjakan di Praktikum 3 |
| 2 | **Ditunda** | Perbaikannya menyentuh kontrak `AuthNotifier.login` dan `sessionProvider`, yaitu 2 provider yang dipakai `home_page.dart`. Perubahan itu bukan bagian dari tujuan PR (validasi email) dan akan menambah luas PR melewati satu tujuan. | Dicatat sebagai issue lanjutan: *"Pesan error menampilkan prefix `Exception:`"* |
| 3 | **Ditunda** | Murni kosmetik layout, tidak mengubah perilaku validasi. | Issue lanjutan: *"Padding ganda pada form login"* |
| 4 | **Ditunda, sebagian ditolak** | Menempatkan `authRepositoryProvider` di presentation memang kompromi yang sudah ada sejak Minggu 7, tetapi memindahkannya sekarang berarti memindahkan seluruh composition root (`tokenStore`, `apiClient`, `pushService`) — perubahan besar yang tidak berhubungan dengan validasi email. | Issue lanjutan: *"Pindahkan composition root ke `lib/core/di.dart`"* |
| 5 | **Diterima sebagian** | Test `budi@` memang belum ada dan perilakunya saat ini lolos validasi — ini celah nyata. Duplikasi fake repository dan `context.go('/')` hardcoded adalah kerapian, bukan kebenaran. | Test `budi@` ditambahkan pada PR lanjutan; dua temuan kerapian masuk satu issue |

Prinsip yang dipegang: PR ini **satu tujuan** (pesan validasi email kosong).
Temuan yang benar tetapi di luar tujuan tidak dipaksakan masuk, melainkan
dicatat sebagai issue agar tidak hilang.

---

## 4. Bukti mesin (dijalankan sendiri, bukan diklaim)

Dijalankan di `_07_week_7_clean_architecture` pada commit `54ea748`:

```text
flutter analyze
  -> No issues found! (ran in 3.5s)

dart format --set-exit-if-changed
   lib/features/auth/domain/usecases/login.dart
   lib/features/auth/presentation/pages/login_page.dart
   test/login_usecase_test.dart
   test/login_page_test.dart
  -> Formatted 4 files (0 changed), exit 0

flutter test
  -> 00:07 +28: All tests passed!
```

Catatan lingkungan: `flutter test` gagal dengan `Building native assets failed`
bila dijalankan dari path berisi spasi (`D:\Semester 5\...`). Test dijalankan
lewat junction tanpa spasi (`D:\mc-link`) — masalah path Windows, bukan kode.

Sisa yang **belum** dikerjakan (dijadwalkan Praktikum 3):

```text
dart format --set-exit-if-changed lib test
  -> Formatted 22 files (12 changed), exit 1
     (lib/main.dart, lib/pages/home_page.dart, lib/core/format.dart,
      lib/features/auth/data/*, lib/features/notifications/data/*,
      lib/features/auth/presentation/providers/auth_providers.dart,
      test/api_errors_test.dart, test/format_test.dart)
```

---

## 5. Review yang saya lakukan untuk PR teman (timbal balik)

Codelab meminta review dua arah. Review yang saya berikan:

| | |
| --- | --- |
| PR yang direview | [oninonins/244107020122-mobile-course#3](https://github.com/oninonins/244107020122-mobile-course/pull/3) |
| Judul | `docs(review): catat temuan review dan keputusan week 8` |
| File | `08-week-8-mid-project-review/docs/ai-review-vs-keputusan.md` (+191) |
| Keputusan saya | **Approve** |
| Status | Sudah di-merge (`d7f5b74`) |

Lima temuan yang saya berikan:

1. **Blocker** — bukti tidak bisa direproduksi: branch `docs/week-8-review`
   hanya 1 commit di atas `develop` dan tidak memuat PR #2. Di branch itu
   `test/data/api_client_refresh_test.dart` dan
   `test/presentation/session_debug_test.dart` tidak ada, sehingga
   `flutter test` menghasilkan 43 test, bukan 47 seperti yang diklaim dokumen.
   Output `+2: All tests passed!` yang ditempel berasal dari file yang tidak
   ada di branch tersebut. Perbaikan: cabangkan dari `fix/session-debug-stale`,
   atau tulis eksplisit "dijalankan pada `fix/session-debug-stale` @ `1e96da3`".
2. **Salah karakterisasi** — dokumen menyebut diff hanya akibat `dart format`,
   padahal ada perubahan prosa komentar yang bukan hasil formatter.
3. **Dokumen tidak lengkap** — `README.md` kosong dan
   `docs/review-checklist.md` masih menyisakan "diisi saat PR, review sejawat"
   tanpa tautan ke file baru.
4. **Temuan tidak tercatat** — dokumen mengklaim 5 temuan, tetapi saran yang
   masih terbuka (sentralisasi notifikasi perubahan token) tidak dicatat
   beserta alasan ditolak/ditunda.
5. **Angka tidak konsisten** — body PR #2 menulis "45 test", dokumen menulis
   "47 test".

Pola komentar yang dipakai: **observasi → bukti → dampak → usulan konkret**,
dengan level eksplisit (blocker / saran) agar author tahu mana yang wajib.

---

## 6. Refleksi

**Beda LGTM buta dengan approve yang bertanggung jawab.** LGTM buta berhenti
di "kodenya kelihatan benar". Approve yang bertanggung jawab menuntut reviewer
menjalankan branch, menjalankan perintah yang diklaim di body PR, dan
membuktikan sendiri angkanya. Temuan #1 pada review saya untuk PR teman
(klaim 47 test vs 43 test) adalah contoh persisnya: tanpa checkout dan hitung
ulang, klaim itu akan lolos begitu saja.

**Kapan request changes, kapan cukup saran.** Request changes dipakai bila
temuan membuat PR tidak layak merge: bukti palsu, bug yang bisa dipicu
pengguna, atau pelanggaran dependency rule yang menular. Saran dipakai bila
temuan benar tetapi di luar tujuan PR — seperti empat temuan pada PR #2.
Mencampur keduanya membuat PR kecil berubah menjadi refactor besar.

**Yang saya tolak atau sederhanakan.** Temuan #4 (composition root di
presentation) saya sederhanakan menjadi issue, bukan dikerjakan di PR ini,
karena memindahkan `tokenStore`/`apiClient`/`pushService` sekaligus akan
membuat PR melewati 300 baris dan sulit direview.

**Satu hal konkret yang saya perbaiki setelah review.** Klaim
`dart format ... -> 0 changed` di body PR #2 saya ganti menjadi perintah
untuk 4 file PR saja, karena perintah versi lama benar-benar keluar exit 1.
Dampaknya: reviewer berikutnya tidak perlu mengulang pengecekan yang sama,
dan sisa 12 file tercatat jelas sebagai pekerjaan Praktikum 3.
