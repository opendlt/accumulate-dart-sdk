// examples\v3\SDK_Examples_file_2_Accumulate_Identities_v3.dart
//
// This example demonstrates:
// - Creating lite identities and token accounts
// - Creating ADIs (Accumulate Digital Identities)
// - Adding credits to lite identities and key pages
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
  print("=== SDK Example 2: ADI Creation ===\n");
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
    print("Lite Token Account: $lta");
    print("Public Key Hash: ${toHex(await liteKey.publicKeyHash)}\n");

    // =========================================================
    // Step 2: Fund the lite account via faucet
    // =========================================================
    print("--- Step 2: Fund Account via Faucet ---\n");

    await fundAccount(client, lta, faucetRequests: 3);

    // Poll for balance
    print("\nPolling for balance...");
    final balance = await pollForBalance(client, lta.toString());
    if (balance == null || balance == 0) {
      print("ERROR: Account not funded. Stopping.");
      return;
    }
    print("Balance confirmed: $balance\n");

    // =========================================================
    // Step 3: Add credits to lite identity using SmartSigner
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

    // Calculate amount for 500 credits (need more for ADI creation)
    final credits = 500;
    final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);
    print("Buying $credits credits for $amount ACME sub-units");

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
      print("AddCredits SUCCESS - TxID: ${addCreditsResult.txid}");
    } else {
      print("AddCredits FAILED: ${addCreditsResult.error}");
      print("Continuing anyway to demonstrate API...");
    }

    // Verify credits were added
    await Future.delayed(Duration(seconds: 3));
    try {
      final lidQuery = await client.v3.rawCall("query", {
        "scope": lid.toString(),
        "query": {"queryType": "default"}
      });
      final creditBalance = lidQuery["account"]?["creditBalance"];
      print("Lite identity credit balance: $creditBalance\n");
    } catch (e) {
      print("Could not query credit balance: $e\n");
    }

    // =========================================================
    // Step 4: Create an ADI
    // =========================================================
    print("--- Step 4: Create ADI ---\n");

    // Generate unique ADI name with timestamp
    String adiName = "sdk-adi-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";

    // Get key hash for ADI key
    final adiPublicKey = await adiKp.publicKeyBytes();
    final adiKeyHashHex = toHex(Uint8List.fromList(sha256.convert(adiPublicKey).bytes));

    print("ADI URL: $identityUrl");
    print("Key Book URL: $bookUrl");
    print("ADI Key Hash: $adiKeyHashHex\n");

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
      print("CreateIdentity SUCCESS - TxID: ${createAdiResult.txid}");
    } else {
      print("CreateIdentity FAILED: ${createAdiResult.error}");
      return;
    }

    // Verify ADI was created
    await Future.delayed(Duration(seconds: 5));
    try {
      final adiQuery = await client.v3.rawCall("query", {
        "scope": identityUrl,
        "query": {"queryType": "default"}
      });
      print("ADI created: ${adiQuery["account"]?["url"]}");
      print("ADI type: ${adiQuery["account"]?["type"]}\n");
    } catch (e) {
      print("Could not verify ADI: $e\n");
    }

    // =========================================================
    // Step 5: Add credits to ADI key page
    // =========================================================
    print("--- Step 5: Add Credits to ADI Key Page ---\n");

    String keyPageUrl = "acc://$adiName.acme/book/1";
    print("Key Page URL: $keyPageUrl");

    // Calculate amount for 200 credits
    final keyPageCredits = 200;
    final keyPageAmount = (BigInt.from(keyPageCredits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);
    print("Buying $keyPageCredits credits for $keyPageAmount ACME sub-units");

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
      print("AddCredits to key page SUCCESS - TxID: ${addKeyPageCreditsResult.txid}");
    } else {
      print("AddCredits to key page FAILED: ${addKeyPageCreditsResult.error}");
    }

    // Verify credits were added to key page
    await Future.delayed(Duration(seconds: 5));
    try {
      final keyPageQuery = await client.v3.rawCall("query", {
        "scope": keyPageUrl,
        "query": {"queryType": "default"}
      });
      final keyPageCredBalance = keyPageQuery["account"]?["creditBalance"];
      print("Key page credit balance: $keyPageCredBalance\n");
    } catch (e) {
      print("Could not query key page: $e\n");
    }

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created lite identity: $lid");
    print("Created ADI: $identityUrl");
    print("ADI Key Book: $bookUrl");
    print("ADI Key Page: $keyPageUrl");
    print("\nUsed SmartSigner API for all transactions!");
    print("No manual version tracking needed.");

  } finally {
    client.close();
  }
}

/// Fund an account using the faucet
Future<void> fundAccount(Accumulate client, AccUrl accountUrl, {int faucetRequests = 3}) async {
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
