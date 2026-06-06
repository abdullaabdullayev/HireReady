import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT access + refresh tokens in the platform secure store.
class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kName = 'user_name';

  static Future<void> save(String access, String refresh) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  static Future<void> saveAccess(String access) =>
      _storage.write(key: _kAccess, value: access);

  static Future<void> saveName(String name) =>
      _storage.write(key: _kName, value: name);

  static Future<String?> get accessToken => _storage.read(key: _kAccess);
  static Future<String?> get refreshToken => _storage.read(key: _kRefresh);
  static Future<String?> get userName => _storage.read(key: _kName);

  static Future<bool> get isLoggedIn async => (await accessToken) != null;

  static Future<void> clear() => _storage.deleteAll();
}
