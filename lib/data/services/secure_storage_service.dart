import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyConnectionUri = 'mongo_connection_uri';
  static const _keyConnectionAlias = 'mongo_connection_alias';

  Future<void> saveConnectionConfig({required String uri, String? alias}) async {
    await _storage.write(key: _keyConnectionUri, value: uri);
    await _storage.write(key: _keyConnectionAlias, value: alias ?? '');
  }

  Future<Map<String, String?>> loadConnectionConfig() async {
    final uri = await _storage.read(key: _keyConnectionUri);
    final alias = await _storage.read(key: _keyConnectionAlias);
    return {'uri': uri, 'alias': alias};
  }

  Future<void> clearConnectionConfig() async {
    await _storage.delete(key: _keyConnectionUri);
    await _storage.delete(key: _keyConnectionAlias);
  }

  Future<bool> hasSavedConnection() async {
    return (await _storage.read(key: _keyConnectionUri)) != null;
  }
}
