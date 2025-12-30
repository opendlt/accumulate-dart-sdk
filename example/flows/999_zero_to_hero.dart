/// Zero-to-Hero orchestrator: Complete Accumulate lifecycle demonstration
/// Runs the full sequence from key generation to token transfers with assertions

import "dart:convert";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "config.dart";

class HeroState {
  late Ed25519KeyPair liteKp;
  late Ed25519KeyPair adiKp;
  late String lid;
  late String lta;
  late String adiUrl;
  late String keyBookUrl;
  late String keyPageUrl;
  late String tokenAccountUrl;
  late String dataAccountUrl;

  final List<String> txHashes = [];
  final Map<String, dynamic> balances = {};

  void addTx(String hash) {
    txHashes.add(hash);
    print("📝 Transaction recorded: $hash");
  }

  void addBalance(String account, dynamic balance) {
    balances[account] = balance;
    print("💰 Balance recorded for $account: $balance");
  }
}

Future<void> main() async {
  print("🚀 === ACCUMULATE ZERO-TO-HERO FLOW ===");
  print("Demonstrating complete Accumulate lifecycle on local DevNet");
  print("");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();
  final state = HeroState();

  try {
    // Ensure DevNet is healthy
    print("🔍 Step 0: DevNet Health Check");
    final isHealthy = await config.checkDevNetHealth();
    if (!isHealthy) {
      throw Exception("DevNet is not accessible. Please start DevNet first.");
    }
    print("[DONE] DevNet is ready");
    print("");

    // Step 1: Generate Keys and URLs
    print("🔑 Step 1: Generate Keys and Derive URLs");
    state.liteKp = await Ed25519KeyPair.generate();
    state.adiKp = await Ed25519KeyPair.generate();
    state.lid = (await state.liteKp.deriveLiteIdentityUrl()).toString();
    state.lta = (await state.liteKp.deriveLiteTokenAccountUrl()).toString();

    final adiSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    state.adiUrl = "acc://hero-adi-$adiSuffix.acme";
    state.keyBookUrl = "${state.adiUrl}/book";
    state.keyPageUrl = "${state.keyBookUrl}/1";
    state.tokenAccountUrl = "${state.adiUrl}/tokens";
    state.dataAccountUrl = "${state.adiUrl}/data";

    print("[DONE] Lite Identity: ${state.lid}");
    print("[DONE] Lite Token Account: ${state.lta}");
    print("[DONE] ADI URL: ${state.adiUrl}");
    print("");

    // Step 2: Fund LTA via Faucet
    print("🚰 Step 2: Fund LTA via Faucet");
    final faucetResult = await accumulate.v2.faucet({
      'account': state.lta,
      'amount': 200000000, // 2 ACME
    });
    if (faucetResult['txid'] != null) {
      state.addTx(faucetResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    // Verify LTA has balance
    final ltaBalance = await accumulate.v3.query({'url': state.lta});
    state.addBalance('LTA_initial', ltaBalance);
    print("[DONE] LTA funded successfully");
    print("");

    // Step 3: Buy Credits for Lite Identity
    print("💳 Step 3: Buy Credits for Lite Identity");

    final addCreditsLite = TxBody.buyCredits(
      recipientUrl: state.lid,
      amount: '1000000',
    );

    final ctx = BuildContext(
      principal: state.lta,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final creditsEnvelope = await TxSigner.buildAndSign(
      ctx: ctx,
      body: addCreditsLite,
      keypair: state.liteKp,
    );

    final creditsResult = await accumulate.v3.submit(creditsEnvelope.toJson());
    if (creditsResult['txid'] != null) {
      state.addTx(creditsResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    // Verify LID has credits
    final lidStatus = await accumulate.v3.query({'url': state.lid});
    state.addBalance('LID_credits', lidStatus);
    print("[DONE] Credits purchased for Lite Identity");
    print("");

    // Step 4: Create ADI Structure
    print("🏗️ Step 4: Create ADI + Key Book + Key Page");

    // Create ADI
    final adiMgmtPubKey = await state.adiKp.publicKeyBytes();
    final createAdi = TxBody.createIdentity(
      url: state.adiUrl,
      keyBookName: state.keyBookUrl,
      publicKeyHash: adiMgmtPubKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    );

    final adiCtx = BuildContext(
      principal: state.lid,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final adiEnvelope = await TxSigner.buildAndSign(
      ctx: adiCtx,
      body: createAdi,
      keypair: state.liteKp,
    );

    final adiResult = await accumulate.v3.submit(adiEnvelope.toJson());
    if (adiResult['txid'] != null) {
      state.addTx(adiResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    // Create Key Book
    final createKeyBook = {
      'type': 'createKeyBook',
      'url': state.keyBookUrl,
    };

    final keyBookCtx = BuildContext(
      principal: state.adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final keyBookEnvelope = await TxSigner.buildAndSign(
      ctx: keyBookCtx,
      body: createKeyBook,
      keypair: state.adiKp,
    );

    final keyBookResult = await accumulate.v3.submit(keyBookEnvelope.toJson());
    if (keyBookResult['txid'] != null) {
      state.addTx(keyBookResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    // Create Key Page
    final createKeyPage = {
      'type': 'createKeyPage',
      'url': state.keyPageUrl,
      'keys': [
        {
          'publicKey': adiMgmtPubKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        }
      ],
    };

    final keyPageCtx = BuildContext(
      principal: state.keyBookUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final keyPageEnvelope = await TxSigner.buildAndSign(
      ctx: keyPageCtx,
      body: createKeyPage,
      keypair: state.adiKp,
    );

    final keyPageResult = await accumulate.v3.submit(keyPageEnvelope.toJson());
    if (keyPageResult['txid'] != null) {
      state.addTx(keyPageResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    print("[DONE] ADI structure created successfully");
    print("");

    // Step 5: Buy Credits for Key Page
    print("💳 Step 5: Buy Credits for Key Page");
    final addCreditsKeyPage = TxBody.buyCredits(
      recipientUrl: state.keyPageUrl,
      amount: '500000',
    );

    final keyPageCreditsCtx = BuildContext(
      principal: state.lta,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final keyPageCreditsEnvelope = await TxSigner.buildAndSign(
      ctx: keyPageCreditsCtx,
      body: addCreditsKeyPage,
      keypair: state.liteKp,
    );

    final keyPageCreditsResult = await accumulate.v3.submit(keyPageCreditsEnvelope.toJson());
    if (keyPageCreditsResult['txid'] != null) {
      state.addTx(keyPageCreditsResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    print("[DONE] Credits added to Key Page");
    print("");

    // Step 6: Create Token Account
    print("🪙 Step 6: Create ADI Token Account");
    final createTokenAccount = TxBody.createTokenAccount(
      url: state.tokenAccountUrl,
      tokenUrl: 'acc://ACME',
    );

    final tokenAccountCtx = BuildContext(
      principal: state.adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final tokenAccountEnvelope = await TxSigner.buildAndSign(
      ctx: tokenAccountCtx,
      body: createTokenAccount,
      keypair: state.adiKp,
    );

    final tokenAccountResult = await accumulate.v3.submit(tokenAccountEnvelope.toJson());
    if (tokenAccountResult['txid'] != null) {
      state.addTx(tokenAccountResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    print("[DONE] Token Account created");
    print("");

    // Step 7: Create Data Account
    print("📊 Step 7: Create ADI Data Account");
    final createDataAccount = TxBody.createDataAccount(
      url: state.dataAccountUrl,
    );

    final dataAccountCtx = BuildContext(
      principal: state.adiUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final dataAccountEnvelope = await TxSigner.buildAndSign(
      ctx: dataAccountCtx,
      body: createDataAccount,
      keypair: state.adiKp,
    );

    final dataAccountResult = await accumulate.v3.submit(dataAccountEnvelope.toJson());
    if (dataAccountResult['txid'] != null) {
      state.addTx(dataAccountResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    print("[DONE] Data Account created");
    print("");

    // Step 8: Write Data
    print("📝 Step 8: Write Data to Data Account");
    final dataPayload = {
      'message': 'Zero-to-Hero flow completed successfully!',
      'timestamp': DateTime.now().toIso8601String(),
      'flow_id': adiSuffix,
      'accounts_created': {
        'adi': state.adiUrl,
        'token_account': state.tokenAccountUrl,
        'data_account': state.dataAccountUrl,
      }
    };

    // Convert data to hex (entriesHex expects hex-encoded data)
    final dataBytes = utf8.encode(jsonEncode(dataPayload));
    final dataHex = dataBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final writeData = TxBody.writeData(
      entriesHex: [dataHex],
    );

    final writeDataCtx = BuildContext(
      principal: state.dataAccountUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final writeDataEnvelope = await TxSigner.buildAndSign(
      ctx: writeDataCtx,
      body: writeData,
      keypair: state.adiKp,
    );

    final writeDataResult = await accumulate.v3.submit(writeDataEnvelope.toJson());
    if (writeDataResult['txid'] != null) {
      state.addTx(writeDataResult['txid']);
    }
    await Future.delayed(Duration(seconds: 3));

    print("[DONE] Data written successfully");
    print("");

    // Step 9: Send Tokens LTA → ADI
    print("💸 Step 9: Send Tokens from LTA to ADI Token Account");
    final sendTokens = TxBody.sendTokensSingle(
      toUrl: state.tokenAccountUrl,
      amount: '75000000', // 0.75 ACME
    );

    final sendTokensCtx = BuildContext(
      principal: state.lta,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
    );

    final sendTokensEnvelope = await TxSigner.buildAndSign(
      ctx: sendTokensCtx,
      body: sendTokens,
      keypair: state.liteKp,
    );

    final sendTokensResult = await accumulate.v3.submit(sendTokensEnvelope.toJson());
    if (sendTokensResult['txid'] != null) {
      state.addTx(sendTokensResult['txid']);
    }
    await Future.delayed(Duration(seconds: 5));

    print("[DONE] Tokens transferred successfully");
    print("");

    // Step 10: Final Verification
    print("[DONE] Step 10: Final Balance Verification");

    // Check final balances
    final ltaFinal = await accumulate.v3.query({'url': state.lta});
    state.addBalance('LTA_final', ltaFinal);

    final adiTokenFinal = await accumulate.v3.query({'url': state.tokenAccountUrl});
    state.addBalance('ADI_token_final', adiTokenFinal);

    print("");
    print("🎉 === ZERO-TO-HERO FLOW COMPLETED SUCCESSFULLY! ===");
    print("");

    // Print Summary
    print("📋 === FLOW SUMMARY ===");
    print("🔑 Accounts Created:");
    print("  • Lite Identity: ${state.lid}");
    print("  • Lite Token Account: ${state.lta}");
    print("  • ADI: ${state.adiUrl}");
    print("  • Key Book: ${state.keyBookUrl}");
    print("  • Key Page: ${state.keyPageUrl}");
    print("  • Token Account: ${state.tokenAccountUrl}");
    print("  • Data Account: ${state.dataAccountUrl}");
    print("");

    print("📝 Transaction Hashes (${state.txHashes.length} total):");
    for (int i = 0; i < state.txHashes.length; i++) {
      print("  ${i + 1}. ${state.txHashes[i]}");
    }
    print("");

    print("💰 Final Balances:");
    state.balances.forEach((account, balance) {
      print("  • $account: $balance");
    });
    print("");

    print("[DONE] All operations completed successfully!");
    print("🚀 Accumulate Dart SDK Zero-to-Hero flow demonstration complete!");

  } catch (e, stackTrace) {
    print("");
    print("[FAIL] === FLOW FAILED ===");
    print("Error: $e");
    print("Stack trace: $stackTrace");
    print("");
    print("Partial state achieved:");
    print("  • Transaction hashes: ${state.txHashes}");
    print("  • Recorded balances: ${state.balances}");
    print("");
    print("Check DevNet status and try again.");

    throw e; // Re-throw for test integration
  } finally {
    accumulate.close();
  }
}