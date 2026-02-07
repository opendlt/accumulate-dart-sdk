// examples/v3/SDK_Examples_file_11_Multi_Signature_Types_v3.dart
//
// This example demonstrates:
// - All 6 supported signature types: Ed25519, RCD1, BTC, ETH, RSA, ECDSA
// - Using UnifiedKeyPair to wrap any key type
// - Using SmartSigner API for auto-version tracking with each key type
// - Adding multiple key types to a single key page
// - Writing data signed with each key type
//
// Updated to use Kermit public testnet and SmartSigner API.
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

// Kermit public testnet endpoints
const String kermitV2 = "https://kermit.accumulatenetwork.io/v2";
const String kermitV3 = "https://kermit.accumulatenetwork.io/v3";

// For local DevNet testing, uncomment these:
// const String kermitV2 = "http://127.0.0.1:26660/v2";
// const String kermitV3 = "http://127.0.0.1:26660/v3";

Future<void> main() async {
  print("=== SDK Example 11: Multi-Signature Types ===\n");
  print("Endpoint: $kermitV3\n");
  await testFeatures();
}

Future<void> testFeatures() async {
  final client = Accumulate.custom(
    v2Endpoint: kermitV2,
    v3Endpoint: kermitV3,
  );

  try {
    // =========================================================
    // Step 1: Generate primary key pair (Ed25519 for setup)
    // =========================================================
    print("--- Step 1: Generate Primary Key Pairs ---\n");

    final liteKp = await Ed25519KeyPair.generate();
    final primaryKp = await Ed25519KeyPair.generate();

    final liteKey = UnifiedKeyPair.fromEd25519(liteKp);

    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();

    print("Lite Identity: $lid");
    print("Lite Token Account: $lta\n");

    // =========================================================
    // Step 2: Fund the lite account via faucet
    // =========================================================
    print("--- Step 2: Fund Account via Faucet ---\n");

    await fundAccount(client, lta, faucetRequests: 10);

    print("\nPolling for balance...");
    final balance = await pollForBalance(client, lta.toString());
    if (balance == null || balance == 0) {
      print("ERROR: Account not funded. Stopping.");
      return;
    }
    print("Balance confirmed: $balance\n");

    // =========================================================
    // Step 3: Add credits to lite identity
    // =========================================================
    print("--- Step 3: Add Credits to Lite Identity ---\n");

    final liteSigner = SmartSigner(
      client: client.v3,
      keypair: liteKey,
      signerUrl: lid.toString(),
    );

    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    print("Oracle price: $oracle");

    final credits = 3000;
    final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

    final addCreditsResult = await liteSigner.signSubmitAndWait(
      principal: lta.toString(),
      body: TxBody.addCredits(
        recipient: lid.toString(),
        amount: amount.toString(),
        oracle: oracle,
      ),
      memo: "Add credits to lite identity",
      maxAttempts: 30,
    );

    if (addCreditsResult.success) {
      print("AddCredits SUCCESS - TxID: ${addCreditsResult.txid}\n");
    } else {
      print("AddCredits FAILED: ${addCreditsResult.error}");
      return;
    }

    // =========================================================
    // Step 4: Create ADI
    // =========================================================
    print("--- Step 4: Create ADI ---\n");

    String adiName = "sdk-msig-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";
    final String keyPageUrl = "$bookUrl/1";

    final primaryPubKey = await primaryKp.publicKeyBytes();
    final primaryKeyHashHex = toHex(Uint8List.fromList(sha256.convert(primaryPubKey).bytes));

    print("ADI URL: $identityUrl");
    print("Key Page URL: $keyPageUrl\n");

    final createAdiResult = await liteSigner.signSubmitAndWait(
      principal: lta.toString(),
      body: TxBody.createIdentity(
        url: identityUrl,
        keyBookUrl: bookUrl,
        publicKeyHash: primaryKeyHashHex,
      ),
      memo: "Create ADI for multi-sig demo",
      maxAttempts: 30,
    );

    if (createAdiResult.success) {
      print("CreateIdentity SUCCESS - TxID: ${createAdiResult.txid}\n");
    } else {
      print("CreateIdentity FAILED: ${createAdiResult.error}");
      return;
    }

    // =========================================================
    // Step 5: Add credits to ADI key page
    // =========================================================
    print("--- Step 5: Add Credits to ADI Key Page ---\n");

    final keyPageCredits = 2000;
    final keyPageAmount = (BigInt.from(keyPageCredits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);

    final addKeyPageCreditsResult = await liteSigner.signSubmitAndWait(
      principal: lta.toString(),
      body: TxBody.addCredits(
        recipient: keyPageUrl,
        amount: keyPageAmount.toString(),
        oracle: oracle,
      ),
      memo: "Add credits to ADI key page",
      maxAttempts: 30,
    );

    if (addKeyPageCreditsResult.success) {
      print("AddCredits to key page SUCCESS - TxID: ${addKeyPageCreditsResult.txid}\n");
    } else {
      print("AddCredits to key page FAILED: ${addKeyPageCreditsResult.error}");
      return;
    }

    final confirmedCredits = await pollForKeyPageCredits(client, keyPageUrl);
    if (confirmedCredits == null || confirmedCredits == 0) {
      print("ERROR: Key page has no credits. Cannot proceed.");
      return;
    }

    // =========================================================
    // Step 6: Create data account for testing signatures
    // =========================================================
    print("--- Step 6: Create Data Account ---\n");

    final primaryKey = UnifiedKeyPair.fromEd25519(primaryKp);
    final primarySigner = SmartSigner(
      client: client.v3,
      keypair: primaryKey,
      signerUrl: keyPageUrl,
    );

    String dataAccountUrl = "$identityUrl/sig-test-data";
    print("Creating data account: $dataAccountUrl");

    final createDataResult = await primarySigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createDataAccount(url: dataAccountUrl),
      memo: "Create data account for signature tests",
      maxAttempts: 30,
    );

    if (createDataResult.success) {
      print("CreateDataAccount SUCCESS - TxID: ${createDataResult.txid}\n");
    } else {
      print("CreateDataAccount FAILED: ${createDataResult.error}");
      return;
    }

    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 7: Generate all 6 key types
    // =========================================================
    print("--- Step 7: Generate All Key Types ---\n");

    // 1. Ed25519
    final ed25519Kp = await Ed25519KeyPair.generate();
    final ed25519PubKey = await ed25519Kp.publicKeyBytes();
    final ed25519KeyHash = Uint8List.fromList(sha256.convert(ed25519PubKey).bytes);
    print("1. Ed25519 key generated (hash: ${toHex(ed25519KeyHash).substring(0, 32)}...)");

    // 2. RCD1 (Factom-style)
    final rcd1Kp = await RCD1KeyPair.generate();
    final rcd1KeyHash = await rcd1Kp.publicKeyHash();
    print("2. RCD1 key generated (hash: ${toHex(rcd1KeyHash).substring(0, 32)}...)");

    // 3. BTC (secp256k1)
    final btcKp = Secp256k1KeyPair.generate();
    final btcKeyHash = btcKp.btcPublicKeyHash;
    print("3. BTC key generated (hash: ${toHex(btcKeyHash).substring(0, 32)}...)");

    // 4. ETH (secp256k1)
    final ethKp = Secp256k1KeyPair.generate();
    final ethKeyHash = ethKp.ethPublicKeyHash;
    print("4. ETH key generated (hash: ${toHex(ethKeyHash).substring(0, 32)}...)");

    // 5. RSA (2048-bit)
    print("5. Generating RSA key (2048-bit)...");
    final rsaKp = RsaKeyPair.generate(bitLength: 2048);
    final rsaKeyHash = rsaKp.publicKeyHash;
    print("   RSA key generated (hash: ${toHex(rsaKeyHash).substring(0, 32)}...)");

    // 6. ECDSA (P-256)
    final ecdsaKp = EcdsaKeyPair.generate(curve: "secp256r1");
    final ecdsaKeyHash = ecdsaKp.publicKeyHash;
    print("6. ECDSA key generated (hash: ${toHex(ecdsaKeyHash).substring(0, 32)}...)\n");

    // =========================================================
    // Step 8: Add all keys to key page
    // =========================================================
    print("--- Step 8: Add All Keys to Key Page ---\n");

    final keyHashes = [
      {"name": "Ed25519", "hash": ed25519KeyHash},
      {"name": "RCD1", "hash": rcd1KeyHash},
      {"name": "BTC", "hash": btcKeyHash},
      {"name": "ETH", "hash": ethKeyHash},
      {"name": "RSA", "hash": rsaKeyHash},
      {"name": "ECDSA", "hash": ecdsaKeyHash},
    ];

    for (final entry in keyHashes) {
      final name = entry["name"] as String;
      final hash = entry["hash"] as Uint8List;
      print("Adding $name key to key page...");

      final result = await primarySigner.signSubmitAndWait(
        principal: keyPageUrl,
        body: TxBody.updateKeyPage(
          operations: [AddKeyOperation(entry: KeySpecParams(keyHash: hash))],
        ),
        memo: "Add $name key",
        maxAttempts: 30,
      );

      if (result.success) {
        print("  $name key added SUCCESS");
        primarySigner.invalidateCache();
      } else {
        print("  $name key add FAILED: ${result.error}");
      }
    }
    print("");

    // Wait for all keys to settle
    await Future.delayed(Duration(seconds: 5));

    // Verify all keys were added
    await queryKeyPageState(client, keyPageUrl);

    // =========================================================
    // Step 9: Write data with each key type
    // =========================================================
    print("--- Step 9: Write Data With Each Signature Type ---\n");

    // Build UnifiedKeyPair wrappers and corresponding SmartSigners
    final sigTests = [
      {"name": "Ed25519", "key": UnifiedKeyPair.fromEd25519(ed25519Kp), "data": "Hello from Ed25519!"},
      {"name": "RCD1", "key": UnifiedKeyPair.fromRCD1(rcd1Kp), "data": "Hello from RCD1 (Factom)!"},
      {"name": "BTC", "key": UnifiedKeyPair.fromBTC(btcKp), "data": "Hello from Bitcoin!"},
      {"name": "ETH", "key": UnifiedKeyPair.fromETH(ethKp), "data": "Hello from Ethereum!"},
      {"name": "RSA", "key": UnifiedKeyPair.fromRSA(rsaKp), "data": "Hello from RSA!"},
      {"name": "ECDSA", "key": UnifiedKeyPair.fromECDSA(ecdsaKp), "data": "Hello from ECDSA P-256!"},
    ];

    int successCount = 0;
    int failCount = 0;

    for (final test in sigTests) {
      final name = test["name"] as String;
      final key = test["key"] as UnifiedKeyPair;
      final data = test["data"] as String;

      print("Writing data with $name signature...");

      final signer = SmartSigner(
        client: client.v3,
        keypair: key,
        signerUrl: keyPageUrl,
      );

      final hexData = toHex(Uint8List.fromList(data.codeUnits));

      try {
        final result = await signer.signSubmitAndWait(
          principal: dataAccountUrl,
          body: TxBody.writeData(entriesHex: [hexData]),
          memo: "WriteData with $name",
          maxAttempts: 30,
        );

        if (result.success) {
          print("  [OK] $name WriteData SUCCESS - TxID: ${result.txid}");
          successCount++;
        } else {
          print("  [FAIL] $name WriteData FAILED: ${result.error}");
          failCount++;
        }
      } catch (e) {
        print("  [FAIL] $name WriteData ERROR: $e");
        failCount++;
      }
    }
    print("");

    // =========================================================
    // Step 10: Verify key page final state
    // =========================================================
    print("--- Step 10: Verify Key Page Final State ---\n");

    await queryKeyPageState(client, keyPageUrl);

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Data Account: $dataAccountUrl");
    print("Key Page: $keyPageUrl");
    print("\nSignature Type Results ($successCount/${ successCount + failCount}):");
    print("  Ed25519:  Standard Ed25519 signing");
    print("  RCD1:     Factom-style Ed25519 signing");
    print("  BTC:      Bitcoin secp256k1 signing");
    print("  ETH:      Ethereum secp256k1 signing (V2 RSV format)");
    print("  RSA:      RSA-SHA256 signing (2048-bit)");
    print("  ECDSA:    ECDSA-SHA256 P-256 signing");
    print("\nUsed SmartSigner API with UnifiedKeyPair for all transactions!");

  } catch (e, stack) {
    print("Error: $e");
    print("Stack trace: $stack");
  } finally {
    client.close();
  }
}

