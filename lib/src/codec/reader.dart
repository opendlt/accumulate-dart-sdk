import "dart:typed_data";

class BinaryReader {
  final Uint8List _buf;
  int _off = 0;
  BinaryReader(this._buf);
  bool get eof => _off >= _buf.length;

  int u8() {
    return _buf[_off++];
  }

  int u32le() {
    final v =
        ByteData.sublistView(_buf, _off, _off + 4).getUint32(0, Endian.little);
    _off += 4;
    return v;
  }

  int u64le() {
    final v =
        ByteData.sublistView(_buf, _off, _off + 8).getUint64(0, Endian.little);
    _off += 8;
    return v;
  }

  int uvarint() {
    var x = 0, s = 0;
    for (;;) {
      final b = u8();
      if (b < 0x80) {
        x |= (b << s);
        break;
      }
      x |= ((b & 0x7F) << s);
      s += 7;
    }
    return x;
  }

  Uint8List bytes(int n) {
    final out = Uint8List.sublistView(_buf, _off, _off + n);
    _off += n;
    return out;
  }

  Uint8List lenPrefixedBytes() {
    final n = uvarint();
    return bytes(n);
  }

  String stringAscii() {
    final b = lenPrefixedBytes();
    return String.fromCharCodes(b);
  }
}
