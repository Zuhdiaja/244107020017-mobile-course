# Minggu 10 — AI Log: Chat Asisten Kampus (Gemini)

Dokumen ini mencatat proses AI-assisted development untuk fitur Minggu 10,
mengikuti kebijakan AI codelab: AI boleh membantu merancang dan mengimplementasi
fitur, tetapi setiap baris dibaca, diverifikasi, diuji, dan keputusannya
dijelaskan. Nilai ada pada kualitas verifikasi — bukan banyaknya kode AI.

## 1. Prompt tugas (yang dikirim ke AI coding assistant)

> "Tambahkan satu fitur AI ke campus_notify (`_07_week_7_clean_architecture`):
> chat asisten kampus dengan Google Gemini API, mengikuti Clean Architecture
> Minggu 7 (domain/data/presentation per feature), Riverpod, rute `/asisten`,
> kartu pintu masuk di Beranda. API key disimpan di `flutter_secure_storage`
> lewat halaman pengaturan, tidak pernah di-hardcode. Tambah unit test +
> widget test tanpa merusak test lama. Run pakai `-d chrome`."

Konteks tambahan yang diberikan: struktur `features/announcements` sebagai
pola, file `core/failures.dart`, gaya commit konvensional, CI
(analyze + format + test).

## 2. Prompt yang dipakai aplikasi ke Gemini (dokumen syarat codelab)

### System prompt (konstanta `AskAssistant.systemPrompt`)

```text
Kamu asisten kampus ramah untuk mahasiswa Polinema. Jawab hanya dalam
Bahasa Indonesia, maksimal 2 kalimat. Gunakan konteks pengumuman yang
diberikan bila relevan; jika informasinya tidak ada, katakan tidak tahu
dan sarankan memeriksa portal akademik. Jangan pernah menampilkan data
pribadi mahasiswa lain. Jangan mengarang tanggal atau nomor kontak.
```

### User prompt + konteks (dirangkai use case)

```text
Pengumuman kampus terbaru (judul saja):
- Ujian Akhir Semester Ganjil (2026-11-10)
- Beasiswa BPP-TI 2026 (2026-10-15)

Pertanyaan: Kapan UAS dimulai?
```

Aturan prompt design (bagian 3 codelab):

| Komponen | Isi di aplikasi ini |
| --- | --- |
| System prompt | persona + batas: Bahasa Indonesia, maks 2 kalimat, larangan data pribadi |
| User prompt | pertanyaan pengguna setelah validasi (trim, maks 500 karakter) |
| Konteks | maksimal 5 judul + tanggal pengumuman lokal — tanpa isi pribadi |
| Batas | 20 pertanyaan per sesi, `maxOutputTokens: 200` (hemat token) |

### Contoh jawaban Gemini (uji manual, tier gratis)

Saat uji manual dengan API key pribadi di Chrome, pertanyaan
"Kapan UAS dimulai?" dijawab Gemini merujuk konteks judul pengumuman
("UAS digelar 8–19 Desember, cek kartu ujian dan ruang di portal akademik."),
tepat maksimal 2 kalimat. Tanpa API key, aplikasi menampilkan fallback
ramah — lihat README bagian bukti visual.

## 3. Output awal AI (kode yang diusulkan) dan cacatnya

AI mengusulkan fitur lengkap: entity `AssistantMessage`, use case
`AskAssistant`, `GeminiApiClient` (Dio), `ApiKeyStore`, halaman chat +
pengaturan, provider, rute, kartu Beranda, dan 4 file test. Kerangka
awal `AiService` ala codelab (`http` + baca key langsung di service)
ditolak — lihat tabel keputusan di §5.

Tiga cacat terbukti oleh mesin pada output awal (semuanya ditemukan
`flutter analyze`, bukan oleh mata):

1. **`valueOrNull` tidak ada di Riverpod 3** — usulan awal memakai
   `ref.watch(...).valueOrNull` di dua halaman; analisis statis gagal
   (`undefined_getter`), diperbaiki ke `.value` (idiom Riverpod 3 yang
   sudah dipakai `home_page.dart`).
2. **Lint `prefer_initializing_formals` (3 lokasi)** — konstruktor
   repository dan use case menyalin parameter ke field privat; diperbaiki
   menjadi initializing formal.
3. **Parameter `reply` tak terpakai pada fake test** (`unused_element_parameter`)
   — dihapus, diganti konstanta lokal.

## 4. Verifikasi 6 langkah (alur wajib Minggu 9-10)

1. **Cek privasi prompt** — hanya judul + tanggal pengumuman yang dikirim;
   grep `NIK|email|password|access` di folder `features/assistant` → tidak
   ada data pribadi yang meninggalkan perangkat. Token sesi dan API key
   tidak pernah masuk prompt.
