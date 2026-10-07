import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

/// Container global: dipakai router untuk membaca state auth di luar widget
/// tree (pola `container.read(authStateProvider)` pada redirect GoRouter).
final container = ProviderContainer();

final _appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final loggedIn = container.read(authStateProvider).value ?? false;
    final goingLogin = state.matchedLocation == '/login';
    // Guard route: belum login selalu diarahkan ke /login.
    if (!loggedIn && !goingLogin) return '/login';
    // Sudah login tapi masih membuka /login -> kembali ke home.
    if (loggedIn && goingLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Notification App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      routerConfig: _appRouter,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wajib sebelum runApp: inisialisasi Firebase
  await Firebase.initializeApp();

  // Praktikum 2: permission + notifikasi lokal + token lifecycle.
  await initLocalNotifications();
  await requestNotificationPermission();

  // Dio dari apiClientProvider (interceptor 401 + token access otomatis).
  final dio = container.read(apiClientProvider);

  await initFcmToken(onToken: (token) async {
    // Token terpotong untuk bukti laporan (jangan token penuh).
    // ignore: avoid_print
    print('Mendaftarkan device, token FCM: '
        '${token.substring(0, token.length.clamp(0, 12))}...');
    try {
      // Kirim token ke backend (endpoint POST /devices).
      final res = await dio.post(
        '/devices',
        data: {'fcm_token': token, 'platform': 'android'},
      );
      // ignore: avoid_print
      print('FCM token terkirim ke backend (POST /devices): '
          'status ${res.statusCode}');
    } on DioException catch (e) {
      // Backend memang belum ada (example-campus-api.test) -> error ini
      // DIHARAPKAN dan justru jadi bukti percobaan pengiriman.
      // ignore: avoid_print
      print('Gagal kirim token ke backend: ${e.type} '
          '${e.response?.statusCode ?? ''}');
    } catch (e) {
      // ignore: avoid_print
      print('Gagal kirim token ke backend: $e');
    }
  });

  runApp(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
}
