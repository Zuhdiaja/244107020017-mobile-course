import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/notifications/presentation/providers/notifications_providers.dart';

/// Halaman beranda aplikasi.
///
/// Menampilkan status sesi (fitur `auth`) dan token FCM (fitur
/// `notifications`) dalam satu layar, sehingga halaman ini ditaruh di
/// `lib/pages/` sebagai halaman lintas fitur. Dengan begitu tidak ada satu
/// fitur pun yang harus mengimpor `presentation` fitur lain — codelab
/// meminta fitur berkomunikasi lewat rute, bukan lewat import.
///
/// Halaman ini hanya membaca state dari provider; tidak ada `Dio`,
/// `FirebaseMessaging`, maupun secure storage di sini.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = ref.watch(sessionProvider).value;
    final fcmAsync = ref.watch(fcmTokenProvider);

    final loggedIn = authState.value ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    final maskedAccess = maskSecret(session?.access);
    final hasRefresh = session != null && session.refresh.isNotEmpty;

    final token = fcmAsync.value;
    final maskedFcmToken = maskSecret(token);

    Future<void> logout() async {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu sambutan
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user,
                    size: 72,
                    color: loggedIn ? Colors.green : colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loggedIn ? 'Login berhasil' : 'Belum login',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text('Selamat datang di Campus Notification App'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Kartu token sesi (Praktikum 1)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Token sesi (terpotong)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('access : $maskedAccess'),
                  Text('refresh: ${hasRefresh ? 'ada' : 'tidak ada'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Disimpan di flutter_secure_storage — persisten '
                    'walau app ditutup/hot restart.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Kartu token FCM (Praktikum 2)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Token FCM (terpotong)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (fcmAsync.hasError)
                    const Text('Gagal mengambil token FCM')
                  else
                    Text(
                      'fcm : ${maskedFcmToken == '-' ? 'mengambil...' : maskedFcmToken}',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Registration token dari Firebase Cloud Messaging. '
                    'Dikirim ke backend via POST /devices dan dipantau '
                    'onTokenRefresh.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
