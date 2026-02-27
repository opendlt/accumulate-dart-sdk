import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'package:opendlt_accumulate/src/codec/transaction_codec.dart';

// Expected from Go sigbytes tool:
// pubkey: 0000000000000000000000000000000000000000000000000000000000000001
// signer: acc://test.acme/book/1
// signer-version: 1
// timestamp: 1234567890
// txhash: 0000000000000000000000000000000000000000000000000000000000000002
//
// mdHash=1b05aec2878f8b167bf5687717d31802255561bd860ddbc9e417aa16a5a0bcce
// digest=ad719adac3a4dbd667a781b1d19ad2e72591c5c7464670762d54577a0cdebb4c

Uint8List hexToBytes(String hex) {
  final cleaned = hex.startsWith('0x') ? hex.substring(2) : hex;
  final bytes = Uint8List(cleaned.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  // Test inputs matching Go sigbytes
  final pubkey = hexToBytes('0000000000000000000000000000000000000000000000000000000000000001');
  final signer = 'acc://test.acme/book/1';
  final signerVersion = 1;
  final timestamp = 1234567890;
  final txHash = hexToBytes('0000000000000000000000000000000000000000000000000000000000000002');

  // Expected outputs from Go
  final expectedMdHash = '1b05aec2878f8b167bf5687717d31802255561bd860ddbc9e417aa16a5a0bcce';
  final expectedDigest = 'ad719adac3a4dbd667a781b1d19ad2e72591c5c7464670762d54577a0cdebb4c';

  // Compute using Dart SDK
  final mdHash = TransactionCodec.computeSignatureMetadataHash(
    publicKey: pubkey,
    signer: signer,
    signerVersion: signerVersion,
    timestamp: timestamp,
    vote: 0,
  );

  final digest = TransactionCodec.createSigningPreimage(mdHash, txHash);

  print('Dart computed mdHash: ${bytesToHex(mdHash)}');
  print('Go expected mdHash:   $expectedMdHash');
  print('Match: ${bytesToHex(mdHash) == expectedMdHash}');
  print('');
  print('Dart computed digest: ${bytesToHex(digest)}');
  print('Go expected digest:   $expectedDigest');
  print('Match: ${bytesToHex(digest) == expectedDigest}');

  // Also print the raw bytes to debug
  print('');
  print('Debug: Enabling binary encoder debug...');
  TransactionCodec.debugPrintBinary = true;
  print('Ed25519 metadata:');
  final mdHash2 = TransactionCodec.computeSignatureMetadataHash(
    publicKey: pubkey,
    signer: signer,
    signerVersion: signerVersion,
    timestamp: timestamp,
    vote: 0,
  );

  print('');
  print('RCD1 metadata (type=3):');
  final rcd1MdHash = TransactionCodec.computeSignatureMetadataHashForType(
    signatureType: 3, // RCD1
    publicKey: pubkey,
    signer: signer,
    signerVersion: signerVersion,
    timestamp: timestamp,
    vote: 0,
  );
  print('RCD1 mdHash: ${bytesToHex(rcd1MdHash)}');

  print('');
  print('BTC metadata (type=4):');
  final btcMdHash = TransactionCodec.computeSignatureMetadataHashForType(
    signatureType: 4, // BTC
    publicKey: pubkey,
    signer: signer,
    signerVersion: signerVersion,
    timestamp: timestamp,
    vote: 0,
  );
  print('BTC mdHash: ${bytesToHex(btcMdHash)}');
}
