import '../../../../core/failures.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/api_key_store.dart';
import '../datasources/assistant_api_errors.dart';
import '../datasources/gemini_api_client.dart';

/// Implementasi repository asisten AI di atas Gemini API.
///
/// Tanggung jawab:
/// - memastikan API key tersedia (bila belum, kembalikan [ValidationFailure]
///   dengan arahan ke Pengaturan AI — tidak pernah melempar exception);
/// - memanggil client, lalu mengubah exception menjadi [Failure] agar
///   presentation cukup menampilkan `failure.message` (pola fitur auth).
class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl({required this.client, required this.apiKeyStore});

  final GeminiApiClient client;
  final ApiKeyStore apiKeyStore;

  @override
  Future<({String reply, Failure? failure})> ask({
    required String system,
    required String question,
    required String context,
  }) async {
    final apiKey = await apiKeyStore.read();
    if (apiKey == null || apiKey.isEmpty) {
      return (
        reply: '',
        failure: const ValidationFailure(
          'API key belum diatur. Buka menu Pengaturan AI (ikon kunci) lalu '
          'tempel key dari Google AI Studio.',
        ),
      );
    }

    // Model pilihan pengguna; kosong berarti default. Memungkinkan ganti
    // model free-tier tanpa menyentuh kode (janji tabel risiko README).
    final storedModel = await apiKeyStore.readModel();
    final model = (storedModel == null || storedModel.trim().isEmpty)
        ? GeminiApiClientDio.defaultModel
        : storedModel.trim();

    try {
      final reply = await client.generateText(
        apiKey: apiKey,
        model: model,
        system: system,
        question: question,
        context: context,
      );
      return (reply: reply, failure: null);
    } catch (e) {
      return (reply: '', failure: mapAssistantDioException(e));
    }
  }
}
