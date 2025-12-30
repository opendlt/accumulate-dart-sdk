import "dart:typed_data";
import "package:crypto/crypto.dart" hide Digest;
import "package:pointycastle/export.dart";
import "../util/bytes.dart";
import "../util/acc_url.dart";

/// NullDigest - a digest that passes through input unchanged (for pre-hashed messages)
///
/// Use this when signing messages that are already hashed. ECDSA signers
/// typically hash the message before signing, but if the message is already
/// a hash (like our signing preimage), we don't want to hash it again.
class NullDigest implements Digest {
  Uint8List? _data;
  final int _digestSize;

  NullDigest([this._digestSize = 32]);

  @override
  String get algorithmName => "NULL";

  @override
  int get digestSize => _digestSize;

  @override
  int get byteLength => _digestSize;

  @override
  void reset() {
    _data = null;
  }

  @override
  void updateByte(int inp) {
    if (_data == null) {
      _data = Uint8List(1);
      _data![0] = inp;
    } else {
      final newData = Uint8List(_data!.length + 1);
      newData.setAll(0, _data!);
      newData[_data!.length] = inp;
      _data = newData;
    }
  }

  @override
  void update(Uint8List inp, int inpOff, int len) {
    final chunk = inp.sublist(inpOff, inpOff + len);
    if (_data == null) {
      _data = Uint8List.fromList(chunk);
    } else {
      final newData = Uint8List(_data!.length + len);
      newData.setAll(0, _data!);
      newData.setAll(_data!.length, chunk);
      _data = newData;
    }
  }

  @override
  int doFinal(Uint8List out, int outOff) {
    // Just copy the input to output unchanged
    if (_data != null) {
      out.setAll(outOff, _data!);
      final len = _data!.length;
      reset();
      return len;
    }
    return 0;
  }

  @override
  Uint8List process(Uint8List data) {
    // For pre-hashed data, just return as-is
    return data;
  }
}

/// Secp256k1 key pair for BTC and ETH signatures
///
/// Matches Go: protocol/signature.go BTCSignature, ETHSignature
/// Uses secp256k1 elliptic curve (same as Bitcoin and Ethereum)
class Secp256k1KeyPair {
  final Uint8List _privateKey;
  final Uint8List _publicKey;
  final bool _compressed;

  Secp256k1KeyPair._(this._privateKey, this._publicKey, this._compressed);

  /// Generate a new secp256k1 key pair with compressed public key
  static Secp256k1KeyPair generate({bool compressed = true}) {
    return fromPrivateKey(randomBytes(32), compressed: compressed);
  }

  /// Create key pair from 32-byte private key
  static Secp256k1KeyPair fromPrivateKey(Uint8List privateKey,
      {bool compressed = true}) {
    if (privateKey.length != 32) {
      throw ArgumentError("Private key must be exactly 32 bytes");
    }

    final domain = ECDomainParameters("secp256k1");
    final d = bytesToBigInt(privateKey);
    final Q = domain.G * d;

    Uint8List publicKey;
    if (compressed) {
      publicKey = _encodeCompressedPoint(Q!);
    } else {
      publicKey = _encodeUncompressedPoint(Q!);
    }

    return Secp256k1KeyPair._(Uint8List.fromList(privateKey), publicKey, compressed);
  }

  /// Get private key bytes
  Uint8List get privateKeyBytes => Uint8List.fromList(_privateKey);

  /// Get public key bytes (33 bytes compressed, 65 bytes uncompressed)
  Uint8List get publicKeyBytes => Uint8List.fromList(_publicKey);

  /// Get uncompressed public key bytes (65 bytes: 0x04 + X + Y)
  /// This is required for ETH signatures which need the full uncompressed key
  Uint8List get uncompressedPublicKeyBytes {
    if (!_compressed) {
      return Uint8List.fromList(_publicKey);
    }
    return _decompressPublicKey(_publicKey);
  }

