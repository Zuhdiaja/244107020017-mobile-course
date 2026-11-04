import 'package:flutter_test/flutter_test.dart';
import 'package:week7_clean_architecture/core/failures.dart';
import 'package:week7_clean_architecture/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:week7_clean_architecture/features/assistant/domain/usecases/ask_assistant.dart';

/// Repository palsu: mencatat argumen yang diterima dan mengembalikan
/// jawaban tetap. Tidak ada jaringan, tidak ada API key.
class _FakeRepository implements AssistantRepository {
  _FakeRepository({this.reply = 'Jawaban uji.'});

  final String reply;
  String? capturedSystem;
  String? capturedQuestion;
  String? capturedContext;
  int calls = 0;

  @override
  Future<({String reply, Failure? failure})> ask({
    required String system,
    required String question,
    required String context,
  }) async {
    calls += 1;
    capturedSystem = system;
    capturedQuestion = question;
    capturedContext = context;
    return (reply: reply, failure: null);
  }
}

void main() {
  group('AskAssistant — validasi (mitigasi biaya & input)', () {
    test('pertanyaan kosong ditolak tanpa memanggil repository', () async {
      final repository = _FakeRepository();
      final result = await AskAssistant(repository)(
        question: '   ',
        contextLines: const [],
      );

      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure!.message, 'Pertanyaan tidak boleh kosong.');
      expect(repository.calls, 0);
    });

    test('pertanyaan lebih dari 500 karakter ditolak', () async {
      final repository = _FakeRepository();
      final result = await AskAssistant(repository)(
        question: 'a' * (AskAssistant.maxQuestionLength + 1),
        contextLines: const [],
      );

      expect(result.failure, isA<ValidationFailure>());
      expect(result.failure!.message, contains('terlalu panjang'));
      expect(repository.calls, 0);
    });

    test('batas pertanyaan per sesi ditegakkan', () async {
      final repository = _FakeRepository();
      final usecase = AskAssistant(repository, sessionLimit: 2);

      final first = await usecase(question: 'satu', contextLines: const []);
      final second = await usecase(question: 'dua', contextLines: const []);
      final third = await usecase(question: 'tiga', contextLines: const []);

      expect(first.failure, isNull);
      expect(second.failure, isNull);
      expect(third.failure, isA<NetworkFailure>());
      expect(third.failure!.message, contains('Batas pertanyaan'));
      expect(repository.calls, 2);
    });
  });

  group('AskAssistant — prompt design', () {
    test('system prompt, pertanyaan terpangkas, dan konteks dikirim', () async {
      final repository = _FakeRepository(reply: 'UAS mulai 8 Desember.');
      final result = await AskAssistant(repository)(
        question: '  Kapan UAS?  ',
        contextLines: const [
          'Ujian Akhir Semester Ganjil (2026-11-10)',
          'Beasiswa BPP-TI 2026 (2026-10-15)',
        ],
      );

      expect(result.reply, 'UAS mulai 8 Desember.');
      expect(repository.capturedSystem, AskAssistant.systemPrompt);
      expect(repository.capturedQuestion, 'Kapan UAS?');
      expect(repository.capturedContext, contains('Ujian Akhir Semester'));
      // System prompt memuat batas privasi + bahasa (syarat codelab).
      expect(repository.capturedSystem, contains('Bahasa Indonesia'));
      expect(repository.capturedSystem, contains('data pribadi'));
    });

    test('buildContext membatasi jumlah baris dan menangani daftar kosong', () {
      final many = List.generate(10, (i) => 'Judul $i');
      final context = AskAssistant.buildContext(many);

      expect(context, contains('Judul 0'));
      expect(context, contains('Judul 4'));
      expect(context, isNot(contains('Judul 5')));
      expect(
        AskAssistant.buildContext(const []),
        contains('Belum ada pengumuman'),
      );
    });
  });
}
