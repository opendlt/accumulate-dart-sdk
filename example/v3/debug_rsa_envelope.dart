// Debug RSA envelope generation
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== Debug RSA Envelope ===\n");

  // Generate RSA key
  print("Generating RSA 2048-bit key...");
  final rsaKey = RsaKeyPair.generate(bitLength: 2048);

  final rsaPubKey = rsaKey.publicKeyBytes;
  final rsaKeyHash = rsaKey.publicKeyHash;

  print("RSA Public Key (PKCS#1 DER): ${rsaPubKey.length} bytes");
  print("RSA Public Key hex: ${toHex(rsaPubKey).substring(0, 80)}...");
  print("RSA Key Hash (SHA256): ${toHex(rsaKeyHash)}");

  // Build a simple WriteData transaction
  final dataAccountUrl = "acc://test-adi.acme/test-data";
  final keyPageUrl = "acc://test-adi.acme/book/1";
  final version = 7;

  final hexData = toHex(Uint8List.fromList("RSA test".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;

  final ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: timestamp,
    memo: "RSA Debug Test",
  );

  print("\n--- Building RSA Envelope ---");
  print("Timestamp: $timestamp");
  print("Principal: $dataAccountUrl");
  print("Signer: $keyPageUrl");
  print("Signer Version: $version");

  final envelope = await TxSigner.buildAndSignRSA(
    ctx: ctx,
    body: body,
    keypair: rsaKey,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  // Print the envelope
  final json = envelope.toJson();
  print("\n--- RSA Envelope JSON ---");
  print(JsonEncoder.withIndent('  ').convert(json));

  // Print signature details
  final sig = json['signatures'][0];
  print("\n--- Signature Details ---");
  print("Type: ${sig['type']}");
  print("Public Key length: ${(sig['publicKey'] as String).length / 2} bytes");
  print("Signature length: ${(sig['signature'] as String).length / 2} bytes");
  print("Signer: ${sig['signer']}");
  print("Signer Version: ${sig['signerVersion']}");
  print("Timestamp: ${sig['timestamp']}");
  print("Transaction Hash: ${sig['transactionHash']}");

  // Print header details
  final tx = json['transaction'];
  final header = tx['header'];
  print("\n--- Header Details ---");
  print("Principal: ${header['principal']}");
  print("Initiator: ${header['initiator']}");
  print("Memo: ${header['memo']}");
}
