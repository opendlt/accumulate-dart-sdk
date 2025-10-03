// GENERATED — Do not edit.

import 'dart:convert';
import 'dart:typed_data';

/// Canonical helpers for encoding/decoding with deterministic output
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
  static String bigIntToJson(BigInt value) {
    return value.toString();
  }

  /// Parse BigInt from decimal string
  static BigInt bigIntFromJson(String value) {
    return BigInt.parse(value);
  }
}

/// Canonical JSON encoder that ensures deterministic output
class CanonicalJson {
  /// Encode object to canonical JSON with sorted keys
  static String encode(dynamic obj) {
    return jsonEncode(_canonicalize(obj));
  }

  /// Recursively canonicalize an object (sort map keys, preserve array order)
  static dynamic _canonicalize(dynamic obj) {
    if (obj is Map) {
      final sorted = <String, dynamic>{};
      final keys = obj.keys.cast<String>().toList()..sort();
      for (final key in keys) {
        sorted[key] = _canonicalize(obj[key]);
      }
      return sorted;
    } else if (obj is List) {
      return obj.map(_canonicalize).toList();
    } else if (obj is BigInt) {
      return obj.toString();
    } else if (obj is Uint8List) {
      return base64Encode(obj);
    } else {
      return obj;
    }
  }

  /// Create a canonically sorted map from input map
  static Map<String, dynamic> sortMap(Map<String, dynamic> input) {
    final sorted = <String, dynamic>{};
    final keys = input.keys.toList()..sort();
    for (final key in keys) {
      var value = input[key];
      if (value is Map<String, dynamic>) {
        value = sortMap(value);
      } else if (value is BigInt) {
        value = value.toString();
      } else if (value is Uint8List) {
        value = base64Encode(value);
      }
      sorted[key] = value;
    }
    return sorted;
  }
}
