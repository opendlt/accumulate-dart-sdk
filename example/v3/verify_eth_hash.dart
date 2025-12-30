// Verify ETH key hash computation matches Go
// The network uses ETHhash() to compute the key hash from the public key
// This must match what we store on the key page

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const debugExe = r'C:\Accumulate_Stuff\accumulate\tools\cmd\debug\accumulate-debug.exe';

Future<void> main() async {
  print("=== ETH Key Hash Verification ===\n");

  // Generate a key
  final keypair = Secp256k1KeyPair.generate();

  final compressedPubKey = keypair.publicKeyBytes;
  final uncompressedPubKey = keypair.uncompressedPublicKeyBytes;
  final dartEthHash = keypair.ethPublicKeyHash;
  final dartBtcHash = keypair.btcPublicKeyHash;

  print("Compressed Public Key (33 bytes):");
  print("  ${toHex(compressedPubKey)}");
  print("\nUncompressed Public Key (65 bytes):");
  print("  ${toHex(uncompressedPubKey)}");
  print("\nDart SDK ETH Hash (20 bytes):");
  print("  ${toHex(dartEthHash)}");
  print("\nDart SDK BTC Hash (20 bytes):");
  print("  ${toHex(dartBtcHash)}");

  // Now use Go to compute the same hashes
  // We'll create a minimal signature with the public key and let Go parse it
  print("\n=== Go Computation ===");

  // Create an ETH signature JSON that Go can parse
  final ethSigJson = JsonEncoder().convert({
    "type": "eth",
    "publicKey": toHex(uncompressedPubKey),
    "signature": "00" * 65,  // dummy signature
    "signer": "acc://test.acme/book/1",
    "signerVersion": 1,
    "timestamp": 1,
    "transactionHash": "00" * 32,  // dummy hash
  });

  // Create a BTC signature JSON for comparison
  final btcSigJson = JsonEncoder().convert({
    "type": "btc",
    "publicKey": toHex(compressedPubKey),
    "signature": "00" * 71,  // dummy DER signature
    "signer": "acc://test.acme/book/1",
    "signerVersion": 1,
    "timestamp": 1,
    "transactionHash": "00" * 32,
  });

  // Run Go encode on ETH signature
  print("\n--- Go ETH Signature Encoding ---");
  try {
    final result = await Process.run(
      debugExe,
      ['encode', 'signature', ethSigJson],
      workingDirectory: Directory.current.path,
    );
    print(result.stdout);
    if (result.stderr.toString().isNotEmpty) {
      print("STDERR: ${result.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // Run Go encode on BTC signature
  print("\n--- Go BTC Signature Encoding ---");
  try {
    final result = await Process.run(
      debugExe,
      ['encode', 'signature', btcSigJson],
      workingDirectory: Directory.current.path,
    );
    print(result.stdout);
    if (result.stderr.toString().isNotEmpty) {
      print("STDERR: ${result.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // Let's also print what key hashes we would add to the key page
  print("\n=== Key Hashes to add to Key Page ===");
  print("For BTC key: ${toHex(dartBtcHash)}");
  print("For ETH key: ${toHex(dartEthHash)}");

  // When the signature is verified, Go will compute:
  // BTC: BTCHash(compressedPubKey) = RIPEMD160(SHA256(compressedPubKey))
  // ETH: ETHHash(uncompressedPubKey) = Keccak256(uncompressedPubKey[1:])[12:]

  print("\n=== Verification ===");
  print("The key hashes above must match what Go computes from the public keys.");
  print("If they don't match, the network will reject with 'key does not belong to signer'");
  print("If they match but sig still fails, it's 'invalid signature' which means");
  print("the cryptographic verification failed.");
}
