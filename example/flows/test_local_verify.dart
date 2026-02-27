// Test local signature verification for all signature types
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== Local Signature Verification Test ===\n");

  // Create a test message (simulating a signing preimage)
  final testMessage = Uint8List.fromList(
    sha256.convert("Test message for signing".codeUnits).bytes
  );
  print("Test message (32 bytes): ${toHex(testMessage)}");

  // Test Ed25519
  print("\n--- Ed25519 ---");
  final ed25519Key = await Ed25519KeyPair.generate();
  final ed25519Sig = await ed25519Key.sign(testMessage);
  final ed25519Valid = await ed25519Key.verify(testMessage, ed25519Sig);
  print("Signature (${ed25519Sig.length} bytes): ${toHex(ed25519Sig)}");
  print("Local verify: ${ed25519Valid ? 'PASS' : 'FAIL'}");

  // Test RCD1 (same as Ed25519 but different type)
  print("\n--- RCD1 ---");
  final rcd1Key = await RCD1KeyPair.generate();
  final rcd1Sig = await rcd1Key.sign(testMessage);
  final rcd1Valid = await rcd1Key.verify(testMessage, rcd1Sig);
  print("Signature (${rcd1Sig.length} bytes): ${toHex(rcd1Sig)}");
  print("Local verify: ${rcd1Valid ? 'PASS' : 'FAIL'}");

  // Test BTC (secp256k1 DER)
  print("\n--- BTC ---");
  final btcKey = Secp256k1KeyPair.generate();
  final btcSig = btcKey.signBTC(testMessage);
  final btcValid = btcKey.verifyBTC(testMessage, btcSig);
  print("Signature (${btcSig.length} bytes): ${toHex(btcSig)}");
  print("Local verify: ${btcValid ? 'PASS' : 'FAIL'}");

  // Test ETH (secp256k1 RSV)
  print("\n--- ETH ---");
  final ethKey = Secp256k1KeyPair.generate();
  final ethSig = ethKey.signETH(testMessage);
  final ethValid = ethKey.verifyETH(testMessage, ethSig);
  print("Signature (${ethSig.length} bytes): ${toHex(ethSig)}");
  print("V value: ${ethSig[64]}");
  print("Local verify: ${ethValid ? 'PASS' : 'FAIL'}");

  // Test RSA
  print("\n--- RSA ---");
  final rsaKey = RsaKeyPair.generate(bitLength: 2048);
  final rsaSig = rsaKey.sign(testMessage);
  final rsaValid = rsaKey.verify(testMessage, rsaSig);
  print("Signature (${rsaSig.length} bytes): ${toHex(rsaSig).substring(0, 64)}...");
  print("Local verify: ${rsaValid ? 'PASS' : 'FAIL'}");

  // Test ECDSA P-256
  print("\n--- ECDSA (P-256) ---");
  final ecdsaKey = EcdsaKeyPair.generate();
  final ecdsaSig = ecdsaKey.sign(testMessage);
  final ecdsaValid = ecdsaKey.verify(testMessage, ecdsaSig);
  print("Signature (${ecdsaSig.length} bytes): ${toHex(ecdsaSig)}");
  print("Local verify: ${ecdsaValid ? 'PASS' : 'FAIL'}");

  print("\n=== Summary ===");
  print("Ed25519: ${ed25519Valid ? 'PASS' : 'FAIL'}");
  print("RCD1: ${rcd1Valid ? 'PASS' : 'FAIL'}");
  print("BTC: ${btcValid ? 'PASS' : 'FAIL'}");
  print("ETH: ${ethValid ? 'PASS' : 'FAIL'}");
  print("RSA: ${rsaValid ? 'PASS' : 'FAIL'}");
  print("ECDSA: ${ecdsaValid ? 'PASS' : 'FAIL'}");

  // All should pass
  final allPass = ed25519Valid && rcd1Valid && btcValid && ethValid && rsaValid && ecdsaValid;
  print("\nAll tests: ${allPass ? 'PASS' : 'FAIL'}");
}
