import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/announcements/presentation/pages/announcement_page.dart';
import 'features/announcements/presentation/pages/announcements_page.dart';
import 'features/assistant/presentation/pages/api_key_page.dart';
import 'features/assistant/presentation/pages/assistant_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'pages/home_page.dart';
import 'routes.dart';

/// Komposisi aplikasi: router + widget akar, tanpa bootstrap Firebase.
///
/// Dipisah dari `main.dart` pada Minggu 12 supaya alur aplikasi bisa diuji
/// (`integration_test/app_test.dart`) dengan container dan repository palsu.
/// `main.dart` tetap memegang Firebase/FCM; berkas ini murni UI + rute.
///
/// Sebelumnya router dan `MaterialApp` hidup di `main.dart`, sehingga setiap
/// integration test harus ikut menyalakan Firebase dan secure storage.
/// Pemecahan ini tidak mengubah perilaku aplikasi produksi.
GoRouter createRouter(ProviderContainer container) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) async {
      // Tunggu status auth selesai dibaca dari secure storage agar cold start
      // tidak salah diarahkan ke /login saat provider masih loading.
      bool loggedIn;
      try {
        loggedIn = await container.read(authStateProvider.future);
      } catch (_) {
        loggedIn = false;
      }
      final goingLogin = state.matchedLocation == AppRoutes.login;
      // Guard route: belum login selalu diarahkan ke /login.
      if (!loggedIn && !goingLogin) return AppRoutes.login;
      // Sudah login tapi masih membuka /login -> kembali ke home.
      if (loggedIn && goingLogin) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.announcements,
        builder: (_, _) => const AnnouncementsPage(),
      ),
      GoRoute(
        path: AppRoutes.announcementPattern,
        builder: (_, state) =>
            AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
      // Fitur AI Minggu 10: chat asisten + pengaturan API key.
      GoRoute(
        path: AppRoutes.assistant,
        builder: (_, _) => const AssistantPage(),
      ),
      GoRoute(
        path: AppRoutes.assistantSettings,
        builder: (_, _) => const ApiKeyPage(),
      ),
    ],
  );
}

/// Widget akar aplikasi. Menerima container + router dari luar agar test
/// dapat menyuntikkan dependensi palsu lewat override provider.
class CampusNotifyApp extends StatelessWidget {
  const CampusNotifyApp({
    super.key,
    required this.container,
    required this.router,
  });

  final ProviderContainer container;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        title: 'Campus Notification App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        routerConfig: router,
      ),
    );
  }
}
