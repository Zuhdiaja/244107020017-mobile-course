import 'package:dio/dio.dart';

import '../../../../core/failures.dart';

/// Pemetaan `DioException` menjadi [Failure].
///
/// Seamula fungsi ini mengembalikan `String`. Sekarang ia mengembalikan objek
/// `Failure` (Refactoring Challenge #3) supaya presentation tidak perlu
/// memilih-tabel pesan lagi, dan supaya jenis kegagalan tetap bisa dibedakan
/// di lapisan lain kalau dibutuhkan.
///
/// Dio hanya boleh muncul di file ini. Pemanggil cukup memakai
/// `failure.message`.
Failure mapDioException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(
          'Koneksi ke server habis waktu. Coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) {
          return const AuthFailure('Sesi berakhir. Silakan login ulang.');
        }
        if (code == 404) {
          return const NetworkFailure('Data tidak ditemukan.');
        }
        if (code != null && code >= 500) {
          return const NetworkFailure(
            'Server sedang bermasalah. Coba beberapa saat lagi.',
          );
        }
        return NetworkFailure('Permintaan gagal. Kode server $code.');
      case DioExceptionType.cancel:
        return const NetworkFailure('Permintaan dibatalkan.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Sertifikat server tidak valid.');
      case DioExceptionType.unknown:
        return const NetworkFailure('Terjadi gangguan jaringan. Coba lagi.');
    }
  }
  return const UnknownFailure('Terjadi kesalahan tak terduga.');
}
