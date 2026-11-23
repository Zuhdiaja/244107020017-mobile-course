# Rencana Pengujian — Minggu 12



---

## 1. Prinsip yang dipakai

test:

1. **Uji perilaku, bukan baris kode.** Test yang ditulis harus gagal bila
   perilaku pengguna rusak. Menambah test yang hanya "menjalankan kode" tanpa
   memeriksa hasil tidak dipakai untuk menaikkan angka cakupan.
2. **Uji pemeriksaan harus bisa gagal.** Setiap klaim diverifikasi dengan
   mutasi kecil: aturan dirusak sementara, test harus merah, lalu dipulihkan.
3. **Rancang agar mudah diuji.** Logika bisnis tidak boleh menempel di widget.
   Bila sebuah aturan sulit diuji, itu tanda aturannya salah tempat.

---

## 2. Pembagian jenis pengujian

| Jenis | Jumlah berkas | Yang diperiksa | Contoh di repo ini |
| --- | --- | --- | --- |
| Unit | 9 | Fungsi/kelas murni tanpa merender UI | `SearchAnnouncements`, `Login`, `isValidEmail`, mapping model |
| Widget | 7 | Tampilan dan interaksi satu halaman | Validator form login, empty state, loading, error |
| Integrasi | 1 | Alur utuh lintas layer + router | Login -> beranda -> cari -> detail |

Alasan pembagiannya: unit test paling murah dan paling cepat memberi umpan
balik, jadi aturan bisnis ditaruh di sana. Widget test dipakai untuk hal yang
hanya muncul setelah UI dirender (pesan validasi, spinner, empty state).
Integration test hanya satu, karena biayanya (build + device) jauh lebih besar
dan nilainya ada pada **rangkaian**, bukan pada satu layar.

---

## 3. Skenario wajib: sukses, kasus tepi, kegagalan

 Berikut pemetaannya pada fitur nyata aplikasi.

### 3.1 Login (fitur `auth`)

| Skenario | Jenis | Test |
| --- | --- | --- |
| Sukses: email + sandi valid -> sesi dibuat | Unit + Widget | `login_usecase_test.dart`, `login_page_test.dart` |
| Kasus tepi: spasi di awal/akhir email, sandi tepat 6 karakter | Unit + Widget | idem |
| Kasus tepi: `"@"` saja, domain tanpa titik, dua `@` | Unit | `validators_test.dart` |
| Kegagalan: kredensial ditolak repository | Unit + Widget | idem |
| Kegagalan: jaringan mati saat login | Unit | `login_usecase_test.dart` |

### 3.2 Pencarian pengumuman (fitur `announcements`)

| Skenario | Jenis | Test |
| --- | --- | --- |
| Sukses: query "ujian" menyaring daftar | Unit + Widget | `search_announcements_test.dart`, `announcements_page_test.dart` |
| Kasus tepi: huruf besar/kecil, spasi berlebih, daftar kosong | Unit | idem |
| Kasus tepi: query tidak cocok -> empty state | Widget | idem |
| Kegagalan: repository melempar -> "Gagal memuat pengumuman" | Widget | idem |
| Kegagalan: data belum siap -> indikator loading | Widget | idem |

### 3.3 Asisten AI (fitur `assistant`)

| Skenario | Jenis | Test |
| --- | --- | --- |
| Sukses: pertanyaan dikirim, jawaban tampil | Unit + Widget | `ask_assistant_test.dart`, `assistant_page_test.dart` |
| Kasus tepi: pertanyaan tepat 500 karakter | Unit | idem |
| Kasus tepi: konteks dibatasi 5 baris | Unit | idem |
| Kegagalan: kuota habis / API key belum diatur | Unit + Widget | idem |
| Kegagalan: API key kosong di halaman pengaturan | Widget | `api_key_page_test.dart` |

### 3.4 Alur utama (integrasi)

Satu test: guard login -> login -> beranda -> daftar pengumuman -> cari
"ujian" (melewati debounce 250 ms) -> buka detail lewat rute.

---

## 4. Cara dependensi dipalsukan

| Dependensi asli | Pengganti di test | Alasan |
| --- | --- | --- |
| `flutter_secure_storage` (token, API key) | kelas fake di memori | plugin platform tidak tersedia di test; isi storage tidak boleh bocor antar test |
| Firebase Auth / `AuthRepositoryImpl` | `_FakeAuthRepository` | tidak butuh jaringan; kegagalan bisa dipicu tepat saat dibutuhkan |
| Gemini API (`Dio`) | `_FakeClient` | jawaban dan error (429/401) harus bisa ditentukan test |
| Firebase Messaging | `fcmTokenProvider` dioverride | FCM tidak jalan di test; beranda hanya butuh nilai token |
| Waktu | `tester.pump(duration)` | debounce 250 ms diuji tanpa benar-benar menunggu |

Yang **tidak** dipalsukan: repository pengumuman, seluruh use case, provider,
dan widget. Kalau bagian-bagian ini dipalsukan juga, integration test berhenti
menjadi integration test.

---

## 5. Perubahan kode yang dilakukan agar bisa diuji

Bagian ini penting: pengujian yang baik sering menuntut kode dirapikan lebih
dulu, bukan test-nya yang dipaksa.

1. **`lib/app.dart` diekstrak dari `main.dart`.** `createRouter(container)` dan
   `CampusNotifyApp` menerima container dari luar. Tanpa ini, integration test
   harus memanggil `main()` yang menyalakan Firebase dan secure storage.
2. **`core/validators.dart` sebagai satu sumber aturan.** Sebelumnya `Login`
   (domain) dan validator `LoginPage` sama-sama hanya memakai `contains('@')`.
   Saat menulis test kasus tepi, keduanya ditemukan meloloskan `"@"` dan
   `"budi@localhost"`. Aturan sekarang dipusatkan dan diuji sekali.
3. **`AnnouncementPage` diuji lewat rute nyata.** Test navigasi memakai
   `GoRouter` betulan, bukan memanggil `context.go` secara tiruan.

---

## 6. Batas cakupan yang disengaja

Tidak diuji, dengan alasan:

| Bagian | Alasan |
| --- | --- |
| `push_service.dart` (FCM, notifikasi lokal) | butuh Firebase asli dan izin OS; tidak bisa dijalankan di `flutter test` |
| `GeminiApiClientDio` (HTTP asli) | butuh jaringan + API key; yang diuji adalah pemetaan error di repository |
| `TokenStore` / `ApiKeyStore` asli | plugin platform; kontraknya sudah diuji lewat fake |
| `main.dart` (bootstrap) | berisi orkestrasi Firebase; isinya dicek manual saat `flutter run` |
| Tampilan/estetika | bukan perilaku; tidak ada klaim yang bisa dibuat dari test |
