import "dart:typed_data";

class BinaryWriter {
  final BytesBuilder _bb = BytesBuilder(copy: false);
  void u8(int v) {
    _bb.add([v & 0xFF]);
  }

  void u32le(int v) {
    final b = ByteData(4);
    b.setUint32(0, v >>> 0, Endian.little);
    _bb.add(b.buffer.asUint8List());
  }

  void u64le(int v) {
    final b = ByteData(8);
    // JS/TS often split hi/lo; in Dart we take int (>= 64-bit support). If >2^53, use BigInt path.
    b.setUint64(0, v & 0xFFFFFFFFFFFFFFFF, Endian.little);
    _bb.add(b.buffer.asUint8List());
  }

  void bytes(Uint8List v) {
    _bb.add(v);
  }

  void lenPrefixedBytes(Uint8List v) {
    uvarint(v.length);
    bytes(v);
  }

  void stringAscii(String s) {
    final b = Uint8List.fromList(s.codeUnits);
    lenPrefixedBytes(b);
  }

  void uvarint(int v) {
    // ULEB128 (same as Go binary/varint, TS impl custom)
    var x = v >>> 0;
    while (x >= 0x80) {
      u8((x & 0x7F) | 0x80);
      x >>= 7;
    }
    u8(x);
  }

  Uint8List toBytes() => _bb.toBytes();
}
