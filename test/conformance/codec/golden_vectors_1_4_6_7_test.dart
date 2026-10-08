import "dart:convert";
import "dart:io";
import "dart:typed_data";
import "package:opendlt_accumulate/src/codec/binary_encoder.dart";
import "package:opendlt_accumulate/src/codec/transaction_codec.dart";
import "package:test/test.dart";

/// Golden vectors produced by Go's own MarshalBinary / GetHash
/// (Accumulate 1.4.6.7). See test/fixtures/accumulate_1_4_6_7_vectors.json.
String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, "0")).join();

void main() {
  final vectors = (jsonDecode(
          File("test/fixtures/accumulate_1_4_6_7_vectors.json")
              .readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  for (final v in vectors) {
    final name = v["name"] as String;
    final j = v["json"];
    if (name.startsWith("header_")) {
      test("$name binary", () {
        final got = TransactionHeaderMarshaler.marshal(
            (j as Map).cast<String, dynamic>());
        expect(_hex(got), v["binaryHex"]);
      });
    } else if (name.startsWith("hashlockoptions_")) {
      test("$name binary", () {
        final got = HashLockOptionsMarshaler.marshal(
            (j as Map).cast<String, dynamic>());
        expect(_hex(got), v["binaryHex"]);
      });
    } else if (name.startsWith("tx_")) {
      final header = ((j as Map)["header"] as Map).cast<String, dynamic>();
      final body = (j["body"] as Map).cast<String, dynamic>();
      test("$name binary envelope", () {
        final e = BinaryEncoder();
        e.writeValue(1, TransactionHeaderMarshaler.marshal(header));
        e.writeValue(2, TransactionBodyMarshaler.marshal(body));
        expect(_hex(e.toBytes()), v["binaryHex"]);
      });
      test("$name hash", () {
        final h = TransactionCodec.encodeTxForSigning(header, body);
        expect(_hex(h), v["hashHex"]);
      });
    }
  }
}