  /// Get BTC-style public key hash (RIPEMD160(SHA256(pubKey)))
  ///
  /// Matches Go: protocol/signature.go BTCHash()
  Uint8List get btcPublicKeyHash {
    final sha256Hash = sha256.convert(_publicKey).bytes;
    final ripemd = RIPEMD160Digest();
    return ripemd.process(Uint8List.fromList(sha256Hash));
  }

  /// Get ETH-style public key hash (Keccak256(pubKey)[12:])
  ///
  /// Matches Go: protocol/signature.go ETHhash()
  /// For ETH, we need the uncompressed public key without the 0x04 prefix
  Uint8List get ethPublicKeyHash {
    Uint8List pubKeyForHash;
    if (_compressed) {
      // Decompress the public key
      pubKeyForHash = _decompressPublicKey(_publicKey);
    } else {
      pubKeyForHash = _publicKey;
    }

    // Remove 0x04 prefix if present (uncompressed point format)
    if (pubKeyForHash[0] == 0x04) {
      pubKeyForHash = pubKeyForHash.sublist(1);
    }

    // Keccak256 hash, take last 20 bytes
    final keccak = KeccakDigest(256);
    final hash = keccak.process(pubKeyForHash);
    return Uint8List.fromList(hash.sublist(12));
  }

  /// Sign message with secp256k1 (DER encoded signature for BTC)
  ///
  /// Matches Go: protocol/signature.go SignBTC()
  /// IMPORTANT: message is expected to be a pre-hashed 32-byte value.
  /// We use NullDigest to avoid double-hashing since ECDSA signers normally hash.
  Uint8List signBTC(Uint8List message) {
    final signer = ECDSASigner(NullDigest(32), null);
    final domain = ECDomainParameters("secp256k1");
    final privateKeyParam = ECPrivateKey(bytesToBigInt(_privateKey), domain);

    signer.init(
        true, ParametersWithRandom(PrivateKeyParameter<ECPrivateKey>(privateKeyParam), secureRandom()));

    final sig = signer.generateSignature(message) as ECSignature;

    // Ensure low-S value (BIP-62)
    var s = sig.s;
    final halfOrder = domain.n >> 1;
    if (s > halfOrder) {
      s = domain.n - s;
    }

    // DER encode the signature
    return derEncode(sig.r, s);
  }

  /// Sign message with secp256k1 (DER format for ETH V1)
  ///
  /// Matches Go: protocol/signature.go SignEthAsDer()
  /// Used by older networks that have not enabled V2 Baikonur upgrade.
  /// Returns DER-encoded signature (variable length, typically 70-72 bytes)
  /// IMPORTANT: message is expected to be a pre-hashed 32-byte value.
  Uint8List signETHv1(Uint8List message) {
    // ETH V1 uses the same DER encoding as BTC
    return signBTC(message);
  }

  /// Sign message with secp256k1 (RSV format for ETH V2)
  ///
  /// Matches Go: protocol/signature.go SignETH()
  /// Returns 65 bytes: R (32) + S (32) + V (1)
  /// Requires V2 Baikonur upgrade to be enabled on the network.
  /// IMPORTANT: message is expected to be a pre-hashed 32-byte value.
  /// We use NullDigest to avoid double-hashing since ECDSA signers normally hash.
  Uint8List signETH(Uint8List message) {
    final signer = ECDSASigner(NullDigest(32), null);
    final domain = ECDomainParameters("secp256k1");
    final privateKeyParam = ECPrivateKey(bytesToBigInt(_privateKey), domain);

    signer.init(
        true, ParametersWithRandom(PrivateKeyParameter<ECPrivateKey>(privateKeyParam), secureRandom()));

    final sig = signer.generateSignature(message) as ECSignature;

    // Ensure low-S value
    var s = sig.s;
    final halfOrder = domain.n >> 1;
    int recoveryId = 0;
    if (s > halfOrder) {
      s = domain.n - s;
      recoveryId = 1;
    }

    // RSV format
    final result = Uint8List(65);
    final rBytes = bigIntToBytes(sig.r, 32);
    final sBytes = bigIntToBytes(s, 32);
    result.setAll(0, rBytes);
    result.setAll(32, sBytes);
    result[64] = recoveryId; // V value (0 or 1, NOT 27/28 - Accumulate expects raw recovery ID)

    return result;
  }

