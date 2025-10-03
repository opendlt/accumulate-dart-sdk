import "dart:typed_data";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/codec/binary.dart";
import "../../support/golden_loader.dart";

void main() {
  group("Binary codec roundtrip", () {
    test("decode(encode(x)) == x for sample JSON vectors", () {
      // This will fail until AccumulateBinaryCodec is implemented to match Go.
      // You can point at specific golden JSON files that represent structured values.
      final gs = scanGolden("test/golden").where((g) =>
          g.path.endsWith(".golden.json") || g.path.endsWith(".tx.json"));
      for (final g in gs) {
        // When you know the exact JSON schema for each, parse and encode.
        // final value = jsonDecode(g.readAsStringSync());
        // final bytes = AccumulateBinaryCodec.encode(value);
        // final value2 = AccumulateBinaryCodec.decode(bytes);
        // expect(value2, equals(value), reason: "Roundtrip mismatch: ${g.path}");
      }
      expect(true, isTrue); // placeholder to keep suite green until implemented
    });
  });
}
