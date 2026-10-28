# Screenshot Minggu 9 - uji manual 3 kondisi query

Screenshot diambil dari aplikasi yang berjalan (device/emulator
Android) setelah login, masuk ke kartu **Pengumuman** di Beranda.
Letakkan tiga file berikut di folder ini:

| File | Kondisi | Isi yang terlihat |
| --- | --- | --- |
| `week9-search-empty-query.png` | query kosong | semua pengumuman tampil |
| `week9-search-match.png` | query `ujian` | hanya kartu "Ujian Akhir Semester Ganjil" |
| `week9-search-no-match.png` | query `zzz-tak-ada` | empty state "Tidak ada pengumuman yang cocok" |

Cara mengambil:

```bash
cd _07_week_7_clean_architecture
flutter run
# login -> Beranda -> kartu Pengumuman
# uji 3 query di atas, screenshot tiap kondisi
```

Tiga kondisi yang sama sudah dikunci sebagai widget test di
`test/announcements_page_test.dart`, sehingga perilakunya tidak bisa
regresi tanpa test merah.