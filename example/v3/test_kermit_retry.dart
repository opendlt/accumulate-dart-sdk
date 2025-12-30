// Retry test on Kermit - reuse existing ADI, poll for confirmations
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const String kermitEndpoint = "https://kermit.accumulatenetwork.io";

// Existing ADI from previous run
const String adiName = "kermit-test-1767095837592";
const String adiUrl = "acc://$adiName.acme";
const String keyPageUrl = "$adiUrl/book/1";
const String dataAccountUrl = "$adiUrl/test-data";

Future<void> main() async {
  print("=== Kermit Testnet Retry - With Polling ===\n");

  final client = Accumulate.custom(
    v2Endpoint: "$kermitEndpoint/v2",
    v3Endpoint: "$kermitEndpoint/v3",
  );

  try {
    // Check if ADI exists
    print("--- Checking existing ADI ---");
    Map<String, dynamic>? adiAccount;
    try {
      final result = await client.v3.rawCall("query", {
        "scope": adiUrl,
        "query": {"queryType": "default"}
      });
      adiAccount = result["account"];
      print("ADI exists: $adiUrl");
    } catch (e) {
      print("ADI not found, will need to create new one");
    }

    // Check key page
    print("\n--- Checking Key Page ---");
    int keyPageVersion = 4; // From previous run
    List<String> existingKeyHashes = [];
    try {
      final kpResult = await client.v3.rawCall("query", {
        "scope": keyPageUrl,
        "query": {"queryType": "default"}
      });
      final account = kpResult["account"];
      keyPageVersion = account?["version"] ?? keyPageVersion;
      final credits = account?["creditBalance"];
      final keys = account?["keys"] as List?;
      print("Key Page Version: $keyPageVersion");
      print("Credits: $credits");
      print("Keys on page:");
      if (keys != null) {
        for (var i = 0; i < keys.length; i++) {
          final hash = keys[i]['publicKeyHash'] as String;
          existingKeyHashes.add(hash);
          print("  $i: $hash");
        }
      }
    } catch (e) {
      print("Key page query failed: $e");
    }

    // Check if data account exists
    print("\n--- Checking Data Account ---");
    bool dataAccountExists = false;
    try {
      final result = await client.v3.rawCall("query", {
        "scope": dataAccountUrl,
        "query": {"queryType": "default"}
      });
      if (result["account"] != null) {
        dataAccountExists = true;
        print("Data account exists: $dataAccountUrl");
      }
    } catch (e) {
      print("Data account does not exist yet");
    }

    // Generate keys matching what's on the key page
    print("\n--- Generating Keys ---");

    // ETH key - find 20-byte hash on page
    final ethKey = Secp256k1KeyPair.generate();
    final ethKeyHash = ethKey.ethPublicKeyHash;
    print("New ETH Key Hash: ${toHex(ethKeyHash)}");

    // RSA key
    print("Generating RSA key...");
    final rsaKey = RsaKeyPair.generate(bitLength: 2048);
    final rsaKeyHash = rsaKey.publicKeyHash;
    print("New RSA Key Hash: ${toHex(rsaKeyHash)}");

    // ECDSA key
    final ecdsaKey = EcdsaKeyPair.generate(curve: "secp256r1");
    final ecdsaKeyHash = ecdsaKey.publicKeyHash;
    print("New ECDSA Key Hash: ${toHex(ecdsaKeyHash)}");

    // We need the original Ed25519 key to manage the key page
    // Since we don't have it, we need to create a new ADI
    print("\n--- Need Fresh Setup (don't have original key) ---");

    // Generate new lite account and ADI
    final liteKp = await Ed25519KeyPair.generate();
    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();
    print("New Lite Identity: $lid");
    print("New Lite Token Account: $lta");

    // Fund lite account
    print("\n--- Funding Lite Account ---");
    for (int i = 0; i < 5; i++) {
      try {
        await client.v2.faucet({'type': 'acmeFaucet', 'url': lta.toString()});
        print("  Faucet ${i + 1}/5 sent");
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print("  Faucet ${i + 1}/5 failed: $e");
      }
    }

    // Poll for balance
    print("\nPolling for balance...");
    for (int i = 0; i < 30; i++) {
      try {
        final result = await client.v3.rawCall("query", {
          "scope": lta.toString(),
          "query": {"queryType": "default"}
        });
        final balance = result["account"]?["balance"];
        if (balance != null && int.tryParse(balance.toString()) != null && int.parse(balance.toString()) > 0) {
          print("  Balance: $balance [OK]");
          break;
        }
        print("  Waiting for balance... ($i)");
      } catch (e) {
        print("  Query failed: $e");
      }
      await Future.delayed(Duration(seconds: 2));
    }

    // Add credits to lite identity
    print("\n--- Adding Credits to Lite Identity ---");
    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    {
      final credits = 10000;
      final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

      final body = TxBody.buyCredits(
        recipientUrl: lid.toString(),
        amount: amount.toString(),
        oracle: oracle,
      );

      final ctx = BuildContext(
        principal: lta.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      );

      final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: liteKp);
      final response = await client.v3.rawCall("submit", envelope.toJson());
      final txid = response[0]?["status"]?["txID"];
      print("AddCredits TxID: $txid");

      // Poll for delivery
      await pollForDelivery(client, txid);
    }

    // Create new ADI
    final newAdiName = "kermit-v2-${DateTime.now().millisecondsSinceEpoch}";
    final newAdiUrl = "acc://$newAdiName.acme";
    final newKeyPageUrl = "$newAdiUrl/book/1";
    final newDataAccountUrl = "$newAdiUrl/test-data";

    print("\n--- Creating ADI: $newAdiName ---");
    final primaryKp = await Ed25519KeyPair.generate();
    {
      final publicKey = await primaryKp.publicKeyBytes();
      final keyHash = sha256.convert(publicKey).bytes;
      final keyHashHex = toHex(Uint8List.fromList(keyHash));

      final body = TxBody.createIdentity(
        url: newAdiUrl,
        keyBookUrl: "$newAdiUrl/book",
        publicKeyHash: keyHashHex,
      );

      final ctx = BuildContext(
        principal: lta.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      );

      final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: liteKp);
      final response = await client.v3.rawCall("submit", envelope.toJson());
      final txid = response[0]?["status"]?["txID"];
      print("CreateIdentity TxID: $txid");

      await pollForDelivery(client, txid);
    }

    // Add credits to key page
    print("\n--- Adding Credits to Key Page ---");
    {
      final credits = 10000;
      final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

      final body = TxBody.buyCredits(
        recipientUrl: newKeyPageUrl,
        amount: amount.toString(),
        oracle: oracle,
      );

      final ctx = BuildContext(
        principal: lta.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      );

      final envelope = await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: liteKp);
      final response = await client.v3.rawCall("submit", envelope.toJson());
      final txid = response[0]?["status"]?["txID"];
      print("AddCredits to KeyPage TxID: $txid");

      await pollForDelivery(client, txid);
    }

    // Verify key page has credits
    print("\n--- Verifying Key Page Credits ---");
    for (int i = 0; i < 20; i++) {
      try {
        final result = await client.v3.rawCall("query", {
          "scope": newKeyPageUrl,
          "query": {"queryType": "default"}
        });
        final credits = result["account"]?["creditBalance"];
        if (credits != null && (credits is int ? credits > 0 : (int.tryParse(credits.toString()) ?? 0) > 0)) {
          print("  Key page credits: $credits [OK]");
          break;
        }
        print("  Waiting for credits... ($i)");
      } catch (e) {
        print("  Query failed: $e");
      }
      await Future.delayed(Duration(seconds: 2));
    }

    // Create data account
    print("\n--- Creating Data Account ---");
    {
      final body = TxBody.createDataAccount(url: newDataAccountUrl);
      final ctx = BuildContext(
        principal: newAdiUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      );

      final envelope = await TxSigner.buildAndSign(
        ctx: ctx,
        body: body,
        keypair: primaryKp,
        signerUrl: newKeyPageUrl,
        signerVersion: 1,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      final txid = response[0]?["status"]?["txID"];
      final code = response[0]?["status"]?["code"];
      print("CreateDataAccount TxID: $txid, code: $code");

      if (code == "ok") {
        await pollForDelivery(client, txid);
      } else {
        print("ERROR: ${JsonEncoder.withIndent('  ').convert(response)}");
        return;
      }
    }

    // Verify data account exists
    print("\n--- Verifying Data Account ---");
    for (int i = 0; i < 20; i++) {
      try {
        final result = await client.v3.rawCall("query", {
          "scope": newDataAccountUrl,
          "query": {"queryType": "default"}
        });
        if (result["account"] != null) {
          print("  Data account created [OK]");
          break;
        }
      } catch (e) {
        print("  Waiting for data account... ($i)");
      }
      await Future.delayed(Duration(seconds: 2));
    }

    // Add keys to key page
    int currentVersion = 1;

    print("\n--- Adding ETH Key ---");
    currentVersion = await addKeyAndPoll(client, primaryKp, newKeyPageUrl, ethKeyHash, currentVersion);

    print("\n--- Adding RSA Key ---");
    currentVersion = await addKeyAndPoll(client, primaryKp, newKeyPageUrl, rsaKeyHash, currentVersion);

    print("\n--- Adding ECDSA Key ---");
    currentVersion = await addKeyAndPoll(client, primaryKp, newKeyPageUrl, ecdsaKeyHash, currentVersion);

    // Query final key page state
    print("\n--- Final Key Page State ---");
    try {
      final result = await client.v3.rawCall("query", {
        "scope": newKeyPageUrl,
        "query": {"queryType": "default"}
      });
      final keys = result["account"]?["keys"] as List?;
      currentVersion = result["account"]?["version"] ?? currentVersion;
      print("Version: $currentVersion");
      print("Keys:");
      keys?.forEach((k) => print("  ${k['publicKeyHash']}"));
    } catch (e) {
      print("Query failed: $e");
    }

    // TEST ETH V2
    print("\n" + "=" * 50);
    print("TEST 1: ETH V2 (RSV Format)");
    print("=" * 50);
    await testWriteData(client, "ETH V2", newDataAccountUrl, newKeyPageUrl, currentVersion,
        () async => TxSigner.buildAndSignETH(
          ctx: BuildContext(
            principal: newDataAccountUrl,
            timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
            memo: "ETH V2 Test",
          ),
          body: TxBody.writeData(entriesHex: [toHex(Uint8List.fromList("ETH V2 test data".codeUnits))]),
          keypair: ethKey,
          signerUrl: newKeyPageUrl,
          signerVersion: currentVersion,
        ));

    // TEST RSA
    print("\n" + "=" * 50);
    print("TEST 2: RSA-SHA256");
    print("=" * 50);
    await testWriteData(client, "RSA", newDataAccountUrl, newKeyPageUrl, currentVersion,
        () async => TxSigner.buildAndSignRSA(
          ctx: BuildContext(
            principal: newDataAccountUrl,
            timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
            memo: "RSA Test",
          ),
          body: TxBody.writeData(entriesHex: [toHex(Uint8List.fromList("RSA test data".codeUnits))]),
          keypair: rsaKey,
          signerUrl: newKeyPageUrl,
          signerVersion: currentVersion,
        ));

    // TEST ECDSA
    print("\n" + "=" * 50);
    print("TEST 3: ECDSA-SHA256 (P-256)");
    print("=" * 50);
    await testWriteData(client, "ECDSA", newDataAccountUrl, newKeyPageUrl, currentVersion,
        () async => TxSigner.buildAndSignECDSA(
          ctx: BuildContext(
            principal: newDataAccountUrl,
            timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
            memo: "ECDSA Test",
          ),
          body: TxBody.writeData(entriesHex: [toHex(Uint8List.fromList("ECDSA test data".codeUnits))]),
          keypair: ecdsaKey,
          signerUrl: newKeyPageUrl,
          signerVersion: currentVersion,
        ));

    print("\n=== ALL TESTS COMPLETE ===");

  } catch (e, stack) {
    print("Error: $e");
    print(stack);
  } finally {
    client.close();
  }
}