  /// Verify BTC signature (DER encoded)
  /// message is expected to be a pre-hashed 32-byte value.
  bool verifyBTC(Uint8List message, Uint8List signature) {
    try {
      final verifier = ECDSASigner(NullDigest(32), null);
      final domain = ECDomainParameters("secp256k1");
      final Q = domain.curve.decodePoint(_publicKey);
      final publicKeyParam = ECPublicKey(Q, domain);

      verifier.init(false, PublicKeyParameter<ECPublicKey>(publicKeyParam));

      final decoded = derDecode(signature);
      if (decoded == null) return false;

      final sig = ECSignature(decoded.$1, decoded.$2);
      return verifier.verifySignature(message, sig);
    } catch (e) {
      return false;
    }
  }

  /// Verify ETH signature (RSV format, uses first 64 bytes RS)
  /// message is expected to be a pre-hashed 32-byte value.
  bool verifyETH(Uint8List message, Uint8List signature) {
    try {
      if (signature.length < 64) return false;

      final verifier = ECDSASigner(NullDigest(32), null);
      final domain = ECDomainParameters("secp256k1");

      // Get uncompressed public key for ETH
      Uint8List pubKey = _compressed ? _decompressPublicKey(_publicKey) : _publicKey;
      final Q = domain.curve.decodePoint(pubKey);
      final publicKeyParam = ECPublicKey(Q, domain);

      verifier.init(false, PublicKeyParameter<ECPublicKey>(publicKeyParam));

      final r = bytesToBigInt(signature.sublist(0, 32));
      final s = bytesToBigInt(signature.sublist(32, 64));
      final sig = ECSignature(r, s);

      return verifier.verifySignature(message, sig);
    } catch (e) {
      return false;
    }
  }

  /// Derive BTC Lite Identity URL
  Future<AccUrl> deriveBTCLiteIdentityUrl() async {
    return AccUrl.parse(deriveLiteIdentityFromKeyHash(btcPublicKeyHash));
  }

  /// Derive ETH Lite Identity URL
  Future<AccUrl> derivETHLiteIdentityUrl() async {
    return AccUrl.parse(deriveLiteIdentityFromKeyHash(ethPublicKeyHash));
  }

  // Helper functions for EC point encoding

  static Uint8List _encodeCompressedPoint(ECPoint point) {
    final x = bigIntToBytes(point.x!.toBigInteger()!, 32);
    final prefix = point.y!.toBigInteger()!.isOdd ? 0x03 : 0x02;
    final result = Uint8List(33);
    result[0] = prefix;
    result.setAll(1, x);
    return result;
  }

  static Uint8List _encodeUncompressedPoint(ECPoint point) {
    final x = bigIntToBytes(point.x!.toBigInteger()!, 32);
    final y = bigIntToBytes(point.y!.toBigInteger()!, 32);
    final result = Uint8List(65);
    result[0] = 0x04;
    result.setAll(1, x);
    result.setAll(33, y);
    return result;
  }

  static Uint8List _decompressPublicKey(Uint8List compressed) {
    if (compressed.length == 65 && compressed[0] == 0x04) {
      return compressed; // Already uncompressed
    }
    if (compressed.length != 33) {
      throw ArgumentError("Invalid compressed public key length");
    }

    final domain = ECDomainParameters("secp256k1");
    final point = domain.curve.decodePoint(compressed);
    return _encodeUncompressedPoint(point!);
  }

}
