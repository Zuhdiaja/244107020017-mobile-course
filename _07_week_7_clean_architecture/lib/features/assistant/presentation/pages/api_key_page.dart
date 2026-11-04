import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../providers/assistant_providers.dart';

/// Halaman Pengaturan AI: menyimpan API key ke secure storage.
///
/// Sesuai aturan codelab, key tidak pernah ditulis di kode sumber dan tidak
/// ditampilkan utuh setelah tersimpan. Halaman ini tidak memanggil API —
/// hanya menyimpan/menghapus kredensial.
class ApiKeyPage extends ConsumerStatefulWidget {
  const ApiKeyPage({super.key});

  @override
  ConsumerState<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends ConsumerState<ApiKeyPage> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      _showMessage('API key tidak boleh kosong.');
      return;
    }
    await ref.read(apiKeyStoreProvider).save(value);
    // Segarkan status agar banner di halaman chat langsung hilang.
    ref.invalidate(apiKeySavedProvider);
    _controller.clear();
    if (!mounted) return;
    _showMessage('API key tersimpan di secure storage.');
  }

  Future<void> _clear() async {
    await ref.read(apiKeyStoreProvider).clear();
    ref.invalidate(apiKeySavedProvider);
    _controller.clear();
    if (!mounted) return;
    _showMessage('API key dihapus.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(apiKeySavedProvider).value;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan AI'),
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Kembali ke chat',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.assistant),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        saved == true ? Icons.lock : Icons.lock_open,
                        size: 18,
                        color: saved == true
                            ? Colors.green
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        saved == true
                            ? 'API key tersimpan'
                            : 'API key belum diatur',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('api-key-field'),
                    controller: _controller,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Gemini API key',
                      hintText: 'Tempel key dari aistudio.google.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilledButton.icon(
                        key: const Key('save-key-button'),
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Simpan'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        key: const Key('clear-key-button'),
                        onPressed: saved == true ? _clear : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cara mendapatkan key (gratis)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Buka aistudio.google.com lalu login akun Google.\n'
                    '2. Pilih "Get API key" dan buat key baru.\n'
                    '3. Tempel di kolom atas, lalu Simpan.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Privasi & biaya',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Key hanya disimpan di secure storage perangkat. '
                    'Percakapan mengirim pertanyaan + judul pengumuman '
                    'kampus — tanpa NIK, email, atau token sesi. '
                    'Gunakan tier gratis; aplikasi membatasi 20 pertanyaan '
                    'per sesi untuk menahan biaya.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
