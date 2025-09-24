import "dart:typed_data";
import "package:cryptography/cryptography.dart";
import "package:crypto/crypto.dart";
import "../util/bytes.dart";
import "../util/acc_url.dart";

/// Ed25519 key pair with Accumulate-specific derivations
///
/// LID/LTA derivation rules discovered from Go: protocol/protocol.go:280-297, 273-278
/// - For Ed25519: keyHash = SHA256(publicKey)
/// - LID: acc://<keyHash[0:20]><checksum> where checksum = SHA256(hex(keyHash[0:20]))[28:]
/// - LTA: acc://<keyHash[0:20]><checksum>/ACME
class Ed25519KeyPair {
  final SimpleKeyPair keyPair;
  final SimplePublicKey publicKey;

  Ed25519KeyPair._(this.keyPair, this.publicKey);

  /// Generate a new Ed25519 key pair
  static Future<Ed25519KeyPair> generate() async {
    final kp = await Ed25519().newKeyPair();
    final pk = await kp.extractPublicKey();
    return Ed25519KeyPair._(kp, pk);
  }

  /// Create key pair from 32-byte seed
  static Future<Ed25519KeyPair> fromSeed(Uint8List seed32) async {
    if (seed32.length != 32) {
      throw ArgumentError("Seed must be exactly 32 bytes");
    }
    final kp = await Ed25519().newKeyPairFromSeed(seed32);
    final pk = await kp.extractPublicKey();
    return Ed25519KeyPair._(kp, pk);
  }

  /// Get public key as bytes
  Future<Uint8List> publicKeyBytes() async {
    return Uint8List.fromList(publicKey.bytes);
  }

  /// Sign message with Ed25519
  Future<Uint8List> sign(Uint8List msg) async {
    final signature = await Ed25519().sign(msg, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verify Ed25519 signature
  Future<bool> verify(Uint8List msg, Uint8List sig) async {
    try {
      return await Ed25519()
          .verify(msg, signature: Signature(sig, publicKey: publicKey));
    } catch (e) {
      return false;
    }
  }

  /// Derive Lite Identity URL using discovered algorithm
  /// Go: protocol/protocol.go:290-296 - keyHash = SHA256(publicKey) for Ed25519
  /// Go: protocol/protocol.go:273-278 - LID format with checksum
  Future<AccUrl> deriveLiteIdentityUrl() async {
    final pk = await publicKeyBytes();

    // For Ed25519: keyHash = SHA256(publicKey) - Go: protocol/protocol.go:290
    final keyHashFull = sha256.convert(pk).bytes;

    // Use first 20 bytes - Go: protocol/protocol.go:274
    final keyHash20 = Uint8List.fromList(keyHashFull.take(20).toList());

    // Convert to hex string - Go: protocol/protocol.go:274
    final keyStr = toHex(keyHash20);

    // Calculate checksum - Go: protocol/protocol.go:275-276
    final checksumFull = sha256.convert(utf8Bytes(keyStr)).bytes;
    final checksum = toHex(Uint8List.fromList(checksumFull.skip(28).toList()));

    // Format: acc://<keyHash[0:20]><checksum> - Go: protocol/protocol.go:277
    return AccUrl.parse("acc://$keyStr$checksum");
  }

  /// Derive Lite Token Account URL for ACME
  /// Go: protocol/protocol.go:267-268 - LTA = LID + "/ACME" path
  Future<AccUrl> deriveLiteTokenAccountUrl() async {
    final lid = await deriveLiteIdentityUrl();
    return AccUrl.parse("${lid.value}/ACME");
  }
}
