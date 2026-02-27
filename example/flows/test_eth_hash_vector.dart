// Test ETH hash computation against known Go test vector
// From Go: protocol/signature_test.go TestETHaddress

import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

void main() {
  print("=== ETH Hash Test Vector Verification ===\n");

  // Test vector from Go: protocol/signature_test.go TestETHaddress
  // Private key: 0x1b48e04041e23c72cacdaa9b0775d31515fc74d6a6d3c8804172f7e7d1248529
  // Compressed pubkey: 02c4755e0a7a0f7082749bf46cdae4fcddb784e11428446a01478d656f588f94c1
  // Expected ETH address: 0xa27df20e6579ac472481f0ea918165d24bfb713b

  final privateKeyHex = "1b48e04041e23c72cacdaa9b0775d31515fc74d6a6d3c8804172f7e7d1248529";
  final expectedEthHash = "a27df20e6579ac472481f0ea918165d24bfb713b";
  final expectedCompressedPubKey = "02c4755e0a7a0f7082749bf46cdae4fcddb784e11428446a01478d656f588f94c1";

  // Create keypair from private key
  final privateKey = fromHex(privateKeyHex);
  final keypair = Secp256k1KeyPair.fromPrivateKey(privateKey);

  // Check compressed public key
  final compressedPubKey = toHex(keypair.publicKeyBytes);
  print("Expected Compressed PubKey: $expectedCompressedPubKey");
  print("Dart SDK Compressed PubKey: $compressedPubKey");
  print("Compressed PubKey MATCH: ${compressedPubKey == expectedCompressedPubKey}");

  // Check uncompressed public key (for ETH signature)
  final uncompressedPubKey = keypair.uncompressedPublicKeyBytes;
  print("\nUncompressed PubKey (65 bytes): ${toHex(uncompressedPubKey)}");

  // Check ETH hash
  final ethHash = toHex(keypair.ethPublicKeyHash);
  print("\nExpected ETH Hash: $expectedEthHash");
  print("Dart SDK ETH Hash: $ethHash");
  print("ETH Hash MATCH: ${ethHash == expectedEthHash}");

  if (ethHash != expectedEthHash) {
    print("\n*** MISMATCH DETECTED! ***");
    print("The Dart SDK's ETH hash computation doesn't match Go!");
    print("This could explain why ETH signatures fail on the network.");
  } else {
    print("\n*** SUCCESS! ETH hash matches Go test vector ***");
  }
}
