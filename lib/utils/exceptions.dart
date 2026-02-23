/// Custom exceptions for the HostelAssist app
/// Provides meaningful error messages and types
library;

/// Base exception class
class HostelAssistException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  HostelAssistException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'HostelAssistException: $message ${code != null ? '(Code: $code)' : ''}';
}

/// Authentication related exceptions
class AuthException extends HostelAssistException {
  AuthException(super.message, {super.code, super.details});
}

/// Firestore related exceptions
class FirestoreException extends HostelAssistException {
  FirestoreException(super.message, {super.code, super.details});
}

/// Room allocation exceptions
class RoomAllocationException extends HostelAssistException {
  RoomAllocationException(super.message, {super.code, super.details});
}

/// Validation exceptions
class ValidationException extends HostelAssistException {
  ValidationException(super.message, {super.code, super.details});
}

/// Network/Server exceptions
class NetworkException extends HostelAssistException {
  NetworkException(super.message, {super.code, super.details});
}

/// Permission/Access exceptions
class PermissionException extends HostelAssistException {
  PermissionException(super.message, {super.code, super.details});
}

/// Not found exceptions
class NotFoundException extends HostelAssistException {
  NotFoundException(super.message, {super.code, super.details});
}
