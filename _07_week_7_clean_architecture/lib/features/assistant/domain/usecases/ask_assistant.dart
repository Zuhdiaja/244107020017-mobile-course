import '../../../../core/failures.dart';
import '../repositories/assistant_repository.dart';

/// Use case murni: validasi pertanyaan, merangkai tiga bagian prompt
/// (system + konteks + pertanyaan), lalu memanggil repository.
///
/// Prompt design (codelab Minggu 10, bagian 3) hidup di sini — di domain,
/// bukan di widget — supaya bisa diuji tanpa jaringan dan tanpa API key:
/// - System prompt menetapkan persona + batas (Bahasa Indonesia, maksimal
///   2 kalimat, larangan menampilkan data pribadi).
/// - Konteks berisi judul pengumuman lokal (TANPA isi pribadi pengguna)
///   supaya jawaban relevan dengan campus_notify.
/// - Mitigasi biaya (tabel risiko codelab): batas pertanyaan per sesi,
///   panjang pertanyaan, dan jumlah baris konteks dibatasi di sini.
class AskAssistant {
  AskAssistant(this._repository, {this.sessionLimit = defaultSessionLimit});

  final AssistantRepository _repository;

  /// Mitigasi biaya sederhana: hitungan in-memory per sesi aplikasi.
  /// Penyimpanan lintas sesi tidak dipakai supaya domain tetap steril.
  int _usedRequests = 0;

  /// Batas panggilan per sesi; bisa dipersempit di test.
  final int sessionLimit;

  /// Persona + batasan asisten. Ditulis eksplisit sebagai konstanta karena
  /// inilah "system prompt" yang dikirim ke API (syarat dokumen ai-log).
  static const String systemPrompt =
      'Kamu asisten kampus ramah untuk mahasiswa Polinema. '
      'Jawab hanya dalam Bahasa Indonesia, maksimal 2 kalimat. '
      'Gunakan konteks pengumuman yang diberikan bila relevan; jika '
      'informasinya tidak ada, katakan tidak tahu dan sarankan memeriksa '
      'portal akademik. Jangan pernah menampilkan data pribadi mahasiswa '
      'lain. Jangan mengarang tanggal atau nomor kontak.';

  /// Mitigasi biaya: pertanyaan sangat panjang memboroskan token.
  static const int maxQuestionLength = 500;

  /// Mitigasi biaya: hanya sejumlah baris konteks yang dikirim.
  static const int maxContextLines = 5;

  /// Batas panggilan per sesi (default) — lihat [defaultSessionLimit].
  static const int defaultSessionLimit = 20;

  /// Blok konteks dirangkai dari judul-judul pengumuman lokal. Input berupa
  /// `List<String>` netral (bukan entity fitur announcements) supaya domain
  /// asisten tidak bergantung pada fitur lain.
  static String buildContext(List<String> contextLines) {
    if (contextLines.isEmpty) {
      return 'Belum ada pengumuman kampus yang tersedia.';
    }
    final limited = contextLines.take(maxContextLines).toList();
    return 'Pengumuman kampus terbaru (judul saja):\n'
        '- ${limited.join('\n- ')}';
  }

  Future<({String reply, Failure? failure})> call({
    required String question,
    required List<String> contextLines,
  }) {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return _fail(const ValidationFailure('Pertanyaan tidak boleh kosong.'));
    }
    if (trimmed.length > maxQuestionLength) {
      return _fail(
        const ValidationFailure(
          'Pertanyaan terlalu panjang. Maksimal $maxQuestionLength karakter.',
        ),
      );
    }
    if (_usedRequests >= sessionLimit) {
      return _fail(
        const NetworkFailure(
          'Batas pertanyaan per sesi tercapai. Coba buka ulang aplikasi.',
        ),
      );
    }
    _usedRequests += 1;
    return _repository.ask(
      system: systemPrompt,
      question: trimmed,
      context: buildContext(contextLines),
    );
  }

  Future<({String reply, Failure? failure})> _fail(Failure failure) async {
    return (reply: '', failure: failure);
  }
}
