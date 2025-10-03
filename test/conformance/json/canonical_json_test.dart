import "dart:convert";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/util/json_canonical.dart";
import "../../support/golden_loader.dart";

void main() {
  group("Canonical JSON conformance", () {
    test("stable ordering & string form", () {
      final input = {
        "b": 2,
        "a": {"d": 4, "c": 3},
        "arr": [
          {"y": 2, "x": 1},
          {"b": 0},
          {"a": 0}
        ]
      };
      final s = canonicalJsonString(input);
      // keys in maps are sorted lexicographically recursively
      expect(
          s,
          equals(
              '{"a":{"c":3,"d":4},"arr":[{"x":1,"y":2},{"b":0},{"a":0}],"b":2}'));
      // round-trip parse yields same canonical string
      final reparsed = jsonDecode(s);
      expect(canonicalJsonString(reparsed), equals(s));
    });
  });
}
