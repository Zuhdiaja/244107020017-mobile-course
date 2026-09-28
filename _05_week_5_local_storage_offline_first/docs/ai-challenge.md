# AI Challenge: Storage dan Offline-first

## Prompt yang digunakan

> Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
> Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini.
> Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing.
> Beri rekomendasi final: mana untuk preferensi, mana untuk catatan, beserta alasannya dalam 1 tabel.
> Tunjukkan skema tabel/kotak untuk 1000+ catatan. Jelaskan trade-off setiap pilihan.

## Ringkasan output awal AI

| Kebutuhan | Rekomendasi awal | Alasan |
| --- | --- | --- |
| Preferensi tema dan waktu terakhir dibuka | SharedPreferences | Key-value sederhana, API kecil, dan cukup untuk beberapa nilai scalar. |
| Catatan offline | SQLite melalui repository | Mendukung query, pengurutan `updated_at`, relasi jika bertambah, dan transaksi. |
| Alternatif | Hive atau Drift | Hive lebih sederhana untuk object store; Drift lebih type-safe dan reaktif tetapi lebih berat. |

Output awal AI juga menyarankan dirty flag untuk perubahan lokal dan `updated_at` untuk menentukan urutan serta membantu resolusi konflik.

## Perbandingan storage

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
| --- | --- | --- | --- | --- |
| Kompleksitas query | Sangat terbatas | Query object sederhana | SQL lengkap dan matang | SQL melalui API type-safe |
| Relasi | Tidak sesuai | Tidak natural | Foreign key dan join | Relasi dengan dukungan tipe |
| Reaktivitas | Tidak ada stream bawaan | Watch box tersedia | Perlu dikelola aplikasi | Stream/watch query bawaan |
| Type-safety | Tipe scalar dasar | Perlu adapter/model | Map dan skema SQL | Tinggi, kode hasil generate |
| Boilerplate | Paling kecil | Kecil sampai sedang | Sedang | Besar pada awal setup |
| Kemudahan testing | Mudah dengan wrapper | Mudah dengan box test | Mudah melalui repository palsu | Baik, tetapi setup lebih besar |
| Cocok untuk 1000+ catatan | Tidak | Bisa, dengan batas query object | Ya | Ya |

## Keputusan final

- **SharedPreferences** dipakai untuk `dark_mode` dan `last_opened_at` karena datanya scalar dan tidak membutuhkan query.
- **SQLite/sqflite** dipakai untuk catatan karena mendukung CRUD, pengurutan terbaru, kolom `dirty`, dan skema yang dapat diperluas.
- Akses SQLite diletakkan di `NoteRepository`, bukan langsung di widget, agar provider dan test dapat memakai repository palsu.
- Cache-first membaca daftar catatan dari SQLite terlebih dahulu. Aplikasi tetap dapat menampilkan data tanpa koneksi.

### Skema untuk 1000+ catatan

```text
notes
├── id          INTEGER PRIMARY KEY AUTOINCREMENT
├── title       TEXT NOT NULL
├── body        TEXT NOT NULL DEFAULT ''
├── updated_at  TEXT NOT NULL
└── dirty       INTEGER NOT NULL DEFAULT 0
```

Query daftar menggunakan `ORDER BY updated_at DESC`. Untuk skala lebih besar, indeks pada `updated_at` dan pagination dapat ditambahkan.

## AI Verification Checklist

| Pemeriksaan | Hasil verifikasi |
| --- | --- |
| Apakah daftar catatan ditempatkan di SharedPreferences? | Tidak. SharedPreferences hanya menyimpan preferensi scalar; daftar catatan ada di SQLite. |
| Apakah skema mendukung antrean sync? | Ya. Tabel `notes` memiliki `dirty` dan `updated_at`; `NoteRepository` memiliki `countDirty` dan `syncPending`. |
| Apakah klaim real-time didukung stream? | Tidak diklaim real-time. UI memakai Riverpod `AsyncNotifier` dan refresh eksplisit. |
| Apakah boilerplate masuk akal setelah dicoba? | Ya. Dependensi `shared_preferences`, `sqflite`, dan `path` terpasang; build APK berhasil. |
| Apakah cache-first dapat diuji offline? | Ya. Daftar dibaca dari SQLite lokal dan tetap dapat ditampilkan tanpa API. |
| Apakah state UI lengkap? | Ya. Ada loading, error, empty, dan success pada `NotesPage`. |
| Apakah test repository palsu tersedia? | Ya. `notes_provider_test.dart` memakai `FakeNoteRepository` tanpa database sungguhan. |

## Bukti testing

- `note_model_test.dart`: menguji konversi `Note` ke map SQLite dan sebaliknya.
- `notes_provider_test.dart`: menguji loading dan penambahan catatan melalui repository palsu.
- Perintah validasi:

```bash
flutter test
flutter analyze
flutter build apk
```
