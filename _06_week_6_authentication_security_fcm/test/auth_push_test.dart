import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:_06_week_6_authentication_security_fcm/data/api_errors.dart';
import 'package:_06_week_6_authentication_security_fcm/messaging/push_service.dart';
import 'package:_06_week_6_authentication_security_fcm/routes.dart';

void main() {
  group('routeFromMessage (parsing data payload FCM)', () {
    test('route kosong -> fallback "/"', () {
      expect(routeFromMessage({}), '/');
      expect(routeFromMessage({'route': ''}), '/');
    });

    test('route tanpa slash di depan ditambahkan', () {
      expect(routeFromMessage({'route': 'pengumuman/3'}), '/pengumuman/3');
    });

    test('route dengan slash tetap', () {
      expect(routeFromMessage({'route': '/pengumuman/3'}), '/pengumuman/3');
    });

    test('data payload membawa id pengumuman', () {
      const data = {'route': '/pengumuman/3', 'id': '3'};
      expect(data['id'], '3');
      expect(routeFromMessage(data), '/pengumuman/3');
    });
  });

  group('AppRoutes', () {
    test('konstanta rute konsisten dengan helper', () {
      expect(AppRoutes.announcement('3'), '/pengumuman/3');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.home, '/');
    });
  });

  group('friendlyErrorMessage (pemetaan error Dio)', () {
    test('connectionError -> pesan ramah', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/devices'),
        type: DioExceptionType.connectionError,
      );
      expect(friendlyErrorMessage(e), contains('Tidak dapat terhubung'));
    });

    test('timeout -> pesan ramah', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/devices'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(friendlyErrorMessage(e), contains('waktu'));
    });

    test('401 -> minta login ulang', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/devices'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/devices'),
          statusCode: 401,
        ),
      );
      expect(friendlyErrorMessage(e), contains('login ulang'));
    });

    test('error non-Dio -> pesan umum', () {
      expect(friendlyErrorMessage(Exception('x')), contains('tak terduga'));
    });
  });
}
