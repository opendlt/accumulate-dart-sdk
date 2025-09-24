import "dart:typed_data";
import "package:crypto/crypto.dart" as c;

Uint8List sha256Bytes(Uint8List input) =>
    Uint8List.fromList(c.sha256.convert(input).bytes);

/// Convenience for hashing canonical JSON bytes.
/// Use only where spec requires JSON-level canonicalization. Prefer binary where applicable.
Uint8List sha256OfBytes(Uint8List bytes) => sha256Bytes(bytes);
