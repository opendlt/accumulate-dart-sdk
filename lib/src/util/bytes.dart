import "dart:convert";
import "dart:math";
import "dart:typed_data";
import "package:crypto/crypto.dart";
import "package:pointycastle/export.dart";

// ============================================================
// BYTE ARRAY UTILITIES
// ============================================================

/// Create Uint8List from List<int>
Uint8List u8(List<int> a) => Uint8List.fromList(a);

/// Convert string to UTF-8 bytes
Uint8List utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));

/// Concatenate multiple byte arrays
Uint8List concatBytes(List<Uint8List> arrays) {
  final totalLength = arrays.fold<int>(0, (sum, arr) => sum + arr.length);
  final result = Uint8List(totalLength);
  var offset = 0;
  for (final arr in arrays) {
    result.setAll(offset, arr);
    offset += arr.length;
  }
  return result;
}

/// Compare two byte arrays for equality
bool bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ============================================================
// HEX ENCODING/DECODING
// ============================================================

/// Convert bytes to lowercase hex string
String toHex(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, "0"));
  }
  return sb.toString();
}

/// Convert hex string to bytes
/// Throws ArgumentError if hex string has invalid length
Uint8List hexTo(String hex) {
  // Remove 0x prefix if present
  if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.substring(2);
  }
  if (hex.length % 2 != 0) throw ArgumentError("Invalid hex length: ${hex.length}");
  final result = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

/// Alias for hexTo for backward compatibility
Uint8List fromHex(String hex) => hexTo(hex);

/// Convert bytes to hex string with optional 0x prefix
String toHexWithPrefix(Uint8List bytes) => '0x${toHex(bytes)}';

// ============================================================
// BIGINT <-> BYTES CONVERSION
// ============================================================

/// Convert bytes to BigInt (big-endian unsigned)
BigInt bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.zero;
  for (int i = 0; i < bytes.length; i++) {
    result = (result << 8) | BigInt.from(bytes[i]);
  }
  return result;
}

/// Convert BigInt to bytes with specified length (big-endian unsigned)
/// If number requires more bytes than length, most significant bytes are truncated
Uint8List bigIntToBytes(BigInt number, int length) {
  final result = Uint8List(length);
  var n = number;
  for (int i = length - 1; i >= 0; i--) {
    result[i] = (n & BigInt.from(0xFF)).toInt();
    n = n >> 8;
  }
  return result;
}

/// Convert BigInt to signed bytes (for DER encoding)
/// Ensures positive values don't have high bit set (adds leading zero if needed)
Uint8List bigIntToSignedBytes(BigInt value) {
  // Determine minimum bytes needed
  int byteLen = (value.bitLength + 8) ~/ 8;
  if (byteLen == 0) byteLen = 1;

  final bytes = bigIntToBytes(value, byteLen);

  // Remove leading zeros but keep at least one byte
  int start = 0;
  while (start < bytes.length - 1 && bytes[start] == 0) {
    start++;
  }

  // Add leading zero if high bit is set (to keep positive)
  if (bytes[start] & 0x80 != 0) {
    final result = Uint8List(bytes.length - start + 1);
    result[0] = 0;
    result.setAll(1, bytes.sublist(start));
    return result;
  }

  return bytes.sublist(start);
}

// ============================================================
// DER ENCODING/DECODING (for ECDSA signatures)
// ============================================================

/// DER encode an ECDSA signature (r, s) to bytes
Uint8List derEncode(BigInt r, BigInt s) {
  final rBytes = bigIntToSignedBytes(r);
  final sBytes = bigIntToSignedBytes(s);

  final totalLen = 2 + rBytes.length + 2 + sBytes.length;
  final result = BytesBuilder();
  result.addByte(0x30); // SEQUENCE
  result.addByte(totalLen);
  result.addByte(0x02); // INTEGER
  result.addByte(rBytes.length);
  result.add(rBytes);
  result.addByte(0x02); // INTEGER
  result.addByte(sBytes.length);
  result.add(sBytes);

  return result.toBytes();
}

