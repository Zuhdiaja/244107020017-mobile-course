# Refactoring dan Testing

## Perubahan

- `PostTile` diekstrak ke `lib/widgets/post_tile.dart` dan dipakai oleh halaman list biasa serta pagination.
- `friendlyErrorMessage` dipindahkan ke `lib/data/network_errors.dart` agar bisa dipakai ulang oleh halaman paged, non-paged, komentar, dan detail.
- GoRouter ditambahkan dengan route berikut:
  - `/`: daftar post.
  - `/post/:id`: detail post lengkap.
  - `/paged`: daftar post dengan pagination.
  - `/comments`: hasil AI Challenge komentar.
- Detail post menggunakan data post dari list yang sudah tersedia; bila tidak tersedia, provider mengambil `/posts/{id}` melalui repository.

## Checklist Verifikasi

- UI tidak memanggil Dio langsung. Semua akses data melewati provider dan repository.
- Loading: provider menghasilkan `CircularProgressIndicator`.
- Error: provider menghasilkan pesan dari `friendlyErrorMessage` dan tombol `Coba lagi`.
- Empty: halaman list menampilkan `Belum ada data dari server.` dan halaman komentar menampilkan `Belum ada komentar.`.
- Success: data ditampilkan melalui `PostTile` atau list komentar.
- Pagination: listener memanggil halaman berikutnya saat mendekati akhir; `isLoadingMore` dan `hasMore` mencegah request ganda dan menampilkan indikator akhir.
- Test repository memakai `FakePostRepository`, `ProviderContainer.overrideWithValue`, dan tidak melakukan request HTTP.

## Validasi

```text
flutter analyze
No issues found!

flutter test
00:05 +6: All tests passed!
```
