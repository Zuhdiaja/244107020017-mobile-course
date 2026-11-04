import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/features/assistant/data/models/gemini_response_model.dart';

void main() {
  test('menggabungkan seluruh parts kandidat pertama', () {
    final model = GeminiResponseModel.fromJson({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'UAS mulai 8 Desember. '},
              {'text': 'Cek portal akademik.'},
            ],
          },
        },
      ],
    });

    expect(model.text, 'UAS mulai 8 Desember. \nCek portal akademik.');
    expect(model.hasUsableText, isTrue);
  });

  test('promptFeedback.blockReason membuat jawaban tidak layak tampil', () {
    final model = GeminiResponseModel.fromJson({
      'promptFeedback': {'blockReason': 'SAFETY'},
      'candidates': const [],
    });

    expect(model.blockReason, 'SAFETY');
    expect(model.hasUsableText, isFalse);
  });

  test('payload kosong / tanpa kandidat menghasilkan teks kosong', () {
    final model = GeminiResponseModel.fromJson(const {});
    expect(model.text, isEmpty);
    expect(model.hasUsableText, isFalse);
  });
}
