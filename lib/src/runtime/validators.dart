// GENERATED — Do not edit.

import 'dart:typed_data';

/// Validation utilities for protocol types
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

  /// Validate BigInt is not null when required
  static void validateBigInt(BigInt? value, String fieldName) {
    if (value == null) {
      throw ArgumentError('$fieldName is required');
    }
  }

  /// Validate list is not empty when required
  static void validateNonEmptyList(List? list, String fieldName) {
    if (list == null || list.isEmpty) {
      throw ArgumentError('$fieldName must not be empty');
    }
  }
}
