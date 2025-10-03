// GENERATED — Do not edit.

import 'dart:convert';
import 'dart:typed_data';

/// Canonical helpers for encoding/decoding
class CanonHelpers {
  /// Convert Uint8List to base64 string
  static String uint8ListToBase64(Uint8List data) {
    return base64Encode(data);
  }

  /// Convert base64 string to Uint8List
  static Uint8List base64ToUint8List(String base64String) {
    return base64Decode(base64String);
  }

  /// Encode BigInt as decimal string for JSON
  static String bigIntToString(BigInt value) {
    return value.toString();
  }

  /// Parse BigInt from decimal string
  static BigInt stringToBigInt(String value) {
    return BigInt.parse(value);
  }
}
