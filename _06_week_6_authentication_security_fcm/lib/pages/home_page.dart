import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// HomePage — Praktikum 1 & 2.
/// - Praktikum 1: status sesi + access token secure storage (terpotong).
/// - Praktikum 2: token FCM tampil TERPOTONG (aturan codelab: jangan
///   pernah menampilkan token penuh di screenshot laporan).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _maskedAccess;
  bool _hasRefresh = false;
  String? _maskedFcmToken;
  bool _fcmError = false;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
    _loadFcmToken();
  }

  /// Praktikum 1: baca token sesi dari secure storage.
  Future<void> _loadTokenInfo() async {
    final store = ref.read(tokenStoreProvider);
    final access = await store.readAccess();
    final refresh = await store.readRefresh();
    if (!mounted) return;
    setState(() {
      _maskedAccess = access == null
          ? null
          : '${access.substring(0, access.length.clamp(0, 12))}...';
      _hasRefresh = refresh != null && refresh.isNotEmpty;
    });
  }

  /// Praktikum 2: ambil registration token FCM, tampilkan terpotong.
  Future<void> _loadFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (!mounted) return;
      setState(() {
        _maskedFcmToken = token == null
            ? null
            : '${token.substring(0, token.length.clamp(0, 12))}...';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _fcmError = true);
    }
  }

  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final loggedIn = authState.value ?? false;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
                      Text('Token sesi (terpotong)',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('access : ${_maskedAccess ?? '-'}'),
                  Text('refresh: ${_hasRefresh ? 'ada' : 'tidak ada'}'),
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
                      Icon(Icons.cloud_outlined,
                          size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Token FCM (terpotong)',
                          style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_fcmError)
                    const Text('Gagal mengambil token FCM')
                  else
                    Text('fcm : ${_maskedFcmToken ?? 'mengambil...'}'),
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
