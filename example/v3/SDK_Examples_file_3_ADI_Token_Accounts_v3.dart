// examples\v3\SDK_Examples_file_3_ADI_Token_Accounts_v3.dart
//
// This example demonstrates:
// - Creating ADI ACME token accounts
// - Sending tokens between lite and ADI accounts
// - Using SmartSigner API with auto-version tracking
// - Using KeyManager for key page operations
//
// Updated to use Kermit public testnet and SmartSigner API.
import 'dart:async';
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
  print("=== SDK Example 3: ADI Token Accounts ===\n");
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

    final liteKp1 = await Ed25519KeyPair.generate();
    final liteKp2 = await Ed25519KeyPair.generate();
    final adiKp = await Ed25519KeyPair.generate();

    // Use UnifiedKeyPair for SmartSigner API
    final liteKey1 = UnifiedKeyPair.fromEd25519(liteKp1);
    final liteKey2 = UnifiedKeyPair.fromEd25519(liteKp2);
    final adiKey = UnifiedKeyPair.fromEd25519(adiKp);

    // Derive lite identity and token account URLs
    final lid1 = await liteKp1.deriveLiteIdentityUrl();
    final lta1 = await liteKp1.deriveLiteTokenAccountUrl();
    final lid2 = await liteKp2.deriveLiteIdentityUrl();
    final lta2 = await liteKp2.deriveLiteTokenAccountUrl();

    print("Lite Account 1: $lta1");
    print("Lite Account 2: $lta2\n");

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
    // Step 3: Add credits to lite identity
    // =========================================================
    print("--- Step 3: Add Credits to Lite Identity ---\n");

    // Create SmartSigner for lite identity
    final liteSigner1 = SmartSigner(
      client: client.v3,
      keypair: liteKey1,
      signerUrl: lid1.toString(),
    );

    // Get oracle price
    final networkStatus = await client.v3.rawCall("network-status", {});
    final oracle = networkStatus["oracle"]["price"] as int;
    print("Oracle price: $oracle");

    // Calculate amount for 1000 credits
    final credits = 1000;
    final amount = (BigInt.from(credits) * BigInt.from(10000000000)) ~/ BigInt.from(oracle);
    print("Buying $credits credits for $amount ACME sub-units");

    final addCreditsResult = await liteSigner1.signSubmitAndWait(
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
      print("AddCredits SUCCESS - TxID: ${addCreditsResult.txid}\n");
    } else {
      print("AddCredits FAILED: ${addCreditsResult.error}");
      return;
    }

    // =========================================================
    // Step 4: Create an ADI
    // =========================================================
    print("--- Step 4: Create ADI ---\n");

    String adiName = "sdk-adi-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";
    final String keyPageUrl = "$bookUrl/1";

    // Get key hash for ADI key
    final adiPublicKey = await adiKp.publicKeyBytes();
    final adiKeyHashHex = toHex(Uint8List.fromList(sha256.convert(adiPublicKey).bytes));

    print("ADI URL: $identityUrl");
    print("Key Page URL: $keyPageUrl\n");

    final createAdiResult = await liteSigner1.signSubmitAndWait(
      principal: lta1.toString(),
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

    final addKeyPageCreditsResult = await liteSigner1.signSubmitAndWait(
      principal: lta1.toString(),
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

    String tokenAccountUrl1 = "$identityUrl/acme-account-1";
    String tokenAccountUrl2 = "$identityUrl/acme-account-2";

    // Create first token account
    final createToken1Result = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createTokenAccount(
        url: tokenAccountUrl1,
        tokenUrl: "acc://ACME",
      ),
      memo: "Create first ADI token account",
      maxAttempts: 30,
    );

    if (createToken1Result.success) {
      print("CreateTokenAccount 1 SUCCESS - TxID: ${createToken1Result.txid}");
    } else {
      print("CreateTokenAccount 1 FAILED: ${createToken1Result.error}");
    }

    // Create second token account
    final createToken2Result = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createTokenAccount(
        url: tokenAccountUrl2,
        tokenUrl: "acc://ACME",
      ),
      memo: "Create second ADI token account",
      maxAttempts: 30,
    );

    if (createToken2Result.success) {
      print("CreateTokenAccount 2 SUCCESS - TxID: ${createToken2Result.txid}\n");
    } else {
      print("CreateTokenAccount 2 FAILED: ${createToken2Result.error}");
    }

    // Wait for accounts to be created
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 7: Send tokens from lite to ADI account
    // =========================================================
    print("--- Step 7: Send Tokens from Lite to ADI ---\n");

    final sendAmount1 = 5 * pow(10, 8).toInt(); // 5 ACME
    print("Sending 5 ACME from $lta1 to $tokenAccountUrl1");

    final sendResult1 = await liteSigner1.signSubmitAndWait(
      principal: lta1.toString(),
      body: TxBody.sendTokensSingle(
        toUrl: tokenAccountUrl1,
        amount: sendAmount1.toString(),
      ),
      memo: "Send 5 ACME to ADI token account",
      maxAttempts: 30,
    );

    if (sendResult1.success) {
      print("SendTokens SUCCESS - TxID: ${sendResult1.txid}\n");
    } else {
      print("SendTokens FAILED: ${sendResult1.error}");
    }

    // Wait for tokens to arrive
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 8: Send tokens from ADI to lite account
    // =========================================================
    print("--- Step 8: Send Tokens from ADI to Lite ---\n");

    final sendAmount2 = 2 * pow(10, 8).toInt(); // 2 ACME
    print("Sending 2 ACME from $tokenAccountUrl1 to $lta2");

    final sendResult2 = await adiSigner.signSubmitAndWait(
      principal: tokenAccountUrl1,
      body: TxBody.sendTokensSingle(
        toUrl: lta2.toString(),
        amount: sendAmount2.toString(),
      ),
      memo: "Send 2 ACME to lite account",
      maxAttempts: 30,
    );

    if (sendResult2.success) {
      print("SendTokens SUCCESS - TxID: ${sendResult2.txid}\n");
    } else {
      print("SendTokens FAILED: ${sendResult2.error}");
    }

    // =========================================================
    // Step 9: Send tokens between ADI accounts
    // =========================================================
    print("--- Step 9: Send Tokens Between ADI Accounts ---\n");

    final sendAmount3 = 1 * pow(10, 8).toInt(); // 1 ACME
    print("Sending 1 ACME from $tokenAccountUrl1 to $tokenAccountUrl2");

    final sendResult3 = await adiSigner.signSubmitAndWait(
      principal: tokenAccountUrl1,
      body: TxBody.sendTokensSingle(
        toUrl: tokenAccountUrl2,
        amount: sendAmount3.toString(),
      ),
      memo: "Send 1 ACME between ADI accounts",
      maxAttempts: 30,
    );

    if (sendResult3.success) {
      print("SendTokens SUCCESS - TxID: ${sendResult3.txid}\n");
    } else {
      print("SendTokens FAILED: ${sendResult3.error}");
    }

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Token Account 1: $tokenAccountUrl1");
    print("Token Account 2: $tokenAccountUrl2");
    print("\nToken transfers:");
    print("  - 5 ACME: lite -> ADI account 1");
    print("  - 2 ACME: ADI account 1 -> lite account 2");
    print("  - 1 ACME: ADI account 1 -> ADI account 2");
    print("\nUsed SmartSigner API for all transactions!");

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
