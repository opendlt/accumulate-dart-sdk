import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Query pending transactions on the data account
  final dataAccountUrl = "acc://multi-sig-1767087064768.acme/test-data";

  print("Checking for pending/failed transactions...\n");

  try {
    // Check if ETH transaction ended up in pending
    final pendingResult = await client.v3.rawCall("query", {
      "scope": dataAccountUrl,
      "query": {"queryType": "pending"}
    });

    print("Pending transactions:");
    print(JsonEncoder.withIndent('  ').convert(pendingResult));

  } catch (e) {
    print("Pending query error: $e");
  }

  // Try to query the ETH transaction hash directly as a message
  try {
    print("\n\nTrying to query ETH tx as message:");
    final ethTxHash = "a4f74505b4a2e8c0da68d275bdeb98b64a1fd0320f1e5e78a96c0d37b5cfdac8";

    // Try querying the signature chain
    final sigResult = await client.v3.rawCall("query", {
      "scope": "acc://multi-sig-1767087064768.acme/book/1",
      "query": {
        "queryType": "chain",
        "name": "signature",
        "range": {
          "start": 0,
          "count": 20
        }
      }
    });

    print("Key page signature chain:");
    final records = sigResult["records"] as List?;
    if (records != null) {
      print("Total: ${sigResult["total"] ?? records.length}");
      for (var i = 0; i < records.length && i < 10; i++) {
        final entry = records[i]["entry"] ?? "?";
        print("  $i: $entry");
      }
    }

  } catch (e) {
    print("Signature chain error: $e");
  }

  client.close();
}
