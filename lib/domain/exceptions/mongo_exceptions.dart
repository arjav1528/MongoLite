sealed class MongoAppException implements Exception {
  final String message;
  const MongoAppException(this.message);

  @override
  String toString() => message;
}

class ConnectionFailedException extends MongoAppException {
  const ConnectionFailedException(super.message);
}

class AuthenticationException extends MongoAppException {
  const AuthenticationException(super.message);
}

class OperationTimeoutException extends MongoAppException {
  const OperationTimeoutException(super.message);
}

class InvalidConnectionStringException extends MongoAppException {
  const InvalidConnectionStringException(super.message);
}

class DocumentNotFoundException extends MongoAppException {
  const DocumentNotFoundException(super.message);
}
