// examples\v3\SDK_Examples_file_9_Key_Management_v3.dart
//
// This example demonstrates:
// - Creating key pages and key books
// - Updating key pages (adding/removing keys)
// - Using SmartSigner and KeyManager APIs
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
  print("=== SDK Example 9: Key Management ===\n");
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

    // Use UnifiedKeyPair for SmartSigner API
    final liteKey = UnifiedKeyPair.fromEd25519(liteKp);
    final adiKey = UnifiedKeyPair.fromEd25519(adiKp);

    // Derive lite identity and token account URLs
    final lid = await liteKp.deriveLiteIdentityUrl();
    final lta = await liteKp.deriveLiteTokenAccountUrl();

    print("Lite Identity: $lid");
    print("Lite Token Account: $lta\n");

    // =========================================================
    // Step 2: Fund the lite account via faucet
    // =========================================================
    print("--- Step 2: Fund Account via Faucet ---\n");

    await fundAccount(client, lta, faucetRequests: 5);

    // Poll for balance
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

    // Create SmartSigner for lite identity
    final liteSigner = SmartSigner(
      client: client.v3,
      keypair: liteKey,
      signerUrl: lid.toString(),
    );

    // Get oracle price
    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    print("Oracle price: $oracle");

    // Calculate amount for 1000 credits
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
    // Step 4: Create an ADI
    // =========================================================
    print("--- Step 4: Create ADI ---\n");

    String adiName = "sdk-keymgmt-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";
    final String keyPageUrl = "$bookUrl/1";

    // Get key hash for ADI key
    final adiPublicKey = await adiKp.publicKeyBytes();
    final adiKeyHashHex = toHex(Uint8List.fromList(sha256.convert(adiPublicKey).bytes));

    print("ADI URL: $identityUrl");
    print("Key Book URL: $bookUrl");
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

    // Poll for key page to have credits (more reliable than fixed delay)
    final confirmedCredits = await pollForKeyPageCredits(client, keyPageUrl);
    if (confirmedCredits == null || confirmedCredits == 0) {
      print("ERROR: Key page has no credits. Cannot proceed.");
      return;
    }

    // =========================================================
    // Step 6: Use KeyManager to Query Key Page
    // =========================================================
    print("--- Step 6: Query Key Page Using KeyManager ---\n");

    // Create KeyManager for the key page
    final keyManager = KeyManager(
      client: client.v3,
      keyPageUrl: keyPageUrl,
    );

    // Query key page state
    final keyPageState = await keyManager.getKeyPageState();
    print("Key Page State:");
    print("  URL: ${keyPageState.url}");
    print("  Version: ${keyPageState.version}");
    print("  Credit Balance: ${keyPageState.creditBalance}");
    print("  Accept Threshold: ${keyPageState.acceptThreshold}");
    print("  Keys (${keyPageState.keys.length}):");
    for (final key in keyPageState.keys) {
      print("    - ${key.keyHash}");
    }
    print("");

    // =========================================================
    // Step 7: Create New Key Page Under Existing Key Book
    // =========================================================
    print("--- Step 7: Create New Key Page ---\n");

    // Create SmartSigner for ADI key page
    final adiSigner = SmartSigner(
      client: client.v3,
      keypair: adiKey,
      signerUrl: keyPageUrl,
    );

    // Generate new keypair for new key page
    final newPage2Kp = await Ed25519KeyPair.generate();
    final newPage2PubKey = await newPage2Kp.publicKeyBytes();
    final newPage2KeyHash = sha256.convert(newPage2PubKey).bytes;

    print("Creating new key page under $bookUrl");

    final createKeyPageResult = await adiSigner.signSubmitAndWait(
      principal: bookUrl,
      body: TxBody.createKeyPage(
        keys: [KeySpecParams(keyHash: Uint8List.fromList(newPage2KeyHash))],
      ),
      memo: "Create new key page",
      maxAttempts: 30,
    );

    if (createKeyPageResult.success) {
      print("CreateKeyPage SUCCESS - TxID: ${createKeyPageResult.txid}");
      print("New key page URL: $bookUrl/2\n");
    } else {
      print("CreateKeyPage FAILED: ${createKeyPageResult.error}\n");
    }

    // Wait for key page creation
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 8: Create New Key Book
    // =========================================================
    print("--- Step 8: Create New Key Book ---\n");

    // Generate new keypair for new key book
    final newBookKp = await Ed25519KeyPair.generate();
    final newBookPubKey = await newBookKp.publicKeyBytes();
    final newBookKeyHash = sha256.convert(newBookPubKey).bytes;
    final newKeyBookUrl = "$identityUrl/book2";

    print("Creating new key book at $newKeyBookUrl");

    final createKeyBookResult = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createKeyBook(
        url: newKeyBookUrl,
        publicKeyHash: toHex(Uint8List.fromList(newBookKeyHash)),
      ),
      memo: "Create new key book",
      maxAttempts: 30,
    );

    if (createKeyBookResult.success) {
      print("CreateKeyBook SUCCESS - TxID: ${createKeyBookResult.txid}\n");
    } else {
      print("CreateKeyBook FAILED: ${createKeyBookResult.error}\n");
    }

    // Wait for key book creation
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 9: Add Key to Existing Key Page Using SmartSigner
    // =========================================================
    print("--- Step 9: Add Key to Key Page ---\n");

    // Generate a new key to add
    final newKeyToAdd = await Ed25519KeyPair.generate();
    final newKeyUnified = UnifiedKeyPair.fromEd25519(newKeyToAdd);

    print("Adding new key to $keyPageUrl using SmartSigner.addKey()");

    final addKeyResult = await adiSigner.addKey(newKeyUnified);

    if (addKeyResult.success) {
      print("AddKey SUCCESS - TxID: ${addKeyResult.txid}");
    } else {
      print("AddKey FAILED: ${addKeyResult.error}");
    }

    // Wait for key addition
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 10: Query Updated Key Page State
    // =========================================================
    print("\n--- Step 10: Query Updated Key Page ---\n");

    final updatedKeyPageState = await keyManager.getKeyPageState();
    print("Updated Key Page State:");
    print("  Version: ${updatedKeyPageState.version}");
    print("  Keys (${updatedKeyPageState.keys.length}):");
    for (final key in updatedKeyPageState.keys) {
      print("    - ${key.keyHash.substring(0, 16)}...");
    }
    print("");

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Original Key Book: $bookUrl");
    print("Original Key Page: $keyPageUrl");
    print("\nKey Management Operations:");
    print("  1. Queried key page state with KeyManager");
    print("  2. Created new key page: $bookUrl/2");
    print("  3. Created new key book: $newKeyBookUrl");
    print("  4. Added new key to existing key page");
    print("\nUsed SmartSigner and KeyManager APIs!");
    print("  - SmartSigner.addKey() for adding keys");
    print("  - KeyManager.getKeyPageState() for querying");

  } finally {
    client.close();
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
