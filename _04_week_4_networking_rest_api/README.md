# week4_Networking & REST API

Nama : Muhammad Zuhdi Yudadharma<br>
NIM  : 244107020017<br>
Kelas: TI-3H<br>

# Praktikum 1 Dio dan model data
1. kode post.dart<br>
![alt text](screanshoot/post.dart.png)<br>

2. kode api_client.dart<br>
![alt text](screanshoot/apiclient.png)<br>

3. kode post_repository.dart<br>
![alt text](screanshoot/postrepo.png)<br>

# Praktikum 2 Provider dan error handling
1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.<br>
![alt text](screanshoot/hasil.png)<br>

2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.<br>
![alt text](screanshoot/wifioff.png)<br>
setelah nyalakan internet lagi<br>
![alt text](screanshoot/hasil.png)<br>

3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.<br>
kode :![alt text](screanshoot/kodesalah.png) <br>
hasil : ![alt text](screanshoot/baseurlslh.png)<br>

# Praktikum 3 Pagination dasar
1. Tambahkan method PostRepository<br>
![<alt text>](screanshoot/tbahmethod.png)<br>

2. code paged_posts.dart<br>
![alt text](screanshoot/pagepost1.png)
![alt text](screanshoot/pagepost2.png)

3. hasil<br>
dari HP : ![alt text](screanshoot/p3hasil.png) <br>
dari chrome untuk tes page : ![alt text](screanshoot/p3hasil2.png)
![alt text](screanshoot/p3hasil3.png)

# AI Challenge
Implementasi repository komentar berada di:
- `lib/data/models/comment.dart`: model `Comment` dengan default aman untuk field null/hilang.
- `lib/data/repositories/comment_repository.dart`: `fetchComments(postId)` memakai `GET /comments?postId={id}`.
- `lib/data/comment_providers.dart`: `AsyncNotifierProvider.family` dengan propagasi exception menjadi `AsyncError`.

## AI Verification Checklist

- UI tidak memanggil Dio secara langsung. UI yang ada memakai provider, lalu provider memakai repository.
- `Comment.fromJson` memakai `as num?`/`as String?` dan fallback, sehingga field `postId`, `id`, `name`, `email`, dan `body` yang null atau hilang tidak menyebabkan crash.
- `friendlyErrorMessage` memetakan timeout, `connectionError`, `badResponse` 404, dan 500 ke pesan ramah pengguna.
- `baseUrl`, connect timeout, send timeout, dan receive timeout 10 detik terpusat di `lib/data/api_client.dart`.
- Test mencakup field yang hilang dan edge case konversi id numerik di `test/widget_test.dart`.
- Validasi terakhir: `flutter analyze` menghasilkan `No issues found!` dan `flutter test` menghasilkan `All tests passed!`.

- hasil AI Challenge : ![alt text](screanshoot/aic.png)<br>

