import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/format.dart';
import 'package:week7_clean_architecture/routes.dart';

/// Fungsi murni di `core/format.dart` diuji tanpa Firebase, tanpa widget,
/// tanpa jaringan. Inilah hasil Refactoring Challenge #2: parsing rute tidak
/// lagi hidup di dalam file yang memanggil `FirebaseMessaging`.
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

  group('maskSecret (pemotongan nilai rahasia)', () {
    test('nilai panjang dipotong 12 karakter pertama', () {
      expect(maskSecret('abcdefghijklmnopqrstuvwxyz'), 'abcdefghijkl...');
    });

    test('nilai kosong atau null -> "-"', () {
      expect(maskSecret(null), '-');
      expect(maskSecret(''), '-');
    });

    test('nilai lebih pendek dari batas tidak terpotong', () {
      expect(maskSecret('abc'), 'abc...');
    });

    test('jumlah karakter terlihat bisa diatur', () {
      expect(maskSecret('abcdefghij', visible: 4), 'abcd...');
    });

    test('visible lebih besar dari panjang nilai tidak melempar', () {
      expect(maskSecret('abc', visible: 50), 'abc...');
    });
  });

  group('AppRoutes', () {
    test('konstanta rute konsisten dengan helper', () {
      expect(AppRoutes.announcement('3'), '/pengumuman/3');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.home, '/');
    });
  });
}