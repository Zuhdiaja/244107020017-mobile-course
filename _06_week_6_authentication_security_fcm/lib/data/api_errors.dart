import 'package:dio/dio.dart';

/// Pemetaan `DioException` menjadi pesan ramah pengguna.
/// UI cukup menampilkan `friendlyErrorMessage(e)` tanpa menyentuh Dio.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi ke server habis waktu. Coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Sesi Anda berakhir. Silakan login ulang.';
        if (code == 404) return 'Data tidak ditemukan.';
        if (code != null && code >= 500) {
          return 'Server sedang bermasalah. Coba beberapa saat lagi.';
        }
        return 'Permintaan gagal (kode $code).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
      case DioExceptionType.unknown:
        return 'Terjadi gangguan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga.';
}
