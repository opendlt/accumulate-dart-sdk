import "dart:typed_data";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/codec/codec.dart";

String toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, "0"));
  }
  return sb.toString();
}

void main() {
  group("Binary encoding conformance (vs TypeScript)", () {
    test("uvarint encoding matches TypeScript", () {
      // Test cases from TypeScript test file
      expect(
        AccumulateCodec.uvarintMarshalBinary(0),
        equals(Uint8List.fromList([0])),
      );

      expect(
        AccumulateCodec.uvarintMarshalBinary(0, 7),
        equals(Uint8List.fromList([7, 0])),
      );

      expect(
        AccumulateCodec.uvarintMarshalBinary(1),
        equals(Uint8List.fromList([1])),
      );

      expect(
        AccumulateCodec.uvarintMarshalBinary(127),
        equals(Uint8List.fromList([127])),
      );

      expect(
        AccumulateCodec.uvarintMarshalBinary(128),
        equals(Uint8List.fromList([128, 1])),
      );

      expect(
        AccumulateCodec.uvarintMarshalBinary(256),
        equals(Uint8List.fromList([128, 2])),
      );
    });

    test("field encoding matches TypeScript", () {
      final field1Data = Uint8List.fromList([42]);
      final result = AccumulateCodec.fieldMarshalBinary(1, field1Data);
      expect(result, equals(Uint8List.fromList([1, 42])));

      final field7Data = Uint8List.fromList([0]);
      final result7 = AccumulateCodec.fieldMarshalBinary(7, field7Data);
      expect(result7, equals(Uint8List.fromList([7, 0])));
    });

    test("string encoding matches TypeScript", () {
      final result = AccumulateCodec.stringMarshalBinary("hello");
      // Length prefix (5) + "hello" bytes
      expect(result, equals(Uint8List.fromList([5, 104, 101, 108, 108, 111])));
    });

    test("boolean encoding matches TypeScript", () {
      expect(
        AccumulateCodec.booleanMarshalBinary(true),
        equals(Uint8List.fromList([1])),
      );

      expect(
        AccumulateCodec.booleanMarshalBinary(false),
        equals(Uint8List.fromList([0])),
      );
    });

    test("bytes encoding matches TypeScript", () {
      final input = Uint8List.fromList([1, 2, 3]);
      final result = AccumulateCodec.bytesMarshalBinary(input);
      // Length prefix (3) + [1, 2, 3]
      expect(result, equals(Uint8List.fromList([3, 1, 2, 3])));
    });

    test("hash encoding (32 bytes, no length prefix)", () {
      final hash = Uint8List(32)..fillRange(0, 32, 0xFF); // 32 bytes of 0xFF
      final result = AccumulateCodec.hashMarshalBinary(hash);
      expect(result, equals(hash)); // No length prefix for hashes

      // Test invalid hash length
      expect(
        () => AccumulateCodec.hashMarshalBinary(Uint8List(31)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("BigInt encoding", () {
      final result = AccumulateCodec.bigIntMarshalBinary(BigInt.from(255));
      // BigInt 255 = 0xFF, encoded as length-prefixed bytes [1, 255]
      expect(result, equals(Uint8List.fromList([1, 255])));

      final result2 = AccumulateCodec.bigIntMarshalBinary(BigInt.from(256));
      // BigInt 256 = 0x100, encoded as length-prefixed bytes [2, 1, 0]
      expect(result2, equals(Uint8List.fromList([2, 1, 0])));
    });
  });
}
