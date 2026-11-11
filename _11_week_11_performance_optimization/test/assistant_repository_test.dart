import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week11_performance_optimization/core/failures.dart';
import 'package:week11_performance_optimization/features/assistant/data/datasources/api_key_store.dart';
import 'package:week11_performance_optimization/features/assistant/data/datasources/gemini_api_client.dart';
import 'package:week11_performance_optimization/features/assistant/data/repositories/assistant_repository_impl.dart';

/// Secure storage palsu di memori — plugin platform tidak disentuh di test.
class _FakeApiKeyStore extends ApiKeyStore {
  _FakeApiKeyStore([this._value]);

  String? _value;
  String? _model;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> save(String value) async => _value = value;

  @override
  Future<void> clear() async => _value = null;

  @override
  Future<String?> readModel() async => _model;

  @override
  Future<void> saveModel(String value) async => _model = value;
}

/// Client Gemini palsu: merekam API key + model, melempar error bila diminta.
class _FakeClient implements GeminiApiClient {
  _FakeClient({this.reply = 'Jawaban palsu.', this.error});

  final String reply;
  final Object? error;
  String? capturedApiKey;
  String? capturedModel;
  String? capturedModelSystem;
  int calls = 0;

  @override
  Future<String> generateText({
    required String apiKey,
    required String model,
    required String system,
    required String question,
    required String context,
  }) async {
    calls += 1;
    capturedApiKey = apiKey;
    capturedModel = model;
    capturedModelSystem = system;
    if (error != null) throw error!;
    return reply;
  }
}

DioException _dioError(int? statusCode, DioExceptionType type) {
  final options = RequestOptions(path: '/models/gemini-flash-latest');
  return DioException(
    requestOptions: options,
    type: type,
    response: statusCode == null
        ? null
        : Response<void>(requestOptions: options, statusCode: statusCode),
  );
}

void main() {
  group('AssistantRepositoryImpl — API key', () {
    test(
      'key belum diatur menghasilkan ValidationFailure tanpa panggilan',
      () async {
        final client = _FakeClient();
        final repository = AssistantRepositoryImpl(
          client: client,
          apiKeyStore: _FakeApiKeyStore(),
        );

        final result = await repository.ask(
          system: 'sistem',
          question: 'Kapan UAS?',
          context: 'konteks',
        );

        expect(result.failure, isA<ValidationFailure>());
        expect(result.failure!.message, contains('API key belum diatur'));
        expect(client.calls, 0);
      },
    );

    test('key tersimpan dipakai untuk memanggil client', () async {
      final client = _FakeClient(reply: 'UAS 8 Desember.');
      final repository = AssistantRepositoryImpl(
        client: client,
        apiKeyStore: _FakeApiKeyStore('AIza-test'),
      );

      final result = await repository.ask(
        system: 'kamu asisten',
        question: 'Kapan UAS?',
        context: 'konteks',
      );

      expect(result.failure, isNull);
      expect(result.reply, 'UAS 8 Desember.');
      expect(client.capturedApiKey, 'AIza-test');
      expect(client.capturedModelSystem, 'kamu asisten');
    });

    test('model tersimpan dipakai; kosong kembali ke default', () async {
      final store = _FakeApiKeyStore('AIza-test');
      await store.saveModel('gemini-2.5-flash');
      final client = _FakeClient();
      await AssistantRepositoryImpl(
        client: client,
        apiKeyStore: store,
      ).ask(system: 's', question: 'q', context: 'c');
      expect(client.capturedModel, 'gemini-2.5-flash');

      final defaultClient = _FakeClient();
      await AssistantRepositoryImpl(
        client: defaultClient,
        apiKeyStore: _FakeApiKeyStore('AIza-test'),
      ).ask(system: 's', question: 'q', context: 'c');
      expect(defaultClient.capturedModel, GeminiApiClientDio.defaultModel);
    });
  });

  group('AssistantRepositoryImpl — pemetaan error jaringan', () {
    Future<({String reply, Failure? failure})> askWith(Object error) {
      return AssistantRepositoryImpl(
        client: _FakeClient(error: error),
        apiKeyStore: _FakeApiKeyStore('AIza-test'),
      ).ask(system: 's', question: 'q', context: 'c');
    }

    test('429 menjadi pesan kuota/rate limit + fallback', () async {
      final result = await askWith(
        _dioError(429, DioExceptionType.badResponse),
      );

      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure!.message, contains('Kuota'));
      expect(result.failure!.message, contains('pencarian pengumuman'));
    });

    test('400/401/403 menjadi pesan API key tidak valid', () async {
      final result = await askWith(
        _dioError(400, DioExceptionType.badResponse),
      );

      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure!.message, contains('API key tidak valid'));
    });

    test('koneksi gagal menjadi pesan ramah', () async {
      final result = await askWith(
        _dioError(null, DioExceptionType.connectionError),
      );

      expect(result.failure, isA<NetworkFailure>());
      expect(result.failure!.message, contains('Tidak dapat terhubung'));
    });

    test('error tak dikenal menjadi UnknownFailure', () async {
      final result = await askWith(StateError('respons kosong'));

      expect(result.failure, isA<UnknownFailure>());
    });
  });
}
