# Week 5: Local Storage & Offline First

## Identitas

| Keterangan | Detail |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

## Ringkasan Proyek

Aplikasi catatan offline-first dengan fitur:
- penyimpanan preferensi tema menggunakan `SharedPreferences`
- penyimpanan data catatan menggunakan `SQLite`
- state management dengan `Riverpod`
- mekanisme `dirty` dan antrean sync untuk data offline

---

# Praktikum 1: SharedPreferences

## Hasil Praktikum

Halaman Settings menampilkan toggle Mode Gelap dan waktu terakhir aplikasi dibuka.

<table>
  <tr>
    <td><img src="screanshoot/prak1light.png" alt="Light mode" width="420" /></td>
    <td><img src="screanshoot/prak1.png" alt="Dark mode" width="420" /></td>
  </tr>
</table>

---

# Praktikum 2: SQLite dan Repository Catatan

## Hasil Praktikum

<table>
  <tr>
    <td><img src="screanshoot/prak2 kosongan.png" alt="Catatan kosong" width="420" /></td>
    <td><img src="screanshoot/prak2 tambah catatan.png" alt="Tambah catatan" width="420" /></td>
  </tr>
  <tr>
    <td colspan="2" align="center"><img src="screanshoot/prak 2 hasil.png" alt="Hasil catatan tersimpan" width="700" /></td>
  </tr>
</table>

Halaman di atas menampilkan aplikasi catatan offline dengan penyimpanan SQLite.

---

# Praktikum 3: Cache-first dan Antrean Sync

## Hasil Praktikum

Catatan tersimpan secara lokal dan masih menunggu sinkronisasi. Ikon `cloud_off` menunjukkan status `dirty`, dan banner menampilkan jumlah antrean sync.

<table>
  <tr>
    <td><img src="screanshoot/prak3 sebelum tersimpan sync.png" alt="Sebelum sync" width="420" /></td>
    <td><img src="screanshoot/prak3 setelah di sync.png" alt="Setelah sync" width="420" /></td>
  </tr>
</table>

Alur cache-first membaca catatan dari SQLite lokal terlebih dahulu, sehingga data tetap dapat ditampilkan secara offline. Perubahan baru diberi status `dirty`, masuk ke antrean, lalu diproses saat tombol **SYNC** ditekan.

---

# AI Challenge

## Hasil AI

Dokumentasi prompt AI, perbandingan SharedPreferences/Hive/sqflite/Drift, keputusan teknis, AI Verification Checklist, aturan konflik, dan hasil testing tersedia di [docs/ai-challenge.md](docs/ai-challenge.md).

---

# Refactoring, testing, dan error umum

## Hasil Refactoring dan Testing

Refactoring dilakukan pada test agar sesuai dengan aplikasi Offline Notes dan tidak lagi menguji counter bawaan Flutter.

- `note_test.dart` menguji parsing `Note`, serialisasi flag `dirty`, provider sukses dengan `FakeNoteRepository`, dan provider error.
- `note_model_test.dart` menguji konversi model `Note` ke map SQLite dan sebaliknya.
- `notes_provider_test.dart` menguji penambahan catatan melalui repository palsu tanpa database sungguhan.

Hasil validasi:

```text
flutter analyze: No issues found!
flutter test: 7 tests passed
```

---

# Tugas, refleksi, dan referensi

## Tugas

1. Menerapkan penyimpanan preferensi aplikasi menggunakan `SharedPreferences` untuk tema gelap dan waktu terakhir aplikasi dibuka.
2. Membuat fitur catatan lokal menggunakan `SQLite` dengan skema tabel `notes` dan status `dirty` untuk mendukung perubahan yang belum tersinkron.
3. Mendesain arsitektur data berbasis repository agar logika CRUD, status pending sync, dan pengelolaan cache tidak tercampur dengan UI.
4. Mengintegrasikan Riverpod untuk state management agar halaman catatan dan settings tetap responsif, mudah diuji, dan mudah dirawat.
5. Menyelesaikan Praktikum 1, 2, dan 3 serta menulis dokumentasi AI Challenge, refactoring, dan validasi testing.

Seluruh hasil implementasi dan dokumentasi teknis telah dipadukan dalam proyek ini, mulai dari preferensi pengguna, penyimpanan nota lokal, sampai mekanisme offline-first.
