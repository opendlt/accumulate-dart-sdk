import "dart:typed_data";
import "dart:convert";
import "writer.dart";
import "reader.dart";

/// Accumulate binary codec that matches TypeScript/Go implementation
class AccumulateCodec {
  /// Encode a field with a field number (1-32)
  static Uint8List fieldMarshalBinary(int field, Uint8List val) {
    if (field < 1 || field > 32) {
      throw ArgumentError("Field number is out of range [1, 32]: $field");
    }
    return Uint8List.fromList([...uvarintMarshalBinary(field), ...val]);
  }

  /// Encode unsigned varint (ULEB128)
  static Uint8List uvarintMarshalBinary(int val, [int? field]) {
    if (val > 0x7FFFFFFFFFFFFFFF) {
      throw ArgumentError(
          "Cannot marshal binary number greater than MAX_SAFE_INTEGER");
    }

    var x = val;
    final buffer = <int>[];
    var i = 0;

    while (x >= 0x80) {
      buffer.add((x & 0xFF) | 0x80);
      x >>= 7;
      i++;
    }

    buffer.add(x & 0xFF);
    final data = Uint8List.fromList(buffer);

    return field != null ? fieldMarshalBinary(field, data) : data;
  }

  /// Encode signed varint (zigzag encoding)
  static Uint8List varintMarshalBinary(int val, [int? field]) {
    var x = val;
    var ux = x << 1;
    if (x < 0) {
      ux = ~ux;
    }
    return uvarintMarshalBinary(ux, field);
  }

  /// Encode boolean
  static Uint8List booleanMarshalBinary(bool b, [int? field]) {
    final data = Uint8List.fromList([b ? 1 : 0]);
    return field != null ? fieldMarshalBinary(field, data) : data;
  }

  /// Encode string (UTF-8, length-prefixed)
  static Uint8List stringMarshalBinary(String val, [int? field]) {
    final data = bytesMarshalBinary(Uint8List.fromList(utf8.encode(val)));
    return field != null ? fieldMarshalBinary(field, data) : data;
  }

  /// Encode bytes (length-prefixed)
  static Uint8List bytesMarshalBinary(Uint8List val, [int? field]) {
    final length = uvarintMarshalBinary(val.length);
    final data = Uint8List.fromList([...length, ...val]);
    return field != null ? fieldMarshalBinary(field, data) : data;
  }

  /// Encode hash (32 bytes, no length prefix)
  static Uint8List hashMarshalBinary(Uint8List val, [int? field]) {
    if (val.length != 32) {
      throw ArgumentError("Invalid length, value is not a hash: ${val.length}");
    }
    return field != null ? fieldMarshalBinary(field, val) : val;
  }

  /// Encode BigInt (as big-endian bytes, length-prefixed)
  static Uint8List bigIntMarshalBinary(BigInt bn, [int? field]) {
    if (bn < BigInt.zero) {
      throw ArgumentError("Cannot marshal a negative bigint");
    }
    var s = bn.toRadixString(16);
    if (s.length % 2 == 1) {
      s = "0$s";
    }
    final bytes = Uint8List.fromList(
      RegExp(r"..")
          .allMatches(s)
          .map((match) => int.parse(match.group(0)!, radix: 16))
          .toList(),
    );
    final data = bytesMarshalBinary(bytes);
    return field != null ? fieldMarshalBinary(field, data) : data;
  }

  /// Example envelope encoder - needs to be filled with actual field structure
  /// This is where you'd implement the exact field order from TypeScript/Go
  static Uint8List encodeEnvelope(Map<String, dynamic> envelope) {
    final writer = BinaryWriter();

    // TODO: Implement exact field order matching TypeScript/Go
    // Example structure (needs to be verified against actual protocol):
    // Field 1: Header bytes
    // Field 2: Body bytes
    // Field 3: Signatures

    if (envelope.containsKey("header") && envelope["header"] != null) {
      final headerBytes = envelope["header"] is Uint8List
          ? envelope["header"] as Uint8List
          : Uint8List.fromList(utf8.encode(jsonEncode(envelope["header"])));
      writer.bytes(fieldMarshalBinary(1, bytesMarshalBinary(headerBytes)));
    }

    if (envelope.containsKey("body") && envelope["body"] != null) {
      final bodyBytes = envelope["body"] is Uint8List
          ? envelope["body"] as Uint8List
          : Uint8List.fromList(utf8.encode(jsonEncode(envelope["body"])));
      writer.bytes(fieldMarshalBinary(2, bytesMarshalBinary(bodyBytes)));
    }

    if (envelope.containsKey("signatures") && envelope["signatures"] != null) {
      final signatures = envelope["signatures"] as List;
      for (int i = 0; i < signatures.length; i++) {
        final sigBytes = signatures[i] is Uint8List
            ? signatures[i] as Uint8List
            : Uint8List.fromList(utf8.encode(jsonEncode(signatures[i])));
        writer.bytes(fieldMarshalBinary(3, bytesMarshalBinary(sigBytes)));
      }
    }

    return writer.toBytes();
  }

  /// Example envelope decoder
  static Map<String, dynamic> decodeEnvelope(Uint8List bytes) {
    final reader = BinaryReader(bytes);
    final envelope = <String, dynamic>{};

    while (!reader.eof) {
      final field = reader.uvarint();
      switch (field) {
        case 1: // header
          envelope["header"] = reader.lenPrefixedBytes();
          break;
        case 2: // body
          envelope["body"] = reader.lenPrefixedBytes();
          break;
        case 3: // signature
          envelope["signatures"] ??= <Uint8List>[];
          (envelope["signatures"] as List).add(reader.lenPrefixedBytes());
          break;
        default:
          throw ArgumentError("Unknown field: $field");
      }
    }

    return envelope;
  }
}
