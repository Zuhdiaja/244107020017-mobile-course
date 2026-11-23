import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/api_key_store.dart';
import '../../data/datasources/gemini_api_client.dart';
import '../../data/repositories/assistant_repository_impl.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../../domain/usecases/ask_assistant.dart';

// ---------------------------------------------------------------------------
// Data layer: hanya untuk MEMBANGUN objek. Presentation memakai interface
// domain, bukan implementasinya.
// ---------------------------------------------------------------------------

/// Penyimpanan API key di secure storage.
final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => ApiKeyStore());

/// Client Gemini (Dio). Di test diganti fake tanpa jaringan.
final geminiApiClientProvider = Provider<GeminiApiClient>((ref) {
  return GeminiApiClientDio();
});

/// Repository asisten: interface domain, implementasi Gemini dari `data`.
final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepositoryImpl(
    client: ref.watch(geminiApiClientProvider),
    apiKeyStore: ref.watch(apiKeyStoreProvider),
  );
});

// ---------------------------------------------------------------------------
// Domain layer: use case murni, tanpa import Riverpod di file domain.
// ---------------------------------------------------------------------------

/// Use case validasi + prompt design + batas request per sesi.
final askAssistantProvider = Provider<AskAssistant>((ref) {
  return AskAssistant(ref.watch(assistantRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Presentation layer: state untuk UI.
// ---------------------------------------------------------------------------

/// Status apakah API key sudah tersimpan (untuk banner di halaman chat).
final apiKeySavedProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(apiKeyStoreProvider).read();
  return key != null && key.isNotEmpty;
});

/// State percakapan: daftar pesan, indikator "mengetik", dan pesan error.
class AssistantChatState {
  const AssistantChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  final List<AssistantMessage> messages;
  final bool isSending;

  /// Pesan kegagalan siap tampil; `null` bila tidak ada error.
  final String? error;

  AssistantChatState copyWith({
    List<AssistantMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return AssistantChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier percakapan. Semua aturan bisnis ada di [AskAssistant]; notifier
/// hanya mengelola urutan pesan dan status UI.
class AssistantChatNotifier extends Notifier<AssistantChatState> {
  @override
  AssistantChatState build() => const AssistantChatState();

  /// Kirim pertanyaan. `contextLines` berisi judul pengumuman lokal yang
  /// sudah diformat halaman (bukan entity fitur lain) — domain asisten
  /// tetap tidak bergantung pada fitur announcements.
  Future<void> send(
    String question, {
    List<String> contextLines = const [],
  }) async {
    if (state.isSending) return;

    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(error: 'Pertanyaan tidak boleh kosong.');
      return;
    }

    // Gelembung pengguna tampil segera supaya UI terasa responsif;
    // indikator "mengetik" menyusul selama menunggu API.
    final withQuestion = [
      ...state.messages,
      AssistantMessage(role: AssistantRole.user, text: trimmed),
    ];
    state = AssistantChatState(messages: withQuestion, isSending: true);

    final result = await ref
        .read(askAssistantProvider)
        .call(question: trimmed, contextLines: contextLines);

    if (result.failure != null) {
      state = state.copyWith(isSending: false, error: result.failure!.message);
      return;
    }

    state = AssistantChatState(
      messages: [
        ...withQuestion,
        AssistantMessage(role: AssistantRole.assistant, text: result.reply),
      ],
    );
  }

  /// Hapus percakapan + error (tombol "Chat baru").
  void clear() => state = const AssistantChatState();
}

final assistantChatProvider =
    NotifierProvider<AssistantChatNotifier, AssistantChatState>(
      AssistantChatNotifier.new,
    );
