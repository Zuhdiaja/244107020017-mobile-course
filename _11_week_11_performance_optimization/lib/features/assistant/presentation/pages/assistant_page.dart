import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../../../announcements/presentation/providers/announcements_providers.dart';
import '../../domain/entities/assistant_message.dart';
import '../providers/assistant_providers.dart';

/// Halaman chat asisten kampus (fitur AI Minggu 10).
///
/// Halaman ini hanya: (1) menampung input, (2) meneruskan pertanyaan ke
/// notifier, (3) menggambar gelembung pesan, indikator mengetik, error, dan
/// empty state. Validasi, prompt, dan batas biaya hidup di domain.
///
/// Konteks yang dikirim ke AI hanya judul + tanggal pengumuman lokal —
/// tidak ada NIK, email, atau token (aturan privasi codelab).
///
/// Optimasi Minggu 11 — halaman tidak lagi mengamati state chat secara
/// utuh, melainkan dipecah menjadi tiga zona yang berlangganan irisan state
/// masing-masing lewat `select`:
/// - [_ChatMessages] hanya rebuild saat daftar pesan / status mengetik
///   berubah — perubahan pesan error saja tidak menyapu daftar chat.
/// - [_ChatComposer] hanya rebuild saat `isSending` berganti — pesan baru
///   masuk tidak lagi membangun ulang TextField (posisi kursor aman).
/// - [_ErrorBannerSlot] hanya muncul/menyusun ulang saat pesan error berubah.
/// Dulu seluruh `Scaffold` rebuild pada SETIAP perubahan state chat.
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Baris konteks untuk prompt AI. Minggu 11: pembentukan baris dipindah
  /// ke [announcementContextLinesProvider] — dihitung hanya saat daftar
  /// pengumuman berubah, bukan setiap kali pengguna mengirim chat.
  List<String> _contextLines() => ref.read(announcementContextLinesProvider);

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      // Validasi ringan di UI supaya pengguna dapat umpan balik instan;
      // aturan sebenarnya tetap di use case.
      ref
          .read(assistantChatProvider.notifier)
          .send(''); // memicu pesan "Pertanyaan tidak boleh kosong."
      return;
    }
    _controller.clear();
    await ref
        .read(assistantChatProvider.notifier)
        .send(text, contextLines: _contextLines());
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen TIDAK memicu rebuild — hanya menggulir saat ada pesan baru
    // atau indikator mengetik muncul.
    ref.listen(assistantChatProvider, (previous, next) {
      final previousCount = previous?.messages.length ?? -1;
      if (next.messages.length != previousCount || next.isSending) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asisten Kampus'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('clear-chat-button'),
            tooltip: 'Chat baru',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {
              _controller.clear();
              ref.read(assistantChatProvider.notifier).clear();
            },
          ),
          IconButton(
            key: const Key('open-settings-button'),
            tooltip: 'Pengaturan AI',
            icon: const Icon(Icons.vpn_key_outlined),
            onPressed: () => context.go(AppRoutes.assistantSettings),
          ),
        ],
      ),
      body: Column(
        children: [
          const _ApiKeyBanner(),
          Expanded(
            child: _ChatMessages(controller: _controller, onSend: _send),
          ),
          _ErrorBannerSlot(onRetry: _send),
          SafeArea(
            top: false,
            child: _ChatComposer(controller: _controller, onSend: _send),
          ),
        ],
      ),
    );
  }
}

/// Banner ramah saat API key belum diatur — jalan keluar tanpa menebak.
/// Mengamati status key sendiri sehingga halaman chat tidak ikut rebuild
/// saat status key selesai dimuat.
class _ApiKeyBanner extends ConsumerWidget {
  const _ApiKeyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keySaved = ref.watch(
      apiKeySavedProvider.select((state) => state.value),
    );
    if (keySaved != false) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.secondaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.info_outline,
          color: colorScheme.onSecondaryContainer,
        ),
        title: const Text('API key belum diatur'),
        subtitle: const Text('Fitur AI butuh key dari Google AI Studio.'),
        trailing: TextButton(
          onPressed: () => context.go(AppRoutes.assistantSettings),
          child: const Text('Atur'),
        ),
      ),
    );
  }
}

/// Daftar pesan + empty state. Hanya rebuild saat pasangan
/// `(messages, isSending)` berubah — pesan error yang berganti sendirian
/// tidak memicu pembangunan ulang daftar.
class _ChatMessages extends ConsumerWidget {
  const _ChatMessages({required this.controller, required this.onSend});

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (messages, isSending) = ref.watch(
      assistantChatProvider.select(
        (state) => (state.messages, state.isSending),
      ),
    );

    if (messages.isEmpty && !isSending) {
      return _EmptyState(controller: controller);
    }
    return ListView.builder(
      key: const Key('chat-list'),
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= messages.length) {
          return const _TypingBubble();
        }
        return RepaintBoundary(
          child: _MessageBubble(message: messages[index]),
        );
      },
    );
  }
}

/// Zona input kirim pesan. Mengamati HANYA `isSending`, sehingga pesan baru
/// atau error tidak membangun ulang TextField dan tombol kirim.
class _ChatComposer extends ConsumerWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSending = ref.watch(
      assistantChatProvider.select((state) => state.isSending),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const Key('chat-field'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Tanya jadwal, beasiswa, pengumuman...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('send-button'),
            tooltip: 'Kirim',
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

/// Empty state + saran pertanyaan agar pengguna tahu fitur ini bisa apa.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller});

  final TextEditingController controller;

  static const _suggestions = [
    'Kapan UAS dimulai?',
    'Ada beasiswa apa?',
    'Kapan kelas pengganti?',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tanya Asisten Kampus',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Jawaban memakai konteks judul pengumuman kampus. '
              'Data pribadi tidak pernah dikirim ke AI.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in _suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => controller.text = suggestion,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu gelembung pesan; pengguna di kanan, asisten di kiri.
/// Dibungkus RepaintBoundary di pemanggil agar paint gelembung tidak
/// menyapu seluruh list saat scroll atau indikator mengetik berkedip.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = message.role == AssistantRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(message.text),
      ),
    );
  }
}

/// Indikator "asisten sedang mengetik" selama menunggu respons API.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Asisten mengetik...',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slot banner error: mengamati hanya pesan error, lalu menyerahkan
/// penggambaran ke [_ErrorBanner] bila ada.
class _ErrorBannerSlot extends ConsumerWidget {
  const _ErrorBannerSlot({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(
      assistantChatProvider.select((state) => state.error),
    );
    if (error == null) return const SizedBox.shrink();
    return _ErrorBanner(
      message: error,
      color: Theme.of(context).colorScheme.error,
      onRetry: onRetry,
    );
  }
}

/// Error state dengan opsi coba lagi (fallback codelab) — bukan crash.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.color,
    required this.onRetry,
  });

  final String message;
  final Color color;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
