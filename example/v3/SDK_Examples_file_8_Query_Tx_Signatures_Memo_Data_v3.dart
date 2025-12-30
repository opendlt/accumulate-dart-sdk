// examples\v3\SDK_Examples_file_8_Query_Tx_Signatures_Memo_Data_v3.dart
//
// This example demonstrates:
// - Querying transactions, signatures, memo data, and account information
// - Using SmartSigner API for auto-version tracking
//
// Updated to use Kermit public testnet and SmartSigner API.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
// ignore_for_file: unused_import
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

// Kermit public testnet endpoints
const String kermitV2 = "https://kermit.accumulatenetwork.io/v2";
const String kermitV3 = "https://kermit.accumulatenetwork.io/v3";

// For local DevNet testing, uncomment these:
// const String kermitV2 = "http://127.0.0.1:26660/v2";
// const String kermitV3 = "http://127.0.0.1:26660/v3";

Future<void> main() async {
  print("=== SDK Example 8: Query Transactions & Signatures ===\n");
  print("Endpoint: $kermitV3\n");
  await testQueryFeatures();
}

Future<void> testQueryFeatures() async {
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

    String adiName = "sdk-query-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";
    final String keyPageUrl = "$bookUrl/1";

    // Get key hash for ADI key
    final adiPublicKey = await adiKp.publicKeyBytes();
    final adiKeyHashHex = toHex(Uint8List.fromList(sha256.convert(adiPublicKey).bytes));

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

    final keyPageCredits = 300;
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
    // Step 6: Create ADI Token Accounts
    // =========================================================
    print("--- Step 6: Create ADI Token Accounts ---\n");

    // Create SmartSigner for ADI key page
    final adiSigner = SmartSigner(
      client: client.v3,
      keypair: adiKey,
      signerUrl: keyPageUrl,
    );

    String tokensAccountUrl = "$identityUrl/tokens";
    String savingsAccountUrl = "$identityUrl/savings";

    final createTokens1Result = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createTokenAccount(
        url: tokensAccountUrl,
        tokenUrl: "acc://ACME",
      ),
      memo: "Create tokens account",
      maxAttempts: 30,
    );

    if (createTokens1Result.success) {
      print("CreateTokenAccount (tokens) SUCCESS");
    }

    final createSavingsResult = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createTokenAccount(
        url: savingsAccountUrl,
        tokenUrl: "acc://ACME",
      ),
      memo: "Create savings account",
      maxAttempts: 30,
    );

    if (createSavingsResult.success) {
      print("CreateTokenAccount (savings) SUCCESS\n");
    }

    // Wait for accounts to be created
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 7: Fund ADI Token Account
    // =========================================================
    print("--- Step 7: Fund ADI Token Account ---\n");

    final fundResult = await liteSigner.signSubmitAndWait(
      principal: lta.toString(),
      body: TxBody.sendTokensSingle(
        toUrl: tokensAccountUrl,
        amount: "1000000000", // 10 ACME
      ),
      memo: "Fund ADI tokens account",
      maxAttempts: 30,
    );

    if (fundResult.success) {
      print("Fund tokens account SUCCESS - TxID: ${fundResult.txid}\n");
    }

    // Wait for tokens
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 8: Send Transaction with Memo for Query Demo
    // =========================================================
    print("--- Step 8: Send Transaction with Memo ---\n");

    final testMemo = "Query Test Signature Memo V3";
    print("Sending transaction with memo: $testMemo");

    final sendResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: savingsAccountUrl,
        amount: "100000000", // 1 ACME
      ),
      memo: testMemo,
      maxAttempts: 30,
    );

    String? demoTxId;
    if (sendResult.success) {
      demoTxId = sendResult.txid;
      print("SendTokens SUCCESS - TxID: $demoTxId\n");
    }

    // Wait for transaction to be processed
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 9: Query Transaction by ID
    // =========================================================
    print("--- Step 9: Query Transaction by ID ---\n");

    if (demoTxId != null) {
      await queryTransactionById(client, demoTxId);
    }

    // =========================================================
    // Step 10: Query Account Information
    // =========================================================
    print("--- Step 10: Query Account Information ---\n");

    await queryAccountInformation(client, tokensAccountUrl);
    await queryAccountInformation(client, savingsAccountUrl);

    // =========================================================
    // Step 11: Query Key Page Information
    // =========================================================
    print("--- Step 11: Query Key Page Information ---\n");

    await queryKeyPageInformation(client, keyPageUrl);

    // =========================================================
    // Step 12: Query Lite Account
    // =========================================================
    print("--- Step 12: Query Lite Account ---\n");

    await queryAccountInformation(client, lta.toString());
    await queryAccountInformation(client, lid.toString());

    // =========================================================
    // Summary
    // =========================================================
    print("\n=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Token Accounts: $tokensAccountUrl, $savingsAccountUrl");
    print("Demonstrated queries for:");
    print("  - Transaction by ID");
    print("  - Account information");
    print("  - Key page information");
    print("  - Lite account information");
    print("\nUsed SmartSigner API for all transactions!");

  } catch (e) {
    print("Error during query testing: $e");
  } finally {
    client.close();
  }
}

