import "dart:typed_data";
import "package:crypto/crypto.dart" hide Digest;
import "package:pointycastle/export.dart";
import "package:pointycastle/asn1.dart";
import "../util/bytes.dart";
import "../util/acc_url.dart";
import "secp256k1.dart" show NullDigest;

/// ECDSA key pair for ECDSA-SHA256 signatures
///
/// Matches Go: protocol/signature.go EcdsaSha256Signature
/// Supports P-256 (secp256r1), P-384, and P-521 curves
/// Uses ASN.1 DER encoded signatures
class EcdsaKeyPair {
  final ECPrivateKey _privateKey;
  final ECPublicKey _publicKey;
  final String _curveName;

  EcdsaKeyPair._(this._privateKey, this._publicKey, this._curveName);

  /// Generate a new ECDSA key pair
  ///
  /// [curve] is the elliptic curve name: "secp256r1" (P-256), "secp384r1" (P-384), or "secp521r1" (P-521)
  static EcdsaKeyPair generate({String curve = "secp256r1"}) {
    final domain = ECDomainParameters(curve);
    final keyGen = ECKeyGenerator();

    keyGen.init(ParametersWithRandom(ECKeyGeneratorParameters(domain), secureRandom()));

    final pair = keyGen.generateKeyPair();
    return EcdsaKeyPair._(
      pair.privateKey as ECPrivateKey,
      pair.publicKey as ECPublicKey,
      curve,
    );
  }

  /// Create key pair from SEC 1 / ASN.1 DER encoded private key
  ///
  /// Matches Go: x509.ParseECPrivateKey()
  static EcdsaKeyPair fromDERPrivateKey(Uint8List derBytes) {
    final parser = ASN1Parser(derBytes);
    final sequence = parser.nextObject() as ASN1Sequence;

    // SEC 1 EC private key format
    // version, privateKey, [0] parameters (curve OID), [1] publicKey
    final privateKeyOctet = sequence.elements![1] as ASN1OctetString;
    final d = bytesToBigInt(privateKeyOctet.octets!);

    // Extract curve from parameters
    String curveName = "secp256r1"; // default
    for (final element in sequence.elements!) {
      if (element is ASN1Sequence && element.elements!.isNotEmpty) {
        final oid = element.elements![0];
        if (oid is ASN1ObjectIdentifier) {
          curveName = _oidToCurveName(oid.objectIdentifierAsString!);
        }
      }
    }

    final domain = ECDomainParameters(curveName);
    final Q = domain.G * d;

    return EcdsaKeyPair._(
      ECPrivateKey(d, domain),
      ECPublicKey(Q, domain),
      curveName,
    );
  }

  /// Get curve name
  String get curveName => _curveName;

  /// Get public key as PKIX/SubjectPublicKeyInfo DER encoded bytes
  ///
  /// Matches Go: x509.MarshalPKIXPublicKey() for EC keys
  Uint8List get publicKeyBytes {
    return _encodePKIXPublicKey(_publicKey);
  }

  /// Get private key as SEC 1 / ASN.1 DER encoded bytes
  ///
  /// Matches Go: x509.MarshalECPrivateKey()
  Uint8List get privateKeyBytes {
    return _encodeSEC1PrivateKey(_privateKey);
  }

  /// Get SHA-256 hash of public key
  ///
  /// Matches Go: protocol/signature.go EcdsaSha256Signature.GetPublicKeyHash()
  Uint8List get publicKeyHash {
    return Uint8List.fromList(sha256.convert(publicKeyBytes).bytes);
  }

  /// Sign message with ECDSA-SHA256 (ASN.1 DER encoded signature)
  ///
  /// Matches Go: protocol/signature.go SignEcdsaSha256()
  /// IMPORTANT: message is expected to be a pre-hashed 32-byte value.
  /// We use NullDigest to avoid double-hashing since ECDSA signers normally hash.
  Uint8List sign(Uint8List message) {
    final signer = ECDSASigner(NullDigest(32), null);
    signer.init(true, ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(_privateKey),
      secureRandom(),
    ));

    final sig = signer.generateSignature(message) as ECSignature;

