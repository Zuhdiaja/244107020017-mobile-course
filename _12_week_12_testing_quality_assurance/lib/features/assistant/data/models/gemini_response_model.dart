/// Representasi payload jawaban Gemini `generateContent` + mapping-nya.
///
/// Mapping JSON API hidup di sini (pola `AnnouncementModel`), bukan di
/// entity maupun widget. Kelas ini murni Dart sehingga parsing-nya bisa
/// diuji tanpa jaringan.
class GeminiResponseModel {
  const GeminiResponseModel._({required this.text, required this.blockReason});

  /// Teks jawaban hasil gabungan seluruh `parts` kandidat pertama.
  final String text;

  /// Alasan permintaan diblokir safety filter, atau `null` bila lolos.
  final String? blockReason;

  factory GeminiResponseModel.fromJson(Map<String, dynamic> json) {
    final promptFeedback = json['promptFeedback'] as Map<String, dynamic>?;
    final blockReason = promptFeedback?['blockReason'] as String?;

    final candidates = json['candidates'] as List<dynamic>? ?? const [];
    var text = '';
    if (candidates.isNotEmpty) {
      final first = candidates.first as Map<String, dynamic>;
      final content = first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>? ?? const [];
      text = parts
          .map(
            (part) => (part as Map<String, dynamic>)['text'] as String? ?? '',
          )
          .where((t) => t.isNotEmpty)
          .join('\n')
          .trim();
    }
    return GeminiResponseModel._(text: text, blockReason: blockReason);
  }

  /// Jawaban layak tampil: tidak diblokir dan teksnya tidak kosong.
  bool get hasUsableText => blockReason == null && text.isNotEmpty;
}
