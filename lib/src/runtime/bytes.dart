library bytes;

import 'dart:typed_data';
import 'dart:convert';

class ByteUtils {
  /// Validate exact byte length
  static void validateLength(Uint8List bytes, int expectedLength, String fieldName) {
    if (bytes.length != expectedLength) {
      throw ArgumentError(
        '$fieldName must be exactly $expectedLength bytes, got ${bytes.length}',
      );
    }
  }

  /// Validate byte length within range
  static void validateLengthRange(Uint8List bytes, int minLength, int maxLength, String fieldName) {
    if (bytes.length < minLength || bytes.length > maxLength) {
      throw ArgumentError(
        '$fieldName must be between $minLength and $maxLength bytes, got ${bytes.length}',
      );
    }
  }

  /// Validate minimum byte length
  static void validateMinLength(Uint8List bytes, int minLength, String fieldName) {
    if (bytes.length < minLength) {
      throw ArgumentError(
        '$fieldName must be at least $minLength bytes, got ${bytes.length}',
      );
    }
  }

  /// Validate maximum byte length
  static void validateMaxLength(Uint8List bytes, int maxLength, String fieldName) {
    if (bytes.length > maxLength) {
      throw ArgumentError(
        '$fieldName must be at most $maxLength bytes, got ${bytes.length}',
      );
    }
  }

  static String bytesToJson(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Uint8List bytesFromJson(String json) {
    return base64Decode(json);
  }
}
