// Driver untuk menjalankan `integration_test/` di browser (web).
//
// `flutter test integration_test/...` tidak mendukung target Chrome, jadi
// web memakai jalur `flutter drive` + ChromeDriver:
//
//   chromedriver --port=4444
//   flutter drive -d chrome \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart
//
// Di Android/emulator atau desktop, berkas ini tidak dipakai; cukup
// `flutter test integration_test/app_test.dart -d <device>`.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