Future<void> pollForDelivery(Accumulate client, String? txid, {int maxAttempts = 30}) async {
  if (txid == null) return;

  print("  Polling for delivery...");
  for (int i = 0; i < maxAttempts; i++) {
    try {
      final result = await client.v3.rawCall("query", {
        "scope": txid,
        "query": {"queryType": "default"}
      });
      final status = result["status"];
      final delivered = status?["delivered"];
      final code = status?["code"];

      if (delivered == true) {
        final failed = status?["failed"] == true;
        if (failed) {
          print("  FAILED: ${status?['error']?['message']} [ERROR]");
        } else {
          print("  Delivered [OK]");
        }
        return;
      }
      print("  Waiting... (attempt $i, code: $code)");
    } catch (e) {
      // Transaction might not be indexed yet
    }
    await Future.delayed(Duration(seconds: 2));
  }
  print("  Timeout waiting for delivery");
}

Future<int> addKeyAndPoll(Accumulate client, Ed25519KeyPair signerKp,
    String keyPageUrl, Uint8List newKeyHash, int version) async {
  final body = {
    "type": "updateKeyPage",
    "operation": [
      {
        "type": "add",
        "entry": {"keyHash": toHex(newKeyHash)}
      }
    ]
  };

  final ctx = BuildContext(
    principal: keyPageUrl,
    timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
  );

  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: signerKp,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.rawCall("submit", envelope.toJson());
  final txid = response[0]?["status"]?["txID"];
  final code = response[0]?["status"]?["code"];
  print("  UpdateKeyPage TxID: $txid, code: $code");

  if (code == "ok") {
    await pollForDelivery(client, txid);
    return version + 1;
  }
  return version;
}

Future<void> testWriteData(Accumulate client, String name, String dataAccountUrl,
    String keyPageUrl, int version, Future<Envelope> Function() buildEnvelope) async {
  try {
    final envelope = await buildEnvelope();
    final response = await client.v3.rawCall("submit", envelope.toJson());

    final txid = response[0]?["status"]?["txID"];
    final code = response[0]?["status"]?["code"];
    final success = response[0]?["success"];

    print("$name WriteData:");
    print("  TxID: $txid");
    print("  Code: $code");
    print("  Success: $success");

    if (code == "ok" && success == true) {
      await pollForDelivery(client, txid);
      print("  [DONE] $name PASSED");
    } else {
      print("  [FAIL] $name FAILED");
      print("  Response: ${JsonEncoder.withIndent('  ').convert(response)}");
    }
  } catch (e) {
    print("  [FAIL] $name ERROR: $e");
  }
}
