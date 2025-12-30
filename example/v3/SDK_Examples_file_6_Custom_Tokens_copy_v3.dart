// examples\v3\SDK_Examples_file_6_Custom_Tokens_copy_v3.dart
//
// This example demonstrates:
// - Creating custom token issuers
// - Creating token accounts for custom tokens
// - Issuing tokens to accounts
// - Transferring custom tokens between accounts
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
  print("=== SDK Example 6: Custom Tokens ===\n");
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
      print("AddCredits SUCCESS - TxID: ${addCreditsResult.txid}\n");
    } else {
      print("AddCredits FAILED: ${addCreditsResult.error}");
      return;
    }

    // =========================================================
    // Step 4: Create an ADI
    // =========================================================
    print("--- Step 4: Create ADI ---\n");

    String adiName = "sdk-tokens-${DateTime.now().millisecondsSinceEpoch}";
    final String identityUrl = "acc://$adiName.acme";
    final String bookUrl = "$identityUrl/book";
    final String keyPageUrl = "$bookUrl/1";

    // Get key hash for ADI key
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

    // Poll for key page to have credits (more reliable than fixed delay)
    final confirmedCredits = await pollForKeyPageCredits(client, keyPageUrl);
    if (confirmedCredits == null || confirmedCredits == 0) {
      print("ERROR: Key page has no credits. Cannot proceed.");
      return;
    }

    // =========================================================
    // Step 6: Create Custom Token Issuer
    // =========================================================
    print("--- Step 6: Create Custom Token ---\n");

    // Create SmartSigner for ADI key page
    final adiSigner = SmartSigner(
      client: client.v3,
      keypair: adiKey,
      signerUrl: keyPageUrl,
    );

    String customTokenUrl = "$identityUrl/mytoken";
    String symbol = "MYTKN";
    int precision = 4;

    print("Creating custom token:");
    print("  URL: $customTokenUrl");
    print("  Symbol: $symbol");
    print("  Precision: $precision\n");

    final createTokenResult = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createToken(
        url: customTokenUrl,
        symbol: symbol,
        precision: precision,
      ),
      memo: "Create custom token: $symbol",
      maxAttempts: 30,
    );

    if (createTokenResult.success) {
      print("CreateToken SUCCESS - TxID: ${createTokenResult.txid}\n");
    } else {
      print("CreateToken FAILED: ${createTokenResult.error}");
    }

    // Wait for token creation
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 7: Create Token Accounts for Custom Token
    // =========================================================
    print("--- Step 7: Create Custom Token Accounts ---\n");

    String tokenAccount1Url = "$identityUrl/tokenAccount1";
    String tokenAccount2Url = "$identityUrl/tokenAccount2";

    // Create first token account
    final createAccount1Result = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createTokenAccount(
        url: tokenAccount1Url,
        tokenUrl: customTokenUrl,
      ),
      memo: "Create token account 1",
      maxAttempts: 30,
    );

    if (createAccount1Result.success) {
      print("CreateTokenAccount 1 SUCCESS - TxID: ${createAccount1Result.txid}");
    } else {
      print("CreateTokenAccount 1 FAILED: ${createAccount1Result.error}");
    }

    // Create second token account
    final createAccount2Result = await adiSigner.signSubmitAndWait(
      principal: identityUrl,
      body: TxBody.createTokenAccount(
        url: tokenAccount2Url,
        tokenUrl: customTokenUrl,
      ),
      memo: "Create token account 2",
      maxAttempts: 30,
    );

    if (createAccount2Result.success) {
      print("CreateTokenAccount 2 SUCCESS - TxID: ${createAccount2Result.txid}\n");
    } else {
      print("CreateTokenAccount 2 FAILED: ${createAccount2Result.error}");
    }

    // Wait for accounts to be created
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 8: Issue Tokens to First Account
    // =========================================================
    print("--- Step 8: Issue Custom Tokens ---\n");

    int issueAmount = 100000; // 10.0000 MYTKN (4 decimal precision)
    print("Issuing $issueAmount tokens to $tokenAccount1Url");

    final issueResult = await adiSigner.signSubmitAndWait(
      principal: customTokenUrl,
      body: TxBody.issueTokensSingle(
        toUrl: tokenAccount1Url,
        amount: issueAmount.toString(),
      ),
      memo: "Issue $issueAmount tokens",
      maxAttempts: 30,
    );

    if (issueResult.success) {
      print("IssueTokens SUCCESS - TxID: ${issueResult.txid}\n");
    } else {
      print("IssueTokens FAILED: ${issueResult.error}");
    }

    // Wait for issuance
    await Future.delayed(Duration(seconds: 5));

    // =========================================================
    // Step 9: Transfer Tokens Between Accounts
    // =========================================================
    print("--- Step 9: Send Custom Tokens ---\n");

    int sendAmount = 25000; // 2.5000 MYTKN
    print("Sending $sendAmount tokens from $tokenAccount1Url to $tokenAccount2Url");

    final sendResult = await adiSigner.signSubmitAndWait(
      principal: tokenAccount1Url,
      body: TxBody.sendTokensSingle(
        toUrl: tokenAccount2Url,
        amount: sendAmount.toString(),
      ),
      memo: "Send custom tokens",
      maxAttempts: 30,
    );

    if (sendResult.success) {
      print("SendTokens SUCCESS - TxID: ${sendResult.txid}\n");
    } else {
      print("SendTokens FAILED: ${sendResult.error}");
    }

    // =========================================================
    // Summary
    // =========================================================
    print("=== Summary ===\n");
    print("Created ADI: $identityUrl");
    print("Created custom token: $customTokenUrl");
    print("  Symbol: $symbol");
    print("  Precision: $precision");
    print("Token Account 1: $tokenAccount1Url");
    print("Token Account 2: $tokenAccount2Url");
    print("\nOperations:");
    print("  - Issued $issueAmount tokens to Account 1");
    print("  - Transferred $sendAmount tokens to Account 2");
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
