import 'package:dio/dio.dart';

import '../../../../core/failures.dart';

/// Mengambil pesan error dari badan respons Gemini (bila ada) supaya
/// penyebab kegagalan terlihat oleh pengguna/pengembang, bukan hanya
/// tebakan berdasarkan kode status. Dipotong agar banner tetap rapi.
String _serverDetail(Object? data) {
  if (data is Map<String, dynamic>) {
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        final trimmed = message.length > 140
            ? '${message.substring(0, 140)}...'
            : message;
        return ' Detail: $trimmed';
      }
    }
  }
  return '';
}

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
        final detail = _serverDetail(error.response?.data);
        if (code == 400 || code == 401 || code == 403) {
          return NetworkFailure(
            'API key tidak valid atau tidak punya izin. Periksa Pengaturan '
            'AI.$detail',
          );
        }
        if (code == 404) {
          return NetworkFailure(
            'Model AI tidak ditemukan. Ganti nama model di Pengaturan AI '
            '(mis. gemini-2.5-flash).$detail',
          );
        }
        if (code == 429) {
          return NetworkFailure(
            'Kuota layanan AI sedang penuh (rate limit). Tunggu sebentar '
            'lalu coba lagi, atau gunakan pencarian pengumuman.$detail',
          );
        }
        if (code != null && code >= 500) {
          return NetworkFailure(
            'Layanan AI sedang bermasalah. Coba beberapa saat lagi, atau '
            'ganti model di Pengaturan AI.$detail',
          );
        }
        return NetworkFailure(
          'Permintaan ke layanan AI gagal. Kode $code.$detail',
        );
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
