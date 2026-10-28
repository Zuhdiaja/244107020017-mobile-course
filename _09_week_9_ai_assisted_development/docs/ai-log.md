# AI Log - Minggu 9: AI-Assisted Development

Laporan lengkap siklus *prompt → generate → verify → test → refactor →
explain* untuk satu fitur kecil: **pencarian judul pengumuman + empty
state** pada aplikasi `_07_week_7_clean_architecture` (campus_notify).

AI berperan sebagai generator dan reviewer awal. Setiap baris hasil AI
dibaca, diverifikasi, diuji, dan di-refactor sebelum diterima. Keputusan
final beserta alasannya tercatat di dokumen ini dan bisa dijelaskan tanpa
membuka AI.

## 0. Identitas dan ringkasan

| | |
| --- | --- |
| Nama | Muhammad Zuhdi Yudadharma |
| NIM | 244107020017 |
| Project | `_07_week_7_clean_architecture` (campus_notify) |
| Branch | `feat/announcements-search` dari `develop` |
| Fitur | Halaman daftar pengumuman + search judul + empty state |
| AI yang dipakai | AI coding assistant (asisten sesi OpenCode) |
| Hasil akhir | `flutter analyze` bersih, `dart format` 0 changed, 40 test hijau |

Ringkasan temuan terhadap output AI:

| Temuan | Pola halusinasi (materi) | Bukti |
| --- | --- | --- |
| Endpoint `GET /announcements` tidak ada | API fiktif | grep seluruh `lib/` |
| Filter case-sensitive | Logika yakin tapi salah | test merah (3 kasus gagal) |
| Filter di widget + riverpod di domain | Pelanggaran dependency rule | grep import |

## 1. Prompt (formula 5 slot, mentah)

```text
Peran   : senior Flutter dev
Konteks : campus_notify (week7_clean_architecture), feature-first
          presentation -> domain <- data, Riverpod 3.4.3, GoRouter, Dio.
          Fitur announcements baru punya halaman deep link /pengumuman/:id,
          belum ada daftar pengumuman. Backend example-campus-api.test
          hanya dipakai untuk auth + POST /devices.
Tugas   : tambah halaman daftar pengumuman + search judul + empty state.
Batas   : jangan ubah arsitektur (domain bebas import Flutter/Dio),
          jangan tambah package baru, maks 80 baris per file.
Output  : kode Dart + 3 test case + cara uji manual.
```

Konteks yang ditempel bersama prompt (potongan, bukan seluruh repo):

- struktur `lib/features/auth/` sebagai contoh pola layer yang sudah
  berjalan;
- isi `domain/usecases/login.dart` dan `domain/repositories/auth_repository.dart`
  sebagai file kontrak;
- versi package dari `pubspec.yaml`: `flutter_riverpod 3.4.3`,
  `go_router 18.0.2`, `dio 5.11.1`.

Konteks yang TIDAK ditempel: token FCM, JWT, isi `google-services.json`,
`service-account.json`, dan kredensial apa pun. Tidak ada rahasia yang
dikirim ke AI - semua contoh berupa struktur dan kode non-rahasia.

## 2. Output awal AI (mentah, sebelum diverifikasi)

Potongan penting dari usulan pertama AI - **belum satu baris pun
diterima apa adanya**:

```dart
// (1) Usulan repository — AI mengusulkan remote source:
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final Dio dio;
  AnnouncementRepositoryImpl(this.dio);

  Future<({List<Announcement> announcements, Failure? failure})>
      fetchAll() async {
    final res = await dio.get('/announcements'); // <-- klaim AI
    final list = (res.data as List)
        .map((json) => AnnouncementModel.fromJson(json))
        .toList();
    return (announcements: list, failure: null);
  }
}

// (2) Usulan use case — AI mengimpor Riverpod ke domain:
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- domain

class SearchAnnouncements {
  List<Announcement> call(List<Announcement> announcements, String query) {
    return announcements
        .where((a) => a.title.contains(query)) // <-- case-sensitive
        .toList();
  }
}

// (3) Usulan UI — filter langsung di build method:
Widget build(BuildContext context, WidgetRef ref) {
  final all = ref.watch(announcementsProvider).value ?? [];
  final query = ref.watch(searchQueryProvider);
  final results = query.isEmpty
      ? all
      : all.where((a) => a.title.contains(query)).toList(); // <-- di widget
  ...
}
```

Tiga masalah ditandai saat dibaca baris per baris, sebelum dijalankan
mesin apa pun:

1. `dio.get('/announcements')` - tidak ada kontrak endpoint seperti itu
   di proyek ini (dugaan API fiktif).
2. `title.contains(query)` - `String.contains` membedakan huruf
   besar/kecil; dugaan bug pencarian.
3. Filter di `build` + import `flutter_riverpod` di file domain - dua
   pelanggaran dependency rule sekaligus.

## 3. Verifikasi (6 langkah)

