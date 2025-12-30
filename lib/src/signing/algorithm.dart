/// Signature algorithm types supported by Accumulate
///
/// This enum maps key types to their corresponding signature types,
/// abstracting away the complexity of knowing which signature format
/// to use for each key type.
///
/// Matches Go: protocol/signature.go SignatureType constants
enum SignatureAlgorithm {
  /// Ed25519 - Standard Accumulate signature (32-byte public key)
  /// Most common signature type, works on all networks.
  ed25519,

  /// RCD1 - Factom-style Ed25519 (same signing, different key hash)
  /// Used for Factom compatibility.
  rcd1,

  /// BTC - Bitcoin-style secp256k1 with DER signature format
  /// 33-byte compressed public key, RIPEMD160(SHA256(pubKey)) hash
  btc,

  /// BTC Legacy - Older Bitcoin signature format
  /// Same as BTC but uses legacy type code.
  btcLegacy,

  /// ETH V1 - Ethereum-style secp256k1 with DER signature (pre-Baikonur)
  /// 65-byte uncompressed public key, Keccak256(pubKey)[12:] hash
  /// Use this for networks that have NOT enabled V2 Baikonur upgrade.
  ethV1,

  /// ETH V2 - Ethereum-style secp256k1 with RSV signature (post-Baikonur)
  /// 65-byte uncompressed public key, Keccak256(pubKey)[12:] hash
  /// Use this for networks WITH V2 Baikonur upgrade enabled.
  ethV2,

  /// RSA-SHA256 - RSA signature with PKCS#1 v1.5 and SHA-256
  /// Variable-length public key (PKCS#1 DER format)
  /// REQUIRES V2 Vandenberg upgrade on the network.
  rsaSha256,

  /// ECDSA-SHA256 - ECDSA with P-256/P-384/P-521 curves and SHA-256
  /// SPKI DER format public key
  /// REQUIRES V2 Vandenberg upgrade on the network.
  ecdsaSha256,
}

/// Extension methods for SignatureAlgorithm
extension SignatureAlgorithmExtension on SignatureAlgorithm {
  /// Get the JSON type name for this signature algorithm
  String get typeName {
    switch (this) {
      case SignatureAlgorithm.ed25519:
        return "ed25519";
      case SignatureAlgorithm.rcd1:
        return "rcd1";
      case SignatureAlgorithm.btc:
        return "btc";
      case SignatureAlgorithm.btcLegacy:
        return "btcLegacy";
      case SignatureAlgorithm.ethV1:
      case SignatureAlgorithm.ethV2:
        return "eth";
      case SignatureAlgorithm.rsaSha256:
        return "rsaSha256";
      case SignatureAlgorithm.ecdsaSha256:
        return "ecdsaSha256";
    }
  }

  /// Whether this algorithm requires V2 Baikonur upgrade
  bool get requiresBaikonur {
    return this == SignatureAlgorithm.ethV2;
  }

  /// Whether this algorithm requires V2 Vandenberg upgrade
  bool get requiresVandenberg {
    switch (this) {
      case SignatureAlgorithm.rsaSha256:
      case SignatureAlgorithm.ecdsaSha256:
        return true;
      default:
        return false;
    }
  }

  /// Human-readable description
  String get description {
    switch (this) {
      case SignatureAlgorithm.ed25519:
        return "Ed25519 (standard)";
      case SignatureAlgorithm.rcd1:
        return "RCD1 (Factom-compatible)";
      case SignatureAlgorithm.btc:
        return "BTC (Bitcoin secp256k1)";
      case SignatureAlgorithm.btcLegacy:
        return "BTC Legacy";
      case SignatureAlgorithm.ethV1:
        return "ETH V1 (DER format, pre-Baikonur)";
      case SignatureAlgorithm.ethV2:
        return "ETH V2 (RSV format, post-Baikonur)";
      case SignatureAlgorithm.rsaSha256:
        return "RSA-SHA256 (requires Vandenberg)";
      case SignatureAlgorithm.ecdsaSha256:
        return "ECDSA-SHA256 (requires Vandenberg)";
    }
  }
}
