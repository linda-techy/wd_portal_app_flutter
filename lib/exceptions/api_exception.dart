/// Standardized API exception class for all HTTP errors
/// Provides structured error handling with correlation IDs for traceability
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final String? correlationId;
  final String? path;
  final Map<String, dynamic>? validationErrors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.correlationId,
    this.path,
    this.validationErrors,
  });

  /// Parse API error from response body
  factory ApiException.fromResponse(dynamic response, int statusCode) {
    if (response is Map<String, dynamic>) {
      return ApiException(
        message: response['message'] ?? 'An error occurred',
        statusCode: statusCode,
        errorCode: response['errorCode'],
        correlationId: response['correlationId'],
        path: response['path'],
        validationErrors: response['validationErrors'],
      );
    }
    
    return ApiException(
      message: response.toString(),
      statusCode: statusCode,
    );
  }

  /// Parse API error from Dio exception
  factory ApiException.fromDioException(dynamic error) {
    if (error.response != null) {
      return ApiException.fromResponse(
        error.response?.data,
        error.response?.statusCode ?? 500,
      );
    }
    
    // Network or timeout error
    if (error.type.toString().contains('connectionTimeout') || 
        error.type.toString().contains('receiveTimeout')) {
      throw TimeoutException();
    }
    
    if (error.type.toString().contains('connectionError')) {
      throw NetworkException();
    }
    
    return ApiException(
      message: error.message ?? 'An error occurred',
      statusCode: null,
    );
  }

  /// Check if this is a validation error (400 with validation details)
  bool get isValidationError => 
      statusCode == 400 && validationErrors != null;

  /// Check if this is an authentication error (401)
  bool get isAuthenticationError => statusCode == 401;

  /// Check if this is an authorization error (403)
  bool get isAuthorizationError => statusCode == 403;

  /// Check if this is a not found error (404)
  bool get isNotFoundError => statusCode == 404;

  /// Check if this is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Get user-friendly error message
  String get userMessage {
    if (isValidationError) {
      return 'Please check the form and try again';
    }
    if (isAuthenticationError) {
      return 'Please log in to continue';
    }
    if (isAuthorizationError) {
      return 'You do not have permission to perform this action';
    }
    if (isNotFoundError) {
      return 'The requested resource was not found';
    }
    if (isServerError) {
      return 'A server error occurred. Please try again later.';
    }
    return message;
  }

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    if (errorCode != null) {
      buffer.write(' [Code: $errorCode]');
    }
    if (correlationId != null) {
      buffer.write(' [Correlation: $correlationId]');
    }
    return buffer.toString();
  }
}

/// Network connectivity exception
class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Timeout exception
class TimeoutException implements Exception {
  final String message;

  TimeoutException([this.message = 'Request timed out']);

  @override
  String toString() => 'TimeoutException: $message';
}
