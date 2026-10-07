import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// HomePage — Praktikum 1.
/// Menandai sesi aktif, menampilkan access token TERPOTONG (12 karakter
/// pertama) sebagai bukti secure storage bekerja, dan tombol logout.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _maskedAccess;
  bool _hasRefresh = false;

  @override
  void initState() {
    super.initState();
    _loadTokenInfo();
  }

  Future<void> _loadTokenInfo() async {
    final store = ref.read(tokenStoreProvider);
    final access = await store.readAccess();
    final refresh = await store.readRefresh();
    if (!mounted) return;
    setState(() {
      // Keamanan (aturan codelab): hanya tampilkan terpotong,
      // jangan pernah token penuh di screenshot laporan.
      _maskedAccess = access == null
          ? null
          : '${access.substring(0, access.length.clamp(0, 12))}...';
      _hasRefresh = refresh != null && refresh.isNotEmpty;
    });
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
        ],
      ),
    );
  }
}
