import '../../../../core/failures.dart';

/// Kontrak repository asisten AI.
///
/// Domain hanya mengenal kontrak ini. Ke mana pertanyaan dikirim (Gemini,
/// provider lain, backend proxy) adalah keputusan implementasi di layer
/// `data` — pola yang sama dengan [AnnouncementRepository] dan
/// `AuthRepository`.
///
/// Tiga bagian prompt (sesuai codelab Minggu 10) dikirim terpisah agar
/// repository bisa menyusun request API seadanya tanpa merangkai string:
/// - `system`   : persona + batasan asisten (system prompt)
/// - `question` : pertanyaan mentah dari pengguna (user prompt)
/// - `context`  : judul pengumuman kampus sebagai konteks lokal
abstract class AssistantRepository {
  Future<({String reply, Failure? failure})> ask({
    required String system,
    required String question,
    required String context,
  });
}
