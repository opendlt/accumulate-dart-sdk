// examples\v3\SDK_Examples_file_13_QuickStart_Demo_v3.dart
// Demonstrates the ultra-simple QuickStart API
//
// BEFORE (hundreds of lines):
//   - Create keypairs
//   - Derive lite identity/token URLs
//   - Call faucet multiple times
//   - Wait for processing
//   - Query oracle price
//   - Calculate credit amounts
//   - Build transaction body
//   - Build context
//   - Sign with correct version
//   - Submit and extract txId
//   - ... repeat for each operation
//
// AFTER (just a few lines per operation):
//   final acc = QuickStart.devnet();
//   final wallet = await acc.createWallet();
//   await acc.fundWallet(wallet);
//   final adi = await acc.setupADI(wallet, "my-adi");

import 'dart:async';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=".padRight(60, "="));
  print("  QuickStart Demo - Ultra-Simple Accumulate SDK Usage");
  print("=".padRight(60, "="));
  print("");

  // ============================================================
  // STEP 1: Connect to Kermit testnet (one line!)
  // ============================================================
  print(">>> Step 1: Connect to Kermit testnet");
  final acc = QuickStart.custom(
    v2Endpoint: "https://kermit.accumulatenetwork.io/v2",
    v3Endpoint: "https://kermit.accumulatenetwork.io/v3",
  );
  print("    Connected to Kermit testnet\n");

  try {
    // ============================================================
    // STEP 2: Create a wallet (one line!)
    // ============================================================
    print(">>> Step 2: Create Wallet");
    final wallet = await acc.createWallet();
    print("    Lite Identity:      ${wallet.liteIdentity}");
    print("    Lite Token Account: ${wallet.liteTokenAccount}\n");

    // ============================================================
    // STEP 3: Fund wallet from faucet (one line!)
    // ============================================================
    print(">>> Step 3: Fund Wallet (faucet x5, wait 15s)");
    await acc.fundWallet(wallet, times: 5);
    final balance = await acc.getBalance(wallet);
    print("    Balance: $balance ACME tokens\n");

    // ============================================================
    // STEP 4: Create ADI with one call (automatically handles
    //         credits, key hashing, transaction building, signing)
    // ============================================================
    print(">>> Step 4: Create ADI (one call does everything!)");
    final adiName = "quickstart-${DateTime.now().millisecondsSinceEpoch}";
    final adi = await acc.setupADI(wallet, adiName);
    print("    ADI URL:      ${adi.url}");
    print("    Key Book:     ${adi.keyBookUrl}");
    print("    Key Page:     ${adi.keyPageUrl}\n");

    // ============================================================
    // STEP 5: Buy credits for ADI (auto-fetches oracle!)
    // ============================================================
    print(">>> Step 5: Buy Credits for ADI (auto-oracle)");
    await acc.buyCreditsForADI(wallet, adi, 500);
    await Future.delayed(Duration(seconds: 15));

    // Query key page to see credits
    final keyPageInfo = await acc.getKeyPageInfo(adi.keyPageUrl);
    print("    Credits: ${keyPageInfo?.credits ?? 0}");
    print("    Version: ${keyPageInfo?.version ?? 1}");
    print("    Threshold: ${keyPageInfo?.threshold ?? 1}\n");

    // ============================================================
    // STEP 6: Create token account (one line!)
    // ============================================================
    print(">>> Step 6: Create Token Account");
    await acc.createTokenAccount(adi, "tokens");
    await Future.delayed(Duration(seconds: 15));
    print("    Created: ${adi.url}/tokens\n");

    // ============================================================
    // STEP 7: Create data account and write data (two lines!)
    // ============================================================
    print(">>> Step 7: Create Data Account & Write Data");
    await acc.createDataAccount(adi, "mydata");
    await Future.delayed(Duration(seconds: 15));

    await acc.writeData(adi, "mydata", [
      "Hello from QuickStart!",
      "This is so easy!",
    ]);
    print("    Created: ${adi.url}/mydata");
    print("    Wrote 2 data entries\n");

    // ============================================================
    // STEP 8: Add key and set multi-sig threshold (two lines!)
    // ============================================================
    print(">>> Step 8: Multi-Sig Setup");
    final secondKey = await Ed25519KeyPair.generate();
    await acc.addKeyToADI(adi, secondKey);
    await Future.delayed(Duration(seconds: 15));

    await acc.setMultiSigThreshold(adi, 2);
    await Future.delayed(Duration(seconds: 15));

    final updatedInfo = await acc.getKeyPageInfo(adi.keyPageUrl);
    print("    Keys: ${updatedInfo?.keyCount ?? 0}");
    print("    Threshold: ${updatedInfo?.threshold ?? 1} (multi-sig!)\n");

    // ============================================================
    // DONE!
    // ============================================================
    print("=".padRight(60, "="));
    print("  DEMO COMPLETE!");
    print("=".padRight(60, "="));
    print("");
    print("Summary:");
    print("  - Created wallet with lite accounts");
    print("  - Funded from faucet");
    print("  - Created ADI: ${adi.url}");
    print("  - Bought credits (auto-oracle)");
    print("  - Created token account: ${adi.url}/tokens");
    print("  - Created data account: ${adi.url}/mydata");
    print("  - Set up 2-of-2 multi-sig");
    print("");
    print("All done with minimal code using QuickStart!");

  } finally {
    acc.close();
  }
}
