// Verify all signature types delivered by querying transaction status
import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Transaction hashes from the test run
  final txHashes = {
    "Ed25519": "8611876c1019c59c502f8512f7f313af5d25f5fbcdee6d331424ff6d425a6a7a",
    "RCD1": "8b9298c3c344ffd95d160a1128ce7c07d8111afea4dc2a96feecf30923019606",
    "BTC": "ba17ab0a965b24b1e7f40cf307043d0ee9388946b8604e6a06c08dd34a95835a",
    "ETH": "a6a539b54365f4497269fb27b93783c5882c37870baffde9a67a7b3e8f2f78af",
    "RSA": "2aafa71cb3544ee330b32915bbd4af49bf6546b3c434ace18f262ae3a4f4e05d",
    "ECDSA": "da0d3d75492881445b3ed7b1d13737381076c9b8e2aa0f9eb9f8bf73b634d513",
  };

  print("=== Verifying Transaction Deliveries ===\n");

  for (var entry in txHashes.entries) {
    final name = entry.key;
    final hash = entry.value;

    try {
      final result = await client.v3.rawCall("query", {
        "scope": "acc://$hash@multi-sig-1767091828636.acme/test-data",
        "query": {"queryType": "default"}
      });

      print("--- $name ---");
      print(JsonEncoder.withIndent('  ').convert(result));
      print("");

    } catch (e) {
      print("[FAIL] $name: Error querying - $e\n");
    }
  }

  client.close();
}
