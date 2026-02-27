// Live RSA test against DevNet - captures full response
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  print("=== Live RSA Test Against DevNet ===\n");

  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  try {
    // Use existing ADI from previous tests
    final keyPageUrl = "acc://multi-sig-1767091828636.acme/book/1";
    final dataAccountUrl = "acc://multi-sig-1767091828636.acme/test-data";

    // Query key page to see RSA key
    print("Querying key page: $keyPageUrl");
    final kpResult = await client.v3.rawCall("query", {
      "scope": keyPageUrl,
      "query": {"queryType": "default"}
    });

    final account = kpResult["account"];
    final version = account?["version"] ?? 1;
    final keys = account?["keys"] as List?;

    print("Key Page Version: $version");
    print("Keys on page:");
    if (keys != null) {
      for (var i = 0; i < keys.length; i++) {
        final hash = keys[i]['publicKeyHash'] ?? "?";
        final lastUsed = keys[i]['lastUsedOn'];
        print("  $i: $hash ${lastUsed != null ? '(used)' : ''}");
      }
    }

    // Generate a fresh RSA key
    print("\nGenerating RSA 2048-bit key...");
    final rsaKey = RsaKeyPair.generate(bitLength: 2048);
    final rsaKeyHash = rsaKey.publicKeyHash;
    print("New RSA Key Hash: ${toHex(rsaKeyHash)}");
    print("(This key is NOT on the key page - should fail with 'key not found')");

    // Build WriteData transaction
    final hexData = toHex(Uint8List.fromList("RSA live test".codeUnits));
    final body = TxBody.writeData(entriesHex: [hexData]);

    final ctx = BuildContext(
      principal: dataAccountUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch * 1000,
      memo: "RSA Live Test",
    );

    final envelope = await TxSigner.buildAndSignRSA(
      ctx: ctx,
      body: body,
      keypair: rsaKey,
      signerUrl: keyPageUrl,
      signerVersion: version,
    );

    // Print envelope summary
    final json = envelope.toJson();
    final envelopeData = json['envelope'];
    final sig = envelopeData['signatures'][0];
    final tx = envelopeData['transaction'][0];

    print("\n--- Envelope Summary ---");
    print("Signature type: ${sig['type']}");
    print("Signer: ${sig['signer']}");
    print("Signer version: ${sig['signerVersion']}");
    print("Transaction hash: ${sig['transactionHash']}");
    print("Initiator: ${tx['header']['initiator']}");

    // Submit and capture FULL response
    print("\n--- Submitting to DevNet ---");
    try {
      // V3 API expects {"envelope": {...}}
      final response = await client.v3.rawCall("submit", json);
      print("\n*** SUCCESS ***");
      print(JsonEncoder.withIndent('  ').convert(response));
    } catch (e) {
      print("\n*** ERROR ***");
      print("Error: $e");
    }

  } catch (e, stack) {
    print("Error: $e");
    print(stack);
  } finally {
    client.close();
  }
}
