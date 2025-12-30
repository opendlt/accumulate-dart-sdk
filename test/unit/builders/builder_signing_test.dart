import "dart:typed_data";
import "dart:convert";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/codec/transaction_codec.dart";

void main() {
  group("Transaction builder signing tests", () {
    test("transaction hash generation is stable", () async {
      final ctx =
          BuildContext(principal: "acc://exampleAdi.acme", timestamp: 1234567890);
      final body = TxBody.createIdentity(
          url: "acc://exampleADI.acme",
          keyBookName: "book",
          publicKeyHash: "00".padLeft(64, "0"));

      final bytes = TransactionCodec.encodeTxForSigning(ctx.headerJson(), body);
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.length, equals(32)); // SHA256 hash

      // Hash should be deterministic
      final bytes2 =
          TransactionCodec.encodeTxForSigning(ctx.headerJson(), body);
      expect(bytes, equals(bytes2));
    });

    test("ed25519 sign/verify workflow", () async {
      final kp = await Ed25519KeyPair.generate();
      final msg = Uint8List.fromList(List.generate(32, (i) => i));

      final sig = await kp.sign(msg);
      expect(sig.length, equals(64)); // Ed25519 signature length

      final ok = await kp.verify(msg, sig);
      expect(ok, isTrue);

      // Wrong message should fail
      final wrongMsg = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final notOk = await kp.verify(wrongMsg, sig);
      expect(notOk, isFalse);
    });

    test("LID/LTA derivation from public key", () async {
      // Test with known seed for deterministic results
      final seed = Uint8List.fromList(List.generate(32, (i) => i));
      final kp = await Ed25519KeyPair.fromSeed(seed);

      final lid = await kp.deriveLiteIdentityUrl();
      final lta = await kp.deriveLiteTokenAccountUrl();

      // LID should be acc://hex format
      expect(lid.toString(), startsWith("acc://"));
      expect(lid.toString().length,
          equals(54)); // acc:// + 40 hex chars + 8 checksum

      // LTA should be LID + /ACME
      expect(lta.toString(), equals("${lid.toString()}/ACME"));
    });

    test("build and sign complete transaction", () async {
      final kp = await Ed25519KeyPair.generate();
      final ctx = BuildContext(
          principal: "acc://example-adi",
          timestamp: DateTime.now().millisecondsSinceEpoch,
          memo: "test transaction");

      final body =
          TxBody.sendTokensSingle(toUrl: "acc://bob.acme/tokens", amount: "1000");

      final envelope =
          await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: kp);

      // Should have one signature
      expect(envelope.signatures.length, equals(1));

      final sig = envelope.signatures.first;
      expect(sig.type, equals("ed25519"));
      expect(sig.publicKey.length, equals(64)); // Hex encoded 32-byte key
      expect(sig.signature.isNotEmpty, isTrue); // Base64 encoded signature
      expect(sig.timestamp, equals(ctx.timestamp));

      // Transaction should have header and body
      expect(envelope.transaction.containsKey("header"), isTrue);
      expect(envelope.transaction.containsKey("body"), isTrue);

      final header = envelope.transaction["header"];
      expect(header["principal"], equals(ctx.principal));
      expect(header["timestamp"], equals(ctx.timestamp));
      expect(header["memo"], equals(ctx.memo));

      final txBody = envelope.transaction["body"];
      expect(txBody["type"], equals("sendTokens"));
      expect(txBody["to"][0]["url"], equals("acc://bob.acme/tokens"));
      expect(txBody["to"][0]["amount"], equals("1000"));
    });

    test("envelope JSON serialization", () async {
      final kp = await Ed25519KeyPair.generate();
      final ctx = BuildContext(
          principal: "acc://test.acme/book", timestamp: 1234567890);

      final body = TxBody.createTokenAccount(
          url: "acc://test.acme/tokens", tokenUrl: "acc://acme");

      final envelope =
          await TxSigner.buildAndSign(ctx: ctx, body: body, keypair: kp);

      final json = envelope.toJson();
      expect(json.containsKey("envelope"), isTrue);

      final env = json["envelope"];
      expect(env.containsKey("signatures"), isTrue);
      expect(env.containsKey("transaction"), isTrue);
      expect(env["signatures"], isA<List>());
      expect(env["signatures"].length, equals(1));

      // Should serialize to valid JSON
      final jsonStr = jsonEncode(json);
      expect(jsonStr.isNotEmpty, isTrue);

      // Should be parseable back
      final parsed = jsonDecode(jsonStr);
      expect(parsed["envelope"]["signatures"][0]["type"], equals("ed25519"));
    });
  });
}
