import 'dart:convert';

class JsonUtils {
  static String formatPretty(Map<String, dynamic> data) {
    return JsonEncoder.withIndent('  ').convert(data);
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
}
