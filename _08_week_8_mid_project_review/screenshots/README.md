# Screenshots

Folder ini menampung bukti visual Minggu 8. Nama file mengikuti pola
`week8-*.png` supaya mudah dirujuk dari README.

| File | Isi | Status |
| --- | --- | --- |
| [#1](https://github.com/Zuhdiaja/244107020017-mobile-course/issues/1) (`week8-issue-closed.png`) | Halaman issue #1 setelah ditutup PR #2 (`closed as completed`) | belum ada |
| `week8-pr2-approved-merged.png` | PR #2: badge Merged, reviewer `oninonins` ✓, Development link ke issue #1, `Closes #1` | ✅ |
| `week8-ci-green.png` | Actions run Success, job `analyze + format + test` hijau (1m 57s) | ✅ |
| `week8-analyze-format-test.png` | Terminal: analyze bersih, format 0 changed, 28 test lulus | ✅ |
| `week8-login-validasi.png` | Layar login dengan pesan "Email wajib diisi" | opsional (widget test menguji hal yang sama) |

Cara mengambil screenshot yang masih kosong:

**Issue #1** — buka
[issue #1](https://github.com/Zuhdiaja/244107020017-mobile-course/issues/1),
pastikan badge Closed dan tulisan `closed this as completed in #2` terlihat,
lalu simpan sebagai `week8-issue-closed.png`.

**Layar login** — hanya dengan perangkat/emulator yang punya
`google-services.json`. Kalau tidak ada, biarkan kosong; bukti
penggantinya ada di widget test `test/login_page_test.dart`
yang menguji pesan validasi yang sama tanpa perangkat.