/// DER decode an ECDSA signature from bytes
/// Returns (r, s) tuple or null if decoding fails
(BigInt, BigInt)? derDecode(Uint8List signature) {
  try {
    if (signature.isEmpty || signature[0] != 0x30) return null;
    int offset = 2;

    if (signature[offset] != 0x02) return null;
    final rLen = signature[offset + 1];
    offset += 2;
    final rBytes = signature.sublist(offset, offset + rLen);
    offset += rLen;

    if (signature[offset] != 0x02) return null;
    final sLen = signature[offset + 1];
    offset += 2;
    final sBytes = signature.sublist(offset, offset + sLen);

    return (bytesToBigInt(rBytes), bytesToBigInt(sBytes));
  } catch (e) {
    return null;
  }
}

// ============================================================
// SECURE RANDOM GENERATION
// ============================================================

/// Create a cryptographically secure random number generator
SecureRandom secureRandom() {
  final secureRandom = FortunaRandom();
  final random = Random.secure();
  final seeds = List<int>.generate(32, (_) => random.nextInt(256));
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

/// Generate random bytes
Uint8List randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
}

// ============================================================
// VARINT ENCODING (for binary protocol)
// ============================================================

/// Encode an integer as unsigned varint
Uint8List encodeUvarint(int value) {
  if (value < 0) throw ArgumentError("Cannot encode negative value as uvarint");

  final bytes = <int>[];
  var v = value;
  while (v >= 0x80) {
    bytes.add((v & 0x7F) | 0x80);
    v >>= 7;
  }
  bytes.add(v);
  return Uint8List.fromList(bytes);
}

/// Encode an integer as signed varint (zigzag encoding)
Uint8List encodeSvarint(int value) {
  // Zigzag encode: (n << 1) ^ (n >> 63)
  final zigzag = (value << 1) ^ (value >> 63);
  return encodeUvarint(zigzag);
}

/// Decode unsigned varint from bytes
/// Returns (value, bytesConsumed) tuple
(int, int) decodeUvarint(Uint8List bytes, [int offset = 0]) {
  int result = 0;
  int shift = 0;
  int bytesRead = 0;

  for (int i = offset; i < bytes.length; i++) {
    final b = bytes[i];
    result |= (b & 0x7F) << shift;
    bytesRead++;
    if (b < 0x80) break;
    shift += 7;
  }

  return (result, bytesRead);
}

// ============================================================
// PADDING UTILITIES
// ============================================================

/// Pad bytes on the left to reach specified length
Uint8List padLeft(Uint8List bytes, int length, [int padByte = 0]) {
  if (bytes.length >= length) return bytes;
  final result = Uint8List(length);
  result.fillRange(0, length - bytes.length, padByte);
  result.setAll(length - bytes.length, bytes);
  return result;
}

/// Pad bytes on the right to reach specified length
Uint8List padRight(Uint8List bytes, int length, [int padByte = 0]) {
  if (bytes.length >= length) return bytes;
  final result = Uint8List(length);
  result.setAll(0, bytes);
  result.fillRange(bytes.length, length, padByte);
  return result;
}

// ============================================================
// LITE IDENTITY DERIVATION
// ============================================================

/// Derive a Lite Identity URL from a 20-byte key hash
///
/// This implements the common Accumulate Lite Identity derivation:
/// - keyHash: First 20 bytes of the key hash (varies by signature type)
/// - Format: acc://<hex(keyHash)><checksum>
/// - Checksum: last 4 bytes of SHA256(hex(keyHash))
///
/// Example:
/// ```dart
/// final keyHash20 = sha256.convert(publicKey).bytes.take(20).toList();
/// final lidUrl = deriveLiteIdentityFromKeyHash(Uint8List.fromList(keyHash20));
/// ```
String deriveLiteIdentityFromKeyHash(Uint8List keyHash20) {
  if (keyHash20.length != 20) {
    throw ArgumentError("Key hash must be exactly 20 bytes");
  }
  final keyStr = toHex(keyHash20);
  final checksumFull = sha256.convert(utf8Bytes(keyStr)).bytes;
  final checksum = toHex(Uint8List.fromList(checksumFull.skip(28).toList()));
  return "acc://$keyStr$checksum";
}

/// Derive a Lite Token Account URL from a 20-byte key hash
///
/// Same as deriveLiteIdentityFromKeyHash but appends /ACME for ACME token accounts.
String deriveLiteTokenAccountFromKeyHash(Uint8List keyHash20, [String tokenPath = "ACME"]) {
  return "${deriveLiteIdentityFromKeyHash(keyHash20)}/$tokenPath";
}
