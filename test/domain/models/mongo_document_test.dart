import 'package:flutter_test/flutter_test.dart';
import 'package:mongolite/domain/models/mongo_document.dart';

void main() {
  group('MongoDocument', () {
    test('exposes _id from data', () {
      final doc = MongoDocument(
        databaseName: 'admin',
        collectionName: 'users',
        data: {'_id': 'abc123', 'name': 'Alice', 'age': 30},
        fetchedAt: DateTime(2026, 1, 1),
      );

      expect(doc.id, 'abc123');
    });

    test('returns null when _id is missing', () {
      final doc = MongoDocument(
        databaseName: 'admin',
        collectionName: 'users',
        data: {'name': 'Alice'},
        fetchedAt: DateTime(2026, 1, 1),
      );

      expect(doc.id, isNull);
    });

    test('returns raw data as Map', () {
      final data = {'_id': '123', 'key': 'value'};
      final doc = MongoDocument(
        databaseName: 'db',
        collectionName: 'col',
        data: data,
        fetchedAt: DateTime(2026, 1, 1),
      );

      expect(doc.toJson(), data);
    });

    test('stores database and collection names', () {
      final doc = MongoDocument(
        databaseName: 'mydb',
        collectionName: 'users',
        data: {},
        fetchedAt: DateTime.now(),
      );

      expect(doc.databaseName, 'mydb');
      expect(doc.collectionName, 'users');
    });
  });
}
