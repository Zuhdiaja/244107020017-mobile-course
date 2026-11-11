// Skenario uji manual Minggu 10 — dijalankan di Chrome via flutter drive.
//
// Alur: login -> Beranda (kartu Asisten) -> chat (banner API key + error
// fallback) -> Pengaturan AI. Setiap layar disimpan sebagai screenshot
// bukti visual di folder _10_week_10_ai_feature_integration/screenshots/.
//
// Jalankan dari folder project:
//   flutter drive -d chrome --target=test_driver/app.dart \
//     --driver=test_driver/week10_flow.dart
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

const _screensDir =
    'D:\\Semester5\\244107020017-mobile-course\\_10_week_10_ai_feature_integration\\screenshots';

Future<void> main() async {
  final driver = await FlutterDriver.connect();

  Future<void> snap(String name) async {
    final bytes = await driver.screenshot();
    final file = File('$_screensDir\\$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    // ignore: avoid_print
    print('Screenshot tersimpan: ${file.path}');
  }

  try {
    // 1) Login (mock backend: email valid + sandi >= 6 karakter).
    await driver.waitUntilNoTransientCallbacks(
      timeout: const Duration(seconds: 60),
    );
    await driver.tap(find.byValueKey('login-email-field'));
    await driver.enterText('budi@polinema.ac.id');
    await driver.tap(find.byValueKey('login-password-field'));
    await driver.enterText('rahasia123');
    await driver.tap(find.byValueKey('login-submit-button'));

    // 2) Beranda: kartu Asisten Kampus (fitur baru) tampil.
    await driver.waitFor(
      find.text('Beranda'),
      timeout: const Duration(seconds: 30),
    );
    await driver.waitFor(find.text('Asisten Kampus (AI)'));
    await snap('week10-home-card');

    // 3) Chat: empty state + banner "API key belum diatur".
    await driver.tap(find.byValueKey('home-assistant-card'));
    await driver.waitFor(
      find.text('Tanya Asisten Kampus'),
      timeout: const Duration(seconds: 30),
    );
    await driver.waitFor(find.text('API key belum diatur'));
    await snap('week10-chat-banner');

    // 4) Kirim pertanyaan tanpa key: fallback error ramah, bukan crash.
    await driver.tap(find.byValueKey('chat-field'));
    await driver.enterText('Kapan UAS dimulai?');
    await driver.tap(find.byValueKey('send-button'));
    await driver.waitFor(
      find.text(
        'API key belum diatur. Buka menu Pengaturan AI (ikon kunci) lalu '
        'tempel key dari Google AI Studio.',
      ),
      timeout: const Duration(seconds: 30),
    );
    await snap('week10-chat-error-fallback');

    // 5) Pengaturan AI: tempat menyimpan API key di secure storage.
    await driver.tap(find.byValueKey('open-settings-button'));
    await driver.waitFor(
      find.text('Pengaturan AI'),
      timeout: const Duration(seconds: 30),
    );
    await snap('week10-api-key-page');

    // ignore: avoid_print
    print('Alur uji manual Minggu 10 selesai tanpa error.');
  } finally {
    await driver.close();
  }
}
