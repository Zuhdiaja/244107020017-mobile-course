# Week 5: Local Storage & Offline First

## Identitas

| Keterangan | Detail |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Kelas | TI-3H |

# Praktikum 1 SharedPreferences

## Hasil Praktikum

1. light mode<br>
![alt text](screanshoot/prak1light.png)<br>
2. dark mode<br>
![alt text](screanshoot/prak1.png)<br>
Halaman Settings menampilkan toggle Mode Gelap dan waktu terakhir aplikasi dibuka.

# Praktikum 2 SQLite dan Repository Catatan

## Hasil Praktikum

1. kondisi awal masih kosong<br>
![alt text](<screanshoot/prak2 kosongan.png>)<br>
2. menambahkan catatan, catatan akan muncul setelah mengisi<br>
![alt text](<screanshoot/prak2 tambah catatan.png>)<br>
3. setelah simpan, catatan tersimpan di halaman notes<br>
![alt text](<screanshoot/prak 2 hasil.png>)<br>

Halaman di atas menampilkan hasil Praktikum 2 berupa aplikasi catatan offline dengan penyimpanan SQLite.

# Praktikum 3 Cache-first dan Antrean Sync

## Hasil Praktikum
1. Catatan tersimpan secara lokal dan masih menunggu sinkronisasi. Ikon `cloud_off` menunjukkan catatan berstatus `dirty`, sedangkan banner menunjukkan jumlah antrean sync.
![alt text](<screanshoot/prak3 sebelum tersimpan sync.png>)<br>
2. Setelah tombol **SYNC** ditekan, antrean diproses dan status catatan berubah menjadi tersinkron. Ikon berubah menjadi `cloud_done` dan banner antrean hilang.
![alt text](<screanshoot/prak3 setelah di sync.png>)

Alur cache-first membaca catatan dari SQLite lokal terlebih dahulu, sehingga data tetap dapat ditampilkan secara offline. Perubahan baru diberi status `dirty` dan dimasukkan ke antrean, kemudian tombol **SYNC** memproses antrean tersebut.

# AI Challenge

## Hasil AI
Dokumentasi prompt AI, perbandingan SharedPreferences/Hive/sqflite/Drift, keputusan teknis, AI Verification Checklist, aturan konflik, dan hasil testing tersedia di [docs/ai-challenge.md](docs/ai-challenge.md).

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

#Tugas, refleksi, dan referensi