/// Query and display key page state
Future<void> queryKeyPageState(Accumulate client, String keyPageUrl) async {
  try {
    final result = await client.v3.rawCall("query", {
      "scope": keyPageUrl,
      "query": {"queryType": "default"}
    });

    final account = result["account"];
    if (account != null) {
      print("Key Page State:");
      print("  URL: ${account['url']}");
      print("  Version: ${account['version']}");
      print("  Accept Threshold: ${account['acceptThreshold'] ?? 1}");
      print("  Credits: ${account['creditBalance']}");

      final keys = account['keys'] as List?;
      if (keys != null) {
        print("  Keys (${keys.length}):");
        for (int i = 0; i < keys.length; i++) {
          final key = keys[i];
          final hash = key['publicKeyHash']?.toString() ?? 'N/A';
          print("    Key ${i + 1}: ${hash.length > 32 ? '${hash.substring(0, 32)}...' : hash}");
        }
      }
      print("");
    }
  } catch (e) {
    print("Could not query key page: $e\n");
  }
}

/// Fund an account using the faucet
Future<void> fundAccount(Accumulate client, AccUrl accountUrl, {int faucetRequests = 5}) async {
  print("Requesting funds from faucet ($faucetRequests times)...");
  for (int i = 0; i < faucetRequests; i++) {
    try {
      final response = await client.v2.faucet({
        'type': 'acmeFaucet',
        'url': accountUrl.toString(),
      });
      final txid = response['txid'];
      print("  Faucet ${i + 1}/$faucetRequests: $txid");
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      print("  Faucet ${i + 1}/$faucetRequests failed: $e");
    }
  }
}

