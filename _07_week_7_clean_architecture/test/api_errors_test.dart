import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/auth/data/datasources/api_errors.dart';

/// Refactoring Challenge #3: pemetaan error harus mengembalikan `Failure`,
/// bukan `String`, supaya presentation tidak perlu memilih tabel pesan lagi.
void main() {
  DioException dioError(DioExceptionType type, {int? statusCode}) {
    final request = RequestOptions(path: '/devices');
    return DioException(
      requestOptions: request,
      type: type,
      response: statusCode == null
          ? null
          : Response(requestOptions: request, statusCode: statusCode),
    );
  }

  group('mapDioException (pemetaan error Dio -> Failure)', () {
    test('connectionError -> NetworkFailure', () {
      final failure = mapDioException(
        dioError(DioExceptionType.connectionError),
      );
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('Tidak dapat terhubung'));
    });

    test('timeout -> NetworkFailure', () {
      final failure = mapDioException(
        dioError(DioExceptionType.connectionTimeout),
      );
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('waktu'));
    });

    test('401 -> AuthFailure, bukan NetworkFailure', () {
      final failure = mapDioException(
        dioError(DioExceptionType.badResponse, statusCode: 401),
      );
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('login ulang'));
    });

    test('404 -> NetworkFailure', () {
      final failure = mapDioException(
        dioError(DioExceptionType.badResponse, statusCode: 404),
      );
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('tidak ditemukan'));
    });

    test('5xx -> NetworkFailure', () {
      final failure = mapDioException(
        dioError(DioExceptionType.badResponse, statusCode: 500),
      );
      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('Server sedang bermasalah'));
    });

    test('error non-Dio -> UnknownFailure', () {
      final failure = mapDioException(Exception('x'));
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, contains('tak terduga'));
    });

    test('semua Failure punya pesan yang bisa langsung ditampilkan', () {
      final samples = <Failure>[
        mapDioException(dioError(DioExceptionType.connectionError)),
        mapDioException(dioError(DioExceptionType.cancel)),
        mapDioException(dioError(DioExceptionType.badCertificate)),
        mapDioException(Exception('x')),
      ];
      for (final failure in samples) {
        expect(failure.message, isNotEmpty);
      }
    });
  });
}
