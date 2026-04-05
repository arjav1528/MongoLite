import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mongolite/data/services/mongo_connection_service.dart';
import 'package:mongolite/data/services/secure_storage_service.dart';
import 'package:mongolite/presentation/providers/connection_provider.dart';

@GenerateMocks([MongoConnectionService, SecureStorageService, MongoRepository])
void main() {
  group('ConnectionProvider', () {
    late FakeMongoConnectionService fakeMongoService;
    late FakeSecureStorageService fakeStorageService;
    late ConnectionProvider provider;

    setUp(() {
      fakeMongoService = FakeMongoConnectionService();
      fakeStorageService = FakeSecureStorageService();
      provider = ConnectionProvider(
        mongoService: fakeMongoService,
        storageService: fakeStorageService,
      );
    });

    test('initial state is disconnected', () {
      expect(provider.state, ConnectionStateEnum.disconnected);
      expect(provider.isConnected, isFalse);
      expect(provider.error, isNull);
      expect(provider.config, isNull);
    });

    test('validInput returns true for valid connection string', () {
      expect(
        provider.validateInput('mongodb://localhost:27017/testdb'),
        isTrue,
      );
    });

    test('validInput returns false for invalid connection string', () {
      expect(provider.validateInput(''), isFalse);
      expect(provider.validateInput('http://example.com'), isFalse);
    });

    test('getValidationError returns null for valid string', () {
      expect(provider.getValidationError('mongodb://host/db'), isNull);
    });

    test('getValidationError returns error for invalid string', () {
      expect(provider.getValidationError(''), isNull,
          reason: 'empty returns null in validator');
      expect(
        provider.getValidationError('invalid'),
        contains('mongodb'),
      );
    });

    test('connect transitions to error for invalid URI', () async {
      await provider.connect('invalid-uri');

      expect(provider.state, ConnectionStateEnum.error);
      expect(provider.isConnected, isFalse);
    });

    test('connect succeeds and saves config', () async {
      fakeMongoService.simulateSuccess = true;

      await provider.connect('mongodb://localhost:27017/testdb');

      expect(provider.isConnected, isTrue);
      expect(provider.config, isNotNull);
      expect(provider.error, isNull);
      expect(provider.config!.uri, 'mongodb://localhost:27017/testdb');
      expect(fakeStorageService.savedUri, 'mongodb://localhost:27017/testdb');
    });

    test('connect fails on service and sets error', () async {
      fakeMongoService.simulateError = 'Connection refused';

      await provider.connect('mongodb://localhost:27017/testdb');

      expect(provider.state, ConnectionStateEnum.error);
      expect(provider.isConnected, isFalse);
      expect(provider.error, contains('Connection refused'));
    });

    test('disconnect clears state and config', () async {
      fakeMongoService.simulateSuccess = true;
      await provider.connect('mongodb://localhost:27017/testdb');
      expect(provider.isConnected, isTrue);

      await provider.disconnect();

      expect(provider.state, ConnectionStateEnum.disconnected);
      expect(provider.config, isNull);
      expect(provider.error, isNull);
    });

    test('loadSavedConnection sets config when saved', () async {
      fakeStorageService.savedUri = 'mongodb://localhost:27017/db';

      await provider.loadSavedConnection();

      expect(provider.config, isNotNull);
      expect(provider.config!.uri, 'mongodb://localhost:27017/db');
    });

    test('loadSavedConnection does nothing when nothing saved', () async {
      await provider.loadSavedConnection();

      expect(provider.config, isNull);
    });

    test('obfuscatedUri hides credentials from config', () async {
      fakeMongoService.simulateSuccess = true;
      await provider.connect('mongodb://user:password@host:27017/db');

      expect(provider.obfuscatedUri, isNot(contains('password')));
      expect(provider.obfuscatedUri, contains('user:****'));
    });
  });
}

class FakeMongoConnectionService extends Fake implements MongoConnectionService {
  bool simulateSuccess = false;
  String? simulateError;

  @override
  Future<void> connect(String uri) async {
    if (simulateError != null) throw Exception(simulateError);
    if (!simulateSuccess) throw Exception('Not configured');
  }

  @override
  bool get isConnected => simulateSuccess;

  @override
  Future<void> disconnect() async {
    simulateSuccess = false;
  }
}

class FakeSecureStorageService extends Fake implements SecureStorageService {
  String? savedUri;

  @override
  Future<void> saveConnectionConfig({required String uri, String? alias}) async {
    savedUri = uri;
  }

  @override
  Future<Map<String, String?>> loadConnectionConfig() async {
    return {'uri': savedUri, 'alias': null};
  }

  @override
  Future<void> clearConnectionConfig() async {
    savedUri = null;
  }

  @override
  Future<bool> hasSavedConnection() async => savedUri != null;
}
