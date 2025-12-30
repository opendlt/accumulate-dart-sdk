import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  final dataAccountUrl = "acc://multi-sig-1767087064768.acme/test-data";

  print("Checking data account: $dataAccountUrl\n");

  try {
    // Query data chain with range
    final result = await client.v3.rawCall("query", {
      "scope": dataAccountUrl,
      "query": {
        "queryType": "chain",
        "name": "main",
        "range": {
          "start": 0,
          "count": 20
        }
      }
    });

    final total = result["total"] ?? 0;
    print("Total main chain entries: $total\n");

    final records = result["records"] as List?;
    if (records != null) {
      for (var i = 0; i < records.length; i++) {
        final record = records[i];
        final entry = record["entry"] ?? record["value"]?["entry"];
        print("Entry $i: $entry");
      }
    }

    // Also check the key page to see all keys
    print("\n\nKey Page Keys:");
    final keyPageUrl = "acc://multi-sig-1767087064768.acme/book/1";
    final keyPageResult = await client.v3.rawCall("query", {
      "scope": keyPageUrl,
      "query": {"queryType": "default"}
    });

    final account = keyPageResult["account"];
    final keys = account?["keys"] as List?;
    if (keys != null) {
      for (var i = 0; i < keys.length; i++) {
        final key = keys[i];
        final hash = key["publicKeyHash"] ?? "?";
        print("Key $i: $hash");
      }
    }

  } catch (e) {
    print("Error: $e");
  }

  client.close();
}