    // ASN.1 DER encode the signature
    return derEncode(sig.r, sig.s);
  }

  /// Verify ECDSA-SHA256 signature (ASN.1 DER encoded)
  ///
  /// Matches Go: protocol/signature.go EcdsaSha256Signature.Verify()
  /// message is expected to be a pre-hashed 32-byte value.
  bool verify(Uint8List message, Uint8List signature) {
    try {
      final verifier = ECDSASigner(NullDigest(32), null);
      verifier.init(false, PublicKeyParameter<ECPublicKey>(_publicKey));

      final decoded = derDecode(signature);
      if (decoded == null) return false;

      final sig = ECSignature(decoded.$1, decoded.$2);
      return verifier.verifySignature(message, sig);
    } catch (e) {
      return false;
    }
  }

  /// Derive Lite Identity URL
  Future<AccUrl> deriveLiteIdentityUrl() async {
    final keyHash20 = Uint8List.fromList(publicKeyHash.take(20).toList());
    return AccUrl.parse(deriveLiteIdentityFromKeyHash(keyHash20));
  }

  // Helper functions for curve OID conversion

  static String _oidToCurveName(String oid) {
    switch (oid) {
      case "1.2.840.10045.3.1.7":
        return "secp256r1";
      case "1.3.132.0.34":
        return "secp384r1";
      case "1.3.132.0.35":
        return "secp521r1";
      default:
        return "secp256r1";
    }
  }

  static String _curveNameToOid(String curveName) {
    switch (curveName) {
      case "secp256r1":
        return "1.2.840.10045.3.1.7";
      case "secp384r1":
        return "1.3.132.0.34";
      case "secp521r1":
        return "1.3.132.0.35";
      default:
        return "1.2.840.10045.3.1.7";
    }
  }

  /// Encode EC public key to PKIX/SubjectPublicKeyInfo DER format
  static Uint8List _encodePKIXPublicKey(ECPublicKey key) {
    final curveName = key.parameters!.domainName;
    final curveOid = _curveNameToOid(curveName);

    // Encode the public key point (uncompressed format)
    final point = key.Q!;
    final coordLen = (key.parameters!.curve.fieldSize + 7) ~/ 8;
    final x = bigIntToBytes(point.x!.toBigInteger()!, coordLen);
    final y = bigIntToBytes(point.y!.toBigInteger()!, coordLen);

    final publicKeyBits = Uint8List(1 + coordLen * 2);
    publicKeyBits[0] = 0x04; // uncompressed point
    publicKeyBits.setAll(1, x);
    publicKeyBits.setAll(1 + coordLen, y);

    // Build SubjectPublicKeyInfo
    final algorithmId = ASN1Sequence();
    algorithmId.add(ASN1ObjectIdentifier.fromIdentifierString("1.2.840.10045.2.1")); // ecPublicKey OID
    algorithmId.add(ASN1ObjectIdentifier.fromIdentifierString(curveOid));

    final subjectPublicKeyInfo = ASN1Sequence();
    subjectPublicKeyInfo.add(algorithmId);
    subjectPublicKeyInfo.add(ASN1BitString(stringValues: publicKeyBits));

    return subjectPublicKeyInfo.encode();
  }

  /// Encode EC private key to SEC 1 DER format
  static Uint8List _encodeSEC1PrivateKey(ECPrivateKey key) {
    final curveName = key.parameters!.domainName;
    final coordLen = (key.parameters!.curve.fieldSize + 7) ~/ 8;

    // Private key bytes
    final dBytes = bigIntToBytes(key.d!, coordLen);

    // Public key point (uncompressed)
    final Q = key.parameters!.G * key.d;
    final x = bigIntToBytes(Q!.x!.toBigInteger()!, coordLen);
    final y = bigIntToBytes(Q.y!.toBigInteger()!, coordLen);
    final publicKeyBits = Uint8List(1 + coordLen * 2);
    publicKeyBits[0] = 0x04;
    publicKeyBits.setAll(1, x);
    publicKeyBits.setAll(1 + coordLen, y);

    // Build SEC 1 structure
    final sequence = ASN1Sequence();
    sequence.add(ASN1Integer(BigInt.one)); // version
    sequence.add(ASN1OctetString(octets: dBytes)); // privateKey

    // [0] parameters - curve OID (context-specific constructed tag 0)
    final curveOid = _curveNameToOid(curveName);
    final paramsSeq = ASN1Sequence(tag: 0xA0); // context-specific [0]
    paramsSeq.add(ASN1ObjectIdentifier.fromIdentifierString(curveOid));

    // [1] publicKey (context-specific constructed tag 1)
    final pubKeySeq = ASN1Sequence(tag: 0xA1); // context-specific [1]
    pubKeySeq.add(ASN1BitString(stringValues: publicKeyBits));

    return sequence.encode();
  }
}
