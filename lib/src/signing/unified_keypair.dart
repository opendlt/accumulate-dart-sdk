import "dart:typed_data";
import "package:crypto/crypto.dart" as crypto;
import "../crypto/ed25519.dart";
import "../crypto/rcd1.dart";
import "../crypto/secp256k1.dart";
import "../crypto/rsa.dart";
import "../crypto/ecdsa.dart";
import "../protocol/envelope.dart";
import "../build/context.dart";
import "../build/builders.dart";
import "algorithm.dart";

/// A unified key pair abstraction that wraps any supported key type
///
/// This class provides a single interface for all key types, automatically
/// selecting the correct signature algorithm and hash format. Developers
/// don't need to know which buildAndSign* method to call - just use
/// UnifiedKeyPair.sign() and it handles everything.
///
/// Example usage:
/// ```dart
/// // Create from any key type
/// final key = UnifiedKeyPair.fromEd25519(ed25519KeyPair);
/// final key = UnifiedKeyPair.fromETH(secp256k1KeyPair);
/// final key = UnifiedKeyPair.fromRSA(rsaKeyPair);
///
/// // Sign - automatically uses correct signature format
/// final envelope = await key.sign(ctx, body, signerUrl: "...", signerVersion: 1);
/// ```
class UnifiedKeyPair {
  final SignatureAlgorithm _algorithm;
  final dynamic _keypair;

  UnifiedKeyPair._(this._algorithm, this._keypair);

  /// The signature algorithm this key pair uses
  SignatureAlgorithm get algorithm => _algorithm;

  /// Create unified key pair from Ed25519 key pair
  factory UnifiedKeyPair.fromEd25519(Ed25519KeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.ed25519, keypair);
  }

  /// Create unified key pair from RCD1 key pair
  factory UnifiedKeyPair.fromRCD1(RCD1KeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.rcd1, keypair);
  }

  /// Create unified key pair from secp256k1 key pair for BTC signatures
  factory UnifiedKeyPair.fromBTC(Secp256k1KeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.btc, keypair);
  }

  /// Create unified key pair from secp256k1 key pair for ETH V1 signatures
  ///
  /// Use this for networks that have NOT enabled V2 Baikonur upgrade.
  factory UnifiedKeyPair.fromETHv1(Secp256k1KeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.ethV1, keypair);
  }

  /// Create unified key pair from secp256k1 key pair for ETH V2 signatures
  ///
  /// Use this for networks WITH V2 Baikonur upgrade enabled.
  /// This is the default for modern networks like Kermit testnet.
  factory UnifiedKeyPair.fromETH(Secp256k1KeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.ethV2, keypair);
  }

  /// Create unified key pair from RSA key pair
  ///
  /// Note: RSA signatures require V2 Vandenberg upgrade on the network.
  factory UnifiedKeyPair.fromRSA(RsaKeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.rsaSha256, keypair);
  }

  /// Create unified key pair from ECDSA key pair
  ///
  /// Note: ECDSA signatures require V2 Vandenberg upgrade on the network.
  factory UnifiedKeyPair.fromECDSA(EcdsaKeyPair keypair) {
    return UnifiedKeyPair._(SignatureAlgorithm.ecdsaSha256, keypair);
  }

  /// Get the public key hash for this key pair
  ///
  /// The format depends on the key type:
  /// - Ed25519: SHA256(publicKey) - 32 bytes
  /// - RCD1: RCD1 hash - 32 bytes
  /// - BTC: RIPEMD160(SHA256(compressedPubKey)) - 20 bytes
  /// - ETH: Keccak256(uncompressedPubKey[1:])[12:] - 20 bytes
  /// - RSA: SHA256(PKCS#1 DER pubKey) - 32 bytes
  /// - ECDSA: SHA256(SPKI DER pubKey) - 32 bytes
  Future<Uint8List> get publicKeyHash async {
    switch (_algorithm) {
      case SignatureAlgorithm.ed25519:
        final kp = _keypair as Ed25519KeyPair;
        final pub = await kp.publicKeyBytes();
        return Uint8List.fromList(crypto.sha256.convert(pub).bytes);
      case SignatureAlgorithm.rcd1:
        final kp = _keypair as RCD1KeyPair;
        return await kp.publicKeyHash();
      case SignatureAlgorithm.btc:
      case SignatureAlgorithm.btcLegacy:
        return (_keypair as Secp256k1KeyPair).btcPublicKeyHash;
      case SignatureAlgorithm.ethV1:
      case SignatureAlgorithm.ethV2:
        return (_keypair as Secp256k1KeyPair).ethPublicKeyHash;
      case SignatureAlgorithm.rsaSha256:
        return (_keypair as RsaKeyPair).publicKeyHash;
      case SignatureAlgorithm.ecdsaSha256:
        return (_keypair as EcdsaKeyPair).publicKeyHash;
    }
  }

  /// Get the raw key pair (use with caution)
  dynamic get rawKeyPair => _keypair;

  /// Sign a transaction with this key pair
  ///
  /// Automatically selects the correct signature algorithm based on the key type.
  /// This is the main convenience method - no need to know which buildAndSign*
  /// method to use.
  ///
  /// Parameters:
  /// - ctx: Build context with principal, timestamp, and optional header fields
  /// - body: Transaction body map
  /// - signerUrl: Signer URL (usually a key page like "acc://adi.acme/book/1")
  /// - signerVersion: Current version of the signer (key page)
  /// - vote: Optional vote for governance transactions
  /// - signatureMemo: Optional memo attached to the signature
  /// - signatureData: Optional metadata attached to the signature
  Future<Envelope> sign({
    required BuildContext ctx,
    required Map<String, dynamic> body,
    required String signerUrl,
    required int signerVersion,
    VoteType? vote,
    String? signatureMemo,
    Uint8List? signatureData,
  }) async {
    switch (_algorithm) {
      case SignatureAlgorithm.ed25519:
        return TxSigner.buildAndSign(
          ctx: ctx,
          body: body,
          keypair: _keypair as Ed25519KeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.rcd1:
        return TxSigner.buildAndSignRCD1(
          ctx: ctx,
          body: body,
          keypair: _keypair as RCD1KeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.btc:
        return TxSigner.buildAndSignBTC(
          ctx: ctx,
          body: body,
          keypair: _keypair as Secp256k1KeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.btcLegacy:
        // BTC Legacy uses same method as BTC
        return TxSigner.buildAndSignBTC(
          ctx: ctx,
          body: body,
          keypair: _keypair as Secp256k1KeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.ethV1:
        return TxSigner.buildAndSignETHv1(
          ctx: ctx,
          body: body,
          keypair: _keypair as Secp256k1KeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.ethV2:
        return TxSigner.buildAndSignETH(
          ctx: ctx,
          body: body,
          keypair: _keypair as Secp256k1KeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.rsaSha256:
        return TxSigner.buildAndSignRSA(
          ctx: ctx,
          body: body,
          keypair: _keypair as RsaKeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );

      case SignatureAlgorithm.ecdsaSha256:
        return TxSigner.buildAndSignECDSA(
          ctx: ctx,
          body: body,
          keypair: _keypair as EcdsaKeyPair,
          signerUrl: signerUrl,
          signerVersion: signerVersion,
          vote: vote,
          signatureMemo: signatureMemo,
          signatureData: signatureData,
        );
    }
  }
}
