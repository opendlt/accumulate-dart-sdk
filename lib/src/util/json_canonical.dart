import "dart:convert";

/// Canonical JSON encoder: sorts object keys lexicographically and
/// encodes with no extra whitespace so hashes are stable across languages.
String canonicalJsonString(dynamic value) {
  return jsonEncode(_canonicalize(value));
}

dynamic _canonicalize(dynamic v) {
  if (v is Map) {
    final keys = v.keys.map((e) => e.toString()).toList()..sort();
    final out = <String, dynamic>{};
    for (final k in keys) {
      out[k] = _canonicalize(v[k]);
    }
    return out;
  } else if (v is List) {
    return v.map(_canonicalize).toList(growable: false);
  } else {
    // Numbers/strings/bool/null pass through
    return v;
  }
}
