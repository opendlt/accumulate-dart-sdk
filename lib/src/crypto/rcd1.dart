import "dart:typed_data";
import "package:cryptography/cryptography.dart";
import "package:crypto/crypto.dart";
import "../util/bytes.dart";
import "../util/acc_url.dart";

/// RCD1 key pair (Factom-style Ed25519)
///
/// RCD1 uses Ed25519 for signing but computes the key hash differently.
/// Matches Go: protocol/signature.go RCD1Signature
///
/// Key hash algorithm: SHA256(SHA256([0x01] + publicKey))
/// This is compatible with Factom's RCD Type 1 addresses.
class RCD1KeyPair {
  final SimpleKeyPair keyPair;
  final SimplePublicKey publicKey;

  RCD1KeyPair._(this.keyPair, this.publicKey);

  /// Generate a new RCD1 key pair
  static Future<RCD1KeyPair> generate() async {
    final kp = await Ed25519().newKeyPair();
    final pk = await kp.extractPublicKey();
    return RCD1KeyPair._(kp, pk);
  }

  /// Create key pair from 32-byte seed
  static Future<RCD1KeyPair> fromSeed(Uint8List seed32) async {
    if (seed32.length != 32) {
      throw ArgumentError("Seed must be exactly 32 bytes");
    }
    final kp = await Ed25519().newKeyPairFromSeed(seed32);
    final pk = await kp.extractPublicKey();
    return RCD1KeyPair._(kp, pk);
  }

  /// Get public key as bytes (32 bytes for Ed25519)
  Future<Uint8List> publicKeyBytes() async {
    return Uint8List.fromList(publicKey.bytes);
  }

  /// Get RCD1 hash of public key
  ///
  /// Matches Go: protocol/signature.go GetRCDHashFromPublicKey()
  /// RCD1 hash = SHA256(SHA256([0x01] + publicKey))
  Future<Uint8List> publicKeyHash() async {
    final pk = await publicKeyBytes();
    return getRCDHashFromPublicKey(pk, 1);
  }

  /// Sign message with Ed25519 (same as standard Ed25519)
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

  /// Derive Lite Identity URL using RCD1 key hash
  Future<AccUrl> deriveLiteIdentityUrl() async {
    final keyHashFull = await publicKeyHash();
    final keyHash20 = Uint8List.fromList(keyHashFull.take(20).toList());
    return AccUrl.parse(deriveLiteIdentityFromKeyHash(keyHash20));
  }

  /// Derive Lite Token Account URL for ACME
  Future<AccUrl> deriveLiteTokenAccountUrl() async {
    final lid = await deriveLiteIdentityUrl();
    return AccUrl.parse("${lid.value}/ACME");
  }
}

/// Compute RCD hash from public key
///
/// Matches Go: protocol/signature.go GetRCDHashFromPublicKey()
/// For RCD type 1: hash = SHA256(SHA256([0x01] + publicKey))
Uint8List getRCDHashFromPublicKey(Uint8List publicKey, int rcdType) {
  if (rcdType != 1) {
    throw ArgumentError("Only RCD type 1 is supported");
  }

  // Prepend RCD type byte to public key
  final data = Uint8List(1 + publicKey.length);
  data[0] = rcdType;
  data.setAll(1, publicKey);

  // Double SHA256
  final firstHash = sha256.convert(data).bytes;
  final secondHash = sha256.convert(firstHash).bytes;

  return Uint8List.fromList(secondHash);
}
