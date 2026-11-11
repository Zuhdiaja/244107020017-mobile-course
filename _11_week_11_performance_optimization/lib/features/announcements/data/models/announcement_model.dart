import '../../domain/entities/announcement.dart';

/// Representasi data luar (payload / isi penyimpanan) + mapping ke entity.
///
/// Mapping hanya boleh hidup di sini — bukan di entity, bukan di widget
/// (pola `AuthSessionModel`). Saat backend pengumuman benar-benar ada,
/// sumber data cukup ditukar tanpa menyentuh domain.
class AnnouncementModel extends Announcement {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.body,
    required super.date,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      date:
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Konversi ke entity murni di batas data -> domain.
  Announcement toEntity() =>
      Announcement(id: id, title: title, body: body, date: date);
}
