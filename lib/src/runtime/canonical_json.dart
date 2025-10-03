library canonical_json;

import 'dart:convert';

class CanonicalJson {
  /// Encode object to canonical JSON string with sorted keys
  static String encode(dynamic object) {
    return const JsonEncoder().convert(_canonicalize(object));
  }

  /// Recursively canonicalize object by sorting map keys
  static dynamic _canonicalize(dynamic obj) {
    if (obj is Map) {
      final sortedMap = <String, dynamic>{};
      final sortedKeys = obj.keys.map((k) => k.toString()).toList()..sort();
      for (final key in sortedKeys) {
        sortedMap[key] = _canonicalize(obj[key]);
      }
      return sortedMap;
    } else if (obj is List) {
      return obj.map(_canonicalize).toList();
    }
    return obj;
  }
}
