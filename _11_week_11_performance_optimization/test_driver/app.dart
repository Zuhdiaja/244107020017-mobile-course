// Entry point khusus flutter_driver (uji manual terotomasi di Chrome).
//
// Bukan bagian dari aplikasi yang dinilai: file ini hanya membungkus
// `main()` asli supaya FlutterDriver bisa mengendalikan UI dari mesin host.
// CI tidak menjalankan file ini (CI hanya analyze + format + test).
//
// Minggu 11: handler diperluas agar driver profiling bisa membaca
// instrumen penghitung build/recompute/parsing (`reset-perf` dan
// `build-stats`) untuk membandingkan baseline vs hasil optimasi.
import 'package:flutter_driver/driver_extension.dart';

import 'package:week11_performance_optimization/features/announcements/data/repositories/announcement_repository_impl.dart';
import 'package:week11_performance_optimization/features/announcements/presentation/pages/announcements_page.dart';
import 'package:week11_performance_optimization/features/announcements/presentation/providers/announcements_providers.dart';
import 'package:week11_performance_optimization/main.dart' as app;

void main() {
  enableFlutterDriverExtension(handler: (message) async {
    switch (message) {
      case 'reset-perf':
        AnnouncementsPage.buildCount = 0;
        filteredRecomputeCount = 0;
        AnnouncementRepositoryImpl.parseRuns = 0;
        return 'ok';
      case 'build-stats':
        return 'pageBuilds=${AnnouncementsPage.buildCount};'
            'filteredRecompute=$filteredRecomputeCount;'
            'parseRuns=${AnnouncementRepositoryImpl.parseRuns}';
    }
    return 'unknown';
  });
  app.main();
}