/// Poll for account balance
Future<int?> pollForBalance(Accumulate client, String accountUrl, {int maxAttempts = 30}) async {
  for (int i = 0; i < maxAttempts; i++) {
    try {
      final result = await client.v3.rawCall("query", {
        "scope": accountUrl,
        "query": {"queryType": "default"}
      });
      final balance = result["account"]?["balance"];
      if (balance != null) {
        final balanceInt = int.tryParse(balance.toString()) ?? 0;
        if (balanceInt > 0) {
          return balanceInt;
        }
      }
      print("  Waiting for balance... (attempt ${i + 1}/$maxAttempts)");
    } catch (e) {
      // Account may not exist yet
    }
    await Future.delayed(Duration(seconds: 2));
  }
  return null;
}

/// Poll for key page credits
Future<int?> pollForKeyPageCredits(Accumulate client, String keyPageUrl, {int maxAttempts = 30}) async {
  print("Waiting for key page credits to settle...");
  for (int i = 0; i < maxAttempts; i++) {
    try {
      final result = await client.v3.rawCall("query", {
        "scope": keyPageUrl,
        "query": {"queryType": "default"}
      });
      final creditBalance = result["account"]?["creditBalance"];
      if (creditBalance != null) {
        final credits = int.tryParse(creditBalance.toString()) ?? 0;
        if (credits > 0) {
          print("Key page credits confirmed: $credits");
          return credits;
        }
      }
      print("  Waiting for credits... (attempt ${i + 1}/$maxAttempts)");
    } catch (e) {
      // Key page may not exist yet
    }
    await Future.delayed(Duration(seconds: 2));
  }
  return null;
}
