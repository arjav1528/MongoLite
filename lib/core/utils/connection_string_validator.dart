
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult._({required this.isValid, this.error});
  const ValidationResult.valid() : this._(isValid: true);
  const ValidationResult.invalid(String error) : this._(isValid: false, error: error);
}

class ConnectionStringValidator {
  static ValidationResult validate(String uri) {
    if (uri.isEmpty) {
      return const ValidationResult.invalid('Connection string cannot be empty');
    }

    final parsed = Uri.tryParse(uri);
    if (parsed == null) {
      return const ValidationResult.invalid('Invalid URI format');
    }

    if (!['mongodb', 'mongodb+srv'].contains(parsed.scheme)) {
      return const ValidationResult.invalid('Scheme must be mongodb:// or mongodb+srv://');
    }

    if (parsed.host.isEmpty && parsed.userInfo.isEmpty) {
      return const ValidationResult.invalid('Host is required');
    }

    if (parsed.hasPort && (parsed.port < 1 || parsed.port > 65535)) {
      return const ValidationResult.invalid('Invalid port number');
    }

    return const ValidationResult.valid();
  }
}
