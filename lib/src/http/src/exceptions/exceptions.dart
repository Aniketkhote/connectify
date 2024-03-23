/// Exception thrown when an HTTP request encounters an error.
class GetHttpException implements Exception {
  /// Constructs a [GetHttpException] with the provided error message and optional URI.
  GetHttpException(this.message, [this.uri]);

  /// The error message associated with the exception.
  final String message;

  /// The URI associated with the exception, if applicable.
  final Uri? uri;

  @override
  String toString() => message;
}

/// Represents an error in a GraphQL response.
class GraphQLError {
  /// Constructs a [GraphQLError] with the provided error message and error code.
  GraphQLError({this.code, this.message});

  /// The error message associated with the GraphQL error.
  final String? message;

  /// The error code associated with the GraphQL error.
  final String? code;

  @override
  String toString() => "GETCONNECT ERROR:\n\tcode:$code\n\tmessage:$message";
}

/// Exception thrown when an operation is unauthorized.
class UnauthorizedException implements Exception {
  @override
  String toString() => "Operation Unauthorized";
}

/// Exception thrown when encountering an unexpected format.
class UnexpectedFormat implements Exception {
  /// Constructs an [UnexpectedFormat] exception with the provided message.
  UnexpectedFormat(this.message);

  /// The message describing the unexpected format.
  final String message;

  @override
  String toString() => "Unexpected format: $message";
}
