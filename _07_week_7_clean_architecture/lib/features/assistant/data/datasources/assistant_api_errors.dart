import 'package:dio/dio.dart';

import '../../../../core/failures.dart';

/// Pemetaan `DioException` milik panggilan Gemini menjadi [Failure].
///
/// Sengaja dipisah dari `mapDioException` milik fitur auth: pesan dan kode
/// yang relevan berbeda (mis. 429 = kuota/rate limit Gemini, 400 berisi
/// alasan API key tidak valid), dan supaya fitur assistant tidak mengimpor
/// file fitur auth. Dio hanya boleh muncul di file data seperti ini.
Failure mapAssistantDioException(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure(
          'Koneksi ke layanan AI habis waktu. Coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Tidak dapat terhubung ke layanan AI. Periksa koneksi internet.',
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 400 || code == 401 || code == 403) {
          return const NetworkFailure(
            'API key tidak valid atau tidak punya izin. Periksa Pengaturan '
            'AI.',
          );
        }
        if (code == 429) {
          return const NetworkFailure(
            'Kuota layanan AI sedang penuh (rate limit). Tunggu sebentar '
            'lalu coba lagi, atau gunakan pencarian pengumuman.',
          );
        }
        if (code != null && code >= 500) {
          return const NetworkFailure(
            'Layanan AI sedang bermasalah. Coba beberapa saat lagi.',
          );
        }
        return NetworkFailure('Permintaan ke layanan AI gagal. Kode $code.');
      case DioExceptionType.cancel:
        return const NetworkFailure('Permintaan dibatalkan.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('Sertifikat layanan AI tidak valid.');
      case DioExceptionType.unknown:
        return const NetworkFailure('Terjadi gangguan jaringan. Coba lagi.');
    }
  }
  return const UnknownFailure('Terjadi kesalahan tak terduga.');
}
