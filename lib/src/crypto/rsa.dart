import "dart:typed_data";
import "package:crypto/crypto.dart" hide Digest;
import "package:pointycastle/export.dart";
import "package:pointycastle/asn1.dart";
import "../util/bytes.dart";
import "../util/acc_url.dart";
import "secp256k1.dart" show NullDigest;

/// RSA key pair for RSA-SHA256 signatures
///
/// Matches Go: protocol/signature.go RsaSha256Signature
/// Uses PKCS#1 v1.5 signature scheme with SHA-256 hash
class RsaKeyPair {
  final RSAPrivateKey _privateKey;
  final RSAPublicKey _publicKey;

  RsaKeyPair._(this._privateKey, this._publicKey);

  /// Generate a new RSA key pair
  ///
  /// [bitLength] is the key size in bits (2048 or 4096 recommended)
  static RsaKeyPair generate({int bitLength = 2048}) {
    final keyGen = RSAKeyGenerator();

    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.from(65537), bitLength, 64),
      secureRandom(),
    ));

    final pair = keyGen.generateKeyPair();
    return RsaKeyPair._(
      pair.privateKey as RSAPrivateKey,
      pair.publicKey as RSAPublicKey,
    );
  }

  /// Create key pair from PKCS#1 DER encoded private key
  ///
  /// Matches Go: x509.ParsePKCS1PrivateKey()
  static RsaKeyPair fromPKCS1PrivateKey(Uint8List derBytes) {
    final parser = ASN1Parser(derBytes);
    final sequence = parser.nextObject() as ASN1Sequence;

    // PKCS#1 format: version, n, e, d, p, q, dP, dQ, qInv
    final n = (sequence.elements![1] as ASN1Integer).integer;
    final e = (sequence.elements![2] as ASN1Integer).integer;
    final d = (sequence.elements![3] as ASN1Integer).integer;
    final p = (sequence.elements![4] as ASN1Integer).integer;
    final q = (sequence.elements![5] as ASN1Integer).integer;

    final privateKey = RSAPrivateKey(n!, d!, p, q);
    final publicKey = RSAPublicKey(n, e!);

    return RsaKeyPair._(privateKey, publicKey);
  }

  /// Get public key as PKCS#1 DER encoded bytes
  ///
  /// Matches Go: x509.MarshalPKCS1PublicKey()
  Uint8List get publicKeyBytes {
    return _encodePKCS1PublicKey(_publicKey);
  }

  /// Get private key as PKCS#1 DER encoded bytes
  ///
  /// Matches Go: x509.MarshalPKCS1PrivateKey()
  Uint8List get privateKeyBytes {
    return _encodePKCS1PrivateKey(_privateKey);
  }

  /// Get SHA-256 hash of public key
  ///
  /// Matches Go: protocol/signature.go RsaSha256Signature.GetPublicKeyHash()
  Uint8List get publicKeyHash {
    return Uint8List.fromList(sha256.convert(publicKeyBytes).bytes);
  }

  /// Sign message with RSA-SHA256 (PKCS#1 v1.5)
  ///
  /// Matches Go: protocol/signature.go SignRsaSha256()
  /// IMPORTANT: message is expected to be a pre-hashed 32-byte value.
  /// We use NullDigest to avoid double-hashing since RSA signers normally hash.
  /// The DigestInfo OID still indicates SHA-256 (matching Go's rsa.SignPKCS1v15).
  Uint8List sign(Uint8List message) {
    final signer = RSASigner(NullDigest(32), "0609608648016503040201");

    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));

    return signer.generateSignature(message).bytes;
  }

  /// Verify RSA-SHA256 signature
  ///
  /// Matches Go: protocol/signature.go RsaSha256Signature.Verify()
  /// message is expected to be a pre-hashed 32-byte value.
  bool verify(Uint8List message, Uint8List signature) {
    try {
      final verifier = RSASigner(NullDigest(32), "0609608648016503040201");
      verifier.init(false, PublicKeyParameter<RSAPublicKey>(_publicKey));
      return verifier.verifySignature(message, RSASignature(signature));
    } catch (e) {
      return false;
    }
  }

  /// Derive Lite Identity URL
  Future<AccUrl> deriveLiteIdentityUrl() async {
    final keyHash20 = Uint8List.fromList(publicKeyHash.take(20).toList());
    return AccUrl.parse(deriveLiteIdentityFromKeyHash(keyHash20));
  }

  // Helper functions for PKCS#1 encoding

  /// Encode RSA public key to PKCS#1 DER format
  static Uint8List _encodePKCS1PublicKey(RSAPublicKey key) {
    final sequence = ASN1Sequence();
    sequence.add(ASN1Integer(key.modulus!));
    sequence.add(ASN1Integer(key.exponent!));
    return sequence.encode();
  }

  /// Encode RSA private key to PKCS#1 DER format
  static Uint8List _encodePKCS1PrivateKey(RSAPrivateKey key) {
    // Calculate additional CRT parameters
    final p = key.p!;
    final q = key.q!;
    final d = key.privateExponent!;
    final dP = d % (p - BigInt.one);
    final dQ = d % (q - BigInt.one);
    final qInv = q.modInverse(p);

    final sequence = ASN1Sequence();
    sequence.add(ASN1Integer(BigInt.zero)); // version
    sequence.add(ASN1Integer(key.modulus!)); // n
    sequence.add(ASN1Integer(key.publicExponent!)); // e
    sequence.add(ASN1Integer(key.privateExponent!)); // d
    sequence.add(ASN1Integer(p)); // p
    sequence.add(ASN1Integer(q)); // q
    sequence.add(ASN1Integer(dP)); // dP
    sequence.add(ASN1Integer(dQ)); // dQ
    sequence.add(ASN1Integer(qInv)); // qInv

    return sequence.encode();
  }
}
