import 'dart:convert';

import 'package:bson/bson.dart';

class JsonUtils {
  /// Pretty-prints a MongoDB document using Extended JSON so BSON types
  /// ([DateTime], [ObjectId], etc.) are representable by [JsonEncoder].
  static String encodeMongoDocumentPretty(Map<String, dynamic> data) {
    final ejson = EJsonCodec.doc2eJson(Map<String, dynamic>.from(data));
    return JsonEncoder.withIndent('  ').convert(ejson);
  }

  /// Pretty-prints a BSON-backed list (e.g. nested array field) for display.
  static String encodeMongoListPretty(List<dynamic> list) {
    final ejson = EJsonCodec.doc2eJson({'__mongolite_root': list});
    return JsonEncoder.withIndent('  ').convert(ejson['__mongolite_root']);
  }

  static String formatPretty(Map<String, dynamic> data) {
    return encodeMongoDocumentPretty(data);
  }

  static Map<String, dynamic>? tryParse(String text) {
    try {
      final parsed = jsonDecode(text);
      if (parsed is Map<String, dynamic>) return parsed;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String truncateValue(Object? value, {int maxLength = 50}) {
    final str = value.toString();
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }

  /// Deep-copy via BSON round-trip (preserves DateTime, ObjectId, etc.).
  static Map<String, dynamic> deepCopy(Map<String, dynamic> value) {
    return Map<String, dynamic>.from(
      BsonCodec.deserialize(BsonCodec.serialize(value)),
    );
  }
}
