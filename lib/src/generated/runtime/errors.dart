// GENERATED - Do not edit.
// Error classes and helpers for Accumulate SDK
// Generated from Go error taxonomy and validation rules

/// Base class for all Accumulate errors
abstract class AccError implements Exception {
  const AccError(this.code, this.name, this.message, [this.details]);

  /// Numeric error code
  final int code;

  /// Mnemonic error name
  final String name;

  /// Human-readable error message
  final String message;

  /// Optional additional details
  final Map<String, dynamic>? details;

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return '$name($code): $message - ${details.toString()}';
    }
    return '$name($code): $message';
  }

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'message': message,
      if (details != null) 'details': details,
    };
  }
}

/// ApiError - errors related to api
class ApiError extends AccError {
  const ApiError(super.code, super.name, super.message, [super.details]);
}

/// AuthError - errors related to auth
class AuthError extends AccError {
  const AuthError(super.code, super.name, super.message, [super.details]);
}

/// DepthError - errors related to depth
class DepthError extends AccError {
  const DepthError(super.code, super.name, super.message, [super.details]);
}

/// EncodingError - errors related to encoding
class EncodingError extends AccError {
  const EncodingError(super.code, super.name, super.message, [super.details]);
}

/// NetworkError - errors related to network
class NetworkError extends AccError {
  const NetworkError(super.code, super.name, super.message, [super.details]);
}

/// SignatureError - errors related to signature
class SignatureError extends AccError {
  const SignatureError(super.code, super.name, super.message, [super.details]);
}

/// TransactionError - errors related to transaction
class TransactionError extends AccError {
  const TransactionError(super.code, super.name, super.message, [super.details]);
}

/// ValidationError - errors related to validation
class ValidationError extends AccError {
  const ValidationError(super.code, super.name, super.message, [super.details]);
}

/// Error registry for creating errors by code
class ErrorRegistry {
  static final Map<int, AccError Function(String message, [Map<String, dynamic>? details])> _registry = {
    10931: (message, [details]) => ValidationError(10931, "ValidationError", message, details),
    2465: (message, [details]) => SignatureError(2465, "SignatureError", message, details),
    5127: (message, [details]) => ValidationError(5127, "ValidationError", message, details),
    1001: (message, [details]) => ValidationError(1001, "RequiredFieldError", message, details),
    1002: (message, [details]) => ValidationError(1002, "InvalidUrlError", message, details),
    1003: (message, [details]) => ValidationError(1003, "InvalidHashError", message, details),
    1004: (message, [details]) => ValidationError(1004, "FixedLengthError", message, details),
    1005: (message, [details]) => ValidationError(1005, "OutOfRangeError", message, details),
    1006: (message, [details]) => DepthError(1006, "DepthExceededError", message, details),
    1007: (message, [details]) => ValidationError(1007, "UnknownDiscriminantError", message, details),
    -32600: (message, [details]) => ApiError(-32600, "InvalidRequestError", message, details),
    -32601: (message, [details]) => ApiError(-32601, "MethodNotFoundError", message, details),
    -32602: (message, [details]) => ValidationError(-32602, "InvalidParamsError", message, details),
    -32603: (message, [details]) => ApiError(-32603, "InternalError", message, details),
  };

  /// Create error by code with custom message
  static AccError createByCode(int code, String message, [Map<String, dynamic>? details]) {
    final factory = _registry[code];
    if (factory != null) {
      return factory(message, details);
    }
    // Fallback to ValidationError for unknown codes
    return ValidationError(code, "UnknownError", message, details);
  }

  /// Check if code is registered
  static bool hasCode(int code) => _registry.containsKey(code);
}

/// Helper factories for common validation errors
class AccErrors {
  /// Required field validation error
  static ValidationError required(String field) {
    return ValidationError(1001, "RequiredFieldError",
      "{field} is required".replaceAll('{field}', field));
  }

  /// Invalid URL validation error
  static ValidationError url(String value) {
    return ValidationError(1002, "InvalidUrlError",
      "Invalid Accumulate URL: {value}".replaceAll('{value}', value));
  }

  /// Hash validation error
  static ValidationError hash32(String field) {
    return ValidationError(1003, "InvalidHashError",
      "{field} must be a 32-byte hash".replaceAll('{field}', field));
  }

  /// Fixed length validation error
  static ValidationError fixed(String field, int n, int got) {
    return ValidationError(1004, "FixedLengthError",
      "{field} must be exactly {n} bytes (got {got})"
        .replaceAll('{field}', field)
        .replaceAll('{n}', n.toString())
        .replaceAll('{got}', got.toString()));
  }

  /// Range validation error
  static ValidationError range(String field, dynamic min, dynamic max, dynamic got) {
    return ValidationError(1005, "OutOfRangeError",
      "{field} must be between {min} and {max} (got {got})"
        .replaceAll('{field}', field)
        .replaceAll('{min}', min.toString())
        .replaceAll('{max}', max.toString())
        .replaceAll('{got}', got.toString()));
  }

  /// Depth exceeded error
  static DepthError depth(int got) {
    return DepthError(1006, "DepthExceededError",
      "DelegatedSignature depth exceeds 5 (got {got})".replaceAll('{got}', got.toString()));
  }

  /// Unknown discriminant error
  static ValidationError discriminant(String kind, String value) {
    return ValidationError(1007, "UnknownDiscriminantError",
      "Unknown {kind} type: {value}"
        .replaceAll('{kind}', kind)
        .replaceAll('{value}', value));
  }

}

/// JSON-RPC error mapping utilities
class JsonRpcErrorMapper {
  /// Map JSON-RPC error to appropriate AccError subclass
  static AccError mapRpcError(Map<String, dynamic> rpcError) {
    final code = rpcError['code'] as int?;
    final message = rpcError['message'] as String? ?? 'Unknown error';
    final data = rpcError['data'] as Map<String, dynamic>?;

    if (code == null) {
      return ApiError(-1, "UnknownApiError", message, data);
    }

    // Map standard JSON-RPC error codes
    switch (code) {
      case -32600:
        return ApiError(code, _getRpcErrorName(code), message, data);
      case -32601:
        return ApiError(code, _getRpcErrorName(code), message, data);
      case -32602:
        return ValidationError(code, _getRpcErrorName(code), message, data);
      case -32603:
        return ApiError(code, _getRpcErrorName(code), message, data);
      default:
        // Use error registry if available
        if (ErrorRegistry.hasCode(code)) {
          return ErrorRegistry.createByCode(code, message, data);
        }
        // Default to ApiError for unknown RPC codes
        return ApiError(code, "ApiError", message, data);
    }
  }

  static String _getRpcErrorName(int code) {
    switch (code) {
      case -32600: return "InvalidRequestError";
      case -32601: return "MethodNotFoundError";
      case -32602: return "InvalidParamsError";
      case -32603: return "InternalError";
      default: return "ApiError";
    }
  }
}
