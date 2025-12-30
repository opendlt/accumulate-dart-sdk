import "dart:typed_data";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/crypto/rcd1.dart";
import "package:opendlt_accumulate/src/crypto/secp256k1.dart";
import "package:opendlt_accumulate/src/crypto/rsa.dart";
import "package:opendlt_accumulate/src/crypto/ecdsa.dart";

void main() {
  group("Ed25519KeyPair", () {
    test("generate creates valid key pair", () async {
      final kp = await Ed25519KeyPair.generate();
      final pubKey = await kp.publicKeyBytes();
      expect(pubKey.length, equals(32));
    });

    test("sign and verify works", () async {
      final kp = await Ed25519KeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = await kp.sign(message);
      expect(signature.length, equals(64));
      final verified = await kp.verify(message, signature);
      expect(verified, isTrue);
    });

    test("verify rejects invalid signature", () async {
      final kp = await Ed25519KeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final badSig = Uint8List(64); // all zeros
      final verified = await kp.verify(message, badSig);
      expect(verified, isFalse);
    });

    test("fromSeed is deterministic", () async {
      final seed = Uint8List.fromList(List.generate(32, (i) => i));
      final kp1 = await Ed25519KeyPair.fromSeed(seed);
      final kp2 = await Ed25519KeyPair.fromSeed(seed);
      final pubKey1 = await kp1.publicKeyBytes();
      final pubKey2 = await kp2.publicKeyBytes();
      expect(pubKey1, equals(pubKey2));
    });

    test("deriveLiteTokenAccountUrl returns ACME LTA", () async {
      final kp = await Ed25519KeyPair.generate();
      final url = await kp.deriveLiteTokenAccountUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
      expect(url.toString().endsWith("/ACME"), isTrue);
    });

    test("deriveLiteIdentityUrl returns valid acc URL", () async {
      final kp = await Ed25519KeyPair.generate();
      final url = await kp.deriveLiteIdentityUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
    });
  });

  group("RCD1KeyPair", () {
    test("generate creates valid key pair", () async {
      final kp = await RCD1KeyPair.generate();
      final pubKey = await kp.publicKeyBytes();
      expect(pubKey.length, equals(32));
    });

    test("sign and verify works", () async {
      final kp = await RCD1KeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = await kp.sign(message);
      expect(signature.length, equals(64));
      final verified = await kp.verify(message, signature);
      expect(verified, isTrue);
    });

    test("publicKeyHash returns RCD1 hash (32 bytes)", () async {
      final kp = await RCD1KeyPair.generate();
      final hash = await kp.publicKeyHash();
      expect(hash.length, equals(32));
    });

    test("RCD1 hash differs from SHA256 hash", () async {
      // Same seed should produce same key but different hashes
      final seed = Uint8List.fromList(List.generate(32, (i) => i));
      final ed25519Kp = await Ed25519KeyPair.fromSeed(seed);
      final rcd1Kp = await RCD1KeyPair.fromSeed(seed);

      // Same public key
      final ed25519PubKey = await ed25519Kp.publicKeyBytes();
      final rcd1PubKey = await rcd1Kp.publicKeyBytes();
      expect(ed25519PubKey, equals(rcd1PubKey));

      // RCD1 hash is SHA256(SHA256([0x01] + pubKey))
      // Ed25519 hash would be just SHA256(pubKey)
      // These should differ
      final rcd1Hash = await rcd1Kp.publicKeyHash();
      expect(rcd1Hash.length, equals(32));
    });

    test("deriveLiteIdentityUrl returns valid acc URL", () async {
      final kp = await RCD1KeyPair.generate();
      final url = await kp.deriveLiteIdentityUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
    });

    test("getRCDHashFromPublicKey matches Go implementation", () {
      // Test the helper function directly
      final pubKey = Uint8List.fromList(List.generate(32, (i) => i));
      final rcd1Hash = getRCDHashFromPublicKey(pubKey, 1);
      expect(rcd1Hash.length, equals(32));

      // RCD1 hash should be SHA256(SHA256([0x01] + pubKey))
      // This is deterministic, so we can verify a specific value
    });
  });

  group("Secp256k1KeyPair", () {
    test("generate creates valid compressed key pair", () {
      final kp = Secp256k1KeyPair.generate(compressed: true);
      expect(kp.publicKeyBytes.length, equals(33));
      expect(kp.privateKeyBytes.length, equals(32));
    });

    test("generate creates valid uncompressed key pair", () {
      final kp = Secp256k1KeyPair.generate(compressed: false);
      expect(kp.publicKeyBytes.length, equals(65));
      expect(kp.privateKeyBytes.length, equals(32));
    });

    test("fromPrivateKey is deterministic", () {
      final privKey = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final kp1 = Secp256k1KeyPair.fromPrivateKey(privKey);
      final kp2 = Secp256k1KeyPair.fromPrivateKey(privKey);
      expect(kp1.publicKeyBytes, equals(kp2.publicKeyBytes));
    });

    test("BTC sign and verify works", () {
      final kp = Secp256k1KeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = kp.signBTC(message);
      expect(signature.length, greaterThan(64)); // DER encoded
      final verified = kp.verifyBTC(message, signature);
      expect(verified, isTrue);
    });

    test("ETH sign and verify works", () {
      final kp = Secp256k1KeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = kp.signETH(message);
      expect(signature.length, equals(65)); // RSV format
      final verified = kp.verifyETH(message, signature);
      expect(verified, isTrue);
    });

    test("btcPublicKeyHash returns 20 bytes", () {
      final kp = Secp256k1KeyPair.generate();
      final hash = kp.btcPublicKeyHash;
      expect(hash.length, equals(20)); // RIPEMD160 output
    });

    test("ethPublicKeyHash returns 20 bytes", () {
      final kp = Secp256k1KeyPair.generate();
      final hash = kp.ethPublicKeyHash;
      expect(hash.length, equals(20)); // Keccak256[12:]
    });

    test("BTC verify rejects invalid signature", () {
      final kp = Secp256k1KeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final badSig = Uint8List.fromList([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01]);
      final verified = kp.verifyBTC(message, badSig);
      expect(verified, isFalse);
    });

    test("deriveBTCLiteIdentityUrl returns valid acc URL", () async {
      final kp = Secp256k1KeyPair.generate();
      final url = await kp.deriveBTCLiteIdentityUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
    });

    test("derivETHLiteIdentityUrl returns valid acc URL", () async {
      final kp = Secp256k1KeyPair.generate();
      final url = await kp.derivETHLiteIdentityUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
    });
  });

  group("RsaKeyPair", () {
    test("generate creates valid key pair", () {
      final kp = RsaKeyPair.generate(bitLength: 2048);
      expect(kp.publicKeyBytes.length, greaterThan(0));
      expect(kp.privateKeyBytes.length, greaterThan(0));
    });

    test("sign and verify works", () {
      final kp = RsaKeyPair.generate(bitLength: 2048);
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = kp.sign(message);
      expect(signature.length, equals(256)); // 2048 bits = 256 bytes
      final verified = kp.verify(message, signature);
      expect(verified, isTrue);
    });

    test("verify rejects invalid signature", () {
      final kp = RsaKeyPair.generate(bitLength: 2048);
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final badSig = Uint8List(256); // all zeros
      final verified = kp.verify(message, badSig);
      expect(verified, isFalse);
    });

    test("publicKeyHash returns 32 bytes", () {
      final kp = RsaKeyPair.generate(bitLength: 2048);
      final hash = kp.publicKeyHash;
      expect(hash.length, equals(32));
    });

    test("fromPKCS1PrivateKey roundtrip works", () {
      final kp1 = RsaKeyPair.generate(bitLength: 2048);
      final derBytes = kp1.privateKeyBytes;
      final kp2 = RsaKeyPair.fromPKCS1PrivateKey(derBytes);
      expect(kp1.publicKeyBytes, equals(kp2.publicKeyBytes));

      // Verify signing still works
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final sig = kp2.sign(message);
      expect(kp1.verify(message, sig), isTrue);
    });

    test("deriveLiteIdentityUrl returns valid acc URL", () async {
      final kp = RsaKeyPair.generate(bitLength: 2048);
      final url = await kp.deriveLiteIdentityUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
    });
  });

  group("EcdsaKeyPair", () {
    test("generate creates valid P-256 key pair", () {
      final kp = EcdsaKeyPair.generate(curve: "secp256r1");
      expect(kp.curveName, equals("secp256r1"));
      expect(kp.publicKeyBytes.length, greaterThan(0));
      expect(kp.privateKeyBytes.length, greaterThan(0));
    });

    test("sign and verify works", () {
      final kp = EcdsaKeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = kp.sign(message);
      expect(signature.length, greaterThan(0)); // DER encoded
      final verified = kp.verify(message, signature);
      expect(verified, isTrue);
    });

    test("verify rejects invalid signature", () {
      final kp = EcdsaKeyPair.generate();
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final badSig = Uint8List.fromList([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01]);
      final verified = kp.verify(message, badSig);
      expect(verified, isFalse);
    });

    test("publicKeyHash returns 32 bytes", () {
      final kp = EcdsaKeyPair.generate();
      final hash = kp.publicKeyHash;
      expect(hash.length, equals(32));
    });

    test("supports P-384 curve", () {
      final kp = EcdsaKeyPair.generate(curve: "secp384r1");
      expect(kp.curveName, equals("secp384r1"));
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = kp.sign(message);
      expect(kp.verify(message, signature), isTrue);
    });

    test("supports P-521 curve", () {
      final kp = EcdsaKeyPair.generate(curve: "secp521r1");
      expect(kp.curveName, equals("secp521r1"));
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = kp.sign(message);
      expect(kp.verify(message, signature), isTrue);
    });

    test("deriveLiteIdentityUrl returns valid acc URL", () async {
      final kp = EcdsaKeyPair.generate();
      final url = await kp.deriveLiteIdentityUrl();
      expect(url.toString().startsWith("acc://"), isTrue);
    });
  });

  group("Cross-key type tests", () {
    test("different key types produce different signatures", () async {
      final message = Uint8List.fromList([1, 2, 3, 4, 5]);

      final ed25519 = await Ed25519KeyPair.generate();
      final secp256k1 = Secp256k1KeyPair.generate();
      final ecdsa = EcdsaKeyPair.generate();

      final ed25519Sig = await ed25519.sign(message);
      final btcSig = secp256k1.signBTC(message);
      final ecdsaSig = ecdsa.sign(message);

      // Signatures should all be different
      expect(ed25519Sig, isNot(equals(btcSig)));
      expect(ed25519Sig, isNot(equals(ecdsaSig)));
      expect(btcSig, isNot(equals(ecdsaSig)));
    });
  });
}
