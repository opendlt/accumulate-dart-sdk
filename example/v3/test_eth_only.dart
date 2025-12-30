// Test ETH signature specifically with debug tool
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const debugExe = r'C:\Accumulate_Stuff\accumulate\tools\cmd\debug\accumulate-debug.exe';

Future<void> main() async {
  print("=== Testing ETH Signature with Go Debug Tool ===\n");

  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final principal = "acc://test.acme/data";
  final signerUrl = "acc://test.acme/book/1";
  final signerVersion = 1;

  final hexData = toHex(Uint8List.fromList("Test ETH".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: principal,
    timestamp: timestamp,
    memo: "Test ETH signature",
  );

  final keypair = Secp256k1KeyPair.generate();

  // Show key details
  print("ETH Key Details:");
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

  final json = JsonEncoder.withIndent('  ').convert(envelope.toJson());
  print("\nEnvelope JSON:");
  print(json);

  // Write to temp file
  final tempFile = File('temp_eth_envelope.json');
  await tempFile.writeAsString(json);

  print("\n--- Go Debug Tool Verification ---");

  try {
    final result = await Process.run(
      'powershell',
      ['-Command', "& '$debugExe' verify --check-initiator --dump-meta --dump-tlv '${tempFile.path}'"],
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.toString().isNotEmpty) {
      print("STDERR: ${result.stderr}");
    }
    print("Exit code: ${result.exitCode}");

    if (result.exitCode == 0) {
      print("\n[OK] ETH signature VERIFIED");
    } else {
      print("\n[ERROR] ETH signature FAILED");
    }
  } catch (e) {
    print("Error running debug tool: $e");
  }

  // Clean up
  try {
    await tempFile.delete();
  } catch (_) {}
}