### 3.1 Baca tiap baris

Usulan AI dibaca lengkap; tiga bagian di atas ditandai sebagai belum
dipercaya. Sisanya (struktur entity, model mapping, empty state) masuk
kandidat "terima dengan refactor ringan".

### 3.2 Cek import - domain harus steril

Grep terhadap `lib/features/announcements/domain` setelah refactor:

```text
pattern : import 'package:(flutter|dio|flutter_riverpod)/
hasil   : No matches found
```

Domain `announcements` terbukti bebas import Flutter, Dio, maupun
Riverpod - sama seperti `auth` dan `core`.

### 3.3 Cek API - klaim `GET /announcements` dibuktikan tidak ada

Grep seluruh `lib/` terhadap pemakaian Dio dan path endpoint:

```text
pattern : dio\.(get|post|put|delete)|baseUrl|/devices|/announcements
hasil   : hanya 1 pemanggilan Dio nyata: dio.post('/devices') di main.dart
          baseUrl: 'https://example-campus-api.test'   (domain placeholder)
          '/announcements' hanya muncul di komentar dokumentasi
          repository lokal (catatan penolakan usulan AI)
```

Bukti tambahan: `AuthRepositoryImpl._signInRequest` pun masih mock yang
mengembalikan `Map` (komentarnya sendiri menyebut "GANTI dengan ...
saat backend siap"). Backend pengumuman **belum ada**, jadi usulan AI
memanggil endpoint yang tidak dimiliki siapa pun. Status: halusinasi
API, ditolak.

### 3.4 `flutter analyze`

Setelah refactor, analyze bersih (bukti lengkap di §7).

### 3.5 Test merah - bukti bug case-sensitive

Test "filter abaikan huruf besar/kecil" dijalankan **terhadap logika
versi awal AI** persis (`a.title.contains(trimmed)`). Hasil nyata:

```text
$ flutter test test/search_announcements_test.dart
00:00 +0 -1: filter abaikan huruf besar/kecil [E]
  Expected: an object with length of <1>
    Actual: []  Which: has length of <0>
00:00 +3 -2: query dipangkas spasi sebelum dicocokkan [E]
  Expected: an object with length of <1>
    Actual: []
00:00 +3 -3: kecocokan di tengah judul ditemukan [E]
  Expected: an object with length of <1>
    Actual: []
Failing tests: 3
```

Bug terbukti: query `'ujian'` gagal menemukan judul `'Ujian Akhir
Semester Ganjil'`. Perbaikan: kedua sisi dinormalkan ke huruf kecil
sebelum `contains`. Setelah perbaikan, 7/7 unit test hijau.

### 3.6 Uji manual 3 kondisi query

| Kondisi | Query | Hasil yang diharapkan | Screenshot |
| --- | --- | --- | --- |
| Kosong | — | seluruh 5 pengumuman tampil | `screenshots/week9-search-empty-query.png` |
| Cocok | `ujian` | 1 kartu "Ujian Akhir Semester Ganjil" | `screenshots/week9-search-match.png` |
| Tak cocok | `zzz-tak-ada` | empty state "Tidak ada pengumuman yang cocok" | `screenshots/week9-search-no-match.png` |

Ketiganya juga dikunci sebagai widget test (§3.5 dan §6), sehingga
perilaku tidak bisa regresi tanpa test merah.

Catatan pelaksanaan: screenshot diambil dari build web
(`flutter run -d chrome`) karena sesi emulator tidak stabil di mesin
uji. Fitur pencarian sendiri tidak menyentuh Firebase sama sekali
(use case murni + repository lokal), jadi perilaku di web identik
dengan Android; init Firebase/FCM di `main()` dijaga `kIsWeb` sehingga
perilaku Android tidak berubah.

## 4. Debug dengan test merah (langkah reproduksi)

1. **Reproduksi**: buka halaman pengumuman, ketik `ujian` (huruf kecil)
   — daftar kosong padahal ada judul diawali huruf kapital.
2. **Isolasi**: logika filter dipindah dari widget ke use case murni
   (`SearchAnnouncements.call`) sehingga bisa diuji tanpa UI.
3. **Test merah**: `search_announcements_test.dart` — 3 kasus gagal
   pada kode versi AI (bukti di §3.5).
4. **Perbaikan kecil**: `final lowered = trimmed.toLowerCase();` dan
   `a.title.toLowerCase().contains(lowered)`.
5. **Akar masalah**: AI menganggap `String.contains` case-insensitive
   (klaim yakin tapi salah); dicatat di dokumen ini.

## 5. Refactor ke layer yang benar

Pemisahan akhir hasil AI:

```text
announcements_page (UI saja — TextField, kartu, empty state)
  -> SearchQueryNotifier / filteredAnnouncementsProvider (state saja)
     -> SearchAnnouncements (aturan filter, domain murni)
        -> AnnouncementRepository (kontrak, domain)
           -> AnnouncementRepositoryImpl (data lokal, mapping di model)
```

- Fungsi terbesar: `AnnouncementsPage.build` ± 60 baris (memuat tiga
  widget turunan `_Message` dan `_AnnouncementCard`); tidak ada fungsi
  > 40 baris yang memegang logika.
- Tidak ada panggilan data source dari widget — widget hanya membaca
  `filteredAnnouncementsProvider`.
- Mapping JSON hanya hidup di `AnnouncementModel` (pola
  `AuthSessionModel`), entity tetap murni.

## 6. AI Prompt Challenge — AI sebagai reviewer

Prompt review yang dikirim setelah fitur jadi:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation -> domain <- data),
Riverpod, GoRouter, sumber data lokal (backend belum ada).
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

