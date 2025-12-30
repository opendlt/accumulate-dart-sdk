// Compare BTC vs ETH signatures using the same keypair and transaction
// BTC works, ETH doesn't - this helps identify what's different

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const debugExe = r'C:\Accumulate_Stuff\accumulate\tools\cmd\debug\accumulate-debug.exe';

Future<void> main() async {
  print("=== BTC vs ETH Signature Comparison ===\n");

  // Fixed values for reproducibility
  final timestamp = 1704067200000000;
  final principal = "acc://test.acme/data";
  final signerUrl = "acc://test.acme/book/1";
  final signerVersion = 7;

  final hexData = toHex(Uint8List.fromList("Test".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  // Generate ONE keypair to use for both
  final keypair = Secp256k1KeyPair.generate();

  print("Key Details:");
  print("  Compressed PubKey (33 bytes): ${toHex(keypair.publicKeyBytes)}");
  print("  Uncompressed PubKey (65 bytes): ${toHex(keypair.uncompressedPublicKeyBytes)}");
  print("  BTC Key Hash (20 bytes): ${toHex(keypair.btcPublicKeyHash)}");
  print("  ETH Key Hash (20 bytes): ${toHex(keypair.ethPublicKeyHash)}");

  // Build BTC envelope
  print("\n--- Building BTC Envelope ---");
  final btcCtx = BuildContext(
    principal: principal,
    timestamp: timestamp,
    memo: "BTC test",
  );
  final btcEnvelope = await TxSigner.buildAndSignBTC(
    ctx: btcCtx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  // Build ETH envelope with same keypair and similar context
  print("\n--- Building ETH Envelope ---");
  final ethCtx = BuildContext(
    principal: principal,
    timestamp: timestamp + 1000, // Slightly different timestamp
    memo: "ETH test",
  );
  final ethEnvelope = await TxSigner.buildAndSignETH(
    ctx: ethCtx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  // Print signature details for comparison
  print("\n=== BTC Signature ===");
  final btcSig = btcEnvelope.signatures.first;
  print("  Type: ${btcSig.type}");
  print("  PublicKey (${btcSig.publicKey.length ~/ 2} bytes): ${btcSig.publicKey}");
  print("  Signature (${btcSig.signature.length ~/ 2} bytes): ${btcSig.signature}");
  print("  TransactionHash: ${btcSig.transactionHash}");
  print("  Initiator: ${btcEnvelope.transaction['header']['initiator']}");

  print("\n=== ETH Signature ===");
  final ethSig = ethEnvelope.signatures.first;
  print("  Type: ${ethSig.type}");
  print("  PublicKey (${ethSig.publicKey.length ~/ 2} bytes): ${ethSig.publicKey}");
  print("  Signature (${ethSig.signature.length ~/ 2} bytes): ${ethSig.signature}");
  print("  V value (last byte): 0x${ethSig.signature.substring(ethSig.signature.length - 2)}");
  print("  TransactionHash: ${ethSig.transactionHash}");
  print("  Initiator: ${ethEnvelope.transaction['header']['initiator']}");

  // Write envelopes to temp files (format that Go tool expects)
  final btcJson = btcEnvelope.toJson();
  final ethJson = ethEnvelope.toJson();

  // Remove the envelope wrapper if present - Go tool expects direct format
  final btcFile = File('temp_btc_compare.json');
  final ethFile = File('temp_eth_compare.json');

  await btcFile.writeAsString(JsonEncoder.withIndent('  ').convert(btcJson));
  await ethFile.writeAsString(JsonEncoder.withIndent('  ').convert(ethJson));

  print("\n=== Verifying with Go Debug Tool ===");

  // Verify BTC
  print("\n--- BTC Verification ---");
  try {
    final btcResult = await Process.run(
      debugExe,
      ['verify', btcFile.path],
      workingDirectory: Directory.current.path,
    );
    print(btcResult.stdout);
    if (btcResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${btcResult.stderr}");
    }
    print("Exit code: ${btcResult.exitCode}");
  } catch (e) {
    print("Error: $e");
  }

  // Verify ETH
  print("\n--- ETH Verification ---");
  try {
    final ethResult = await Process.run(
      debugExe,
      ['verify', ethFile.path],
      workingDirectory: Directory.current.path,
    );
    print(ethResult.stdout);
    if (ethResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${ethResult.stderr}");
    }
    print("Exit code: ${ethResult.exitCode}");
  } catch (e) {
    print("Error: $e");
  }

  // Also encode signatures for comparison
  print("\n=== Encoding Signatures with Go Tool ===");

  // Encode BTC signature
  print("\n--- BTC Signature Encoding ---");
  try {
    final sigJson = JsonEncoder().convert({
      "type": "btc",
      "publicKey": btcSig.publicKey,
      "signature": btcSig.signature,
      "signer": btcSig.signer,
      "signerVersion": btcSig.signerVersion,
      "timestamp": btcSig.timestamp,
      "transactionHash": btcSig.transactionHash,
    });
    final encResult = await Process.run(
      debugExe,
      ['encode', 'signature', sigJson],
      workingDirectory: Directory.current.path,
    );
    print(encResult.stdout);
    if (encResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${encResult.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // Encode ETH signature
  print("\n--- ETH Signature Encoding ---");
  try {
    final sigJson = JsonEncoder().convert({
      "type": "eth",
      "publicKey": ethSig.publicKey,
      "signature": ethSig.signature,
      "signer": ethSig.signer,
      "signerVersion": ethSig.signerVersion,
      "timestamp": ethSig.timestamp,
      "transactionHash": ethSig.transactionHash,
    });
    final encResult = await Process.run(
      debugExe,
      ['encode', 'signature', sigJson],
      workingDirectory: Directory.current.path,
    );
    print(encResult.stdout);
    if (encResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${encResult.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // Cleanup
  try {
    await btcFile.delete();
    await ethFile.delete();
  } catch (_) {}

  print("\n=== Done ===");
}
