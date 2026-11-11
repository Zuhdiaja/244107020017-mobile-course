// Skenario profiling Minggu 11 - dijalankan di Chrome via flutter drive.
//
// Skenario persis seperti codelab: buka daftar pengumuman, scroll, ketik
// query pencarian karakter demi karakter. Selama skenario berjalan, timeline
// frame direkam (traceAction) lalu diringkas menjadi JSON metrik frame
// (average/worst frame build time, jumlah frame yang meleset budget 16 ms).
// Instrumen penghitung build dibaca lewat handler `build-stats`.
//
// Output dikendalikan variabel lingkungan host:
//   PERF_OUT  folder tujuan JSON timeline (default: folder project)
//
// Jalankan dari folder project (nama file JSON bebas, lihat PERF_OUT):
//   $env:PERF_OUT='<absolut path output>'
//   flutter drive -d chrome --profile --target=test_driver/app.dart `
//     --driver=test_driver/perf_flow.dart
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final outDir = Platform.environment['PERF_OUT'] ?? Directory.current.path;
  final driver = await FlutterDriver.connect();

  try {
    // 1) Login mock (email valid + sandi >= 6 karakter).
    await driver.waitUntilNoTransientCallbacks(
      timeout: const Duration(seconds: 60),
    );
    await driver.tap(find.byValueKey('login-email-field'));
    await driver.enterText('budi@polinema.ac.id');
    await driver.tap(find.byValueKey('login-password-field'));
    await driver.enterText('rahasia123');
    await driver.tap(find.byValueKey('login-submit-button'));
    await driver.waitFor(
      find.text('Beranda'),
      timeout: const Duration(seconds: 30),
    );

    // 2) Buka daftar pengumuman.
    await driver.tap(find.text('Pengumuman'));
    await driver.waitFor(
      find.text('Ujian Akhir Semester Ganjil'),
      timeout: const Duration(seconds: 30),
    );

    // 3) Nol-kan instrumen, lalu jalankan skenario dengan perekaman timeline.
    await driver.requestData('reset-perf');

    final timeline = await driver.traceAction(() async {
      // Scroll daftar penuh turun-naik (menggunkan kartu pertama sebagai
      // pijakan gesture).
      await driver.scroll(
        find.text('Ujian Akhir Semester Ganjil'),
        0,
        -300,
        const Duration(milliseconds: 300),
      );
      await driver.scroll(
        find.text('Ujian Akhir Semester Ganjil'),
        0,
        300,
        const Duration(milliseconds: 300),
      );

      // Ketik "ujian" karakter demi karakter dengan jeda 120 ms (di bawah
      // jeda debounce 250 ms) - mensimulasikan ketikan manusia beruntun.
      await driver.tap(find.byValueKey('search-field'));
      for (final partial in const ['u', 'uj', 'uja', 'ujia', 'ujian']) {
        await driver.enterText(partial);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }

      // Beri waktu debounce selesai agar frame filter ikut terekam.
      await Future<void>.delayed(const Duration(milliseconds: 700));
    });

    // 4) Baca instrumen penghitung build/recompute/parsing.
    final stats = await driver.requestData('build-stats');
    // ignore: avoid_print
    print('PERF_STATS: $stats');

    // 5) Ringkas timeline ke JSON metrik frame.
    final summary = TimelineSummary.summarize(timeline);
    await summary.writeTimelineToFile(
      'perf-timeline',
      destinationDirectory: outDir,
      includeSummary: true,
      pretty: true,
    );
    // ignore: avoid_print
    print('PERF_TIMELINE_JSON: $outDir\\perf-timeline.timeline.json');

    // ignore: avoid_print
    print('Skenario profiling Minggu 11 selesai tanpa error.');
  } finally {
    await driver.close();
  }
}
