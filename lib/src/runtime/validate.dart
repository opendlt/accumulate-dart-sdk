library validate;

import 'dart:typed_data';

class Validate {
  /// Validate required field
  static T required<T>(T? value, String fieldName) {
    if (value == null) {
      throw ArgumentError('$fieldName is required');
    }
    return value;
  }

  /// Validate signature nesting depth
  static void signatureDepth(int depth, int maxDepth) {
    if (depth >= maxDepth) {
      throw ArgumentError('Signature nesting depth cannot exceed $maxDepth');
    }
  }

  /// Validate string length limits
  static void stringLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      throw ArgumentError('$fieldName cannot exceed $maxLength characters, got ${value.length}');
    }
  }

  /// Validate numeric range
  static void numericRange(num? value, num min, num max, String fieldName) {
    if (value != null && (value < min || value > max)) {
      throw ArgumentError('$fieldName must be between $min and $max, got $value');
    }
  }

  /// Validate positive number
  static void positiveNumber(num? value, String fieldName) {
    if (value != null && value <= 0) {
      throw ArgumentError('$fieldName must be positive, got $value');
    }
  }

  /// Validate threshold for signature sets
  static void threshold(int threshold, int signatureCount, String fieldName) {
    if (threshold <= 0 || threshold > signatureCount) {
      throw ArgumentError('$fieldName must be between 1 and $signatureCount, got $threshold');
    }
  }

  /// Validate signature set is not empty
  static void signatureSetNotEmpty<T>(List<T> signatures, String fieldName) {
    if (signatures.isEmpty) {
      throw ArgumentError('$fieldName must not be empty');
    }
  }

  /// Validate enum values
  static void enumValue<T>(T value, List<T> allowedValues, String fieldName) {
    if (!allowedValues.contains(value)) {
      throw ArgumentError('$fieldName must be one of $allowedValues, got $value');
    }
  }
}
