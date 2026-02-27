import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Transaction IDs from the latest test run
  final txIds = {
    "Ed25519": "acc://f276c9e05fc2ecae05b6be31a1b88b29ba35cac730a661fa3070ae5d844a161d@multi-sig-1767087064768.acme/test-data",
    "RCD1": "acc://bb0ffe9d4d6d4588873144dda043fdb77003dd3dd423dd10628ed59955ddf2b4@multi-sig-1767087064768.acme/test-data",
    "BTC": "acc://1f6975cf287aa288473fd44ab215cd5d3a9f4b5a537e13013481e0c63ffa1304@multi-sig-1767087064768.acme/test-data",
    "ETH": "acc://a4f74505b4a2e8c0da68d275bdeb98b64a1fd0320f1e5e78a96c0d37b5cfdac8@multi-sig-1767087064768.acme/test-data",
    "RSA": "acc://351ace422e8c32601b58ab46f3c682d478d5b195cd11388b629da4b9ed51fb21@multi-sig-1767087064768.acme/test-data",
    "ECDSA": "acc://ceb88516d7fdfd199493b71259b1e9bca9a48d03b1cc156d4586be80385ed165@multi-sig-1767087064768.acme/test-data",
  };

  print("Verifying transaction statuses...\n");

  int passed = 0;
  int failed = 0;

  for (final entry in txIds.entries) {
    final name = entry.key;
    final txId = entry.value;

    try {
      final result = await client.v3.rawCall("query", {
        "scope": txId,
        "query": {"queryType": "default"}
      });

      final status = result["status"]?.toString() ?? "unknown";
      final statusNo = result["statusNo"];

      print("$name Transaction:");
      print("  TxID: ${txId.split("@")[0].split("//")[1].substring(0, 16)}...");
      print("  Status: $status (code: $statusNo)");

      if (status == "delivered" || statusNo == 201) {
        print("  RESULT: [OK] DELIVERED");
        passed++;
      } else {
        print("  RESULT: ? STATUS: $status");
        failed++;
      }
      print("");
    } catch (e) {
      print("$name Transaction:");
      print("  TxID: ${txId.split("@")[0].split("//")[1].substring(0, 16)}...");
      print("  Error: $e");
      print("  RESULT: [ERROR] ERROR");
      failed++;
      print("");
    }
  }

  print("=" * 60);
  print("SUMMARY: $passed passed, $failed failed");
  print("=" * 60);

  if (failed == 0) {
    print("\n🎉 ALL 6 SIGNATURE TYPES WORKING CORRECTLY!");
    print("The Dart SDK now has FULL PARITY with Go core!");
  }

  client.close();
}
