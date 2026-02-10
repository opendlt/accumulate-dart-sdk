// examples\v3\SDK_Examples_file_14_Adi_to_Adi_Transfer_with_Header_Options.dart
//
// This example demonstrates:
// - Sending ACME tokens between ADI token accounts (ADI-to-ADI transfers)
// - Using optional transaction header fields:
//   - memo: Human-readable memo text
//   - metadata: Binary metadata bytes
//   - expire: Transaction expiration time
//   - holdUntil: Scheduled execution (minor block)
//   - authorities: Additional signing authorities
//
// Uses Kermit public testnet and SmartSigner API.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  print("=== SDK Example 14: ADI-to-ADI Transfer with Header Options (Dart) ===\n");
  print("Endpoint: $kermitV3\n");
  await testFeatures();
}

Future<void> testFeatures() async {
  final client = Accumulate.custom(
    v2Endpoint: kermitV2,
    v3Endpoint: kermitV3,
  );

  final List<MapEntry<String, String?>> txIds = [];

  try {
    // =========================================================
    // Step 1: Generate key pairs
    // =========================================================
    print("--- Step 1: Generate Key Pairs ---\n");

    final liteKp = await Ed25519KeyPair.generate();
    final adiKp = await Ed25519KeyPair.generate();

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

    final credits = 2000;
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
      txIds.add(MapEntry("AddCredits (lite identity)", addCreditsResult.txid));
    } else {
      print("AddCredits FAILED: ${addCreditsResult.error}");
      return;
    }

    // Poll for lite identity credits
    print("Polling for lite identity credits...");
    final lidCredits = await pollForCredits(client, lid.toString());
    if (lidCredits == null || lidCredits == 0) {
      print("ERROR: Lite identity has no credits. Stopping.");
      return;
    }
    print("Lite identity credits confirmed: $lidCredits\n");

    // =========================================================
    // Step 4: Create an ADI
    // =========================================================
    print("--- Step 4: Create ADI ---\n");

    String adiName = "sdk-hdropt-${DateTime.now().millisecondsSinceEpoch}";
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
      print("CreateIdentity SUCCESS - TxID: ${createAdiResult.txid}");
      txIds.add(MapEntry("CreateIdentity", createAdiResult.txid));
    } else {
      print("CreateIdentity FAILED: ${createAdiResult.error}");
      return;
    }

    // Poll for ADI creation
    print("Polling to confirm ADI creation...");
    if (!await pollForAccountExists(client, identityUrl)) {
      print("ERROR: ADI not found after creation. Stopping.");
      return;
    }
    print("ADI confirmed: $identityUrl\n");

    // =========================================================
    // Step 5: Add credits to ADI key page
    // =========================================================
    print("--- Step 5: Add Credits to ADI Key Page ---\n");

    final keyPageCredits = 1000;
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
      print("AddCredits to key page SUCCESS - TxID: ${addKeyPageCreditsResult.txid}");
      txIds.add(MapEntry("AddCredits (key page)", addKeyPageCreditsResult.txid));
    } else {
      print("AddCredits to key page FAILED: ${addKeyPageCreditsResult.error}");
      return;
    }

    final confirmedCredits = await pollForKeyPageCredits(client, keyPageUrl);
    if (confirmedCredits == null || confirmedCredits == 0) {
      print("ERROR: Key page has no credits. Cannot proceed.");
      return;
    }
    print("");

    // =========================================================
    // Step 6: Create ADI Token Accounts
    // =========================================================
    print("--- Step 6: Create ADI Token Accounts ---\n");

    final adiSigner = SmartSigner(
      client: client.v3,
      keypair: adiKey,
      signerUrl: keyPageUrl,
    );

    String tokensAccountUrl = "$identityUrl/tokens";
    String stakingAccountUrl = "$identityUrl/staking";
    String savingsAccountUrl = "$identityUrl/savings";
    String reserveAccountUrl = "$identityUrl/reserve";

    final accounts = [
      [tokensAccountUrl, "tokens"],
      [stakingAccountUrl, "staking"],
      [savingsAccountUrl, "savings"],
      [reserveAccountUrl, "reserve"],
    ];

    for (final entry in accounts) {
      final accountUrl = entry[0];
      final accountName = entry[1];

      print("Creating $accountName account: $accountUrl");
      final createResult = await adiSigner.signSubmitAndWait(
        principal: identityUrl,
        body: TxBody.createTokenAccount(
          url: accountUrl,
          tokenUrl: "acc://ACME",
        ),
        memo: "Create $accountName account",
        maxAttempts: 30,
      );

      if (createResult.success) {
        print("CreateTokenAccount ($accountName) SUCCESS - TxID: ${createResult.txid}");
        txIds.add(MapEntry("CreateTokenAccount ($accountName)", createResult.txid));
        if (!await pollForAccountExists(client, accountUrl)) {
          print("WARNING: $accountName account not confirmed after creation");
        } else {
          print("  $accountName account confirmed");
        }
      } else {
        print("CreateTokenAccount ($accountName) FAILED: ${createResult.error}");
        print("ERROR: Token account creation failed. Stopping.");
        return;
      }
    }

    // =========================================================
    // Step 7: Fund ADI tokens account from lite account
    // =========================================================
    print("\n--- Step 7: Fund ADI tokens account from lite ---\n");

    final fundAmount = 50 * pow(10, 8).toInt(); // 50 ACME
    print("Sending 50 ACME from lite to $tokensAccountUrl");

    final fundResult = await liteSigner.signSubmitAndWait(
      principal: lta.toString(),
      body: TxBody.sendTokensSingle(
        toUrl: tokensAccountUrl,
        amount: fundAmount.toString(),
      ),
      memo: "Fund ADI tokens account",
      maxAttempts: 30,
    );

    if (fundResult.success) {
      print("SendTokens SUCCESS - TxID: ${fundResult.txid}");
      txIds.add(MapEntry("SendTokens (lite to ADI)", fundResult.txid));
    } else {
      print("SendTokens FAILED: ${fundResult.error}");
      return;
    }

    // Poll for tokens account balance
    print("Polling for tokens account balance...");
    final tokensBalance = await pollForTokenBalance(client, tokensAccountUrl);
    if (tokensBalance == null || tokensBalance == 0) {
      print("ERROR: Tokens account has no balance. Stopping.");
      return;
    }
    print("Tokens account balance confirmed: $tokensBalance\n");

    // =========================================================
    // Step 8: Transfer with MEMO
    // =========================================================
    print("--- Step 8: Transfer with MEMO Header Option ---\n");

    final transferAmount1 = 2 * pow(10, 8).toInt(); // 2 ACME
    final memoText = "Payment for SDK example services - Invoice #12345";

    print("Sending 2 ACME with memo: '$memoText'");
    print("From: $tokensAccountUrl");
    print("To: $stakingAccountUrl\n");

    final transferMemoResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: stakingAccountUrl,
        amount: transferAmount1.toString(),
      ),
      memo: memoText,
      maxAttempts: 30,
    );

    if (transferMemoResult.success) {
      print("Transfer with MEMO SUCCESS!");
      print("TxID: ${transferMemoResult.txid}\n");
      txIds.add(MapEntry("SendTokens (with memo)", transferMemoResult.txid));
    } else {
      print("Transfer with MEMO FAILED: ${transferMemoResult.error}");
    }

    await Future.delayed(Duration(seconds: 9));

    // =========================================================
    // Step 9: Transfer with METADATA
    // =========================================================
    print("--- Step 9: Transfer with METADATA Header Option ---\n");

    final transferAmount2 = 2 * pow(10, 8).toInt(); // 2 ACME
    final metadataBytes = Uint8List.fromList(utf8.encode("Binary metadata: SDK Example 14"));

    print("Sending 2 ACME with metadata: ${utf8.decode(metadataBytes)}");
    print("From: $tokensAccountUrl");
    print("To: $savingsAccountUrl\n");

    final transferMetadataResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: savingsAccountUrl,
        amount: transferAmount2.toString(),
      ),
      metadata: metadataBytes,
      maxAttempts: 30,
    );

    if (transferMetadataResult.success) {
      print("Transfer with METADATA SUCCESS!");
      print("TxID: ${transferMetadataResult.txid}\n");
      txIds.add(MapEntry("SendTokens (with metadata)", transferMetadataResult.txid));
    } else {
      print("Transfer with METADATA FAILED: ${transferMetadataResult.error}");
    }

    await Future.delayed(Duration(seconds: 9));

    // =========================================================
    // Step 10: Transfer with EXPIRE (1 hour from now)
    // =========================================================
    print("--- Step 10: Transfer with EXPIRE Header Option ---\n");

    final transferAmount3 = 2 * pow(10, 8).toInt(); // 2 ACME
    final expireTime = DateTime.now().toUtc().add(Duration(hours: 1));

    print("Sending 2 ACME with expire time: ${expireTime.toIso8601String()}");
    print("From: $tokensAccountUrl");
    print("To: $reserveAccountUrl\n");

    final transferExpireResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: reserveAccountUrl,
        amount: transferAmount3.toString(),
      ),
      expire: expireTime,
      maxAttempts: 30,
    );

    if (transferExpireResult.success) {
      print("Transfer with EXPIRE SUCCESS!");
      print("TxID: ${transferExpireResult.txid}\n");
      txIds.add(MapEntry("SendTokens (with expire)", transferExpireResult.txid));
    } else {
      print("Transfer with EXPIRE FAILED: ${transferExpireResult.error}");
    }

    await Future.delayed(Duration(seconds: 9));

    // =========================================================
    // Step 11: Transfer with HOLD_UNTIL (minor block)
    // =========================================================
    print("--- Step 11: Transfer with HOLD_UNTIL Header Option ---\n");

    final transferAmount4 = 2 * pow(10, 8).toInt(); // 2 ACME
    final holdBlock = 1000000; // Example future block number

    print("Sending 2 ACME with hold_until block: $holdBlock");
    print("From: $tokensAccountUrl");
    print("To: $stakingAccountUrl");
    print("(Transaction will be held until the specified minor block)\n");

    final transferHoldResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: stakingAccountUrl,
        amount: transferAmount4.toString(),
      ),
      holdUntil: holdBlock,
      maxAttempts: 30,
    );

    if (transferHoldResult.success) {
      print("Transfer with HOLD_UNTIL SUCCESS!");
      print("TxID: ${transferHoldResult.txid}\n");
      txIds.add(MapEntry("SendTokens (with hold_until)", transferHoldResult.txid));
    } else {
      print("Transfer with HOLD_UNTIL FAILED: ${transferHoldResult.error}");
    }

    await Future.delayed(Duration(seconds: 9));

    // =========================================================
    // Step 12: Transfer with AUTHORITIES
    // =========================================================
    print("--- Step 12: Transfer with AUTHORITIES Header Option ---\n");

    final transferAmount5 = 2 * pow(10, 8).toInt(); // 2 ACME
    final authoritiesList = [keyPageUrl]; // Using same key page for demonstration

    print("Sending 2 ACME with authorities: $authoritiesList");
    print("From: $tokensAccountUrl");
    print("To: $savingsAccountUrl\n");

    final transferAuthResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: savingsAccountUrl,
        amount: transferAmount5.toString(),
      ),
      authorities: authoritiesList,
      maxAttempts: 30,
    );

    if (transferAuthResult.success) {
      print("Transfer with AUTHORITIES SUCCESS!");
      print("TxID: ${transferAuthResult.txid}\n");
      txIds.add(MapEntry("SendTokens (with authorities)", transferAuthResult.txid));
    } else {
      print("Transfer with AUTHORITIES FAILED: ${transferAuthResult.error}");
    }

    await Future.delayed(Duration(seconds: 9));

    // =========================================================
    // Step 13: Transfer with ALL header options combined
    // =========================================================
    print("--- Step 13: Transfer with ALL Header Options Combined ---\n");

    final transferAmount6 = 2 * pow(10, 8).toInt(); // 2 ACME
    final combinedMemo = "Complete transaction with all header options";
    final combinedMetadata = Uint8List.fromList(utf8.encode("Full featured transaction metadata"));
    final combinedExpire = DateTime.now().toUtc().add(Duration(hours: 2));

    print("Sending 2 ACME with ALL header options:");
    print("  - memo: '$combinedMemo'");
    print("  - metadata: ${utf8.decode(combinedMetadata)}");
    print("  - expire: ${combinedExpire.toIso8601String()}");
    print("From: $tokensAccountUrl");
    print("To: $reserveAccountUrl\n");

    final transferAllResult = await adiSigner.signSubmitAndWait(
      principal: tokensAccountUrl,
      body: TxBody.sendTokensSingle(
        toUrl: reserveAccountUrl,
        amount: transferAmount6.toString(),
      ),
      memo: combinedMemo,
      metadata: combinedMetadata,
      expire: combinedExpire,
      maxAttempts: 30,
    );

    if (transferAllResult.success) {
      print("Transfer with ALL OPTIONS SUCCESS!");
      print("TxID: ${transferAllResult.txid}\n");
      txIds.add(MapEntry("SendTokens (all options)", transferAllResult.txid));
    } else {
      print("Transfer with ALL OPTIONS FAILED: ${transferAllResult.error}");
    }

    // =========================================================
    // Step 14: Verify balances
    // =========================================================
    print("--- Step 14: Verify Balances ---\n");

    await Future.delayed(Duration(seconds: 15));

    for (final entry in accounts) {
      final accountUrl = entry[0];
      final accountName = entry[1];
      try {
        final queryResult = await client.v3.rawCall("query", {
          "scope": accountUrl,
          "query": {"queryType": "default"}
        });
        final accountBalance = queryResult["account"]?["balance"];
        print("${accountName[0].toUpperCase()}${accountName.substring(1)} account balance: $accountBalance");
      } catch (e) {
        print("Could not query $accountName balance: $e");
      }
    }

    // =========================================================
    // Summary
    // =========================================================
    print("\n=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Token Accounts: tokens, staking, savings, reserve");
    print("\nToken transfers demonstrated with header options:");
    print("  - MEMO: Human-readable transaction memo");
    print("  - METADATA: Binary metadata bytes");
    print("  - EXPIRE: Transaction expiration time");
    print("  - HOLD_UNTIL: Scheduled execution at specific block");
    print("  - AUTHORITIES: Additional signing authorities");
    print("  - ALL COMBINED: Multiple header options together");

    // =========================================================
    // TxID Report
    // =========================================================
    print("\n=== TRANSACTION IDs FOR VERIFICATION ===\n");
    for (final entry in txIds) {
      print("  ${entry.key}: ${entry.value}");
    }
    print("\nTotal transactions: ${txIds.length}");
    print("Example 14 COMPLETED SUCCESSFULLY!");

  } finally {
    client.close();
  }
}

