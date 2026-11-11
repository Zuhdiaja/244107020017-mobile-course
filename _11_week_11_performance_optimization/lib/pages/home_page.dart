import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/notifications/presentation/providers/notifications_providers.dart';
import '../routes.dart';

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
///
/// Optimasi Minggu 11:
/// - `ref.watch` diganti `select` pada field yang benar-benar ditampilkan
///   (`.value`), bukan seluruh `AsyncValue` — transisi loading selesai tidak
///   lagi memicu rebuild kalau nilai akhirnya sama.
/// - Kartu navigasi (Pengumuman, Asisten AI) diekstrak ke [_NavCard] dan
///   dibuat `const` — Flutter melewati widget `const` yang identik, jadi
///   kedua kartu ini tidak pernah ikut rebuild meski token/session berubah.
/// - Kartu sambutan, sesi, dan FCM diekstrak agar tiap bagian kecil dan
///   menyusun ulang hanya dirinya sendiri.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select: halaman hanya peduli pada nilai boolean/sesi/token akhir.
    final loggedIn = ref.watch(
      authStateProvider.select((state) => state.value ?? false),
    );
    final session = ref.watch(sessionProvider.select((state) => state.value));
    final fcmToken = ref.watch(
      fcmTokenProvider.select((state) => state.value),
    );

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
          _WelcomeCard(loggedIn: loggedIn),
          const SizedBox(height: 8),
          // Kartu pintu masuk daftar pengumuman (Minggu 9: fitur search).
          const _NavCard(
            key: Key('home-announcements-card'),
            icon: Icons.campaign,
            title: 'Pengumuman',
            subtitle: 'Daftar pengumuman + pencarian judul',
            route: AppRoutes.announcements,
          ),
          const SizedBox(height: 8),
          // Kartu pintu masuk asisten AI (Minggu 10: fitur AI).
          const _NavCard(
            key: Key('home-assistant-card'),
            icon: Icons.smart_toy_outlined,
            title: 'Asisten Kampus (AI)',
            subtitle: 'Tanya jawab dengan konteks pengumuman',
            route: AppRoutes.assistant,
          ),
          const SizedBox(height: 8),
          // Kartu token sesi (Praktikum 1)
          _SessionCard(
            maskedAccess: maskSecret(session?.access),
            hasRefresh: session != null && session.refresh.isNotEmpty,
          ),
          const SizedBox(height: 8),
          // Kartu token FCM (Praktikum 2)
          _FcmCard(maskedFcmToken: maskSecret(fcmToken)),
        ],
      ),
    );
  }
}

/// Kartu sambutan; isinya hanya berubah saat status login berganti.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }
}

/// Kartu navigasi statis: seluruh field `const`, jadi instance-nya konstan
/// dan Flutter tidak pernah membangun ulang kartu ini saat beranda rebuild.
class _NavCard extends StatelessWidget {
  const _NavCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      ),
    );
  }
}

/// Kartu token sesi; hanya ikon baris pertama yang bergantung tema.
class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.maskedAccess, required this.hasRefresh});

  final String maskedAccess;
  final bool hasRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              'Disimpan di flutter_secure_storage - persisten '
              'walau app ditutup/hot restart.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu token FCM; dibangun ulang hanya saat token berubah.
class _FcmCard extends StatelessWidget {
  const _FcmCard({required this.maskedFcmToken});

  final String maskedFcmToken;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }
}
