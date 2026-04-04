import 'package:flutter_test/flutter_test.dart';
import 'package:mongolite/core/utils/connection_string_validator.dart';

void main() {
  group('ConnectionStringValidator', () {
    test('validates empty string', () {
      final result = ConnectionStringValidator.validate('');
      expect(result.isValid, isFalse);
      expect(result.error, contains('empty'));
    });

    test('validates mongodb:// scheme with host', () {
      final result = ConnectionStringValidator.validate(
        'mongodb://localhost:27017/testdb',
      );
      expect(result.isValid, isTrue);
    });

    test('validates mongodb+srv:// scheme', () {
      final result = ConnectionStringValidator.validate(
        'mongodb+srv://user:pass@cluster.mongodb.net/testdb',
      );
      expect(result.isValid, isTrue);
    });

    test('accepts mongodb:// with credentials', () {
      final result = ConnectionStringValidator.validate(
        'mongodb://admin:secret@host:27017/admin',
      );
      expect(result.isValid, isTrue);
    });

    test('accepts mongodb+srv with no explicit port', () {
      final result = ConnectionStringValidator.validate(
        'mongodb+srv://user:pass@cluster.mongodb.net/db',
      );
      expect(result.isValid, isTrue);
    });

    test('rejects missing scheme', () {
      final result = ConnectionStringValidator.validate(
        'localhost:27017/testdb',
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('mongodb'));
    });

    test('rejects http:// scheme', () {
      final result = ConnectionStringValidator.validate(
        'http://localhost:27017/testdb',
      );
      expect(result.isValid, isFalse);
      expect(result.error, contains('mongodb'));
    });

    test('rejects non-URI format', () {
      final result = ConnectionStringValidator.validate('not-a-uri-at-all');
      expect(result.isValid, isFalse);
    });

    test('rejects empty host with no user info', () {
      final result = ConnectionStringValidator.validate('mongodb:///testdb');
      expect(result.isValid, isFalse);
      expect(result.error, contains('Host'));
    });

    test('accepts mongodb with just host (no port)', () {
      final result = ConnectionStringValidator.validate(
        'mongodb://myhost/testdb',
      );
      expect(result.isValid, isTrue);
    });

    test('accepts mongodb+srv URI without explicit port', () {
      final result = ConnectionStringValidator.validate(
        'mongodb+srv://cluster0.mongodb.net/testdb',
      );
      expect(result.isValid, isTrue);
    });
  });

  group('ValidationResult', () {
    test('valid result has no error', () {
      const result = ValidationResult.valid();
      expect(result.isValid, isTrue);
      expect(result.error, isNull);
    });

    test('invalid result has error message', () {
      const result = ValidationResult.invalid('test error');
      expect(result.isValid, isFalse);
      expect(result.error, 'test error');
    });
  });
}
