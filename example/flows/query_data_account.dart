import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Query the data account from the latest run
  final dataAccountUrl = "acc://multi-sig-1767062706002.acme/test-data";

  print("Querying data account: $dataAccountUrl\n");

  try {
    // Query the account
    final result = await client.v3.rawCall("query", {
      "scope": dataAccountUrl,
      "query": {"queryType": "default"}
    });

    print("Data Account Query Result:");
    print(JsonEncoder.withIndent('  ').convert(result));
  } catch (e) {
    print("Query Error: $e");
  }

  // Try querying the Ed25519 transaction directly
  final ed25519TxId = "acc://b9aaa712c66c0a6d7a4b4256990d004f8adea038903701726ed1325348069ed6@multi-sig-1767062706002.acme/test-data";
  try {
    print("\n\nQuerying Ed25519 transaction:");
    final result = await client.v3.rawCall("query", {
      "scope": ed25519TxId,
      "query": {"queryType": "default"}
    });

    print("Ed25519 Transaction Result:");
    print(JsonEncoder.withIndent('  ').convert(result));
  } catch (e) {
    print("Ed25519 Query Error: $e");
  }

  // Query the RCD1 transaction
  final rcd1TxId = "acc://6ad6fbf1d9fed875c662f6a4675de072b9a54840dc30a31864fb4fd01283b7e7@multi-sig-1767062706002.acme/test-data";
  try {
    print("\n\nQuerying RCD1 transaction:");
    final result = await client.v3.rawCall("query", {
      "scope": rcd1TxId,
      "query": {"queryType": "default"}
    });

    print("RCD1 Transaction Result:");
    print(JsonEncoder.withIndent('  ').convert(result));
  } catch (e) {
    print("RCD1 Query Error: $e");
  }

  client.close();
}
