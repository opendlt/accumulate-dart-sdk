/// Fund a lite token account using the discovered DevNet faucet

import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "config.dart";

Future<void> main() async {
  print("=== Faucet Funding (Local DevNet) ===");

  final config = await FlowConfig.fromDevNetDiscovery();
  final accumulate = config.make();

  try {
    // Generate or reuse a key pair for demo
    print("Generating demo key pair...");
    final kp = await Ed25519KeyPair.generate();
    final lta = await kp.deriveLiteTokenAccountUrl();
    print("Target LTA: $lta");

    // Check initial balance
    print("Checking initial balance...");
    try {
      final balanceQuery = await accumulate.v3.query({
        'url': lta.toString(),
      });
      print("Initial balance query result: $balanceQuery");
    } catch (e) {
      print("LTA doesn't exist yet (expected): $e");
    }

    // Request tokens from faucet
    print("Requesting tokens from faucet: ${config.faucetAccount}");

    // For DevNet, we typically use V2 faucet endpoint
    try {
      final faucetResult = await accumulate.v2.faucet({
        'account': lta.toString(),
        'amount': 100000000, // 1 ACME in credits (10^8)
      });
      print("Faucet request result: $faucetResult");

      // Wait a moment for transaction to process
      print("Waiting for transaction to process...");
      await Future.delayed(Duration(seconds: 3));

      // Check balance after funding
      print("Checking balance after funding...");
      final newBalanceQuery = await accumulate.v3.query({
        'url': lta.toString(),
      });
      print("New balance query result: $newBalanceQuery");

      print("✓ Faucet funding completed successfully!");
      print("✓ LTA: $lta");

    } catch (e) {
      print("✗ Faucet request failed: $e");
      print("This might happen if:");
      print("  - DevNet faucet has limits or is rate-limited");
      print("  - The faucet account format is incorrect");
      print("  - DevNet is not properly configured");
    }

  } finally {
    accumulate.close();
  }
}