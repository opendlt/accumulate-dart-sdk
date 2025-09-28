import "dart:convert";
import "dart:io";
import "config.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/util/time.dart";

Future<void> main() async {
  print("=== Create Identity (ADI) v3 Transaction ===");

  final cfg = await FlowConfig.fromDevNetDiscovery();
  final acc = cfg.make();

  // Generate key pair for signing
  final kp = await Ed25519KeyPair.generate();
  final publicKey = await kp.publicKeyBytes();
  final publicKeyHex =
      publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  // ADI URL to create
  final adi = Platform.environment["ACC_ADI_URL"] ??
      "acc://example-adi-${DateTime.now().millisecondsSinceEpoch}";
  print("Creating ADI: $adi");
  print("Using key: $publicKeyHex");

  // Build transaction
  final ctx = BuildContext(
    principal: adi,
    timestamp: nowTimestampMillis(),
    memo: "Create identity via Dart SDK",
  );

  final body = TxBody.createIdentity(
    url: adi,
    keyBookName: "book",
    publicKeyHash: publicKeyHex,
  );

  // Sign transaction
  final envelope = await TxSigner.buildAndSign(
    ctx: ctx,
    body: body,
    keypair: kp,
  );

  print("\n=== Transaction Envelope ===");
  print(const JsonEncoder.withIndent("  ").convert(envelope.toJson()));

  try {
    final response = await acc.submit(envelope.toJson());
    print("\n=== Submission Response ===");
    print(const JsonEncoder.withIndent("  ").convert(response));
  } catch (e) {
    stderr.writeln("Transaction submission failed: $e");
    stderr.writeln(
        "Note: This may fail if ADI already exists or insufficient credits");
    exit(1);
  } finally {
    acc.close();
  }
}
