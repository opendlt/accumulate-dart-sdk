import "dart:convert";
import "dart:typed_data";

import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "package:opendlt_accumulate/src/codec/transaction_codec.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/enums.dart";
import "package:opendlt_accumulate/src/generated/types/general_types.dart";
import "package:opendlt_accumulate/src/protocol/envelope.dart";
import "package:opendlt_accumulate/src/v3/client_v3.dart";
import "package:test/test.dart";

String hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, "0")).join();

void main() {
  final now = DateTime.utc(2030, 1, 1);
  HashLockOptions lock(HashAlgorithm a, int len, Duration? ahead) =>
      HashLockOptions(
          hashAlgorithm: a,
          hash: Uint8List(len),
          expiration: ahead == null ? null : now.add(ahead));

  group("HashLockOptions.validateForSubmit mirrors the node", () {
    test("accepts valid locks", () {
      lock(HashAlgorithm.SHA256, 32, const Duration(hours: 1))
          .validateForSubmit(now: now);
      lock(HashAlgorithm.SHA256D, 32, const Duration(days: 30))
          .validateForSubmit(now: now);
      lock(HashAlgorithm.HASH160, 20, const Duration(minutes: 10))
          .validateForSubmit(now: now);
    });
    test("rejects wrong length, unknown algorithm, bad expiration", () {
      void bad(HashLockOptions l) =>
          expect(() => l.validateForSubmit(now: now), throwsArgumentError);
      bad(lock(HashAlgorithm.SHA256, 20, const Duration(hours: 1)));
      bad(lock(HashAlgorithm.HASH160, 32, const Duration(hours: 1)));
      bad(lock(HashAlgorithm.Unknown, 32, const Duration(hours: 1)));
      bad(lock(HashAlgorithm.SHA256, 32, null));
      bad(lock(HashAlgorithm.SHA256, 32, const Duration(minutes: 9)));
      bad(lock(HashAlgorithm.SHA256, 32, const Duration(days: 31)));
    });
  });

  group("releaseLockedOperation builder", () {
    test("body is JSON-safe and marshals as type 0x18", () {
      final body = TxBody.releaseLockedOperation(
          lockedTxId: "acc://${"ab" * 32}@alice.acme/tokens",
          preimage: Uint8List.fromList(utf8.encode("secret")));
      expect(body["preimage"], equals(hex(utf8.encode("secret"))));
      expect(jsonDecode(jsonEncode(body))["preimage"], isA<String>());
    });
  });

  group("signing with every header option (fields 5-8)", () {
    late Ed25519KeyPair kp;
    setUp(() async => kp = await Ed25519KeyPair.generate());

    BuildContext fullCtx() => BuildContext(
          principal: "acc://alice.acme/tokens",
          timestamp: 1700000000000000,
          memo: "all",
          expire: ExpireOptions(atTime: DateTime.utc(2031, 5, 6, 7, 8, 9)),
          holdUntil: HoldUntilOptions(minorBlock: 5),
          authorities: ["acc://auth1.acme/book"],
          hashLock: HashLockOptions(
              hashAlgorithm: HashAlgorithm.SHA256,
              hash: Uint8List.fromList(List.generate(32, (i) => i + 1)),
              expiration: DateTime.utc(2030, 1, 2, 3, 4, 5)),
        );

    test("the signed hash covers every header field, even after a JSON hand-off",
        () async {
      final body = TxBody.sendTokensSingle(
          toUrl: "acc://bob.acme/tokens", amount: "12345");
      final env = await TxSigner.buildAndSign(
          ctx: fullCtx(),
          body: body,
          keypair: kp,
          signerUrl: "acc://alice.acme/book/1",
          signerVersion: 1);
      final signedHash = env.signatures.first.transactionHash;

      // What a co-signer holds after receiving the envelope as JSON.
      final wire = jsonDecode(jsonEncode(env.toJson())) as Map<String, dynamic>;
      final back = Envelope.fromJson(wire);
      final h = back.transaction["header"] as Map<String, dynamic>;
      expect(h.keys,
          containsAll(["expire", "holdUntil", "authorities", "hashLock"]));
      final recomputed = TransactionCodec.encodeTxForSigning(
          h, back.transaction["body"] as Map<String, dynamic>);
      expect(hex(recomputed), equals(signedHash));
    });
  });

  group("v3 models", () {
    test("Receipt parses the new fields and tolerates old responses", () {
      final r = Receipt.fromJson({
        "start": "ab",
        "end": "cd",
        "anchor": "ef",
        "entries": [
          {"right": true, "hash": "01"}
        ],
        "localBlock": 12,
        "localBlockTime": "2030-01-02T03:04:05Z",
        "majorBlock": 3,
        "forHeight": 9,
        "complete": false,
        "partition": "bvn0",
        "startsAtMainState": true,
      });
      expect(r.forHeight, 9);
      expect(r.complete, isFalse);
      expect(r.partition, "bvn0");
      expect(r.startsAtMainState, isTrue);
      expect(r.entries, hasLength(1));

      final old = Receipt.fromJson({"start": "ab", "localBlock": 12});
      expect(old.forHeight, 0);
      expect(old.startsAtMainState, isFalse);
      expect(old.partition, isNull);
    });

    test("options serialize as Go expects", () {
      expect(const ReceiptOptions(forAny: true, forHeight: 7).toJson(),
          {"forAny": true, "forHeight": 7});
      expect(const ReceiptOptions().toJson(), isEmpty);
      expect(
          const MajorHeaderRangeOptions(partition: "Directory", start: 1, end: 4)
              .toJson(),
          {"partition": "Directory", "start": 1, "end": 4});
      expect(
          const MinorRootRangeOptions(partition: "Directory", since: 10).toJson(),
          {"partition": "Directory", "since": 10, "until": 0});
      expect(
          AnchorReceiptOptions(partition: "bvn0", bptRoot: "AB" * 32, atOrAfter: 3)
              .toJson(),
          {"partition": "bvn0", "bptRoot": "ab" * 32, "atOrAfter": 3});
      expect(() => AnchorReceiptOptions(partition: "bvn0", bptRoot: "abcd"),
          throwsArgumentError);
    });

    test("NetworkGlobals keeps blockInterval raw and tolerates its absence", () {
      Map<String, dynamic> base() => {
            "OperatorAcceptThreshold": {"numerator": 2, "denominator": 3},
            "ValidatorAcceptThreshold": {"numerator": 2, "denominator": 3},
            "MajorBlockSchedule": "0 */12 * * *",
            "AnchorEmptyBlocks": true,
            "FeeSchedule": {},
            "Limits": {},
          };
      expect(NetworkGlobals.fromJson(base()).blockInterval, isNull);
      final g = NetworkGlobals.fromJson(
          {...base(), "BlockInterval": {"seconds": 1, "nanoseconds": 500000000}});
      expect(g.blockInterval, {"seconds": 1, "nanoseconds": 500000000});
    });
  });
}
