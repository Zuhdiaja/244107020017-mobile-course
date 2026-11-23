import 'package:flutter_test/flutter_test.dart';

import 'package:week12_testing_quality_assurance/features/announcements/data/models/announcement_model.dart';
import 'package:week12_testing_quality_assurance/features/announcements/domain/entities/announcement.dart';

/// Unit test mapping data -> domain untuk pengumuman.
///
/// Mapping adalah satu-satunya tempat JSON mentah berubah menjadi entity,
/// sehingga kasus tepi di sini (field hilang, tanggal rusak) menentukan apakah
/// seluruh fitur menerima data yang aman atau melempar exception.
void main() {
  group('AnnouncementModel.fromJson', () {
    test('payload lengkap dipetakan apa adanya', () {
      final model = AnnouncementModel.fromJson({
        'id': '7',
        'title': 'Ujian Akhir Semester Ganjil',
        'body': 'Ujian digelar 8-19 Desember.',
        'date': '2026-11-10T08:00:00.000',
      });

      expect(model.id, '7');
      expect(model.title, 'Ujian Akhir Semester Ganjil');
      expect(model.body, 'Ujian digelar 8-19 Desember.');
      expect(model.date, DateTime(2026, 11, 10, 8));
    });

    test('payload kosong menghasilkan nilai default, bukan exception', () {
      final model = AnnouncementModel.fromJson(const {});

      expect(model.id, '');
      expect(model.title, '');
      expect(model.body, '');
      expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('tanggal tidak valid jatuh ke epoch', () {
      final model = AnnouncementModel.fromJson({
        'id': '1',
        'title': 'Judul',
        'date': 'bukan-tanggal',
      });

      expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test(
      'tipe field yang salah tetap gagal cepat (bukan diterima diam-diam)',
      () {
        // `id: 7` (int, bukan String) adalah payload rusak. Model memakai cast
        // `as String?` sehingga gagal jelas di batas data, bukan menghasilkan
        // entity dengan id aneh yang baru ketahuan di UI.
        expect(
          () => AnnouncementModel.fromJson({'id': 7, 'title': 'Judul'}),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });

  group('AnnouncementModel.toEntity', () {
    test('menghasilkan entity murni dengan nilai yang sama', () {
      final model = AnnouncementModel.fromJson({
        'id': '3',
        'title': 'Wisuda dan Yudisium',
        'body': 'Pendaftaran dibuka.',
        'date': '2026-10-28T13:00:00.000',
      });

      final entity = model.toEntity();

      expect(entity, isA<Announcement>());
      expect(entity, isNot(isA<AnnouncementModel>()));
      expect(entity.id, model.id);
      expect(entity.title, model.title);
      expect(entity.body, model.body);
      expect(entity.date, model.date);
    });
  });
}
