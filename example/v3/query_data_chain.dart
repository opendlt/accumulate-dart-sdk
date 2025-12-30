import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  final dataAccountUrl = "acc://multi-sig-1767085766701.acme/test-data";

  print("Querying data chain range for: $dataAccountUrl\n");

  try {
    // Query data entries with range
    final dataResult = await client.v3.rawCall("query", {
      "scope": dataAccountUrl,
      "query": {
        "queryType": "chain",
        "name": "data",
        "range": {
          "start": 0,
          "count": 10
        }
      }
    });

    print("Data chain entries:");
    print(JsonEncoder.withIndent('  ').convert(dataResult));

    // Check total
    final total = dataResult["total"] ?? dataResult["records"]?.length ?? 0;
    print("\nTotal data entries: $total");

  } catch (e) {
    print("Error: $e");
  }

  client.close();
}
