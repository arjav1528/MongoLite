import 'package:flutter_test/flutter_test.dart';
import 'package:mongolite/domain/models/connection_config.dart';

void main() {
  group('ConnectionConfig', () {
    test('stores uri and optional alias', () {
      final config = ConnectionConfig(
        uri: 'mongodb://localhost:27017/testdb',
        alias: 'mydb',
      );

      expect(config.uri, 'mongodb://localhost:27017/testdb');
      expect(config.alias, 'mydb');
      expect(config.lastConnected, isNull);
    });

    test('obfuscates uri with user credentials', () {
      final config = ConnectionConfig(
        uri: 'mongodb://admin:secret123@cluster0.mongodb.net/testdb',
      );

      expect(config.obfuscatedUri, isNot(contains('secret123')));
      expect(config.obfuscatedUri, contains('admin:****'));
      expect(config.obfuscatedUri, contains('cluster0.mongodb.net'));
    });

    test('returns original uri when no credentials', () {
      final config = ConnectionConfig(
        uri: 'mongodb://localhost:27017/testdb',
      );

      expect(config.obfuscatedUri, config.uri);
    });

    test('copyWith updates only provided fields', () {
      final config = ConnectionConfig(
        uri: 'mongodb://localhost:27017/db1',
        alias: 'alias1',
      );

      final updated = config.copyWith(uri: 'mongodb://localhost:27017/db2');

      expect(updated.uri, 'mongodb://localhost:27017/db2');
      expect(updated.alias, 'alias1');

      final updatedAlias = config.copyWith(alias: 'alias2');
      expect(updatedAlias.uri, config.uri);
      expect(updatedAlias.alias, 'alias2');
    });
  });
}
