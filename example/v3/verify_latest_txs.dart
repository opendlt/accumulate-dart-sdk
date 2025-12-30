import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Transaction IDs from the latest test run
  final txIds = {
    "Ed25519": "acc://5c3e665905dd191f8058472c18601b0608f83f0a5e71e1d218e6eda4a16e7506@multi-sig-1767086642308.acme/test-data",
    "RCD1": "acc://ab859b5b912900c98165ea53c0c0bf5e8bbaed57ada6e4aeb481ef95684b531c@multi-sig-1767086642308.acme/test-data",
    "BTC": "acc://2f935a4ac99db3f452896d3baf11d78b639dd69ed5eb2e04884c6d65e4155e0e@multi-sig-1767086642308.acme/test-data",
    "ETH": "acc://3b6783814a7e38cf681c31771ed4b27f8f378561b9b211515ebb4770db79dfd9@multi-sig-1767086642308.acme/test-data",
    "RSA": "acc://8d63e2f81d514b3d6139ee9e057fbb31a30e83180021cb90006133f37790c4c3@multi-sig-1767086642308.acme/test-data",
    "ECDSA": "acc://b85fa6c4757f62ef004829a28097371d78bd943f10f0d7f2ecc45f06fc275a62@multi-sig-1767086642308.acme/test-data",
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
      final delivered = result["message"]?["transaction"]?["status"]?["delivered"];
      final statusNo = result["statusNo"];

      print("$name Transaction:");
      print("  TxID: ${txId.split("@")[0].split("//")[1].substring(0, 16)}...");
      print("  Status: $status (code: $statusNo)");

      if (status == "delivered" || statusNo == 201 || delivered == true) {
        print("  RESULT: [OK] DELIVERED");
        passed++;
      } else {
        print("  RESULT: [ERROR] NOT DELIVERED (status: $status)");
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
    print("The SignatureTypeEnum fix resolved all signature failures.");
  }

  client.close();
}
