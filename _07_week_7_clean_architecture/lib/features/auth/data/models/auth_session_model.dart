import '../../domain/entities/auth_session.dart';

/// Representasi data luar (respons API / isi penyimpanan) + mapping ke entity.
///
/// Mapping JSON hanya boleh hidup di sini, bukan di entity dan bukan di widget.
/// [toJson] dipakai saat menulis ke penyimpanan/API, [fromJson] saat membaca.
///
/// Catatan: payload auth hanya berisi dua field, sehingga model ini minimal.
/// Pola ini menjadi bernilai saat backend mengembalikan JSON yang lebih kaya.
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({required super.access, required super.refresh});

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionModel(
      access: json['access_token'] as String? ?? '',
      refresh: json['refresh_token'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() => {
    'access_token': access,
    'refresh_token': refresh,
  };

  /// Konversi ke entity murni di batas data -> domain.
  AuthSession toEntity() => AuthSession(access: access, refresh: refresh);
}
