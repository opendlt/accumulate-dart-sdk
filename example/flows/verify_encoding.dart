// Verify encoding by comparing Dart SDK output with Go debug tool
// This tests: transaction body, header, full transaction, and signature encoding

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'package:opendlt_accumulate/src/codec/transaction_codec.dart';
import 'package:opendlt_accumulate/src/codec/binary_encoder.dart';

const debugExe = r'C:\Accumulate_Stuff\accumulate\tools\cmd\debug\accumulate-debug.exe';

Future<void> main() async {
  print("=== Encoding Verification: Go vs Dart SDK ===\n");

  // Fixed test data
  final timestamp = 1704067200000000;
  final principal = "acc://test.acme/data";
  final signerUrl = "acc://test.acme/book/1";
  final signerVersion = 7;
  final memo = "ETH test";

  final hexData = toHex(Uint8List.fromList("Test".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  // Generate keypair
  final keypair = Secp256k1KeyPair.generate();
  print("ETH Uncompressed PubKey: ${toHex(keypair.uncompressedPublicKeyBytes)}");

  // Build ETH envelope with Dart SDK
  final ctx = BuildContext(
    principal: principal,
    timestamp: timestamp,
    memo: memo,
  );
  final envelope = await TxSigner.buildAndSignETH(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  final sig = envelope.signatures.first;
  final tx = envelope.transaction;

  print("\n=== Dart SDK Output ===");
  print("Transaction Hash (from sig): ${sig.transactionHash}");
  print("Initiator: ${tx['header']['initiator']}");
  print("Signature (${sig.signature.length ~/ 2} bytes): ${sig.signature}");

  // Now let's use Go to encode the same components and compare

  // 1. TRANSACTION BODY - encode with Go and get hash
  print("\n=== Step 1: Transaction Body ===");
  final bodyJson = JsonEncoder().convert(body);
  print("Body JSON: $bodyJson");

  try {
    final bodyResult = await Process.run(
      debugExe,
      ['encode', 'body', '--hash', bodyJson],
      workingDirectory: Directory.current.path,
    );
    print("Go Body Hash: ${bodyResult.stdout.toString().trim()}");
    if (bodyResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${bodyResult.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // 2. TRANSACTION HEADER - encode with Go
  print("\n=== Step 2: Transaction Header ===");
  final headerJson = JsonEncoder().convert({
    "principal": principal,
    "initiator": tx['header']['initiator'],
    "memo": memo,
  });
  print("Header JSON: $headerJson");

  try {
    final headerResult = await Process.run(
      debugExe,
      ['encode', 'header', '--hash', headerJson],
      workingDirectory: Directory.current.path,
    );
    print("Go Header Hash: ${headerResult.stdout.toString().trim()}");
    if (headerResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${headerResult.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // 3. FULL TRANSACTION - encode with Go and get hash
  print("\n=== Step 3: Full Transaction ===");
  final txJson = JsonEncoder().convert({
    "header": {
      "principal": principal,
      "initiator": tx['header']['initiator'],
      "memo": memo,
    },
    "body": body,
  });
  print("Transaction JSON: $txJson");

  try {
    final txResult = await Process.run(
      debugExe,
      ['encode', 'transaction', '--hash', txJson],
      workingDirectory: Directory.current.path,
    );
    final goTxHash = txResult.stdout.toString().trim();
    print("Go Transaction Hash: $goTxHash");
    print("Dart Transaction Hash: ${sig.transactionHash}");
    print("MATCH: ${goTxHash == sig.transactionHash}");
    if (txResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${txResult.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // 4. SIGNATURE ENCODING - encode with Go
  print("\n=== Step 4: ETH Signature ===");
  final sigJson = JsonEncoder().convert({
    "type": "eth",
    "publicKey": sig.publicKey,
    "signature": sig.signature,
    "signer": sig.signer,
    "signerVersion": sig.signerVersion,
    "timestamp": sig.timestamp,
    "transactionHash": sig.transactionHash,
  });
  print("Signature JSON: $sigJson");

  try {
    final sigResult = await Process.run(
      debugExe,
      ['encode', 'signature', sigJson],
      workingDirectory: Directory.current.path,
    );
    print("\nGo Signature Encoding:");
    print(sigResult.stdout);
    if (sigResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${sigResult.stderr}");
    }
  } catch (e) {
    print("Error: $e");
  }

  // 5. Compare METADATA HASH
  print("\n=== Step 5: Metadata Hash Comparison ===");

  // Get Go's metadata hash (already printed above, extract from signature encoding)
  // The initiator should equal the metadata hash

  // Now compute what Dart SDK produces for metadata
  final dartMetadataHash = TransactionCodec.computeSignatureMetadataHashForType(
    signatureType: SignatureTypeEnum.eth,
    publicKey: keypair.uncompressedPublicKeyBytes,
    signer: signerUrl,
    signerVersion: signerVersion,
    timestamp: timestamp,
  );
  print("Dart Metadata Hash: ${toHex(dartMetadataHash)}");
  print("Transaction Initiator: ${tx['header']['initiator']}");
  print("MATCH: ${toHex(dartMetadataHash) == tx['header']['initiator']}");

  // 6. Verify the full envelope with Go
  print("\n=== Step 6: Full Envelope Verification ===");
  final envJson = envelope.toJson();
  final envFile = File('temp_verify_encoding.json');
  await envFile.writeAsString(JsonEncoder.withIndent('  ').convert(envJson));

  try {
    final verifyResult = await Process.run(
      debugExe,
      ['verify', envFile.path],
      workingDirectory: Directory.current.path,
    );
    print("Go Verify Output:");
    print(verifyResult.stdout);
    if (verifyResult.stderr.toString().isNotEmpty) {
      print("STDERR: ${verifyResult.stderr}");
    }
    print("Exit code: ${verifyResult.exitCode}");
  } catch (e) {
    print("Error: $e");
  }

  // Cleanup
  try {
    await envFile.delete();
  } catch (_) {}

  print("\n=== Done ===");
}
