import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week11_performance_optimization/core/failures.dart';
import 'package:week11_performance_optimization/features/assistant/data/datasources/api_key_store.dart';
import 'package:week11_performance_optimization/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:week11_performance_optimization/features/assistant/presentation/pages/assistant_page.dart';
import 'package:week11_performance_optimization/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:week11_performance_optimization/features/announcements/presentation/providers/announcements_providers.dart';

/// Secure storage palsu di memori.
class _FakeApiKeyStore extends ApiKeyStore {
  _FakeApiKeyStore([this._value]);

  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> save(String value) async => _value = value;
}

/// Repository palsu: jawaban instan.
class _FakeRepository implements AssistantRepository {
  _FakeRepository({this.failure});

  static const _defaultReply = 'UAS digelar 8-19 Desember.';
  final Failure? failure;

  @override
  Future<({String reply, Failure? failure})> ask({
    required String system,
    required String question,
    required String context,
  }) async {
    return failure != null
        ? (reply: '', failure: failure)
        : (reply: _defaultReply, failure: null);
  }
}

/// Repository lambat: menahan jawaban sampai completer selesai, untuk
/// membuktikan indikator "mengetik" tampil selama menunggu API.
class _DelayedRepository implements AssistantRepository {
  final completer = Completer<({String reply, Failure? failure})>();

  @override
  Future<({String reply, Failure? failure})> ask({
    required String system,
    required String question,
    required String context,
  }) {
    return completer.future;
  }
}

Widget _wrap({required AssistantRepository repository, ApiKeyStore? store}) {
  return ProviderScope(
    overrides: [
      assistantRepositoryProvider.overrideWithValue(repository),
      apiKeyStoreProvider.overrideWithValue(store ?? _FakeApiKeyStore('key')),
      announcementsProvider.overrideWith((ref) async => const []),
    ],
    child: const MaterialApp(home: AssistantPage()),
  );
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('chat-field')), text);
  await tester.tap(find.byKey(const Key('send-button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('belum ada percakapan menampilkan empty state + saran', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(), store: _FakeApiKeyStore()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tanya Asisten Kampus'), findsOneWidget);
    // Chip saran pertanyaan tersedia.
    expect(find.text('Kapan UAS dimulai?'), findsOneWidget);
    expect(find.byKey(const Key('chat-list')), findsNothing);
  });

  testWidgets('API key belum diatur memunculkan banner pengaturan', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(), store: _FakeApiKeyStore()),
    );
    await tester.pumpAndSettle();

    expect(find.text('API key belum diatur'), findsOneWidget);
    expect(find.text('Atur'), findsOneWidget);
  });

  testWidgets('API key sudah tersimpan tidak menampilkan banner', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository: _FakeRepository()));
    await tester.pumpAndSettle();

    expect(find.text('API key belum diatur'), findsNothing);
  });

  testWidgets('mengirim pertanyaan menampilkan gelembung user + jawaban', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await _type(tester, 'Kapan UAS dimulai?');

    expect(find.text('Kapan UAS dimulai?'), findsOneWidget);
    expect(find.text('UAS digelar 8-19 Desember.'), findsOneWidget);
    expect(find.byKey(const Key('chat-list')), findsOneWidget);
    // Empty state hilang setelah percakapan dimulai.
    expect(find.text('Tanya Asisten Kampus'), findsNothing);
  });

  testWidgets('indikator mengetik tampil selama menunggu respons', (
    tester,
  ) async {
    final delayed = _DelayedRepository();
    await tester.pumpWidget(_wrap(repository: delayed));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('chat-field')), 'Halo');
    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pump(); // tanpa settle: respons masih dijeda.

    expect(find.text('Halo'), findsOneWidget);
    expect(find.text('Asisten mengetik...'), findsOneWidget);

    // Selesaikan respons: gelembung jawaban menggantikan indikator.
    delayed.completer.complete((reply: 'Halo juga!', failure: null));
    await tester.pumpAndSettle();

    expect(find.text('Asisten mengetik...'), findsNothing);
    expect(find.text('Halo juga!'), findsOneWidget);
  });

  testWidgets('kegagalan API menampilkan pesan ramah + tombol coba lagi', (
    tester,
  ) async {
    const failure = NetworkFailure(
      'Kuota layanan AI sedang penuh (rate limit). Tunggu sebentar lalu '
      'coba lagi, atau gunakan pencarian pengumuman.',
    );
    await tester.pumpWidget(
      _wrap(repository: _FakeRepository(failure: failure)),
    );
    await tester.pumpAndSettle();
    await _type(tester, 'Kapan UAS?');

    expect(find.textContaining('Kuota layanan AI'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    // Pertanyaan tetap tercatat sebagai gelembung user.
    expect(find.text('Kapan UAS?'), findsOneWidget);
  });

  testWidgets('input kosong memunculkan pesan validasi tanpa gelembung', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(repository: _FakeRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('send-button')));
    await tester.pumpAndSettle();

    expect(find.text('Pertanyaan tidak boleh kosong.'), findsOneWidget);
    // Tidak ada gelembung percakapan yang tercipta.
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('tombol chat baru mengosongkan percakapan', (tester) async {
    await tester.pumpWidget(_wrap(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await _type(tester, 'Kapan UAS?');
    expect(find.text('UAS digelar 8-19 Desember.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-chat-button')));
    await tester.pumpAndSettle();

    expect(find.text('UAS digelar 8-19 Desember.'), findsNothing);
    expect(find.text('Tanya Asisten Kampus'), findsOneWidget);
  });
}
