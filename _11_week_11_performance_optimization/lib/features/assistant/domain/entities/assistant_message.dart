/// Pesan tunggal dalam percakapan dengan asisten AI.
///
/// Entity murni milik domain — tanpa import framework apa pun, sama seperti
/// `Announcement` dan `AuthSession`. Mapping dari/jadi JSON API Gemini tidak
/// hidup di sini; itu tugas model di layer `data`.
enum AssistantRole { user, assistant }

class AssistantMessage {
  const AssistantMessage({required this.role, required this.text});

  /// Siapa pemilik pesan: pengguna atau asisten.
  final AssistantRole role;

  /// Isi pesan yang tampil di gelembung chat.
  final String text;

  /// Anggap dua pesan sama bila role dan teksnya sama — cukup untuk
  /// perbandingan di widget test.
  @override
  bool operator ==(Object other) =>
      other is AssistantMessage && other.role == role && other.text == text;

  @override
  int get hashCode => Object.hash(role, text);
}
