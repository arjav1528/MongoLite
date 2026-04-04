import 'package:flutter/foundation.dart';

import '../../core/utils/connection_string_validator.dart';
import '../../data/services/mongo_connection_service.dart';
import '../../data/services/secure_storage_service.dart';
import '../../domain/models/connection_config.dart';

enum ConnectionStateEnum { disconnected, connecting, connected, error }

class ConnectionProvider extends ChangeNotifier {
  final MongoConnectionService _mongoService;
  final SecureStorageService _storageService;

  ConnectionStateEnum _state = ConnectionStateEnum.disconnected;
  String? _error;
  ConnectionConfig? _config;

  ConnectionProvider({required MongoConnectionService mongoService, required SecureStorageService storageService})
      : _mongoService = mongoService,
        _storageService = storageService;

  ConnectionStateEnum get state => _state;
  String? get error => _error;
  ConnectionConfig? get config => _config;
  String? get obfuscatedUri => _config?.obfuscatedUri;
  bool get isConnected => _state == ConnectionStateEnum.connected;

  bool validateInput(String uri) {
    final result = ConnectionStringValidator.validate(uri);
    return result.isValid;
  }

  String? getValidationError(String uri) {
    if (uri.isEmpty) return null;
    final result = ConnectionStringValidator.validate(uri);
    return result.isValid ? null : result.error;
  }

  Future<void> connect(String uri) async {
    final result = ConnectionStringValidator.validate(uri);
    if (!result.isValid) {
      _state = ConnectionStateEnum.error;
      _error = result.error;
      notifyListeners();
      return;
    }

    _state = ConnectionStateEnum.connecting;
    _error = null;
    notifyListeners();

    try {
      await _mongoService.connect(uri);
      _state = ConnectionStateEnum.connected;
      _config = ConnectionConfig(uri: uri, alias: null, lastConnected: DateTime.now());
      _error = null;
      await _storageService.saveConnectionConfig(uri: uri);
    } catch (e) {
      _state = ConnectionStateEnum.error;
      _error = 'Connection failed: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> disconnect() async {
    await _mongoService.disconnect();
    _state = ConnectionStateEnum.disconnected;
    _config = null;
    _error = null;
    notifyListeners();
  }

  Future<void> loadSavedConnection() async {
    final config = await _storageService.loadConnectionConfig();
    final uri = config['uri'];
    final alias = config['alias'];

    if (uri != null && uri.isNotEmpty) {
      _config = ConnectionConfig(
        uri: uri,
        alias: alias != null && alias.isNotEmpty ? alias : null,
      );
      notifyListeners();
    }
  }
}