/// Fund an account using the faucet
Future<void> fundAccount(Accumulate client, AccUrl accountUrl, {int faucetRequests = 10}) async {
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

/// Poll for credits on a lite identity or key page
Future<int?> pollForCredits(Accumulate client, String url, {int maxAttempts = 30}) async {
  for (int i = 0; i < maxAttempts; i++) {
    try {
      final result = await client.v3.rawCall("query", {
        "scope": url,
        "query": {"queryType": "default"}
      });
      final creditBalance = result["account"]?["creditBalance"];
      if (creditBalance != null) {
        final credits = int.tryParse(creditBalance.toString()) ?? 0;
        if (credits > 0) {
          return credits;
        }
      }
      print("  Waiting for credits... (attempt ${i + 1}/$maxAttempts)");
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

/// Poll to confirm an account exists
Future<bool> pollForAccountExists(Accumulate client, String accountUrl, {int maxAttempts = 30}) async {
  for (int i = 0; i < maxAttempts; i++) {
    try {
      final result = await client.v3.rawCall("query", {
        "scope": accountUrl,
        "query": {"queryType": "default"}
      });
      final account = result["account"];
      if (account != null) {
        return true;
      }
    } catch (e) {
      // Account may not exist yet
    }
    if (i > 0 && i % 5 == 0) {
      print("  Waiting for account... (attempt ${i + 1}/$maxAttempts)");
    }
    await Future.delayed(Duration(seconds: 2));
  }
  return false;
}

/// Poll for token account balance
Future<int?> pollForTokenBalance(Accumulate client, String accountUrl, {int maxAttempts = 30}) async {
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
      print("  Waiting for token balance... (attempt ${i + 1}/$maxAttempts)");
    } catch (e) {
      // Account may not exist yet
    }
    await Future.delayed(Duration(seconds: 2));
  }
  return null;
}
