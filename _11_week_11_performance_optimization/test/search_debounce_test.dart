import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week11_performance_optimization/features/announcements/presentation/providers/announcements_providers.dart';

/// Bukti verifikasi optimasi Minggu 11: debounce input pencarian.
///
/// Metric yang dibuktikan di sini: lima ketikan beruntun hanya menghasilkan
/// SATU perubahan state query (recompute filter + rebuild UI turun dari
/// 5x menjadi 1x), dan `clear()` tetap instan tanpa menunggu debounce.
///
/// Waktu diuji dengan fake time `tester.pump` — Timer debounce benar-benar
/// dijalankan oleh fake event loop, bukan dipercepat atau dilewati.
void main() {
  testWidgets('lima ketikan beruntun menghasilkan satu pembaruan state',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(searchQueryProvider.notifier);

    // Simulasi pengguna mengetik "ujian" karakter demi karakter.
    notifier.set('u');
    notifier.set('uj');
    notifier.set('uja');
    notifier.set('ujia');
    notifier.set('ujian');

    // Selama jeda debounce, state belum berubah -> filter belum recompute.
    expect(container.read(searchQueryProvider), '');

    await tester.pump(searchDebounceDelay);

    // Setelah jeda lewat, hanya nilai TERAKHIR yang diterapkan.
    expect(container.read(searchQueryProvider), 'ujian');
  });

  testWidgets('ketikan baru mereset jeda debounce (trailing update)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(searchQueryProvider.notifier);

    notifier.set('u');
    await tester.pump(
      searchDebounceDelay - const Duration(milliseconds: 50),
    );
    expect(container.read(searchQueryProvider), '');

    // Ketikan lagi sebelum jeda selesai: timer lama batal, jeda dimulai baru.
    notifier.set('uj');
    await tester.pump(const Duration(milliseconds: 50));
    expect(container.read(searchQueryProvider), '');

    await tester.pump(searchDebounceDelay);
    expect(container.read(searchQueryProvider), 'uj');
  });

  testWidgets('clear() langsung mengosongkan tanpa menunggu debounce',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(searchQueryProvider.notifier);

    notifier.set('ujian');
    await tester.pump(searchDebounceDelay);
    expect(container.read(searchQueryProvider), 'ujian');

    notifier.clear();
    expect(container.read(searchQueryProvider), '');

    // Timer dari set() sebelumnya sudah dibatalkan: nilai tetap kosong.
    await tester.pump(searchDebounceDelay * 2);
    expect(container.read(searchQueryProvider), '');
  });

  testWidgets('widget field pencarian tampil dan terhubung provider',
      (tester) async {
    // Pengujian integrasi ringan: mengetik di UI memicu jalur debounce.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: _SearchProbe())),
      ),
    );

    await tester.enterText(find.byKey(const Key('search-field')), 'beasiswa');
    await tester.pump(searchDebounceDelay);

    expect(container.read(searchQueryProvider), 'beasiswa');
  });
}

/// Replika kecil field pencarian yang memakai jalur yang sama dengan
/// [_SearchField] di halaman asli — tanpa menarik seluruh Scaffold halaman.
class _SearchProbe extends ConsumerWidget {
  const _SearchProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      key: const Key('search-field'),
      onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
    );
  }
}