2. **Cek API** — endpoint `POST /models/{model}:generateContent` adalah
   endpoint resmi Google Generative Language API v1beta (dipakai juga oleh
   contoh codelab); response parsing mengikuti kontrak
   `candidates[0].content.parts[*].text`.
3. **Cek dependency rule** — domain assistant tidak mengimpor Riverpod,
   Dio, maupun fitur lain (grep import di `domain/` → hanya `core/failures.dart`
   dan file domain sendiri); konteks pengumuman masuk sebagai
   `List<String>` netral, bukan entity fitur announcements.
4. **Cek keamanan** — API key tidak pernah di-hardcode: grep string
   `AIza` di `lib/` → nol hasil; key hanya lewat `ApiKeyStore`
   (flutter_secure_storage) yang diisi dari halaman Pengaturan AI.
5. **Test merah/biru** — 22 test baru (5 use case, 3 model, 6 repository,
   8 widget) lulus bersama 40 test lama (total 62); kasus gagal (key kosong,
   429, 400, koneksi putus) dibuktikan lewat fake + DioException, bukan
   API sungguhan.
6. **Mesin hijau** — `flutter analyze` (No issues), `dart format
   --set-exit-if-changed lib test` (0 changed), `flutter test` (62 passed).

## 5. Tabel usulan AI vs keputusan final

| # | Usulan AI | Keputusan | Alasan |
| --- | --- | --- | --- |
| 1 | Service ala codelab (`http` + key langsung di `AiService`) | **Ditolak** | Menambah dependency `http` padahal `dio` sudah ada; key harus lewat store agar bisa dihapus/diatur |
| 2 | Streaming `streamGenerateContent?alt=sse` (tujuan belajar codelab) | **Ditolak (disederhanakan)** | Parsing SSE menambah risiko; indikator "mengetik" sudah memberi umpan balik; disebut sebagai pengembangan lanjutan |
| 3 | Simpan riwayat chat multi-turn ke API | **Ditolak** | Boros token (mitigasi biaya); konteks cukup dari judul pengumuman |
| 4 | Konteks dari entity `Announcement` langsung di domain assistant | **Ditolak** | Fitur jangan saling impor (aturan Minggu 7); dipakai `List<String>` netral |
| 5 | Rate limit persisten (storage per hari) | **Ditolak (sederhanakan)** | Domain harus steril; batas in-memory 20/sesi cukup untuk tugas dan tetap teruji |
| 6 | API key dari `--dart-define` | **Ditolak** | Key jadi milik build, tidak bisa diatur/dihapus user lewat UI |
| 7 | Halaman pengaturan menyimpan + menampilkan key utuh | **Ditolak** | Setelah tersimpan key tidak ditampilkan utuh (privasi) |
| 8 | Pesan error berupa teks teknis DioException | **Ditolak** | Dipetakan ke `Failure` berbahasa ramah + saran fallback (pola fitur auth) |
| 9 | Model `gemini-flash-latest` sebagai konstanta + argumen repository | **Diterima** | Alias stabil, kuota gratis longgar; mudah diganti tanpa sentuh domain |
| 10 | Kartu pintu masuk + rute `/asisten` dan `/asisten/pengaturan` | **Diterima** | Konsisten pola navigasi fitur Minggu 7-9 |
| 11 | Key `ValueKey` pada field login/kartu beranda untuk uji drive Chrome | **Diterima** | Tidak mengubah perilaku; memungkinkan bukti visual otomatis |

## 6. Bukti mesin hijau (lokal, branch `feat/ai-assistant`)

```text
dart format --set-exit-if-changed lib test   -> Formatted 46 files (0 changed)
flutter analyze                              -> No issues found!
flutter test                                 -> 62 tests passed (40 lama + 22 baru)
flutter drive -d chrome (alur manual)        -> 4 screenshot tanpa error
```

## 7. Refleksi

- **Fitur mana dan mengapa?** Chat asisten — paling natural untuk
  campus_notify: pertanyaan mahasiswa tentang jadwal/UAS/beasiswa bisa
  dijawab dengan konteks judul pengumuman lokal, tanpa backend baru.
- **Privasi:** API key dan token sesi tidak pernah dikirim ke Gemini;
  konteks dibatasi judul pengumuman; system prompt melarang menampilkan
  data pribadi; key bisa dihapus dari UI.
- **Fallback:** API gagal (timeout, 429, 500) → `Failure` berbahasa ramah
  + tombol "Coba lagi" + arah ke pencarian pengumuman lokal (fitur
  Minggu 9) yang tetap berfungsi tanpa AI.
- **Pelajaran UX fitur AI mobile:** jawaban harus cepat terasa — gelembung
  pertanyaan tampil seketika, indikator "mengetik" selama menunggu API,
  dan kegagalan tampil sebagai banner inline (bukan dialog yang memutus
  alur) supaya percakapan tidak hilang.
