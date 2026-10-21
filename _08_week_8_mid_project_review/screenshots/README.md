# Screenshots

Folder ini menampung bukti visual Minggu 8. Nama file mengikuti pola
`week8-*.png` supaya mudah dirujuk dari README.

| File | Isi | Status |
| --- | --- | --- |
| `week8-issue-1.png` | Halaman issue #1 setelah ditutup PR #2 (`closed as completed`) | belum ada |
| `week8-pr-2-review.png` | PR #2 dengan review `oninonins` berstatus APPROVED | belum ada |
| `week8-pr-2-merged.png` | PR #2 setelah squash merge `26f4e1f` | belum ada |
| `week8-ci-green.png` | Tab Actions dengan workflow `ci` hijau | belum ada |
| `week8-analyze-format-test.png` | Terminal: analyze bersih, format 0 changed, 28 test lulus | belum ada |
| `week8-login-validasi.png` | Layar login dengan pesan "Email wajib diisi" | belum ada |

Cara mengambil yang berbasis terminal (PowerShell):

```powershell
cd _07_week_7_clean_architecture
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

Screenshot layar login hanya bisa diambil dengan menjalankan aplikasi di
perangkat/emulator yang punya `google-services.json`. Kalau belum tersedia,
bukti pengganti ada di widget test `test/login_page_test.dart` yang menguji
pesan validasi yang sama tanpa perangkat.
