import 'package:flutter_test/flutter_test.dart';

import 'package:week12_testing_quality_assurance/core/validators.dart';

/// Unit test aturan validasi bersama (Minggu 12).
///
/// Fungsi-fungsi ini murni: tidak menyentuh widget, provider, atau jaringan.
/// Karena `Login` (domain) dan `LoginPage` (presentation) memakai fungsi yang
/// sama, satu berkas test ini menutup dua jalur sekaligus.
void main() {
  group('isValidEmail — bentuk yang diterima', () {
    test('email kampus biasa diterima', () {
      expect(isValidEmail('budi@polinema.ac.id'), isTrue);
    });

    test('spasi di awal/akhir dipangkas lebih dulu', () {
      expect(isValidEmail('  budi@polinema.ac.id  '), isTrue);
    });

    test('subdomain dan tanda plus diterima', () {
      expect(isValidEmail('budi+uas@student.polinema.ac.id'), isTrue);
    });
  });

  group('isValidEmail — kasus tepi ditolak', () {
    test('string kosong ditolak', () {
      expect(isValidEmail(''), isFalse);
      expect(isValidEmail('   '), isFalse);
    });

    test('tanpa "@" ditolak', () {
      expect(isValidEmail('budi'), isFalse);
      expect(isValidEmail('budi.polinema.ac.id'), isFalse);
    });

    test('"@" saja ditolak (dulu lolos karena hanya contains)', () {
      expect(isValidEmail('@'), isFalse);
    });

    test('bagian sebelum "@" kosong ditolak', () {
      expect(isValidEmail('@polinema.ac.id'), isFalse);
    });

    test('bagian sesudah "@" kosong ditolak', () {
      expect(isValidEmail('budi@'), isFalse);
    });

    test('domain tanpa titik ditolak', () {
      expect(isValidEmail('budi@localhost'), isFalse);
    });

    test('titik di awal atau akhir domain ditolak', () {
      expect(isValidEmail('budi@.ac.id'), isFalse);
      expect(isValidEmail('budi@polinema.ac.id.'), isFalse);
    });

    test('dua "@" ditolak', () {
      expect(isValidEmail('budi@@polinema.ac.id'), isFalse);
      expect(isValidEmail('budi@polinema@ac.id'), isFalse);
    });

    test('spasi di tengah ditolak', () {
      expect(isValidEmail('budi polinema@ac.id'), isFalse);
    });
  });

  group('isValidPassword', () {
    test('tepat 6 karakter diterima (batas bawah)', () {
      expect(isValidPassword('123456'), isTrue);
    });

    test('5 karakter ditolak satu di bawah batas', () {
      expect(isValidPassword('12345'), isFalse);
    });

    test('string kosong ditolak', () {
      expect(isValidPassword(''), isFalse);
    });

    test('spasi dihitung sebagai karakter sah', () {
      expect(isValidPassword('      '), isTrue);
    });
  });
}
