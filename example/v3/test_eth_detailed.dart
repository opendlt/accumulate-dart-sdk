// Detailed ETH signature test with Go debug tool
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const debugExe = r'C:\Accumulate_Stuff\accumulate\tools\cmd\debug\accumulate-debug.exe';

Future<void> main() async {
  print("=== Detailed ETH Signature Test ===\n");

  final timestamp = 1704067200000000; // Fixed for reproducibility
  final principal = "acc://test.acme/data";
  final signerUrl = "acc://test.acme/book/1";
  final signerVersion = 1;

  final hexData = toHex(Uint8List.fromList("Test".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: principal,
    timestamp: timestamp,
    memo: "ETH test",
  );

  final keypair = Secp256k1KeyPair.generate();

  // Show key details
  print("ETH Key Details:");
  print("  Private Key: [hidden]");
  print("  Compressed PubKey (33 bytes): ${toHex(keypair.publicKeyBytes)}");
  print("  Uncompressed PubKey (65 bytes): ${toHex(keypair.uncompressedPublicKeyBytes)}");
  print("  ETH Key Hash (20 bytes): ${toHex(keypair.ethPublicKeyHash)}");

  final envelope = await TxSigner.buildAndSignETH(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  final sig = envelope.signatures.first;
  print("\nSignature Details:");
  print("  Type: ${sig.type}");
  print("  PublicKey (${sig.publicKey.length ~/ 2} bytes): ${sig.publicKey}");
  print("  Signature (${sig.signature.length ~/ 2} bytes): ${sig.signature}");
  print("  V value (last byte): 0x${sig.signature.substring(sig.signature.length - 2)}");
  print("  Timestamp: ${sig.timestamp}");
  print("  TransactionHash: ${sig.transactionHash}");

  print("\nTransaction Details:");
  final tx = envelope.transaction;
  print("  Initiator: ${tx['header']['initiator']}");

  final json = JsonEncoder.withIndent('  ').convert(envelope.toJson());
  print("\nFull Envelope JSON:");
  print(json);

  // Write to temp file
  final tempFile = File('temp_eth_detailed.json');
  await tempFile.writeAsString(json);

  print("\n--- Go Debug Tool Verification (Full Output) ---\n");

  try {
    final result = await Process.run(
      'powershell',
      ['-Command', "& '$debugExe' verify --check-initiator --dump-meta --dump-tlv '${tempFile.path}'"],
      workingDirectory: Directory.current.path,
    );

    print("STDOUT:");
    print(result.stdout);
    if (result.stderr.toString().isNotEmpty) {
      print("\nSTDERR:");
      print(result.stderr);
    }
    print("\nExit code: ${result.exitCode}");

  } catch (e) {
    print("Error running debug tool: $e");
  }

  // Clean up
  try {
    await tempFile.delete();
  } catch (_) {}
}
