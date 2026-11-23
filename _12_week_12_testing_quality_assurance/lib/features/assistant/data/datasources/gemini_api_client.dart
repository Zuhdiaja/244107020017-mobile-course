import 'package:dio/dio.dart';

import '../models/gemini_response_model.dart';

/// Kontrak sumber data Gemini API.
///
/// Dibuat abstrak supaya repository bisa diuji dengan fake tanpa jaringan
/// (pola seam yang sama dengan [AssistantRepository]).
abstract class GeminiApiClient {
  Future<String> generateText({
    required String apiKey,
    required String model,
    required String system,
    required String question,
    required String context,
  });
}

/// Implementasi `GeminiApiClient` memakai Dio.
///
/// Endpoint: `POST {base}/models/{model}:generateContent?key=...`
/// (Google Generative Language API). API key dikirim sebagai query param —
/// nilainya datang dari [ApiKeyStore], tidak pernah di-hardcode.
///
/// Timeout sengaja diset (mitigasi risiko "API error/down" di codelab):
/// permintaan yang menggantung lebih baik gagal cepat lalu menampilkan
/// pesan ramah + tombol coba lagi daripada membiarkan UI menggantung.
class GeminiApiClientDio implements GeminiApiClient {
  GeminiApiClientDio({Dio? dio, String baseUrl = defaultBaseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  static const defaultBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Model default: flash-lite generasi terbaru — kuota gratisnya paling
  /// longgar dan latensinya kecil untuk chat singkat. Jawaban pendek
  /// (maks ~200 token) sesuai system prompt "maksimal 2 kalimat" sekaligus
  /// mitigasi biaya. Bisa diganti dari halaman Pengaturan AI.
  static const defaultModel = 'gemini-3.5-flash-lite';

  final Dio _dio;

  @override
  Future<String> generateText({
    required String apiKey,
    required String model,
    required String system,
    required String question,
    required String context,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/models/$model:generateContent',
      queryParameters: {'key': apiKey},
      data: {
        // System prompt terpisah dari isi percakapan (API Gemini mendukung).
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              // Konteks + pertanyaan dalam satu bagian: konteks berupa
              // judul pengumuman (data non-sensitif) milik aplikasi sendiri.
              {'text': '$context\n\nPertanyaan: $question'},
            ],
          },
        ],
        // Jawaban pendek = hemat token = mitigasi biaya (tabel risiko).
        'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 200},
      },
    );

    final body = response.data;
    if (body == null) {
      throw StateError('Respons Gemini kosong.');
    }
    final parsed = GeminiResponseModel.fromJson(body);
    if (parsed.blockReason != null) {
      throw StateError(
        'Permintaan diblokir safety filter: ${parsed.blockReason}',
      );
    }
    if (parsed.text.isEmpty) {
      throw StateError('Respons Gemini tidak berisi teks.');
    }
    return parsed.text;
  }
}
