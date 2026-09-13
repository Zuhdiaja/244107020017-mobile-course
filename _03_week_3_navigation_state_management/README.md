# week3_navigation

Nama : Muhammad Zuhdi Yudadharma<br>
NIM  : 244107020017<br>
Kelas: TI-3H<br>

1. Hasil Aplikasi multi-page dengan GoRouter<br>
![alt text](screanshoot/hasil1.png)

2. Hasil Aplikasi ToDo dengan Riverpod dan crud nya<br>
![alt text](screanshoot/hasil2.png)
![alt text](screanshoot/hasil2.1.png)
![alt text](screanshoot/hasil2.2.png)

3. Hasil AsyncValue: loading, error, success, Uji ketiga state<br>
   - Salin kode di atas ke project ToDo Anda (atau project terpisah) dan jalankan : ![alt text](screanshoot/loading.png)<br>
   - Ubah build() : throw Exception('Gagal terhubung ke server'); : ![alt text](screanshoot/eror.png)<br>
   - Pulihkan kode, pastikan state success tampil : ![alt text](screanshoot/succes.png)<br>
   - refleksi : Stale data lebih baik karena pengguna tetap dapat melihat data sebelumnya saat proses refresh berlangsung, sehingga aplikasi terasa lebih responsif dan tidak membingungkan. Pola ini penting pada aplikasi yang sering melakukan pembaruan data seperti berita, e-commerce, dashboard, dan media sosial.

4.  AI Challenge<br>
AI yang digunakan Chat GPT berikut untuk hasil promp nya<br>
- stats_page.dart<br>
![alt text](screanshoot/statspage1.png)![alt text](screanshoot/statspage2.png)<br>
- stats_provide.dart<br>
![alt text](screanshoot/statsprovider.png)<br>
- stats_provider_test<br>
![alt text](screanshoot/providertest.png)<br>
- widget_test.dart<br>
![alt text](screanshoot/widgettest.png)
- main.dart<br>
![alt text](screanshoot/main.png)<br>
- hasil tampilan<br>
![alt text](screanshoot/hasilAI.png)<br>
-hasil testing<br>
![alt text](screanshoot/testingAI.png)

## AI Verification Checklist

| No. | Pemeriksaan | Hasil | Temuan / Penjelasan |
|---|---|---|---|
| 1 | State diubah secara immutable | LULUS | State tidak dimutasi secara langsung. Tidak terdapat `state.add()`, `state.remove()`, atau mutasi list secara langsung. Perubahan state menggunakan assignment seperti `state = const AsyncLoading()` dan hasil `AsyncValue.guard()`. |
| 2 | `ref.watch` hanya di `build` dan `ref.read` di callback | LULUS | `ref.watch(statsProvider)` digunakan di dalam `build()` untuk mengamati perubahan state. `ref.read(statsProvider.notifier).retry()` digunakan pada callback tombol Retry. |
| 3 | Ketiga state `AsyncValue` ditangani | LULUS | `statsAsync.when()` menangani tiga kondisi: `loading` dengan `CircularProgressIndicator`, `error` dengan pesan error dan tombol Retry, serta `data` dengan `ListView` berisi data statistik. |
| 4 | Provider eksplisit dan tidak duplikat | LULUS | Provider dideklarasikan secara eksplisit sebagai `AsyncNotifierProvider<StatsNotifier, List<String>>` dengan nama `statsProvider`. Hanya terdapat satu provider untuk data statistik. |
| 5 | Tidak menggunakan API Riverpod lama | LULUS | Implementasi menggunakan `AsyncNotifier`, `AsyncNotifierProvider`, dan `ConsumerWidget`. Tidak menggunakan `StateProvider` atau `StateNotifierProvider` lama. |
| 6 | `flutter analyze` dan `flutter test` | LULUS SETELAH PERBAIKAN | `flutter analyze` telah diperbaiki dari warning `avoid_relative_lib_imports` dengan menggunakan package import. `flutter test` sebelumnya mengalami error timer pending karena test tidak menunggu delay asynchronous 2 detik. Test kemudian diperbaiki agar menunggu proses asynchronous selesai. |

5. Refactoring dan Testing
- todo_tile.dart<br>
![alt text](screanshoot/tile.png)<br>
- ubah todo_provider.dart<br>
![alt text](<screanshoot/provider refactor.png>)<br>
- Refactor TodoPage<br>
![alt text](<screanshoot/todopage rafactor1.png>)
![alt text](<screanshoot/todopage refactor2.png>)<br>
- Integrasi GoRouter<br>
![alt text](screanshoot/gorouter1.png)
![<alt text>](screanshoot/gorouter2.png)<br>
- dokumentasi docs/ai_verification.md<br>
[text](week3_todo/doc/ai_verification.md)<br>
- Jalankan verifikasi<br>
![alt text](screanshoot/verif4.png)<br>
- Hasil<br>
![alt text](<screanshoot/hasil refactor.png>)
![alt text](<screanshoot/hasil refactor 2.png>)

## Refleksi
1. Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?<br>
setState cukup untuk state sederhana dalam satu widget. Riverpod lebih cocok jika state digunakan banyak widget/halaman atau memiliki logika yang kompleks.
2. Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?<br>
context.go untuk berpindah langsung ke route tertentu, context.push untuk membuka halaman baru dan tetap menyimpan halaman sebelumnya di stack.
3. Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?<br>
AsyncValue mengatur kondisi loading, data, dan error di state jadi lebih aman dan mengurangi state yang salah.
4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?<br>
memperbaiki struktur kode, memisahkan TodoTile, membuat derived provider, memperbaiki retry() pada StatsNotifier, dan membuat testing mudah dites.