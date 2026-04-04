import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mongolite/data/repositories/mongo_repository.dart';
import 'package:mongolite/domain/models/mongo_collection.dart';
import 'package:mongolite/domain/models/mongo_database.dart';
import 'package:mongolite/presentation/providers/database_provider.dart';

import 'database_provider_test.mocks.dart';

@GenerateMocks([MongoRepository])
void main() {
  group('DatabaseProvider', () {
    late MongoRepository mockRepository;
    late DatabaseProvider provider;

    setUp(() {
      mockRepository = MockMongoRepository();
      provider = DatabaseProvider(repository: mockRepository);
    });

    test('initial state is empty', () {
      expect(provider.databases, isEmpty);
      expect(provider.collections, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadDatabases fetches and stores databases', () async {
      final databases = [
        const MongoDatabaseInfo(name: 'admin', empty: false),
        const MongoDatabaseInfo(name: 'mydb', empty: false),
      ];
      when(mockRepository.getDatabases()).thenAnswer((_) async => databases);

      await provider.loadDatabases();

      expect(provider.databases.length, 2);
      expect(provider.databases[0].name, 'admin');
      expect(provider.databases[1].name, 'mydb');
      expect(provider.error, isNull);
    });

    test('loadDatabases sets error on failure', () async {
      when(mockRepository.getDatabases())
          .thenThrow(Exception('Network error'));

      await provider.loadDatabases();

      expect(provider.databases, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Network error'));
    });

    test('loadCollections fetches collections for a database', () async {
      final collections = [
        const MongoCollectionInfo(databaseName: 'mydb', name: 'users'),
        const MongoCollectionInfo(databaseName: 'mydb', name: 'orders'),
      ];
      when(mockRepository.getCollections('mydb'))
          .thenAnswer((_) async => collections);

      await provider.loadCollections('mydb');

      expect(provider.collections.length, 2);
      expect(provider.collections[0].name, 'users');
      expect(provider.collections[1].name, 'orders');
    });

    test('loadCollections sets error on failure', () async {
      when(mockRepository.getCollections('mydb'))
          .thenThrow(Exception('Auth failed'));

      await provider.loadCollections('mydb');

      expect(provider.collections, isEmpty);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Auth failed'));
    });

    test('clearData removes all data', () async {
      when(mockRepository.getDatabases()).thenAnswer((_) async => [
            const MongoDatabaseInfo(name: 'admin', empty: false),
          ]);
      when(mockRepository.getCollections('admin')).thenAnswer((_) async => [
            const MongoCollectionInfo(databaseName: 'admin', name: 'system.users'),
          ]);

      await provider.loadDatabases();
      await provider.loadCollections('admin');

      provider.clearData();

      expect(provider.databases, isEmpty);
      expect(provider.collections, isEmpty);
      expect(provider.error, isNull);
    });
  });
}
