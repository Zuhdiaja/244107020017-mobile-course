import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier untuk mengambil data statistik secara asynchronous.
class StatsNotifier extends AsyncNotifier<List<String>> {
  /// Fungsi untuk mengambil data statistik.
  Future<List<String>> _fetchStats() async {
    // Simulasi proses mengambil data dari server selama 2 detik.
    await Future.delayed(const Duration(seconds: 2));

    // Membuat nilai random antara 0.0 sampai kurang dari 1.0.
    final random = Random();

    // 30% kemungkinan terjadi error.
    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // Jika berhasil, kembalikan 3 data statistik.
    return [
      'Total Pengguna: 1.250',
      'Pengguna Aktif: 875',
      'Transaksi Hari Ini: 342',
    ];
  }

  /// Dipanggil pertama kali ketika provider digunakan.
  @override
  Future<List<String>> build() async {
    return _fetchStats();
  }

  /// Mengambil ulang data ketika tombol Retry ditekan.
  Future<void> retry() async {
    // Ubah state menjadi loading.
    state = const AsyncLoading();

    // Ambil data kembali dan ubah hasilnya menjadi AsyncValue.
    state = await AsyncValue.guard(_fetchStats);
  }
}

/// Satu-satunya provider untuk statistik.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);