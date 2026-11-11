# Performance Findings - Minggu 11

Temuan dari membaca kode Minggu 7-10 (`campus_notify`) dan dari timeline
Chrome DevTools Performance pada build profile. Setiap temuan ditulis dengan
gejala, lokasi kode, dampak, dan perbaikan yang dipilih.

Project dasar: `_07_week_7_clean_architecture` (auth + notifications +
announcements + asisten AI). Baseline diukur dari kode sebelum optimasi,
bukan dari screenshot terpisah - lihat catatan di bagian
[Keterbatasan](#keterbatasan-pengukuran).

---

## Ringkasan

| # | Temuan | Kategori | Dampak | Status |
| --- | --- | --- | --- | --- |
| 1 | Setiap karakter ketikan memicu recompute filter + rebuild seluruh halaman | CPU / rebuild | 5 recompute untuk kata "ujian" | Diperbaiki |
| 2 | `fetchAll()` mem-parse ulang 5 map JSON setiap halaman dibuka | CPU / data | parsing berulang, alokasi objek sia-sia | Diperbaiki |
| 3 | Halaman chat rebuild total pada tiap perubahan state | CPU / rebuild | daftar + TextField ikut dibangun ulang saat pesan masuk | Diperbaiki |
| 4 | Kartu navigasi statis ikut rebuild saat token/sesi berubah | CPU / rebuild | widget statis dibangun ulang tanpa alasan | Diperbaiki |
| 5 | Baris konteks AI dibentuk ulang setiap kirim chat | CPU / data | pemformatan string berulang per kirim | Diperbaiki |
| 6 | Paint satu kartu menyapu seluruh list saat scroll | Raster | tanpa isolasi repaint | Diperbaiki |

---

## Temuan 1 - Rebuild per karakter pada pencarian

**Gejala.** Di timeline, area sekitar kolom pencarian menghasilkan satu blok
kerja per karakter yang diketik. Setiap karakter memicu `setState` setara:
provider query berubah, provider hasil filter menghitung ulang, lalu seluruh
`Scaffold` halaman membangun ulang.

**Lokasi kode (baseline).**

```dart
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;   // langsung, tanpa jeda
  void clear() => state = '';
}
```

dan di halaman:

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final query = ref.watch(searchQueryProvider);        // seluruh halaman ikut
  final results = ref.watch(filteredAnnouncementsProvider);
  return Scaffold(... TextField(onChanged: ...) ...);
}
```

**Dampak.** Mengetik "ujian" (5 karakter) = 5 kali recompute filter + 5 kali
rebuild `Scaffold` penuh (AppBar, field, list). Biaya per karakter tumbuh
seiring jumlah item.

**Perbaikan.** Debounce 250 ms pada notifier + `select` di halaman:

```dart
void set(String value) {
  _cancelDebounce();
  _debounce = Timer(searchDebounceDelay, () => state = value);
}
```

Field pencarian juga diekstrak menjadi `_SearchField` yang mengamati
`searchQueryProvider.select((q) => q.isEmpty)`, sehingga halaman utama tidak
ikut rebuild per karakter. `clear()` sengaja tetap instan karena tombol hapus
harus terasa langsung.

**Verifikasi.** `test/search_debounce_test.dart`: 5 ketikan beruntun hanya
menghasilkan 1 pembaruan state, dan `filteredRecompute` naik 1x.

---

## Temuan 2 - Parsing JSON berulang di repository

**Gejala.** Setiap kali halaman daftar dibuka kembali, repository memetakan
ulang seluruh payload mentah menjadi entity. Untuk 5 item biayanya kecil,
tetapi polanya sama untuk data besar: kerja identik diulang tanpa alasan.

**Lokasi kode (baseline).**

```dart
Future<...> fetchAll() async {
  final announcements = _seed
      .map(AnnouncementModel.fromJson)      // dipanggil setiap fetchAll()
      .map((model) => model.toEntity())
      .toList(growable: false);
  return (announcements: announcements, failure: null);
}
```

**Dampak.** Alokasi `AnnouncementModel` + `Announcement` baru setiap
pemanggilan. Di timeline terlihat sebagai aktivitas `build`/alokasi berulang
saat navigasi bolak-balik.

**Perbaikan.** Cache-first di repository, kontrak tidak berubah:

```dart
final cached = _cache;
if (cached != null) {
  return (announcements: cached, failure: null);
}
parseRuns++;
final announcements = _seed.map(...).toList(growable: false);
_cache = announcements;
```

**Verifikasi.** `test/announcement_repository_cache_test.dart`: `parseRuns`
tetap 1 setelah dua kali `fetchAll()`, dan instance daftar yang dikembalikan
identik (`identical(...) == true`).

---

## Temuan 3 - Rebuild total pada halaman chat

**Gejala.** Satu `ref.watch(assistantChatProvider)` di `build` membuat
seluruh `Scaffold` chat (AppBar, banner API key, daftar pesan, banner error,
TextField, tombol kirim) dibangun ulang setiap state berubah - termasuk saat
hanya `isSending` berganti.

**Lokasi kode (baseline).**

```dart
Widget build(BuildContext context) {
  final state = ref.watch(assistantChatProvider);   // semuanya
  final keySaved = ref.watch(apiKeySavedProvider).value;
  ...
}
```

**Dampak.** Setiap pesan baru dan setiap pergantian indikator mengetik
membangun ulang `TextField` beserta daftar pesan. Semakin panjang riwayat
chat, semakin mahal.

**Perbaikan.** Halaman dipecah menjadi tiga zona yang berlangganan irisan
state masing-masing lewat `select`:

| Zona | Berlangganan | Rebuild saat |
| --- | --- | --- |
| `_ChatMessages` | `(messages, isSending)` | pesan baru / indikator mengetik |
| `_ChatComposer` | `isSending` | status kirim berubah |
| `_ErrorBannerSlot` | `error` | pesan error berubah |
| `_ApiKeyBanner` | `apiKeySavedProvider.value` | status key berubah |

**Verifikasi.** `test/assistant_page_test.dart` tetap lulus seluruhnya (empty
state, banner API key, indikator mengetik, validasi input kosong, chat baru),
membuktikan pemecahan zona tidak mengubah perilaku.

---

## Temuan 4 - Widget statis ikut rebuild di beranda

**Gejala.** Kartu "Pengumuman" dan "Asisten Kampus (AI)" tidak pernah
berubah isinya, tetapi ikut dibangun ulang setiap kali beranda rebuild.

**Lokasi kode (baseline).** `Card` + `ListTile` ditulis inline di `build`
beranda, dengan closure `onTap` baru tiap build.

**Dampak.** Dua kartu + closure baru setiap rebuild beranda (dipicu perubahan
token FCM atau sesi).

**Perbaikan.** Diekstrak menjadi `_NavCard` dengan seluruh field `const`,
sehingga instance-nya konstan dan dilewati Flutter saat parent rebuild.
Kartu lain juga dipecah (`_WelcomeCard`, `_SessionCard`, `_FcmCard`), dan
`ref.watch` diganti `select` pada nilai akhir (`.value`) agar transisi
loading selesai tidak memicu rebuild bila nilainya sama.

**Verifikasi.** `flutter analyze` bersih; perilaku beranda tidak berubah
(dibuktikan test login dan navigasi yang ada).

---

## Temuan 5 - Konteks AI dibentuk ulang setiap kirim

**Gejala.** Setiap kirim chat memanggil `_contextLines()` yang memetakan
seluruh daftar pengumuman menjadi string tanggal + judul.

**Lokasi kode (baseline).**

```dart
List<String> _contextLines() {
  return ref.watch(announcementsProvider).value
      ?.map((a) => '${a.title} (${a.date.toIso8601String().substring(0, 10)})')
      .toList() ?? const [];
}
```

**Dampak.** Pemformatan string berulang untuk data yang sama, dijalankan di
jalur kritis sebelum request AI.

**Perbaikan.** Dihitung sekali sebagai provider turunan:

```dart
final announcementContextLinesProvider = Provider<List<String>>((ref) {
  final announcements = ref.watch(announcementsProvider).value;
  if (announcements == null) return const [];
  return [for (final a in announcements) '...'];
});
```

Pengiriman chat cukup `ref.read(announcementContextLinesProvider)`.

---

## Temuan 6 - Paint tanpa isolasi pada item list

**Gejala.** Saat scroll dan saat indikator mengetik berkedip, satu area yang
berubah dapat memicu repaint area yang lebih luas dari seharusnya.

**Perbaikan.** `RepaintBoundary` pada tiap item list pengumuman dan tiap
gelembung chat. Isolasi ini membuat repaint terbatas pada layer item terkait.

**Catatan jujur.** Pada 5 item dan layar desktop, dampak `RepaintBoundary`
tidak terlihat di timeline. Perbaikan tetap dipertahankan karena murah dan
berdampak saat list memanjang, tetapi tidak diklaim sebagai penyumbang utama.

---

## Keterbatasan pengukuran

1. Profiling dilakukan di **Flutter web (Chrome)**. Flutter web tidak
   mengekspos track **UI Thread** dan **Raster Thread** terpisah seperti
   DevTools Flutter di Android, sehingga `build`, `layout`, dan `rasterize`
   tidak bisa dibaca per-track.
2. Screenshot DevTools yang tersedia hanya untuk kondisi **sesudah** optimasi
   (`screenshots/after-profile.png`). Baseline tidak direkam ulang dengan
   kondisi setara, jadi angka baseline di laporan ini berasal dari **analisis
   kode**, bukan dari frame chart. Perbandingan angka frame before/after
   karena itu tidak diklaim.
3. Data uji hanya 5 pengumuman dan build profile desktop sangat cepat, jadi
   selisih frame time antar versi kecil. Bukti dampak utama ada pada instrumen
   kode (`parseRuns`, `filteredRecompute`) dan test otomatis, bukan pada frame
   chart.
4. Rekaman awal sempat memuat frame berdurasi 3-5 detik. Setelah diperiksa,
   penyebabnya adalah Chrome men-throttle tab background (DevTools dan
   aplikasi berada di tab berbeda), bukan jank aplikasi. Rekaman yang dipakai
   (`after-profile.png`) sudah bebas frame multi-detik; frame terlama 86,6 ms.
