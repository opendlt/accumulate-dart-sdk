// examples\v3\SDK_Examples_file_1_lite_identities_v3.dart
//
// This example demonstrates:
// - Creating lite identities and token accounts
// - Using the SmartSigner API for auto-version tracking
// - Funding accounts via faucet
// - Adding credits and sending tokens
//
// Updated to use Kermit public testnet and new SmartSigner API.
import 'dart:async';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

// Kermit public testnet endpoints
const String kermitV2 = "https://kermit.accumulatenetwork.io/v2";
const String kermitV3 = "https://kermit.accumulatenetwork.io/v3";

// For local DevNet testing, uncomment these:
// const String kermitV2 = "http://127.0.0.1:26660/v2";
// const String kermitV3 = "http://127.0.0.1:26660/v3";

Future<void> main() async {
  print("=== SDK Example 1: Lite Identities ===\n");
  print("Endpoint: $kermitV3\n");
  await testLiteIdentities();
}

Future<void> testLiteIdentities() async {
  final client = Accumulate.custom(
    v2Endpoint: kermitV2,
    v3Endpoint: kermitV3,
  );

  try {
    // =========================================================
    // Step 1: Generate key pairs for two lite identities
    // =========================================================
    print("--- Step 1: Generate Key Pairs ---\n");

    final kp1 = await Ed25519KeyPair.generate();
    final kp2 = await Ed25519KeyPair.generate();

    // Use UnifiedKeyPair for the new SmartSigner API
    final key1 = UnifiedKeyPair.fromEd25519(kp1);
    final key2 = UnifiedKeyPair.fromEd25519(kp2);

    // Derive lite identity and token account URLs
    final lid1 = await kp1.deriveLiteIdentityUrl();
    final lta1 = await kp1.deriveLiteTokenAccountUrl();
    final lid2 = await kp2.deriveLiteIdentityUrl();
    final lta2 = await kp2.deriveLiteTokenAccountUrl();

    print("Lite Identity 1: $lid1");
    print("Lite Token Account 1: $lta1");
    print("Public Key Hash 1: ${toHex(await key1.publicKeyHash)}\n");

    print("Lite Identity 2: $lid2");
    print("Lite Token Account 2: $lta2");
    print("Public Key Hash 2: ${toHex(await key2.publicKeyHash)}\n");

    // =========================================================
    // Step 2: Fund the first lite account via faucet
    // =========================================================
    print("--- Step 2: Fund Account via Faucet ---\n");

    await fundAccount(client, lta1, faucetRequests: 5);

    // Poll for balance
    print("\nPolling for balance...");
    final balance = await pollForBalance(client, lta1.toString());
    if (balance == null || balance == 0) {
      print("ERROR: Account not funded. Stopping.");
      return;
    }
    print("Balance confirmed: $balance\n");

    // =========================================================
    // Step 3: Add credits to lite identity using SmartSigner
    // =========================================================
    print("--- Step 3: Add Credits (using SmartSigner) ---\n");

    // Create SmartSigner - auto-queries signer version!
    final signer1 = SmartSigner(
      client: client.v3,
      keypair: key1,
      signerUrl: lid1.toString(), // For lite accounts, signer is the lite identity
    );

    // Get oracle price
    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    print("Oracle price: $oracle");

    // Calculate amount for 1000 credits
    final credits = 1000;
    final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);
    print("Buying $credits credits for ${amount} ACME sub-units");

    // Use SmartSigner to sign and submit - no manual version tracking!
    final addCreditsResult = await signer1.signSubmitAndWait(
      principal: lta1.toString(),
      body: TxBody.addCredits(
        recipient: lid1.toString(),
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
    await Future.delayed(Duration(seconds: 5));
    try {
      final lidQuery = await client.v3.rawCall("query", {
        "scope": lid1.toString(),
        "query": {"queryType": "default"}
      });
      final creditBalance = lidQuery["account"]?["creditBalance"];
      print("Lite identity credit balance: $creditBalance\n");
    } catch (e) {
      print("Could not query credit balance: $e\n");
    }

    // =========================================================
    // Step 4: Send tokens from lta1 to lta2
    // =========================================================
    print("--- Step 4: Send Tokens ---\n");

    final sendAmount = 100000000; // 1 ACME (8 decimal places)
    print("Sending 1 ACME from $lta1 to $lta2");

    final sendResult = await signer1.signSubmitAndWait(
      principal: lta1.toString(),
      body: TxBody.sendTokensSingle(
        toUrl: lta2.toString(),
        amount: sendAmount.toString(),
      ),
      memo: "Send 1 ACME",
      maxAttempts: 30,
    );

    if (sendResult.success) {
      print("SendTokens SUCCESS - TxID: ${sendResult.txid}");
    } else {
      print("SendTokens FAILED: ${sendResult.error}");
    }

    // Check recipient balance
    await Future.delayed(Duration(seconds: 5));
    try {
      final lta2Query = await client.v3.rawCall("query", {
        "scope": lta2.toString(),
        "query": {"queryType": "default"}
      });
      final recipientBalance = lta2Query["account"]?["balance"];
      print("Recipient balance: $recipientBalance\n");
    } catch (e) {
      print("Could not query recipient: $e\n");
    }

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created two lite identities:");
    print("  1. $lid1");
    print("  2. $lid2");
    print("\nUsed SmartSigner API which:");
    print("  - Automatically queries signer version");
    print("  - Provides sign(), signAndSubmit(), signSubmitAndWait()");
    print("  - No manual version tracking needed!");

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
