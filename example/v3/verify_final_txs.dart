import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Transaction IDs from the latest test run
  final txIds = {
    "Ed25519": "acc://573009875e4da2b14e2609b83a675a77e0093d527e43c919d540cc4f3e40bc50@multi-sig-1767085766701.acme/test-data",
    "RCD1": "acc://96abf1f5cdc40fda4332cfe8a140e1d3b41f2b3adccca58f2a7158ba6d6a11a3@multi-sig-1767085766701.acme/test-data",
    "BTC": "acc://a08390d31597bc93ddefb9f31174b8399c24e7144661342b68b6489826396e61@multi-sig-1767085766701.acme/test-data",
    "ETH": "acc://b62f6649b00388a3761ca442ed15d72bc44e8ae2c11071ed3f2a9859df830470@multi-sig-1767085766701.acme/test-data",
    "RSA": "acc://1735eace22313651100170fe00d1785c02d15bb4aec9a75fcb2d136ba9d5f8f2@multi-sig-1767085766701.acme/test-data",
    "ECDSA": "acc://37c91d5d777ad980fe9b83e921e6708f66e5ae1f7a4641b6e85070e3b5e8fd19@multi-sig-1767085766701.acme/test-data",
  };

  print("Verifying transaction statuses after SignatureTypeEnum fix...\n");

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

      final status = result["status"];
      final statusCode = status?["code"] ?? "unknown";
      final delivered = result["message"]?["transaction"]?["status"]?["delivered"] ?? false;

      print("$name Transaction:");
      print("  TxID: ${txId.split("@")[0].split("//")[1].substring(0, 16)}...");
      print("  Status Code: $statusCode");
      print("  Delivered: $delivered");

      if (delivered == true) {
        print("  RESULT: [OK] SUCCESS");
        passed++;
      } else {
        print("  RESULT: [ERROR] NOT DELIVERED");
        failed++;
      }
      print("");
    } catch (e) {
      print("$name Transaction:");
      print("  Query Error: $e");
      print("  RESULT: [ERROR] ERROR");
      failed++;
      print("");
    }
  }

  print("=" * 60);
  print("SUMMARY: $passed passed, $failed failed");
  print("=" * 60);

  if (failed == 0) {
    print("\n🎉 ALL SIGNATURE TYPES WORKING! The SignatureTypeEnum fix was the ROOT CAUSE.");
  }

  client.close();
}
