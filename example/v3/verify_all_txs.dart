import 'dart:convert';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  final txIds = {
    "Ed25519": "acc://4ccde49dc190b93fbe299c35be5d811cd98b7ec91f239f297ec8a2ce6ec188f8@multi-sig-1767064284044.acme/test-data",
    "RCD1": "acc://5267070490eb01f783164462e3f7b9681c000f968652d41f63af4ac95cf1094a@multi-sig-1767064284044.acme/test-data",
    "BTC": "acc://21b7086cdc14c47390950f4eb76066f95cf98b37845a593840e0fd0c85c11af7@multi-sig-1767064284044.acme/test-data",
    "ETH": "acc://00d3db76e5b2840391f43bc938cdf60d8350d03dfca3305b30b89f8c89d7f1b3@multi-sig-1767064284044.acme/test-data",
    "RSA": "acc://55fca36b70ae298bf1f773d48e1172a2334f0eb9be5e327995e91b2fdb408d35@multi-sig-1767064284044.acme/test-data",
    "ECDSA": "acc://19547250a12eaa40bd7785f21f72d4d0d2e9e32af40e2ab53e7525c623c00ee8@multi-sig-1767064284044.acme/test-data",
  };

  print("Verifying transaction statuses...\n");

  for (final entry in txIds.entries) {
    final name = entry.key;
    final txId = entry.value;

    try {
      final result = await client.v3.rawCall("query", {
        "scope": txId,
        "query": {"queryType": "default"}
      });

      final status = result["status"];
      print("$name Transaction:");
      print("  TxID: ${txId.split("@")[0].split("//")[1]}...");
      print("  STATUS: $status");
      print("");
    } catch (e) {
      print("$name Transaction:");
      print("  Query Error: $e");
      print("");
    }
  }

  client.close();
}
