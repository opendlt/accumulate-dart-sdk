// Debug: Capture full submit response including signature hashes
import 'dart:convert';
import 'dart:typed_data';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== Testing All Signature Types with Full Response Logging ===\n");

  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Use existing ADI from previous test
  final dataAccountUrl = "acc://multi-sig-1767087064768.acme/test-data";
  final keyPageUrl = "acc://multi-sig-1767087064768.acme/book/1";
  final keyPageVersion = 7;

  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final hexData = toHex(Uint8List.fromList("Debug test".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  // Test each signature type
  print("=" * 70);
  print("Testing Ed25519");
  print("=" * 70);
  await testSignatureType(
    client, "Ed25519",
    () async {
      final keypair = await Ed25519KeyPair.generate();
      final ctx = BuildContext(principal: dataAccountUrl, timestamp: timestamp, memo: "Debug Ed25519");
      return TxSigner.buildAndSign(ctx: ctx, body: body, keypair: keypair, signerUrl: keyPageUrl, signerVersion: keyPageVersion);
    },
  );

  print("\n" + "=" * 70);
  print("Testing RCD1");
  print("=" * 70);
  await testSignatureType(
    client, "RCD1",
    () async {
      final keypair = await RCD1KeyPair.generate();
      final ctx = BuildContext(principal: dataAccountUrl, timestamp: timestamp + 1000, memo: "Debug RCD1");
      return TxSigner.buildAndSignRCD1(ctx: ctx, body: body, keypair: keypair, signerUrl: keyPageUrl, signerVersion: keyPageVersion);
    },
  );

  print("\n" + "=" * 70);
  print("Testing BTC");
  print("=" * 70);
  await testSignatureType(
    client, "BTC",
    () async {
      final keypair = Secp256k1KeyPair.generate();
      final ctx = BuildContext(principal: dataAccountUrl, timestamp: timestamp + 2000, memo: "Debug BTC");
      return TxSigner.buildAndSignBTC(ctx: ctx, body: body, keypair: keypair, signerUrl: keyPageUrl, signerVersion: keyPageVersion);
    },
  );

  print("\n" + "=" * 70);
  print("Testing ETH");
  print("=" * 70);
  await testSignatureType(
    client, "ETH",
    () async {
      final keypair = Secp256k1KeyPair.generate();
      final ctx = BuildContext(principal: dataAccountUrl, timestamp: timestamp + 3000, memo: "Debug ETH");
      return TxSigner.buildAndSignETH(ctx: ctx, body: body, keypair: keypair, signerUrl: keyPageUrl, signerVersion: keyPageVersion);
    },
  );

  print("\n" + "=" * 70);
  print("Testing RSA");
  print("=" * 70);
  await testSignatureType(
    client, "RSA",
    () async {
      final keypair = RsaKeyPair.generate(bitLength: 2048);
      final ctx = BuildContext(principal: dataAccountUrl, timestamp: timestamp + 4000, memo: "Debug RSA");
      return TxSigner.buildAndSignRSA(ctx: ctx, body: body, keypair: keypair, signerUrl: keyPageUrl, signerVersion: keyPageVersion);
    },
  );

  print("\n" + "=" * 70);
  print("Testing ECDSA");
  print("=" * 70);
  await testSignatureType(
    client, "ECDSA",
    () async {
      final keypair = EcdsaKeyPair.generate();
      final ctx = BuildContext(principal: dataAccountUrl, timestamp: timestamp + 5000, memo: "Debug ECDSA");
      return TxSigner.buildAndSignECDSA(ctx: ctx, body: body, keypair: keypair, signerUrl: keyPageUrl, signerVersion: keyPageVersion);
    },
  );

  client.close();
}

Future<void> testSignatureType(Accumulate client, String name, Future<Envelope> Function() buildEnvelope) async {
  try {
    final envelope = await buildEnvelope();

    // Print envelope details
    final sig = envelope.signatures.first;
    print("Signature Details:");
    print("  Type: ${sig.type}");
    print("  PublicKey: ${sig.publicKey}");
    print("  Signature: ${sig.signature}");
    print("  Signer: ${sig.signer}");
    print("  SignerVersion: ${sig.signerVersion}");
    print("  Timestamp: ${sig.timestamp}");
    print("  TransactionHash: ${sig.transactionHash}");

    print("\nTransaction Details:");
    final tx = envelope.transaction;
    print("  Header Initiator: ${tx['header']['initiator']}");

    // Submit and get full response
    print("\nSubmitting transaction...");

    // Use rawCall to get full response
    final response = await client.v3.rawCall("submit", envelope.toJson());

    print("\n*** FULL RPC RESPONSE ***");
    print(JsonEncoder.withIndent('  ').convert(response));

    // Extract signature hash if present
    if (response is Map) {
      final records = response["records"] ?? [response];
      if (records is List) {
        for (var i = 0; i < records.length; i++) {
          final record = records[i];
          final sigHash = record["signatureHash"] ?? record["signature"]?["hash"];
          final txHash = record["transactionHash"] ?? record["hash"];
          final status = record["status"];
          print("\nRecord $i:");
          print("  Signature Hash: $sigHash");
          print("  Transaction Hash: $txHash");
          print("  Status: $status");
        }
      }
    }

  } catch (e) {
    print("Error: $e");
  }
}
