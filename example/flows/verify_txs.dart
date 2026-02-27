import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // These are the txids from the latest run (12/29/2025)
  final txIds = {
    "Ed25519": "acc://b9aaa712c66c0a6d7a4b4256990d004f8adea038903701726ed1325348069ed6@multi-sig-1767062706002.acme/test-data",
    "RCD1": "acc://6ad6fbf1d9fed875c662f6a4675de072b9a54840dc30a31864fb4fd01283b7e7@multi-sig-1767062706002.acme/test-data",
    "BTC": "acc://9643f6887e0b1c51125cfed7a97322af6ab822021e63e886ccbfda52fb6f2fea@multi-sig-1767062706002.acme/test-data",
    "ETH": "acc://601eb04b2afd6489f144e67a4e0434ec7455ea20009393e4e7c670f65278bedc@multi-sig-1767062706002.acme/test-data",
    "RSA": "acc://f4dea812dc42faf4ed60f3204f8f859818776db44189219dcc8cd452cb559758@multi-sig-1767062706002.acme/test-data",
    "ECDSA": "acc://c924e7f13517fe0adaf8b1bb8ec42807456e4a33e22a690cc0578def4c9e8186@multi-sig-1767062706002.acme/test-data",
  };

  print("Verifying transaction statuses...\n");

  for (final entry in txIds.entries) {
    final name = entry.key;
    final txId = entry.value;

    try {
      // Use rawCall to avoid parsing issues
      final result = await client.v3.rawCall("query", {
        "scope": txId,
        "query": {"queryType": "default"}
      });

      print("$name Transaction:");
      print("  TxID: $txId");

      // Print key parts of the status
      final status = result["status"];
      if (status != null) {
        print("  STATUS: $status");
      } else {
        print("  DELIVERED: ${result['status'] ?? 'unknown'}");
      }
      print("");
    } catch (e) {
      print("$name Transaction:");
      print("  TxID: $txId");
      print("  Query Error: $e");
      print("");
    }
  }

  client.close();
}
