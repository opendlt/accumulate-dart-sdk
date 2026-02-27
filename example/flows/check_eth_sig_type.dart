// Check the actual signature type used in ETH transaction
import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // ETH transaction hash from the test
  final ethTxHash = "a6a539b54365f4497269fb27b93783c5882c37870baffde9a67a7b3e8f2f78af";

  print("=== Checking ETH Transaction Signature Type ===\n");

  try {
    final result = await client.v3.rawCall("query", {
      "scope": "acc://$ethTxHash@multi-sig-1767091828636.acme/test-data",
      "query": {"queryType": "default"}
    });

    // Find the signature in the response
    final signatures = result["signatures"]?["records"] as List?;
    if (signatures != null) {
      for (var sigSet in signatures) {
        final account = sigSet["account"];
        if (account?["type"] == "keyPage") {
          print("Key Page Signatures:");
          final sigs = sigSet["signatures"]?["records"] as List?;
          if (sigs != null) {
            for (var sig in sigs) {
              final message = sig["message"];
              if (message?["type"] == "signature") {
                final signature = message["signature"];
                print("  Signature Type: ${signature?["type"]}");
                print("  Public Key: ${signature?["publicKey"]}");
                print("  Signature: ${signature?["signature"]?.toString().substring(0, 40)}...");
                print("");
              }
            }
          }
        }
      }
    }
  } catch (e) {
    print("Error: $e");
  }

  client.close();
}
