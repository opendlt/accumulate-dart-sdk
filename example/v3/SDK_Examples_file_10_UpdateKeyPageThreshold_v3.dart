// examples\v3\SDK_Examples_file_10_UpdateKeyPageThreshold_v3.dart
//
// This example demonstrates:
// - Updating key page threshold for multi-sig
// - Adding multiple keys to key pages
// - Setting and verifying threshold changes
// - Using SmartSigner API for auto-version tracking
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
  print("=== SDK Example 10: Update Key Page Threshold (Multi-Sig) ===\n");
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
    // Step 1: Generate key pairs
    // =========================================================
    print("--- Step 1: Generate Key Pairs ---\n");

    final liteKp = await Ed25519KeyPair.generate();
    final adiKp = await Ed25519KeyPair.generate();
    final secondKp = await Ed25519KeyPair.generate();

    final liteKey = UnifiedKeyPair.fromEd25519(liteKp);
    final adiKey = UnifiedKeyPair.fromEd25519(adiKp);

    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();

    print("Lite Identity: $lid");
    print("Lite Token Account: $lta\n");

    // =========================================================
    // Step 2: Fund the lite account via faucet
    // =========================================================
    print("--- Step 2: Fund Account via Faucet ---\n");

    await fundAccount(client, lta, faucetRequests: 5);

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

    final credits = 1000;
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

    String adiName = "sdk-thresh-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";
    final String keyPageUrl = "$bookUrl/1";

    final adiPublicKey = await adiKp.publicKeyBytes();
    final adiKeyHashHex = toHex(Uint8List.fromList(sha256.convert(adiPublicKey).bytes));

    print("ADI URL: $identityUrl");
    print("Key Page URL: $keyPageUrl\n");

    final createAdiResult = await liteSigner.signSubmitAndWait(
      principal: lta.toString(),
      body: TxBody.createIdentity(
        url: identityUrl,
        keyBookUrl: bookUrl,
        publicKeyHash: adiKeyHashHex,
      ),
      memo: "Create ADI via Dart SDK",
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

    final keyPageCredits = 500;
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
    // Step 6: Query initial key page state
    // =========================================================
    print("--- Step 6: Query Initial Key Page State ---\n");

    final adiSigner = SmartSigner(
      client: client.v3,
      keypair: adiKey,
      signerUrl: keyPageUrl,
    );

    await queryKeyPageState(client, keyPageUrl);

    // =========================================================
    // Step 7: Add second key to key page
    // =========================================================
    print("--- Step 7: Add Second Key to Key Page ---\n");

    final secondPublicKey = await secondKp.publicKeyBytes();
    final secondKeyHash = Uint8List.fromList(sha256.convert(secondPublicKey).bytes);

    print("Adding second key (hash: ${toHex(secondKeyHash).substring(0, 32)}...)");

    final addKeyResult = await adiSigner.signSubmitAndWait(
      principal: keyPageUrl,
      body: TxBody.updateKeyPage(
        operations: [AddKeyOperation(entry: KeySpecParams(keyHash: secondKeyHash))],
      ),
      memo: "Add second key to key page",
      maxAttempts: 30,
    );

    if (addKeyResult.success) {
      print("AddKey SUCCESS - TxID: ${addKeyResult.txid}\n");
      adiSigner.invalidateCache();
    } else {
      print("AddKey FAILED: ${addKeyResult.error}");
      return;
    }

    await Future.delayed(Duration(seconds: 5));
    await queryKeyPageState(client, keyPageUrl);

    // =========================================================
    // Step 8: Update threshold to 2
    // =========================================================
    print("--- Step 8: Update Threshold to 2 ---\n");

    print("Setting threshold to 2 (require both keys to sign)");

    final setThresholdResult = await adiSigner.signSubmitAndWait(
      principal: keyPageUrl,
      body: TxBody.updateKeyPage(
        operations: [SetThresholdKeyPageOperation(threshold: 2)],
      ),
      memo: "Set threshold to 2",
      maxAttempts: 30,
    );

    if (setThresholdResult.success) {
      print("SetThreshold SUCCESS - TxID: ${setThresholdResult.txid}\n");
      adiSigner.invalidateCache();
    } else {
      print("SetThreshold FAILED: ${setThresholdResult.error}");
    }

    await Future.delayed(Duration(seconds: 5));
    await queryKeyPageState(client, keyPageUrl);

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Key Page: $keyPageUrl");
    print("\nThreshold Operations:");
    print("  1. Queried initial key page state (1 key, threshold 1)");
    print("  2. Added second key to key page");
    print("  3. Updated threshold to 2 (multi-sig required)");
    print("\nUsed SmartSigner API for all transactions!");

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
