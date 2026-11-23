import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week12_testing_quality_assurance/features/assistant/data/datasources/api_key_store.dart';
import 'package:week12_testing_quality_assurance/features/assistant/presentation/pages/api_key_page.dart';
import 'package:week12_testing_quality_assurance/features/assistant/presentation/providers/assistant_providers.dart';

/// Penyimpanan API key palsu di memori — `flutter_secure_storage` tidak
/// disentuh sama sekali di test.
class _FakeApiKeyStore extends ApiKeyStore {
  _FakeApiKeyStore({String? value, String? model}) {
    _value = value;
    _model = model;
  }

  String? _value;
  String? _model;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> save(String value) async {
    saveCalls++;
    _value = value;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    _value = null;
  }

  @override
  Future<String?> readModel() async => _model;

  @override
  Future<void> saveModel(String value) async => _model = value;
}

Future<void> _pumpPage(WidgetTester tester, _FakeApiKeyStore store) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiKeyStoreProvider.overrideWithValue(store)],
      child: const MaterialApp(home: ApiKeyPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ApiKeyPage — validasi input', () {
    testWidgets('key kosong ditolak dengan pesan, tanpa menyimpan', (
      tester,
    ) async {
      final store = _FakeApiKeyStore();
      await _pumpPage(tester, store);

      await tester.tap(find.byKey(const Key('save-key-button')));
      await tester.pumpAndSettle();

      expect(find.text('API key tidak boleh kosong.'), findsOneWidget);
      expect(store.saveCalls, 0);
    });

    testWidgets('key berisi spasi saja juga ditolak', (tester) async {
      final store = _FakeApiKeyStore();
      await _pumpPage(tester, store);

      await tester.enterText(find.byKey(const Key('api-key-field')), '   ');
      await tester.tap(find.byKey(const Key('save-key-button')));
      await tester.pumpAndSettle();

      expect(find.text('API key tidak boleh kosong.'), findsOneWidget);
      expect(store.saveCalls, 0);
    });
  });

  group('ApiKeyPage — simpan dan hapus', () {
    testWidgets('key valid disimpan dan status berubah jadi tersimpan', (
      tester,
    ) async {
      final store = _FakeApiKeyStore();
      await _pumpPage(tester, store);

      expect(find.text('API key belum diatur'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('api-key-field')),
        '  AIza-test-key  ',
      );
      await tester.tap(find.byKey(const Key('save-key-button')));
      await tester.pumpAndSettle();

      // Disimpan dalam bentuk terpangkas.
      expect(store.saveCalls, 1);
      expect(store._value, 'AIza-test-key');
      expect(find.text('API key tersimpan'), findsOneWidget);
      expect(find.text('API key tersimpan di secure storage.'), findsOneWidget);
    });

    testWidgets('tombol hapus nonaktif saat belum ada key', (tester) async {
      await _pumpPage(tester, _FakeApiKeyStore());

      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('clear-key-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('hapus key mengosongkan penyimpanan dan status', (
      tester,
    ) async {
      final store = _FakeApiKeyStore(value: 'AIza-lama');
      await _pumpPage(tester, store);

      expect(find.text('API key tersimpan'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clear-key-button')));
      await tester.pumpAndSettle();

      expect(store.clearCalls, 1);
      expect(store._value, isNull);
      expect(find.text('API key dihapus.'), findsOneWidget);
      expect(find.text('API key belum diatur'), findsOneWidget);
    });

    testWidgets('model tersimpan dimuat ke kolom model', (tester) async {
      await _pumpPage(
        tester,
        _FakeApiKeyStore(value: 'AIza-test', model: 'gemini-2.5-flash'),
      );

      final field = tester.widget<TextField>(
        find.byKey(const Key('model-field')),
      );
      expect(field.controller!.text, 'gemini-2.5-flash');
    });
  });
}
