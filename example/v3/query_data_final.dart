import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  final dataAccountUrl = "acc://multi-sig-1767085766701.acme/test-data";

  print("Querying data account: $dataAccountUrl\n");

  try {
    // Query the data account
    final result = await client.v3.rawCall("query", {
      "scope": dataAccountUrl,
      "query": {"queryType": "default"}
    });

    print("Account query result:");
    print(JsonEncoder.withIndent('  ').convert(result));

    // Query data entries
    print("\n\nQuerying data entries:");
    final dataResult = await client.v3.rawCall("query", {
      "scope": dataAccountUrl,
      "query": {"queryType": "data"}
    });
    print(JsonEncoder.withIndent('  ').convert(dataResult));

  } catch (e) {
    print("Error: $e");
  }

  client.close();
}
