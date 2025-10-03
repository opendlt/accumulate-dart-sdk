import 'dart:typed_data';
import 'dart:convert';

class ByteUtils {
  static bool validateLength(Uint8List? bytes, int expectedLength) {
    return bytes != null && bytes.length == expectedLength;
  }

  static bool validateHash(Uint8List? hash) {
    return validateLength(hash, 32);
  }

  static String bytesToJson(Uint8List bytes) {
    return base64Encode(bytes);
  }

  static Uint8List bytesFromJson(String json) {
    return base64Decode(json);
  }
}
