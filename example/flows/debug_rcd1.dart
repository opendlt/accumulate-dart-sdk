import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';

Future<void> main() async {
  final client = Accumulate.custom(
    v2Endpoint: "http://127.0.0.1:26660/v2",
    v3Endpoint: "http://127.0.0.1:26660/v3",
  );

  // Use a data account that already exists
  final dataAccountUrl = "acc://multi-sig-1767062706002.acme/test-data";
  final keyPageUrl = "acc://multi-sig-1767062706002.acme/book/1";
  final keyPageVersion = 7;

  // Generate fresh keys
  final ed25519Key = await Ed25519KeyPair.generate();
  final rcd1Key = await RCD1KeyPair.generate();

  print("=== Ed25519 Key ===");
  final ed25519PubKey = await ed25519Key.publicKeyBytes();
  final ed25519KeyHash = Uint8List.fromList(sha256.convert(ed25519PubKey).bytes);
  print("Public Key: ${toHex(ed25519PubKey)}");
  print("Key Hash (SHA256): ${toHex(ed25519KeyHash)}");

  print("\n=== RCD1 Key ===");
  final rcd1PubKey = await rcd1Key.publicKeyBytes();
  final rcd1KeyHash = await rcd1Key.publicKeyHash();
  print("Public Key: ${toHex(rcd1PubKey)}");
  print("Key Hash (RCD1): ${toHex(rcd1KeyHash)}");

  // Compute what the key hashes would be if we swapped algorithms
  final ed25519AsRcd1Hash = getRCDHashFromPublicKey(ed25519PubKey, 1);
  final rcd1AsSha256Hash = Uint8List.fromList(sha256.convert(rcd1PubKey).bytes);
  print("\n=== Cross-check ===");
  print("Ed25519 with RCD1 hash: ${toHex(ed25519AsRcd1Hash)}");
  print("RCD1 with SHA256 hash: ${toHex(rcd1AsSha256Hash)}");

  // Build envelopes without submitting
  final hexData = toHex(Uint8List.fromList("Test data".codeUnits));
  final body = TxBody.writeData(entriesHex: [hexData]);

  final timestamp = DateTime.now().millisecondsSinceEpoch * 1000;

  print("\n=== Ed25519 Envelope ===");
  final ed25519Ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: timestamp,
    memo: "Debug Ed25519",
  );
  final ed25519Envelope = await TxSigner.buildAndSign(
    ctx: ed25519Ctx,
    body: body,
    keypair: ed25519Key,
    signerUrl: keyPageUrl,
    signerVersion: keyPageVersion,
  );
  print(JsonEncoder.withIndent('  ').convert(ed25519Envelope.toJson()));

  print("\n=== RCD1 Envelope ===");
  final rcd1Ctx = BuildContext(
    principal: dataAccountUrl,
    timestamp: timestamp,
    memo: "Debug RCD1",
  );
  final rcd1Envelope = await TxSigner.buildAndSignRCD1(
    ctx: rcd1Ctx,
    body: body,
    keypair: rcd1Key,
    signerUrl: keyPageUrl,
    signerVersion: keyPageVersion,
  );
  print(JsonEncoder.withIndent('  ').convert(rcd1Envelope.toJson()));

  // Also print what the RCD1 key hash would be from the public key in the signature
  final rcd1SigPubKey = rcd1Envelope.signatures.first.publicKey;
  print("\n=== RCD1 Signature Analysis ===");
  print("Public Key in signature: $rcd1SigPubKey");
  final rcd1SigPubKeyBytes = hexTo(rcd1SigPubKey);
  final computedRcd1Hash = getRCDHashFromPublicKey(rcd1SigPubKeyBytes, 1);
  print("Computed RCD1 hash from sig pubkey: ${toHex(computedRcd1Hash)}");
  print("Expected RCD1 hash on key page: ${toHex(rcd1KeyHash)}");
  print("Match: ${toHex(computedRcd1Hash) == toHex(rcd1KeyHash)}");

  client.close();
}

Uint8List hexTo(String hex) {
  final cleaned = hex.startsWith('0x') ? hex.substring(2) : hex;
  final bytes = Uint8List(cleaned.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}
