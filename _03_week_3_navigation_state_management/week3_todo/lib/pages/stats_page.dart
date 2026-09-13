import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../providers/stats_provider.dart';

/// ConsumerWidget digunakan karena halaman ini membutuhkan Riverpod.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch digunakan di dalam build untuk mengawasi perubahan state.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
      ),

      // AsyncValue.when menangani tiga kemungkinan state:
      // loading, error, dan data/success.
      body: statsAsync.when(
        // STATE 1: Loading
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // STATE 2: Error
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Menampilkan pesan error kepada pengguna.
              Text(
                'Gagal memuat data:\n$error',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Tombol retry digunakan untuk mengambil data kembali.
              FilledButton(
                // ref.read digunakan pada callback/event,
                // bukan ref.watch.
                onPressed: () {
                  ref.read(statsProvider.notifier).retry();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),

        // STATE 3: Success
        data: (stats) => ListView.builder(
          // Data statistik terdiri dari 3 item.
          itemCount: stats.length,

          // Membuat setiap item statistik menjadi ListTile.
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(stats[index]),
            );
          },
        ),
      ),
    );
  }
}