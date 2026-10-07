import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

void main() {
  runApp(
    UncontrolledProviderScope(container: container, child: const MyApp()),
  );
}
