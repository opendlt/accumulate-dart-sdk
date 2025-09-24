import "dart:convert";
import "dart:typed_data";

Uint8List u8(List<int> a) => Uint8List.fromList(a);
Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

String toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, "0"));
  }
  return sb.toString();
}

Uint8List hexTo(String hex) {
  if (hex.length % 2 != 0) throw ArgumentError("Invalid hex length");
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}