/// Query a specific transaction by its ID
Future<void> queryTransactionById(Accumulate client, String txId) async {
  try {
    print("Transaction ID: $txId");

    final txHash = txId.split('@')[0].replaceAll('acc://', '');
    final txQuery = await client.v3.rawCall("query", {
      "scope": "acc://$txHash@unknown",
      "query": {"queryType": "default"}
    });

    print("\nTransaction query result:");
    print(const JsonEncoder.withIndent("  ").convert(txQuery));

    // Extract and display signature information if available
    if (txQuery is Map && txQuery["signatures"] != null) {
      final signatures = txQuery["signatures"] as List;
      print("\n--- Signature Information ---");
      for (int i = 0; i < signatures.length; i++) {
        final sig = signatures[i];
        print("Signature $i:");
        print("  Type: ${sig['type'] ?? 'Unknown'}");
        print("  PublicKey: ${sig['publicKey']?.toString().substring(0, 20) ?? 'N/A'}...");
      }
    }

    // Extract and display transaction body information
    if (txQuery is Map && txQuery["transaction"] != null) {
      final tx = txQuery["transaction"];
      print("\n--- Transaction Information ---");
      print("  Principal: ${tx['header']?['principal']}");
      print("  Memo: ${tx['header']?['memo']}");
      print("  Body Type: ${tx['body']?['type']}");
    }
    print("");

  } catch (e) {
    print("Error querying transaction by ID: $e\n");
  }
}

/// Query account information
Future<void> queryAccountInformation(Accumulate client, String accountUrl) async {
  try {
    print("Querying: $accountUrl");

    final accountQuery = await client.v3.rawCall("query", {
      "scope": accountUrl,
      "query": {"queryType": "default"}
    });

    // Display account-specific information
    if (accountQuery is Map && accountQuery["account"] != null) {
      final data = accountQuery["account"];
      print("  Type: ${data['type']}");
      print("  URL: ${data['url']}");
      if (data['balance'] != null) {
        print("  Balance: ${data['balance']}");
      }
      if (data['creditBalance'] != null) {
        print("  Credits: ${data['creditBalance']}");
      }
      if (data['tokenUrl'] != null) {
        print("  Token URL: ${data['tokenUrl']}");
      }
    }
    print("");

  } catch (e) {
    print("  Error: $e\n");
  }
}

/// Query key page information
Future<void> queryKeyPageInformation(Accumulate client, String keyPageUrl) async {
  try {
    print("Querying Key Page: $keyPageUrl");

    final keyPageQuery = await client.v3.rawCall("query", {
      "scope": keyPageUrl,
      "query": {"queryType": "default"}
    });

    // Display key page-specific information
    if (keyPageQuery is Map && keyPageQuery["account"] != null) {
      final data = keyPageQuery["account"];
      print("  Type: ${data['type']}");
      print("  URL: ${data['url']}");
      print("  Version: ${data['version']}");
      if (data['acceptThreshold'] != null) {
        print("  Accept Threshold: ${data['acceptThreshold']}");
      }
      if (data['keys'] != null) {
        final keys = data['keys'] as List;
        print("  Keys count: ${keys.length}");
      }
      if (data['creditBalance'] != null) {
        print("  Credits: ${data['creditBalance']}");
      }
    }
    print("");

  } catch (e) {
    print("  Error: $e\n");
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
