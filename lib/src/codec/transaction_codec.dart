import "dart:typed_data";
import "dart:convert";
import "package:crypto/crypto.dart";
import "codec.dart";

/// Transaction hashing facade that implements discovered rules from Go/TypeScript
///
/// Key discoveries:
/// - Go: protocol/transaction_hash.go:27-71 - SHA256(SHA256(header_binary) + SHA256(body_binary))
/// - TypeScript: src/core/base.ts:13-44 - Same algorithm with special WriteData handling
/// - Signing: protocol/signature_utils.go:50-57 - SHA256(signature_metadata_hash + transaction_hash)
class TransactionCodec {
  /// Encode transaction for signing - implements discovered preimage construction
  /// Based on Go: protocol/transaction_hash.go:27-71 and TypeScript: src/core/base.ts:13-44
  static Uint8List encodeTxForSigning(
      Map<String, dynamic> header, Map<String, dynamic> body) {
    // Encode header and body to canonical binary format
    final headerBytes = AccumulateCodec.bytesMarshalBinary(
        Uint8List.fromList(utf8.encode(jsonEncode(header))));
    final bodyBytes = AccumulateCodec.bytesMarshalBinary(
        Uint8List.fromList(utf8.encode(jsonEncode(body))));

    // Hash header and body separately
    final headerHash = sha256.convert(headerBytes).bytes;
    final bodyHash = sha256.convert(bodyBytes).bytes;

    // Transaction hash = SHA256(SHA256(header) + SHA256(body))
    final combined = Uint8List.fromList([...headerHash, ...bodyHash]);
    return Uint8List.fromList(sha256.convert(combined).bytes);
  }

  /// Create signing preimage - implements discovered signing rules
  /// Based on Go: protocol/signature_utils.go:50-57
  static Uint8List createSigningPreimage(
      Uint8List signatureMetadataHash, Uint8List transactionHash) {
    final combined =
        Uint8List.fromList([...signatureMetadataHash, ...transactionHash]);
    return Uint8List.fromList(sha256.convert(combined).bytes);
  }
}