Temuan dan hasil verifikasi:

| # | Temuan AI | Level | Verifikasi | Keputusan |
| --- | --- | --- | --- | --- |
| 1 | State "belum ada pengumuman sama sekali" (daftar kosong + query kosong) belum punya test | saran | grep `'Belum ada pengumuman'` di `test/` → 0 hasil; benar belum teruji | **Terima** — widget test ke-5 ditambahkan (`_wrapEmpty`), 40 test hijau |
| 2 | Ganti `Notifier<String>` query dengan `TextEditingController` di widget | saran | controller perlu `dispose()` dan state pencarian pecah antara UI dan provider; query sebagai state provider tetap teruji widget | **Tolak** — state pencarian harus tunggal dan testable di luar widget |
| 3 | `DateTime.tryParse` dengan fallback epoch bisa menyembunyikan data rusak dari backend masa depan | saran | benar untuk data remote; data saat ini lokal dan terkontrol | **Terima sebagian** — fallback dipertahankan untuk data lokal, dicatat sebagai wajib divalidasi saat backend nyata ada |

## 7. Bukti mesin hijau

```text
$ flutter analyze
Analyzing _07_week_7_clean_architecture...
No issues found! (ran in 12.0s)

$ dart format --set-exit-if-changed lib test
Formatted 31 files (0 changed) in 0.74s

$ flutter test
00:05 +40: All tests passed!
```

40 test = 28 test Minggu 5–8 (tidak ada yang rusak) + 7 unit test
`SearchAnnouncements` + 5 widget test `AnnouncementsPage` (termasuk
empty state dan tombol hapus query).

## 8. Tabel usulan AI vs keputusan final

| Usulan AI | Keputusan | Alasan teknis + bukti |
| --- | --- | --- |
| `dio.get('/announcements')` sebagai sumber data | Tolak + tulis manual | endpoint tidak ada: grep `lib/` hanya menemukan `POST /devices`; `baseUrl` adalah placeholder; repository lokal dengan payload JSON mentah dibuat agar `AnnouncementModel.fromJson` tetap terpakai dan sumber mudah ditukar |
| Filter `title.contains(query)` di `build` widget | Tolak + refactor | pelanggaran dependency rule, tak teruji tanpa widget; dipindah ke `SearchAnnouncements` (domain) |
| Filter case-sensitive `contains(query)` | Tolak + perbaiki | bug terbukti: 3 test merah pada versi AI; diperbaiki dengan normalisasi huruf kecil di kedua sisi |
| `import flutter_riverpod` di use case domain | Tolak + tulis manual | domain wajib steril: grep import framework di `domain/` → 0 hasil setelah ditulis ulang |
| Entity `Announcement` + model mapping `AnnouncementModel` | Terima | sesuai pola `AuthSession`/`AuthSessionModel` yang sudah lolos review Minggu 8 |
| Susunan provider (repository → use case → provider filter) | Terima | mengikuti struktur `auth_providers.dart`; satu-satunya tempat presentation menyentuh data |
| Empty state ikon + pesan + saran kata kunci | Terima | memenuhi syarat tugas; dua varian (daftar kosong vs tak cocok) dipisah agar bisa diuji |
| Struktur test: 1 sukses + 1 gagal untuk search | Terima + perluas | ditambah trim, kecocokan tengah, imutabilitas, dan 5 widget test |
| (review) test state "belum ada pengumuman" | Terima + test baru | bukti grep → test ke-5 ditambahkan, hijau |
| (review) `TextEditingController` menggantikan state provider | Tolak | controller berumur widget, state pecah, tak bisa diuji tanpa UI |
| (review) validasi ketat parsing tanggal | Terima sebagian | wajar untuk data remote; data lokal terkontrol, catatan migrasi backend diberi |

## 9. Cara uji ulang (tanpa perangkat)

```bash
cd _07_week_7_clean_architecture
flutter analyze
dart format --set-exit-if-changed lib test
flutter test
```

Dengan perangkat/emulator:

```bash
flutter run   # login -> beranda -> kartu "Pengumuman"
```

Lalu uji manual tiga query: kosong, `ujian`, `zzz-tak-ada`.
