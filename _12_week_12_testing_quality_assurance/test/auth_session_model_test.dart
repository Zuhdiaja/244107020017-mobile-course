import 'package:flutter_test/flutter_test.dart';

import 'package:week12_testing_quality_assurance/features/auth/data/models/auth_session_model.dart';
import 'package:week12_testing_quality_assurance/features/auth/domain/entities/auth_session.dart';

/// Unit test mapping sesi auth: JSON <-> model <-> entity.
void main() {
  group('AuthSessionModel.fromJson', () {
    test('membaca access_token dan refresh_token', () {
      final model = AuthSessionModel.fromJson({
        'access_token': 'access-abc',
        'refresh_token': 'refresh-xyz',
      });

      expect(model.access, 'access-abc');
      expect(model.refresh, 'refresh-xyz');
    });

    test('field hilang menjadi string kosong, bukan null', () {
      final model = AuthSessionModel.fromJson(const {});

      expect(model.access, isEmpty);
      expect(model.refresh, isEmpty);
    });

    test('nama field alternatif diabaikan (kontrak hanya snake_case)', () {
      final model = AuthSessionModel.fromJson({
        'accessToken': 'salah',
        'access_token': 'benar',
      });

      expect(model.access, 'benar');
    });
  });

  group('AuthSessionModel.toJson', () {
    test('menulis kunci snake_case yang dibaca fromJson', () {
      const model = AuthSessionModel(access: 'a', refresh: 'r');

      expect(model.toJson(), {'access_token': 'a', 'refresh_token': 'r'});
    });

    test('bolak-balik fromJson -> toJson stabil', () {
      const payload = {
        'access_token': 'access-123',
        'refresh_token': 'refresh-456',
      };

      final roundTrip = AuthSessionModel.fromJson(payload).toJson();

      expect(roundTrip, payload);
    });
  });

  group('AuthSessionModel.toEntity', () {
    test('menghasilkan entity murni, bukan model', () {
      final model = AuthSessionModel.fromJson({
        'access_token': 'access-abc',
        'refresh_token': 'refresh-xyz',
      });

      final entity = model.toEntity();

      expect(entity, isA<AuthSession>());
      expect(entity, isNot(isA<AuthSessionModel>()));
      expect(entity.access, 'access-abc');
      expect(entity.refresh, 'refresh-xyz');
    });
  });
}
