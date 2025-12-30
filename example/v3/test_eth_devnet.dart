// Focused ETH test against DevNet
// Purpose: Get exact error message for ETH signature failure

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== ETH Signature Test Against DevNet ===\n");

  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  try {
    // Phase 1: Setup - create lite account and fund it
    print("--- Phase 1: Setup ---");
    final liteKp = await Ed25519KeyPair.generate();
    final primaryKp = await Ed25519KeyPair.generate();
    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();

    print("Lite Token Account: $lta");

    // Fund with faucet
    print("Funding with faucet...");
    for (int i = 0; i < 5; i++) {
      try {
        await client.v2.faucet({'type': 'acmeFaucet', 'url': lta.toString()});
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print("  Faucet $i failed: $e");
      }
    }
    await Future.delayed(Duration(seconds: 15));

    // Add credits
    print("Adding credits to lite identity...");
    await _addCredits(client, lid, lta, 2000, liteKp);
    await Future.delayed(Duration(seconds: 15));

    // Create ADI
    final adiName = "eth-test-${DateTime.now().millisecondsSinceEpoch}";
    final adiUrl = "acc://$adiName.acme";
    final keyPageUrl = "$adiUrl/book/1";
    print("Creating ADI: $adiUrl");
    await _createAdi(client, lid, lta, primaryKp, adiName, liteKp);
    await Future.delayed(Duration(seconds: 15));

    // Add credits to ADI key page
    print("Adding credits to key page...");
    await _addCreditsToAdiKeyPage(client, lid, lta, keyPageUrl, 2000, liteKp);
    await Future.delayed(Duration(seconds: 20));

    // Create data account
    final dataUrl = "$adiUrl/data";
    print("Creating data account: $dataUrl");
    await _createDataAccount(client, primaryKp, adiUrl, "data", keyPageUrl);
    await Future.delayed(Duration(seconds: 15));

    // Phase 2: Generate ETH key and add to key page
    print("\n--- Phase 2: Add ETH Key ---");
    final ethKey = Secp256k1KeyPair.generate();
    final ethKeyHash = ethKey.ethPublicKeyHash;
    print("ETH Key Hash (20 bytes): ${toHex(ethKeyHash)}");
    print("ETH Uncompressed PubKey: ${toHex(ethKey.uncompressedPublicKeyBytes)}");

    // Add ETH key to key page (current version is 1)
    print("Adding ETH key to key page...");
    await _addKeyToKeyPage(client, primaryKp, keyPageUrl, ethKeyHash, 1);
    await Future.delayed(Duration(seconds: 15));

    // Verify key was added
    print("Querying key page to verify key was added...");
    final kpResult = await client.v3.rawCall("query", {
      "scope": keyPageUrl,
      "query": {"queryType": "default"}
    });
    final keys = kpResult["account"]?["keys"] as List?;
    print("Keys on key page: ${keys?.length ?? 0}");
    if (keys != null) {
      for (var i = 0; i < keys.length; i++) {
        print("  Key $i: ${keys[i]['publicKeyHash']}");
      }
    }

    // Phase 3: Write data with ETH signature
    print("\n--- Phase 3: Write Data with ETH Signature ---");
    final keyPageVersion = 2; // After adding the ETH key

    final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
    final hexData = toHex(Uint8List.fromList("Test ETH signature".codeUnits));
    final body = TxBody.writeData(entriesHex: [hexData]);

    final ctx = BuildContext(
      principal: dataUrl,
      timestamp: timestamp,
      memo: "ETH WriteData test",
    );

    final envelope = await TxSigner.buildAndSignETH(
      ctx: ctx,
      body: body,
      keypair: ethKey,
      signerUrl: keyPageUrl,
      signerVersion: keyPageVersion,
    );

    // Print envelope details
    final sig = envelope.signatures.first;
    print("\nEnvelope Details:");
    print("  Type: ${sig.type}");
    print("  PublicKey (${sig.publicKey.length ~/ 2} bytes)");
    print("  Signature (${sig.signature.length ~/ 2} bytes)");
    print("  Signer: ${sig.signer}");
    print("  SignerVersion: ${sig.signerVersion}");
    print("  Timestamp: ${sig.timestamp}");
    print("  TransactionHash: ${sig.transactionHash}");
    print("  Initiator: ${envelope.transaction['header']['initiator']}");

    // Submit and capture FULL response
    print("\nSubmitting to DevNet...");
    try {
      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("\n*** FULL RESPONSE ***");
      print(JsonEncoder.withIndent('  ').convert(response));
    } catch (e) {
      print("\n*** ERROR ***");
      print(e);
    }

  } finally {
    client.close();
  }
}

// Helper functions (simplified)
Future<void> _addCredits(Accumulate client, dynamic lid, dynamic lta, int amount, Ed25519KeyPair kp) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final body = TxBody.buyCredits(recipientUrl: lid.toString(), amount: amount.toString());
  final ctx = BuildContext(principal: lta.toString(), timestamp: timestamp);
  final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: kp);
  await client.v3.submit(envelope.toJson());
}

Future<void> _createAdi(Accumulate client, dynamic lid, dynamic lta, Ed25519KeyPair primaryKp, String name, Ed25519KeyPair signerKp) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final pubKeyHash = Uint8List.fromList(sha256.convert(await primaryKp.publicKeyBytes()).bytes);
  final body = TxBody.createIdentity(url: "acc://$name.acme", publicKeyHash: toHex(pubKeyHash), keyBookUrl: "acc://$name.acme/book");
  final ctx = BuildContext(principal: lid.toString(), timestamp: timestamp);
  final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: signerKp);
  await client.v3.submit(envelope.toJson());
}

Future<void> _addCreditsToAdiKeyPage(Accumulate client, dynamic lid, dynamic lta, String keyPageUrl, int amount, Ed25519KeyPair kp) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final body = TxBody.buyCredits(recipientUrl: keyPageUrl, amount: amount.toString());
  final ctx = BuildContext(principal: lta.toString(), timestamp: timestamp);
  final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: kp);
  await client.v3.submit(envelope.toJson());
}

Future<void> _createDataAccount(Accumulate client, Ed25519KeyPair kp, String adiUrl, String name, String keyPageUrl) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final body = TxBody.createDataAccount(url: "$adiUrl/$name");
  final ctx = BuildContext(principal: adiUrl, timestamp: timestamp);
  final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: kp, signerUrl: keyPageUrl);
  await client.v3.submit(envelope.toJson());
}

Future<void> _addKeyToKeyPage(Accumulate client, Ed25519KeyPair signerKp, String keyPageUrl, Uint8List keyHash, int version) async {
  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;
  final body = {
    "type": "updateKeyPage",
    "operation": [
      {
        "type": "add",
        "entry": {"keyHash": toHex(keyHash)}
      }
    ]
  };
  final ctx = BuildContext(principal: keyPageUrl, timestamp: timestamp);
  final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: signerKp, signerUrl: keyPageUrl, signerVersion: version);
  await client.v3.submit(envelope.toJson());
}
