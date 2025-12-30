// Test ETH V2, RSA, and ECDSA against Kermit public testnet
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

const String kermitEndpoint = "https://kermit.accumulatenetwork.io";

Future<void> main() async {
  print("=== Testing Against Kermit Public Testnet ===\n");
  print("Endpoint: $kermitEndpoint\n");

  final client = Accumulate.custom(
    v2Endpoint: "$kermitEndpoint/v2",
    v3Endpoint: "$kermitEndpoint/v3",
  );

  try {
    // First, check network status
    print("--- Checking Network Status ---");
    try {
      final status = await client.v3.rawCall("network-status", {});
      print("Network: ${status['network']?['id'] ?? 'unknown'}");
      print("Oracle price: ${status['oracle']?['price']}");
      final globals = status['globals'];
      if (globals != null) {
        print("Executor Version: ${globals['executorVersion']}");
      }
      print("");
    } catch (e) {
      print("Could not get network status: $e\n");
    }

    // Generate keys for testing
    print("--- Generating Test Keys ---");

    // Ed25519 for lite account
    final liteKp = await Ed25519KeyPair.generate();
    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();
    print("Lite Identity: $lid");
    print("Lite Token Account: $lta");

    // ETH key for V2 test
    final ethKey = Secp256k1KeyPair.generate();
    final ethKeyHash = ethKey.ethPublicKeyHash;
    print("\nETH Key Hash: ${toHex(ethKeyHash)}");

    // RSA key
    print("Generating RSA key (2048-bit)...");
    final rsaKey = RsaKeyPair.generate(bitLength: 2048);
    final rsaKeyHash = rsaKey.publicKeyHash;
    print("RSA Key Hash: ${toHex(rsaKeyHash)}");

    // ECDSA key
    final ecdsaKey = EcdsaKeyPair.generate(curve: "secp256r1");
    final ecdsaKeyHash = ecdsaKey.publicKeyHash;
    print("ECDSA Key Hash: ${toHex(ecdsaKeyHash)}");

    // Fund lite account
    print("\n--- Funding Lite Account from Faucet ---");
    for (int i = 0; i < 5; i++) {
      try {
        final response = await client.v2.faucet({
          'type': 'acmeFaucet',
          'url': lta.toString(),
        });
        print("  Faucet request ${i + 1}/5: ${response['txid'] ?? 'submitted'}");
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print("  Faucet request ${i + 1}/5 failed: $e");
      }
    }

    print("\nWaiting 20 seconds for faucet transactions...");
    await Future.delayed(Duration(seconds: 20));

    // Check lite account balance
    print("\n--- Checking Lite Account Balance ---");
    try {
      final balanceResult = await client.v3.rawCall("query", {
        "scope": lta.toString(),
        "query": {"queryType": "default"}
      });
      final balance = balanceResult["account"]?["balance"];
      print("Balance: $balance");
    } catch (e) {
      print("Could not get balance: $e");
    }

    // Add credits to lite identity
    print("\n--- Adding Credits to Lite Identity ---");
    try {
      final networkStatus = await client.v3.rawCall("network-status", {});
      final oracle = networkStatus["oracle"]["price"] as int;
      final credits = 5000;
      final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

      final body = TxBody.buyCredits(
        recipientUrl: lid.toString(),
        amount: amount.toString(),
        oracle: oracle,
      );

      final ctx = BuildContext(
        principal: lta.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "Buy credits",
      );

      final envelope = await TxSigner.buildAndSign(
        ctx: ctx,
        body: body,
        keypair: liteKp,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("AddCredits response: ${JsonEncoder.withIndent('  ').convert(response)}");
    } catch (e) {
      print("AddCredits failed: $e");
    }

    print("\nWaiting 15 seconds for credits...");
    await Future.delayed(Duration(seconds: 15));

    // Create ADI
    final adiName = "kermit-test-${DateTime.now().millisecondsSinceEpoch}";
    final adiUrl = "acc://$adiName.acme";
    final keyPageUrl = "$adiUrl/book/1";
    final keyBookUrl = "$adiUrl/book";

    print("\n--- Creating ADI: $adiName ---");
    final primaryKp = await Ed25519KeyPair.generate();
    try {
      final publicKey = await primaryKp.publicKeyBytes();
      final keyHash = sha256.convert(publicKey).bytes;
      final keyHashHex = toHex(Uint8List.fromList(keyHash));

      final body = TxBody.createIdentity(
        url: adiUrl,
        keyBookUrl: keyBookUrl,
        publicKeyHash: keyHashHex,
      );

      final ctx = BuildContext(
        principal: lta.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "Create ADI",
      );

      final envelope = await TxSigner.buildAndSign(
        ctx: ctx,
        body: body,
        keypair: liteKp,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("CreateIdentity response: ${JsonEncoder.withIndent('  ').convert(response)}");
    } catch (e) {
      print("CreateIdentity failed: $e");
    }

    print("\nWaiting 15 seconds for ADI creation...");
    await Future.delayed(Duration(seconds: 15));

    // Add credits to key page
    print("\n--- Adding Credits to Key Page ---");
    try {
      final networkStatus = await client.v3.rawCall("network-status", {});
      final oracle = networkStatus["oracle"]["price"] as int;
      final credits = 5000;
      final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

      final body = TxBody.buyCredits(
        recipientUrl: keyPageUrl,
        amount: amount.toString(),
        oracle: oracle,
      );

      final ctx = BuildContext(
        principal: lta.toString(),
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "Credits for key page",
      );

      final envelope = await TxSigner.buildAndSign(
        ctx: ctx,
        body: body,
        keypair: liteKp,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("AddCredits to key page: ${JsonEncoder.withIndent('  ').convert(response)}");
    } catch (e) {
      print("AddCredits to key page failed: $e");
    }

    print("\nWaiting 15 seconds...");
    await Future.delayed(Duration(seconds: 15));

    // Create data account
    final dataAccountUrl = "$adiUrl/test-data";
    print("\n--- Creating Data Account ---");
    try {
      final body = TxBody.createDataAccount(url: dataAccountUrl);
      final ctx = BuildContext(
        principal: adiUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "Create data account",
      );

      final envelope = await TxSigner.buildAndSign(
        ctx: ctx,
        body: body,
        keypair: primaryKp,
        signerUrl: keyPageUrl,
        signerVersion: 1,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("CreateDataAccount: ${JsonEncoder.withIndent('  ').convert(response)}");
    } catch (e) {
      print("CreateDataAccount failed: $e");
    }

    print("\nWaiting 15 seconds...");
    await Future.delayed(Duration(seconds: 15));

    // Add ETH, RSA, ECDSA keys to key page
    int keyPageVersion = 1;

    print("\n--- Adding ETH Key to Key Page ---");
    try {
      await addKeyToKeyPage(client, primaryKp, keyPageUrl, ethKeyHash, keyPageVersion);
      keyPageVersion++;
      await Future.delayed(Duration(seconds: 15));
    } catch (e) {
      print("Add ETH key failed: $e");
    }

    print("\n--- Adding RSA Key to Key Page ---");
    try {
      await addKeyToKeyPage(client, primaryKp, keyPageUrl, rsaKeyHash, keyPageVersion);
      keyPageVersion++;
      await Future.delayed(Duration(seconds: 15));
    } catch (e) {
      print("Add RSA key failed: $e");
    }

    print("\n--- Adding ECDSA Key to Key Page ---");
    try {
      await addKeyToKeyPage(client, primaryKp, keyPageUrl, ecdsaKeyHash, keyPageVersion);
      keyPageVersion++;
      await Future.delayed(Duration(seconds: 15));
    } catch (e) {
      print("Add ECDSA key failed: $e");
    }

    // Query key page to verify keys
    print("\n--- Key Page State ---");
    try {
      final kpResult = await client.v3.rawCall("query", {
        "scope": keyPageUrl,
        "query": {"queryType": "default"}
      });
      final keys = kpResult["account"]?["keys"] as List?;
      print("Keys on page:");
      if (keys != null) {
        for (var i = 0; i < keys.length; i++) {
          print("  $i: ${keys[i]['publicKeyHash']}");
        }
      }
      keyPageVersion = kpResult["account"]?["version"] ?? keyPageVersion;
      print("Current version: $keyPageVersion");
    } catch (e) {
      print("Query key page failed: $e");
    }

    // Test ETH V2 (RSV format)
    print("\n" + "=" * 50);
    print("TEST 1: ETH V2 (RSV Format)");
    print("=" * 50);
    try {
      final hexData = toHex(Uint8List.fromList("ETH V2 test".codeUnits));
      final body = TxBody.writeData(entriesHex: [hexData]);
      final ctx = BuildContext(
        principal: dataAccountUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "ETH V2 Test",
      );

      // Use ETH V2 (RSV format) - requires Baikonur
      final envelope = await TxSigner.buildAndSignETH(
        ctx: ctx,
        body: body,
        keypair: ethKey,
        signerUrl: keyPageUrl,
        signerVersion: keyPageVersion,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("ETH V2 Response:");
      print(JsonEncoder.withIndent('  ').convert(response));
    } catch (e) {
      print("ETH V2 failed: $e");
    }

    await Future.delayed(Duration(seconds: 10));

    // Test RSA
    print("\n" + "=" * 50);
    print("TEST 2: RSA-SHA256");
    print("=" * 50);
    try {
      final hexData = toHex(Uint8List.fromList("RSA test".codeUnits));
      final body = TxBody.writeData(entriesHex: [hexData]);
      final ctx = BuildContext(
        principal: dataAccountUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "RSA Test",
      );

      final envelope = await TxSigner.buildAndSignRSA(
        ctx: ctx,
        body: body,
        keypair: rsaKey,
        signerUrl: keyPageUrl,
        signerVersion: keyPageVersion,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("RSA Response:");
      print(JsonEncoder.withIndent('  ').convert(response));
    } catch (e) {
      print("RSA failed: $e");
    }

    await Future.delayed(Duration(seconds: 10));

    // Test ECDSA
    print("\n" + "=" * 50);
    print("TEST 3: ECDSA-SHA256 (P-256)");
    print("=" * 50);
    try {
      final hexData = toHex(Uint8List.fromList("ECDSA test".codeUnits));
      final body = TxBody.writeData(entriesHex: [hexData]);
      final ctx = BuildContext(
        principal: dataAccountUrl,
        timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
        memo: "ECDSA Test",
      );

      final envelope = await TxSigner.buildAndSignECDSA(
        ctx: ctx,
        body: body,
        keypair: ecdsaKey,
        signerUrl: keyPageUrl,
        signerVersion: keyPageVersion,
      );

      final response = await client.v3.rawCall("submit", envelope.toJson());
      print("ECDSA Response:");
      print(JsonEncoder.withIndent('  ').convert(response));
    } catch (e) {
      print("ECDSA failed: $e");
    }

    print("\n=== Test Complete ===");

  } catch (e, stack) {
    print("Error: $e");
    print(stack);
  } finally {
    client.close();
  }
}

Future<void> addKeyToKeyPage(Accumulate client, Ed25519KeyPair signerKp,
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
    memo: "Add key",
  );

  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: signerKp,
    signerUrl: keyPageUrl,
    signerVersion: version,
  );

  final response = await client.v3.rawCall("submit", envelope.toJson());
  print("UpdateKeyPage: ${response[0]?['status']?['code'] ?? response}");
}
