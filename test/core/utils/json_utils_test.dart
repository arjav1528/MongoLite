import 'package:flutter_test/flutter_test.dart';
import 'package:mongolite/core/utils/json_utils.dart';

void main() {
  group('JsonUtils', () {
    test('formatPretty returns indented JSON string', () {
      final data = {'name': 'Alice', 'age': 30};
      final formatted = JsonUtils.formatPretty(data);

      expect(formatted, contains('\n'));
      expect(formatted, contains('  '));
      expect(formatted, contains('"name"'));
      expect(formatted, contains('"age"'));
    });

    test('formatPretty handles nested objects', () {
      final data = {
        'user': {
          'name': 'Bob',
          'address': {'city': 'NYC'},
        },
      };
      final formatted = JsonUtils.formatPretty(data);

      expect(formatted, contains('"address"'));
      expect(formatted, contains('"city"'));
      expect(formatted, contains('"NYC"'));
    });

    test('tryParse returns Map from valid JSON string', () {
      final json = '{"key": "value", "num": 42}';
      final result = JsonUtils.tryParse(json);

      expect(result, isNotNull);
      expect(result!['key'], 'value');
      expect(result['num'], 42);
    });

    test('tryParse returns null for invalid JSON', () {
      expect(JsonUtils.tryParse('not json'), isNull);
      expect(JsonUtils.tryParse('{invalid}'), isNull);
      expect(JsonUtils.tryParse(''), isNull);
      expect(JsonUtils.tryParse('[1,2,3]'), isNull,
          reason: 'arrays are not Map<String, dynamic>');
    });

    test('truncateValue returns full string when within limit', () {
      final result = JsonUtils.truncateValue('hello', maxLength: 10);
      expect(result, 'hello');
    });

    test('truncateValue truncates long strings with ellipsis', () {
      final result = JsonUtils.truncateValue('abcdefghijklmnopqrstuvwxyz',
          maxLength: 10);
      expect(result.length, 13); // 10 + 3 for '...'
      expect(result, startsWith('abcdefghij'));
      expect(result, endsWith('...'));
    });

    test('truncateValue handles non-string types', () {
      expect(JsonUtils.truncateValue(12345, maxLength: 3), '123...');
      expect(JsonUtils.truncateValue(null, maxLength: 10), 'null');
    });
  });
}
