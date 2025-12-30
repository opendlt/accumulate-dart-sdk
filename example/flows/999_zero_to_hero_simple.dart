/// Simplified Zero-to-Hero orchestrator using raw API calls
/// Demonstrates the DevNet discovery and basic connectivity

import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "config.dart";

class SimpleHeroState {
  late Ed25519KeyPair liteKp;
  late String lid;
  late String lta;
  late String adiUrl;

  final List<String> txHashes = [];
  final Map<String, dynamic> results = {};
}

Future<void> main() async {
  print("🚀 === ACCUMULATE SIMPLE ZERO-TO-HERO FLOW ===");
  print("Demonstrating DevNet discovery and basic API calls");
  print("");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();
  final state = SimpleHeroState();

  try {
    // Step 0: DevNet Health Check
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
    state.lid = (await state.liteKp.deriveLiteIdentityUrl()).toString();
    state.lta = (await state.liteKp.deriveLiteTokenAccountUrl()).toString();

    final adiSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    state.adiUrl = "acc://simple-hero-$adiSuffix.acme";

    print("[DONE] Lite Identity: ${state.lid}");
    print("[DONE] Lite Token Account: ${state.lta}");
    print("[DONE] Planned ADI URL: ${state.adiUrl}");
    print("");

    // Step 2: Try Faucet Funding
    print("🚰 Step 2: Attempt Faucet Funding");
    try {
      final faucetResult = await accumulate.v2.faucet({
        'account': state.lta,
        'amount': 100000000, // 1 ACME
      });
      print("Faucet response: $faucetResult");
      if (faucetResult['txid'] != null) {
        state.txHashes.add(faucetResult['txid']);
        print("[DONE] Faucet request submitted with tx: ${faucetResult['txid']}");
      }
      state.results['faucet'] = faucetResult;
    } catch (e) {
      print("[WARN] Faucet request failed: $e");
      state.results['faucet_error'] = e.toString();
    }
    print("");

    // Step 3: Check Network Status
    print("🌐 Step 3: Check Network Status");
    try {
      final networkStatus = await accumulate.v3.rawCall('network-status', {});
      print("Network status: $networkStatus");
      state.results['network_status'] = networkStatus;
      print("[DONE] Network status retrieved");
    } catch (e) {
      print("[WARN] Network status failed: $e");
      state.results['network_status_error'] = e.toString();
    }
    print("");

    // Step 4: Try Account Queries
    print("🔍 Step 4: Try Account Queries");

    // Query LTA (may not exist yet)
    try {
      final ltaQuery = await accumulate.v3.query({'url': state.lta});
      print("LTA query result: $ltaQuery");
      state.results['lta_query'] = ltaQuery;
      print("[DONE] LTA exists and was queried successfully");
    } catch (e) {
      print("[WARN] LTA query failed (expected if not funded): $e");
      state.results['lta_query_error'] = e.toString();
    }

    // Query LID (may not exist yet)
    try {
      final lidQuery = await accumulate.v3.query({'url': state.lid});
      print("LID query result: $lidQuery");
      state.results['lid_query'] = lidQuery;
      print("[DONE] LID exists and was queried successfully");
    } catch (e) {
      print("[WARN] LID query failed (expected if no credits): $e");
      state.results['lid_query_error'] = e.toString();
    }
    print("");

    // Step 5: Test API Methods
    print("🧪 Step 5: Test Additional API Methods");

    // Test V2 version
    try {
      final v2Version = await accumulate.v2.version();
      print("V2 version: $v2Version");
      state.results['v2_version'] = v2Version;
      print("[DONE] V2 version retrieved");
    } catch (e) {
      print("[WARN] V2 version failed: $e");
      state.results['v2_version_error'] = e.toString();
    }

    // Test V2 status
    try {
      final v2Status = await accumulate.v2.status();
      print("V2 status: $v2Status");
      state.results['v2_status'] = v2Status;
      print("[DONE] V2 status retrieved");
    } catch (e) {
      print("[WARN] V2 status failed: $e");
      state.results['v2_status_error'] = e.toString();
    }
    print("");

    // Final Summary
    print("📋 === SIMPLE FLOW SUMMARY ===");
    print("🔑 Generated Accounts:");
    print("  • Lite Identity: ${state.lid}");
    print("  • Lite Token Account: ${state.lta}");
    print("  • Planned ADI: ${state.adiUrl}");
    print("");

    print("📝 Transaction Hashes (${state.txHashes.length} total):");
    for (int i = 0; i < state.txHashes.length; i++) {
      print("  ${i + 1}. ${state.txHashes[i]}");
    }
    print("");

    print("📊 API Results:");
    state.results.forEach((key, value) {
      if (key.endsWith('_error')) {
        print("  [FAIL] $key: $value");
      } else {
        print("  [DONE] $key: Success");
      }
    });
    print("");

    print("🎯 Discovered Configuration:");
    print("  • DevNet Dir: ${config.devnetDir}");
    print("  • V2 Endpoint: ${config.v2}");
    print("  • V3 Endpoint: ${config.v3}");
    print("  • Faucet Account: ${config.faucetAccount}");
    print("");

    print("[DONE] Simple Zero-to-Hero flow completed!");
    print("🚀 DevNet discovery and basic API connectivity verified!");

  } catch (e, stackTrace) {
    print("");
    print("[FAIL] === SIMPLE FLOW FAILED ===");
    print("Error: $e");
    print("Stack trace: $stackTrace");
    print("");
    print("Partial state:");
    print("  • Transaction hashes: ${state.txHashes}");
    print("  • Results: ${state.results}");

    rethrow; // Re-throw for test integration
  } finally {
    accumulate.close();
  }
}