# Tinjauan Keamanan Pipeline - Minggu 13

## 1. Release ditandatangani debug keystore - risiko terbesar

`android/app/build.gradle.kts` masih berisi:

```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

Artinya APK/AAB yang dihasilkan pipeline **ditandatangani kunci debug yang
publik**. Konsekuensinya:

- Google Play **menolak** unggahan bertanda tangan debug;
- siapa pun yang memegang `~/.android/debug.keystore` standar dapat membuat
  pembaruan yang diterima sebagai "aplikasi yang sama" bila aplikasi dipasang
  manual (sideload);
- sidik jari sertifikat berbeda dari rencana rilis, sehingga API key Firebase
  yang dibatasi per SHA-1 akan menolak build ini.

Build saat ini tetap berguna untuk **uji internal** (bagian yang memang disebut
codelab: "APK praktis untuk instalasi dan uji internal"), tetapi tidak boleh
disebut siap rilis.

Perbaikan yang diperlukan:

1. buat keystore rilis, simpan sebagai base64 di GitHub Actions Secrets
   (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`);
2. `key.properties` dibaca `build.gradle.kts`, berkasnya **tidak** di-commit;
3. step dekode keystore hanya pada workflow rilis yang dibatasi (tag `v*`),
   tidak pada `pull_request`.

## 2. `google-services.json` di dalam repository

Berkas ini ter-commit sejak Minggu 6 (747 byte) dan berisi Firebase **API key
client** (`AIza...`), project ID, dan app ID.

Yang perlu dipahami: API key Firebase untuk Android **bukan** rahasia server -
ia memang tertanam di setiap APK. Yang membuatnya aman adalah pembatasan di
Google Cloud Console (batas per package name + SHA-1 sertifikat). Karena build
ini bertanda tangan debug, SHA-1 yang terdaftar harus mencakup debug keystore,
atau `Firebase.initializeApp()` akan gagal pada build rilis nanti.

Yang **tidak** boleh masuk repository: `service-account.json` (kunci admin
Firebase). Berkas itu sudah ada di `.gitignore` sejak Minggu 6 dan tidak
ditemukan di riwayat commit.

Tindakan lanjutan: batasi API key di Google Cloud, dan pertimbangkan
menyuntikkan `google-services.json` lewat secret saat rilis produksi.

## 3. Artefak dapat diunduh

Artefak `android-builds` dapat diunduh oleh siapa pun yang punya akses baca ke
repository. Repository ini publik, sehingga APK hasil setiap run **dapat diunduh
publik** selama masa retensi.

Diterima karena: (a) isinya build debug-signed dari kode yang juga publik;
(b) retensi dibatasi 7 hari. Yang tidak boleh terjadi: artefak bertanda tangan
produksi diunggah ke run publik. Karena itu signing rilis harus berada di
workflow terpisah yang hanya berjalan pada tag, dengan retensi lebih pendek.

## 4. Action pihak ketiga

| Action | Pin | Catatan |
| --- | --- | --- |
| `actions/checkout@v4` | tag mayor | resmi GitHub |
| `actions/setup-java@v4` | tag mayor | resmi GitHub |
| `subosito/flutter-action@v2` | tag mayor | **pihak ketiga** |
| `actions/upload-artifact@v4` | tag mayor | resmi GitHub |

Tag dapat dipindahkan oleh pemilik action. Praktik terkeras adalah memakai
commit SHA penuh. Kompromi yang diambil: tag mayor, karena SHA harus diperbarui
manual setiap rilis dan mudah terlupa - sebuah pipeline yang basi juga risiko.
Yang membatasi dampak: `permissions: contents: read` dan tidak ada secret di
job ini, sehingga action yang disusupi tidak mendapat token tulis atau
kredensial.

## 5. Belum ada pemindaian secret dan dependensi

Pipeline ini memeriksa format, analisis, dan test - **tidak** memeriksa:

- kebocoran secret di commit (`gitleaks`, GitHub secret scanning);
- kerentanan dependensi (`dart pub outdated`, Dependabot);
- lisensi paket.

Karena tidak ada secret di pipeline, kebocoran lewat log CI kecil
kemungkinannya. Namun `google-services.json` (butir 2) dan kunci yang mungkin
ditambahkan nanti tetap perlu pemindaian. Usulan: aktifkan Dependabot untuk
`pub` dan `gradle`, lalu tambahkan `gitleaks` sebagai step terpisah.

## 6. `--dart-define` bukan tempat rahasia

Codelab menegaskan: nilai `--dart-define` **dikompilasi ke dalam aplikasi** dan
dapat diekstrak dari APK. Karena itu:

| Boleh lewat `--dart-define` | Tidak boleh |
| --- | --- |
| URL API, nama environment, flag fitur | API key Gemini, token, password, kunci signing |

Di aplikasi ini, API key asisten AI disimpan pengguna lewat halaman **API key**
(`flutter_secure_storage`), bukan ditanam saat build. Itu pilihan yang benar:
kunci milik pengguna tidak ikut terdistribusi bersama APK.

## 7. Pull request dari fork

`pull_request` dari fork menjalankan kode yang belum ditinjau di runner GitHub.
Karena workflow ini tidak memakai secret dan hanya punya `contents: read`, PR
dari fork tidak dapat mencuri kredensial atau menulis ke repository. Yang tetap
mungkin: menghabiskan menit runner. Bila itu menjadi masalah, tambahkan
persetujuan manual untuk run dari fork.

## Yang sudah benar dan sebaiknya dipertahankan

- `permissions: contents: read` - bukan `write-all`, bukan default.
- Tidak ada secret di job ini, sehingga PR dari fork aman dijalankan.
- `service-account.json` di `.gitignore`.
- Kunci API asisten disimpan di secure storage per pengguna, tidak di-build.
- `if-no-files-found: error` - run tidak bisa "hijau" tanpa artefak.
