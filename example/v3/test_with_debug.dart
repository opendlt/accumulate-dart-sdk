// Test envelope generation and verify with Go debug tool
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const debugExe = r'C:\Accumulate_Stuff\accumulate\tools\cmd\debug\accumulate-debug.exe';

Future<void> main() async {
  print("=== Testing Dart SDK Signatures with Go Debug Tool ===\n");

  // Use fixed test values for reproducibility
  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final principal = "acc://test.acme/data";
  final signerUrl = "acc://test.acme/book/1";
  final signerVersion = 1;

  // Create a simple WriteData body
  final hexData = toHex(Uint8List.fromList("Test".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final ctx = BuildContext(
    principal: principal,
    timestamp: timestamp,
    memo: "Test signature",
  );

  // Test each signature type
  await testEd25519(ctx, body, signerUrl, signerVersion);
  await testRCD1(ctx, body, signerUrl, signerVersion);
  await testBTC(ctx, body, signerUrl, signerVersion);
  await testETH(ctx, body, signerUrl, signerVersion);
  await testRSA(ctx, body, signerUrl, signerVersion);
  await testECDSA(ctx, body, signerUrl, signerVersion);
}

Future<void> testEd25519(BuildContext ctx, Map<String, dynamic> body, String signerUrl, int signerVersion) async {
  print("\n" + "=" * 60);
  print("Testing Ed25519 Signature");
  print("=" * 60);

  final keypair = await Ed25519KeyPair.generate();
  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  await verifyEnvelope("Ed25519", envelope);
}

Future<void> testRCD1(BuildContext ctx, Map<String, dynamic> body, String signerUrl, int signerVersion) async {
  print("\n" + "=" * 60);
  print("Testing RCD1 Signature");
  print("=" * 60);

  final keypair = await RCD1KeyPair.generate();
  final envelope = await TxSigner.buildAndSignRCD1(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  await verifyEnvelope("RCD1", envelope);
}

Future<void> testBTC(BuildContext ctx, Map<String, dynamic> body, String signerUrl, int signerVersion) async {
  print("\n" + "=" * 60);
  print("Testing BTC Signature");
  print("=" * 60);

  final keypair = Secp256k1KeyPair.generate();
  final envelope = await TxSigner.buildAndSignBTC(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  await verifyEnvelope("BTC", envelope);
}

Future<void> testETH(BuildContext ctx, Map<String, dynamic> body, String signerUrl, int signerVersion) async {
  print("\n" + "=" * 60);
  print("Testing ETH Signature");
  print("=" * 60);

  final keypair = Secp256k1KeyPair.generate();
  final envelope = await TxSigner.buildAndSignETH(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  await verifyEnvelope("ETH", envelope);
}

Future<void> testRSA(BuildContext ctx, Map<String, dynamic> body, String signerUrl, int signerVersion) async {
  print("\n" + "=" * 60);
  print("Testing RSA Signature");
  print("=" * 60);

  final keypair = RsaKeyPair.generate(bitLength: 2048);
  final envelope = await TxSigner.buildAndSignRSA(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  await verifyEnvelope("RSA", envelope);
}

Future<void> testECDSA(BuildContext ctx, Map<String, dynamic> body, String signerUrl, int signerVersion) async {
  print("\n" + "=" * 60);
  print("Testing ECDSA Signature");
  print("=" * 60);

  final keypair = EcdsaKeyPair.generate();
  final envelope = await TxSigner.buildAndSignECDSA(
    ctx: ctx,
    body: body,
    keypair: keypair,
    signerUrl: signerUrl,
    signerVersion: signerVersion,
  );

  await verifyEnvelope("ECDSA", envelope);
}

Future<void> verifyEnvelope(String name, Envelope envelope) async {
  final json = JsonEncoder.withIndent('  ').convert(envelope.toJson());

  print("\nEnvelope JSON:");
  print(json);

  // Write to temp file
  final tempFile = File('temp_envelope_$name.json');
  await tempFile.writeAsString(json);

  print("\n--- Go Debug Tool Verification ---");

  try {
    final result = await Process.run(
      'powershell',
      ['-Command', "& '$debugExe' verify --check-initiator '${tempFile.path}'"],
      workingDirectory: Directory.current.path,
    );

    print(result.stdout);
    if (result.stderr.toString().isNotEmpty) {
      print("STDERR: ${result.stderr}");
    }
    print("Exit code: ${result.exitCode}");

    if (result.exitCode == 0) {
      print("\n[OK] $name signature VERIFIED by Go debug tool");
    } else {
      print("\n[ERROR] $name signature FAILED verification");
    }
  } catch (e) {
    print("Error running debug tool: $e");
  }

  // Clean up
  try {
    await tempFile.delete();
  } catch (_) {}
}
