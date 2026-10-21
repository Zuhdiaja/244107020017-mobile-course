import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sumber data lokal: penyimpanan token yang aman.
///
/// Berada di layer `data` karena ia tahu detail teknis
/// (`flutter_secure_storage`). Domain tidak pernah menyentuh kelas ini.
///
/// Method di sini sengaja melempar exception bila gagal; repository
/// (`AuthRepositoryImpl`) yang menangkapnya dan mengubahnya menjadi [Failure].
/// Dengan begitu exception tidak pernah bocor sampai presentation.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);
  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> clear() => _storage.deleteAll();
}
