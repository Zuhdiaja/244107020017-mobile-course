import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan API key layanan AI.
///
/// Kunci API tidak pernah ditulis di kode sumber (aturan codelab Minggu 10):
/// pengguna memasukkannya lewat halaman Pengaturan AI, dan nilainya disimpan
/// di `flutter_secure_storage` — penyimpanan yang sama dengan token sesi.
/// Kelas ini berada di layer `data` karena tahu detail teknis storage.
class ApiKeyStore {
  ApiKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _apiKey = 'ai_api_key';

  Future<String?> read() => _storage.read(key: _apiKey);

  Future<void> save(String value) => _storage.write(key: _apiKey, value: value);

  Future<void> clear() => _storage.delete(key: _apiKey);
}
