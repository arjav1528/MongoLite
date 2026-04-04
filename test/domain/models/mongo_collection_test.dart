import 'package:flutter_test/flutter_test.dart';
import 'package:mongolite/domain/models/mongo_collection.dart';

void main() {
  group('MongoCollectionInfo', () {
    test('stores all required fields', () {
      final col = MongoCollectionInfo(
        databaseName: 'mydb',
        name: 'users',
        documentCount: 150,
        storageSize: 2048.0,
      );

      expect(col.databaseName, 'mydb');
      expect(col.name, 'users');
      expect(col.documentCount, 150);
      expect(col.storageSize, 2048.0);
    });

    test('fullName concatenates database and collection', () {
      final col = MongoCollectionInfo(
        databaseName: 'mydb',
        name: 'users',
      );

      expect(col.fullName, 'mydb.users');
    });

    test('documentCount and storageSize are optional', () {
      final col = MongoCollectionInfo(
        databaseName: 'db',
        name: 'col',
      );

      expect(col.documentCount, isNull);
      expect(col.storageSize, isNull);
    });
  });
}
