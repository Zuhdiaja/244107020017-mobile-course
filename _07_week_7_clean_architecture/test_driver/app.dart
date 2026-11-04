// Entry point khusus flutter_driver (uji manual terotomasi di Chrome).
//
// Bukan bagian dari aplikasi yang dinilai: file ini hanya membungkus
// `main()` asli supaya FlutterDriver bisa mengendalikan UI dari mesin host.
// CI tidak menjalankan file ini (CI hanya analyze + format + test).
import 'package:flutter_driver/driver_extension.dart';

import 'package:week7_clean_architecture/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
