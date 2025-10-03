// GENERATED — Do not edit.

import 'dart:typed_data';

/// Validation utilities for protocol types with comprehensive field checking
class Validators {
  /// Validate URL format (must start with acc://)
  static void validateUrl(String? url, String fieldName) {
    if (url == null) return;
    if (!url.startsWith('acc://')) {
      throw ArgumentError('$fieldName must be a valid Accumulate URL starting with acc://');
    }
  }

  /// Validate hash32 (must be 32 bytes)
  static void validateHash32(Uint8List? hash, String fieldName) {
    if (hash == null) return;
    if (hash.length != 32) {
      throw ArgumentError('$fieldName must be exactly 32 bytes');
    }
  }

  /// Validate fixed-length bytes
  static void validateFixed(Uint8List? data, int expectedLength, String fieldName) {
    if (data == null) return;
    if (data.length != expectedLength) {
      throw ArgumentError('$fieldName must be exactly $expectedLength bytes');
    }
  }

  /// Validate required field is not null
  static void validateRequired<T>(T? value, String fieldName) {
    if (value == null) {
      throw ArgumentError('$fieldName is required and cannot be null');
    }
  }

  /// Validate BigInt is not null when required
  static void validateBigInt(BigInt? value, String fieldName) {
    if (value == null) {
      throw ArgumentError('$fieldName is required');
    }
  }

  /// Validate list is not empty when required
  static void validateNonEmptyList<T>(List<T>? list, String fieldName) {
    if (list == null || list.isEmpty) {
      throw ArgumentError('$fieldName must not be empty');
    }
  }

  /// Validate integer is within specified range
  static void validateIntRange(int? value, String fieldName, {int? min, int? max}) {
    if (value == null) return;
    if (min != null && value < min) {
      throw ArgumentError('$fieldName must be >= $min, got $value');
    }
    if (max != null && value > max) {
      throw ArgumentError('$fieldName must be <= $max, got $value');
    }
  }

  /// Validate string length is within specified range
  static void validateStringLength(String? value, String fieldName, {int? minLength, int? maxLength}) {
    if (value == null) return;
    if (minLength != null && value.length < minLength) {
      throw ArgumentError('$fieldName must be at least $minLength characters, got ${value.length}');
    }
    if (maxLength != null && value.length > maxLength) {
      throw ArgumentError('$fieldName must be at most $maxLength characters, got ${value.length}');
    }
  }

  /// Validate list size is within specified range
  static void validateListSize<T>(List<T>? list, String fieldName, {int? minSize, int? maxSize}) {
    if (list == null) return;
    if (minSize != null && list.length < minSize) {
      throw ArgumentError('$fieldName must have at least $minSize items, got ${list.length}');
    }
    if (maxSize != null && list.length > maxSize) {
      throw ArgumentError('$fieldName must have at most $maxSize items, got ${list.length}');
    }
  }
}
