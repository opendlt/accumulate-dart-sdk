import "dart:convert";
import "dart:io";
import "config.dart";

Future<void> main() async {
  print("=== Accumulate Testnet Faucet ===");

  final cfg = await FlowConfig.fromDevNetDiscovery();
  if (!cfg.v2.contains("testnet")) {
    stderr.writeln("ERROR: Faucet only works on testnet");
    stderr.writeln("Set ACC_NET=testnet (or leave unset for default)");
    exit(3);
  }

  final lta = Platform.environment["ACC_LTA_URL"];
  if (lta == null) {
    stderr.writeln("ERROR: Set ACC_LTA_URL environment variable");
    stderr.writeln(
        "Example: ACC_LTA_URL=acc://1234567890abcdef1234567890abcdef12345678checksum/ACME");
    stderr.writeln("Use example 100_keygen_lite_urls.dart to generate LTA");
    exit(2);
  }

  print("Using testnet: ${cfg.v2}");
  print("Requesting tokens for: $lta");

  final acc = cfg.make();
  try {
    final response = await acc.v2.faucet({"url": lta});
    print("\n=== Faucet Response ===");
    print(const JsonEncoder.withIndent("  ").convert(response));
    print("\nTokens should arrive in a few blocks.");
    print("Check balance with: dart run example/flows/query_account.dart");
  } catch (e) {
    stderr.writeln("Faucet request failed: $e");
    exit(1);
  } finally {
    acc.close();
  }
}
