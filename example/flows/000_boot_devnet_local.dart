/// DevNet bootstrapping helper
/// Ensures local DevNet is running and ready for examples

import "dart:io";
import "config.dart";

Future<void> main() async {
  print("=== DevNet Bootstrap Helper ===");

  final config = await FlowConfig.fromDevNetDiscovery();

  // Check if DevNet is accessible
  print("Checking DevNet health...");
  final isHealthy = await config.checkDevNetHealth();

  if (isHealthy) {
    print("✓ DevNet is running and accessible");
    print("✓ Endpoints: V2=${config.v2}, V3=${config.v3}");
    print("✓ Faucet: ${config.faucetAccount}");
  } else {
    print("✗ DevNet is not accessible");
    print("");
    print("To start DevNet:");
    print("1. cd ${config.devnetDir}");
    print("2. docker-compose up -d");
    print("3. Wait ~30 seconds for startup");
    print("4. Run this script again to verify");

    exit(1);
  }

  print("");
  print("DevNet is ready for examples! ✅");
}