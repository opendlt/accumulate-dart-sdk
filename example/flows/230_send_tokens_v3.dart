import "dart:convert";
import "dart:io";
import "config.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/util/time.dart";

Future<void> main() async {
  print("=== Send Tokens v3 Transaction ===");

  final cfg = await FlowConfig.fromDevNetDiscovery();
  final acc = cfg.make();

  // Generate key pair (in real use, load from secure storage)
  final kp = await Ed25519KeyPair.generate();

  // Get transaction parameters from environment
  final from =
      Platform.environment["ACC_FROM_URL"] ?? "acc://sender.acme/tokens";
  final to = Platform.environment["ACC_TO_URL"] ?? "acc://receiver.acme/tokens";
  final amount = Platform.environment["ACC_AMOUNT"] ?? "1000";

  print("From: $from");
  print("To: $to");
  print("Amount: $amount");

  // Build transaction context
  final ctx = BuildContext(
    principal: from,
    timestamp: nowTimestampMillis(),
    memo: "Token transfer via Dart SDK",
  );

  // Build send tokens transaction body
  final body = TxBody.sendTokensSingle(
    toUrl: to,
    amount: amount,
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
    print("\nTransaction submitted successfully!");
    print("Monitor status with transaction hash from response.");
  } catch (e) {
    stderr.writeln("Transaction submission failed: $e");
    stderr.writeln("\nCommon issues:");
    stderr.writeln("- Insufficient balance in sender account");
    stderr.writeln("- Insufficient credits for transaction fees");
    stderr.writeln("- Invalid account URLs");
    stderr.writeln("- Network connectivity issues");
    exit(1);
  } finally {
    acc.close();
  }
}
