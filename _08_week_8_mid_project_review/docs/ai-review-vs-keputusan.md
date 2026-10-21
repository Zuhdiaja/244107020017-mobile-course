# Review AI vs Keputusan Final

Dokumen ini memenuhi syarat Minggu 8: prompt disimpan, keluaran awal AI dicatat,
lalu setiap temuan diverifikasi sebelum diterima atau ditolak. AI berperan sebagai
reviewer awal; keputusan teknis tetap milik saya.

Review sejawat manusia punya catatan terpisah di [`peer-review.md`](peer-review.md).
Dokumen ini khusus temuan yang datang dari AI.

## 1. Prompt yang dipakai

```text
praktikum 3 sekarang
```

```text
sekarang cek lagi ci
```

```text
screenshot ini yang apa
```

Ketiga prompt itu dipakai berurutan: menyiapkan Praktikum 3, membaca status
CI, lalu memverifikasi isi gambar sebelum dipasang di README.

Catatan jujur: prompt satu-tembak ala panduan ("Review PR Flutter ini sebagai
senior Flutter dev ... 5 temuan teratas + level") **tidak** dipakai persis.
Review berjalan menyatu dengan pengerjaan, dan keluarannya diuji dengan
perintah nyata. Karena itu tabel di bawah memuat bukti berupa exit code,
keluaran perintah, dan id run Actions — bukan kutipan opini.

## 2. Tabel usulan AI vs keputusan final

| # | Klaim AI | Level | Verifikasi | Keputusan | Bukti |
| --- | --- | --- | --- | --- | --- |
| A1 | 12 file sisa Minggu 5–7 belum terformat, sehingga `dart format --set-exit-if-changed` gagal | blocker | perintah dijalankan di lokal | **Diterima**, seluruh `lib` dan `test` diformat | sebelum: `Formatted 22 files (12 changed)`, exit 1. sesudah: `0 changed`, exit 0 |
| A2 | Setelah diformat, muncul lint `curly_braces_in_flow_control_structures` di `api_client.dart:24` karena formatter memecah `if` satu baris | blocker | `flutter analyze` | **Diterima**, ditambah blok `{ }` | sebelum: `1 issue found ... api_client.dart:24:15`. sesudah: `No issues found!` |
| A3 | PR CI akan merah di step `dart format` bila di-merge sebelum PR format, karena dicabangkan dari `develop` yang lama | saran | diprediksi, lalu dibuktikan lewat run Actions | **Diterima**, merge diurutkan (#5 lalu #4) dan branch disinkron | run [39656242167](https://github.com/Zuhdiaja/244107020017-mobile-course/actions/runs/39656242167) gagal di `dart format`; run [39657414147](https://github.com/Zuhdiaja/244107020017-mobile-course/actions/runs/39657414147) hijau |
| A4 | Rujukan "backlog A (bagian 6)" di `peer-review.md` menggantung karena bagian 6 sudah tidak ada | saran | `Select-String` pada berkas | **Diterima**, rujukan diganti keterangan mandiri | `peer-review.md` hanya berisi bagian 1–5 |
| A5 | `week8-issue-closed.png` berisi halaman issue #1 yang sudah tertutup | — | gambar dibuka dan diperiksa | **Ditolak**, isinya bukan issue #1 | gambar menampilkan PR #2: badge Merged, reviewer `oninonins`, `Closes #1`, +193/−18. Berkas di-rename jadi `week8-pr2-approved-merged.png` |
| A6 | Naikkan `actions/checkout@v4` ke `v5` sekarang karena Node.js 20 deprecated | saran | annotation pada run | **Ditunda**, warning bukan kegagalan dan di luar satu tujuan PR | annotation run [39657414147](https://github.com/Zuhdiaja/244107020017-mobile-course/actions/runs/39657414147) |
| A7 | Pakai `dart format .` di CI persis seperti contoh panduan | saran | dijalankan dari root repo dan dari folder project | **Diterima sebagian**, cakupan dipersempit ke `lib test` | dari root: `PathNotFoundException` pada `_05_week_5_local_storage_offline_first\build\...`, exit 1. dari folder project: `Formatted 22 files (0 changed)`, exit 0 |

Ringkasan: **4 diterima**, **1 diterima sebagian**, **1 ditolak**, **1 ditunda**.

Syarat tugas terpenuhi: minimal 2 temuan AI terbukti benar dengan bukti
(A1, A2, A3, A4) dan minimal 1 ditolak dengan alasan tertulis (A5).

## 3. Temuan AI yang salah dan dampaknya

A5 adalah contoh paling berguna. Sebelumnya daftar screenshot saya susun
berdasarkan nama berkas, bukan isinya. Nama `week8-issue-closed.png` membuat
saya menyimpulkan isinya halaman issue. Setelah gambar benar-benar dibuka,
ternyata isinya halaman PR #2.

Kalau dipercaya begitu saja, README akan memuat keterangan palsu: gambar PR #2
diberi caption "issue #1 tertutup". Itu bukti yang menyesatkan, dan persis
jenis kesalahan yang diperingatkan panduan: review AI yang salah lebih
berbahaya daripada tidak ada review.

Perbaikan: nama berkas diganti sesuai isi, dan `screenshots/README.md` sekarang
menandai issue #1 sebagai **belum ada** — bukan diklaim ada.

## 4. Aturan yang saya pakai untuk menerima atau menolak

1. Temuan harus bisa direproduksi: perintah, exit code, atau gambar. Klaim tanpa bukti tidak diterima.
2. Usulan yang melanggar dependency rule (domain mengimpor Flutter/Dio/SQLite) langsung ditolak.
3. Nitpick gaya diserahkan ke `dart format` dan CI, bukan jadi komentar manual.
4. Perubahan di luar satu tujuan PR ditunda, dicatat sebagai backlog, bukan dipaksakan masuk.
5. Satu temuan salah membuat seluruh keluarganya diperiksa ulang, bukan hanya temuan itu.

## 5. Bukti mesin

Dijalankan di `_07_week_7_clean_architecture` setelah semua keputusan diterapkan:

```text
flutter analyze
  -> No issues found! (ran in 2.3s)

dart format --set-exit-if-changed lib test
  -> Formatted 22 files (0 changed) in 0.10 seconds, exit 0

flutter test
  -> 00:02 +28: All tests passed!
```

CI pada `develop` setelah PR terakhir di-merge:

```text
run 39659911400  develop  push  -> success
  flutter pub get   success
  flutter analyze   success
  dart format       success
  flutter test      success
```

Tiga grep sterilitas juga dijalankan ulang dan hasilnya nol untuk ketiganya
(rincian di [`review-checklist.md`](review-checklist.md) §5.3).
