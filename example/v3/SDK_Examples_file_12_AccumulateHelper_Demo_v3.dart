// examples\v3\SDK_Examples_file_12_AccumulateHelper_Demo_v3.dart
// Demonstrates the AccumulateHelper class for more fine-grained control
//
// AccumulateHelper provides:
// - Auto-oracle fetching with caching
// - Auto-version lookup for key pages
// - Auto SHA256 hashing for keys
// - Individual operation methods for granular control

import 'dart:async';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=".padRight(60, "="));
  print("  AccumulateHelper Demo - Fine-Grained Control");
  print("=".padRight(60, "="));
  print("");

  // Create client and helper
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );
  final helper = AccumulateHelper(client);

  try {
    // ============================================================
    // ORACLE CACHING
    // ============================================================
    print(">>> Oracle Price (with caching)");
    final oracle1 = await helper.getOracle();
    print("    First call:  $oracle1 (fetched from network)");

    final oracle2 = await helper.getOracle();
    print("    Second call: $oracle2 (from cache - no network request!)");

    final oracle3 = await helper.getOracle(forceRefresh: true);
    print("    Force refresh: $oracle3 (fetched fresh)\n");

    // ============================================================
    // WALLET SETUP
    // ============================================================
    print(">>> Setting up wallet");
    final liteKp = await Ed25519KeyPair.generate();
    final adiKp = await Ed25519KeyPair.generate();

    final liteIdentity = await liteKp.deriveLiteIdentityUrl();
    final liteTokenAccount = await liteKp.deriveLiteTokenAccountUrl();
    print("    Lite Token Account: $liteTokenAccount");

    // Fund from faucet
    print("\n>>> Funding from faucet (5x)");
    final faucetTxs = await helper.faucet(liteTokenAccount.toString(), times: 5);
    print("    Got ${faucetTxs.length} faucet transactions");
    await Future.delayed(Duration(seconds: 15));

    // Check balance
    final balance = await helper.getBalance(liteTokenAccount.toString());
    print("    Balance: $balance ACME tokens");

    // ============================================================
    // BUY CREDITS (auto-oracle!)
    // ============================================================
    print("\n>>> Buy Credits (auto-fetches oracle)");
    final creditTx = await helper.buyCredits(
      from: liteTokenAccount.toString(),
      to: liteIdentity.toString(),
      credits: 500,
      signer: liteKp,
    );
    print("    Transaction: $creditTx");
    await Future.delayed(Duration(seconds: 15));

    // Check credits
    final credits = await helper.getCreditBalance(liteIdentity.toString());
    print("    Credits: $credits");

    // ============================================================
    // CREATE ADI (auto-hashes public key!)
    // ============================================================
    print("\n>>> Create ADI (auto SHA256 hash)");
    final adiName = "helper-demo-${DateTime.now().millisecondsSinceEpoch}";
    final adiTx = await helper.createADI(
      name: adiName,
      fundingAccount: liteTokenAccount.toString(),
      fundingSigner: liteKp,
      adiSigner: adiKp,
    );
    print("    ADI: acc://$adiName.acme");
    print("    Transaction: $adiTx");
    await Future.delayed(Duration(seconds: 15));

    // Add credits to key page
    print("\n>>> Buy Credits for Key Page");
    final keyPageUrl = "acc://$adiName.acme/book/1";
    await helper.buyCredits(
      from: liteTokenAccount.toString(),
      to: keyPageUrl,
      credits: 500,
      signer: liteKp,
    );
    await Future.delayed(Duration(seconds: 15));

    // ============================================================
    // QUERY HELPERS
    // ============================================================
    print("\n>>> Query Helpers");

    // Get account info
    final accountInfo = await helper.getAccount("acc://$adiName.acme");
    print("    ADI Type: ${accountInfo?['type']}");

    // Get key page info (convenient wrapper)
    final keyPageInfo = await helper.getKeyPageInfo(keyPageUrl);
    print("    Key Page Version: ${keyPageInfo?.version}");
    print("    Key Page Threshold: ${keyPageInfo?.threshold}");
    print("    Key Page Credits: ${keyPageInfo?.credits}");
    print("    Key Count: ${keyPageInfo?.keyCount}");

    // ============================================================
    // KEY MANAGEMENT (auto-version, auto-hash!)
    // ============================================================
    print("\n>>> Add Key (auto-version, auto-hash)");
    final newKey = await Ed25519KeyPair.generate();
    final addKeyTx = await helper.addKey(
      keyPageUrl: keyPageUrl,
      newKey: newKey,
      signer: adiKp,
    );
    print("    Transaction: $addKeyTx");
    await Future.delayed(Duration(seconds: 15));

    // Verify key was added
    final updatedKeyPage = await helper.getKeyPageInfo(keyPageUrl);
    print("    Keys now: ${updatedKeyPage?.keyCount}");
    print("    Version now: ${updatedKeyPage?.version}");

    // ============================================================
    // SET THRESHOLD (auto-version!)
    // ============================================================
    print("\n>>> Set Threshold (auto-version)");
    final thresholdTx = await helper.setThreshold(
      keyPageUrl: keyPageUrl,
      threshold: 2,
      signer: adiKp,
    );
    print("    Transaction: $thresholdTx");
    await Future.delayed(Duration(seconds: 15));

    // Verify threshold
    final finalKeyPage = await helper.getKeyPageInfo(keyPageUrl);
    print("    Threshold now: ${finalKeyPage?.threshold}");

    // ============================================================
    // TOKEN ACCOUNT OPERATIONS
    // ============================================================
    print("\n>>> Create Token Account (auto-version)");
    final tokenAccountTx = await helper.createTokenAccount(
      adiUrl: "acc://$adiName.acme",
      accountName: "acme-tokens",
      signer: adiKp,
      keyPageUrl: keyPageUrl,
    );
    print("    Transaction: $tokenAccountTx");
    await Future.delayed(Duration(seconds: 15));

    // Send tokens
    print("\n>>> Send Tokens (auto-version)");
    final sendTx = await helper.sendTokens(
      from: liteTokenAccount.toString(),
      to: "acc://$adiName.acme/acme-tokens",
      amount: "100000000",  // 1 ACME (8 decimals)
      signer: liteKp,
    );
    print("    Transaction: $sendTx");
    await Future.delayed(Duration(seconds: 15));

    // Check balance
    final adiBalance = await helper.getBalance("acc://$adiName.acme/acme-tokens");
    print("    ADI Token Account Balance: $adiBalance");

    // ============================================================
    // DATA OPERATIONS
    // ============================================================
    print("\n>>> Create Data Account & Write Data");
    await helper.createDataAccount(
      adiUrl: "acc://$adiName.acme",
      accountName: "logs",
      signer: adiKp,
      keyPageUrl: keyPageUrl,
    );
    await Future.delayed(Duration(seconds: 15));

    await helper.writeData(
      dataAccountUrl: "acc://$adiName.acme/logs",
      data: ["Log entry 1: System started", "Log entry 2: Operation complete"],
      signer: adiKp,
      keyPageUrl: keyPageUrl,
    );
    print("    Created data account and wrote 2 entries");

    // ============================================================
    // DONE!
    // ============================================================
    print("\n" + "=".padRight(60, "="));
    print("  AccumulateHelper Demo Complete!");
    print("=".padRight(60, "="));
    print("\nKey features demonstrated:");
    print("  - Oracle caching (reduces network calls)");
    print("  - Auto SHA256 hashing for key operations");
    print("  - Auto version lookup for key page signatures");
    print("  - Convenient query helpers (getBalance, getCreditBalance, etc.)");
    print("  - KeyPageInfo class for easy key page queries");

  } finally {
    client.close();
  }
}
