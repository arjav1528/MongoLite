import 'package:flutter_test/flutter_test.dart';
import 'package:mongolite/domain/models/mongo_database.dart';

void main() {
  group('MongoDatabaseInfo', () {
    test('stores name and required empty flag', () {
      final db = MongoDatabaseInfo(
        name: 'admin',
        empty: false,
        sizeOnDisk: 1024.0,
      );

      expect(db.name, 'admin');
      expect(db.empty, isFalse);
      expect(db.sizeOnDisk, 1024.0);
    });

    test('sizeOnDisk is optional', () {
      final db = MongoDatabaseInfo(name: 'testdb', empty: true);

      expect(db.name, 'testdb');
      expect(db.empty, isTrue);
      expect(db.sizeOnDisk, isNull);
    });
  });
}
