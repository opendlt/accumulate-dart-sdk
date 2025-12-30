import "dart:typed_data";
import "package:test/test.dart";
import "package:opendlt_accumulate/src/codec/binary_encoder.dart";

void main() {
  group("BinaryEncoder", () {
    group("uvarint encoding", () {
      test("encodes single byte values (0-127)", () {
        final encoder = BinaryEncoder();
        encoder.writeUint(1, 0); // Zero not written
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x80]))); // empty

        final encoder2 = BinaryEncoder();
        encoder2.writeUint(1, 1);
        // Field 1 = 0x01, value 1 = 0x01
        expect(encoder2.toBytes(), equals(Uint8List.fromList([0x01, 0x01])));

        final encoder3 = BinaryEncoder();
        encoder3.writeUint(1, 127);
        // Field 1 = 0x01, value 127 = 0x7F
        expect(encoder3.toBytes(), equals(Uint8List.fromList([0x01, 0x7F])));
      });

      test("encodes multi-byte values (128+)", () {
        final encoder = BinaryEncoder();
        encoder.writeUint(1, 128);
        // Field 1 = 0x01, value 128 = 0x80 0x01
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x01, 0x80, 0x01])));

        final encoder2 = BinaryEncoder();
        encoder2.writeUint(1, 300);
        // 300 = 0xAC 0x02
        expect(encoder2.toBytes(), equals(Uint8List.fromList([0x01, 0xAC, 0x02])));

        final encoder3 = BinaryEncoder();
        encoder3.writeUint(1, 16384);
        // 16384 = 0x80 0x80 0x01
        expect(encoder3.toBytes(), equals(Uint8List.fromList([0x01, 0x80, 0x80, 0x01])));
      });
    });

    group("field encoding", () {
      test("writes multiple fields in order", () {
        final encoder = BinaryEncoder();
        encoder.writeUint(1, 1);
        encoder.writeUint(2, 2);
        encoder.writeUint(3, 3);
        // Field 1=0x01 val=0x01, Field 2=0x02 val=0x02, Field 3=0x03 val=0x03
        expect(encoder.toBytes(),
            equals(Uint8List.fromList([0x01, 0x01, 0x02, 0x02, 0x03, 0x03])));
      });

      test("skips zero values", () {
        final encoder = BinaryEncoder();
        encoder.writeUint(1, 0);
        encoder.writeUint(2, 5);
        encoder.writeUint(3, 0);
        // Only field 2 should be written
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x02, 0x05])));
      });
    });

    group("string encoding", () {
      test("encodes string with length prefix", () {
        final encoder = BinaryEncoder();
        encoder.writeString(1, "abc");
        // Field 1=0x01, length=3, 'a'=97 'b'=98 'c'=99
        expect(encoder.toBytes(),
            equals(Uint8List.fromList([0x01, 0x03, 97, 98, 99])));
      });

      test("skips empty strings", () {
        final encoder = BinaryEncoder();
        encoder.writeString(1, "");
        encoder.writeString(2, "x");
        // Only field 2 should be written
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x02, 0x01, 120])));
      });

      test("encodes URL field", () {
        final encoder = BinaryEncoder();
        encoder.writeUrl(1, "acc://test.acme");
        // Same as string encoding
        final bytes = encoder.toBytes();
        expect(bytes[0], equals(0x01)); // field
        expect(bytes[1], equals(15)); // length of "acc://test.acme"
      });
    });

    group("bytes encoding", () {
      test("encodes bytes with length prefix", () {
        final encoder = BinaryEncoder();
        encoder.writeBytes(1, Uint8List.fromList([0xAB, 0xCD, 0xEF]));
        // Field 1=0x01, length=3, bytes
        expect(encoder.toBytes(),
            equals(Uint8List.fromList([0x01, 0x03, 0xAB, 0xCD, 0xEF])));
      });

      test("skips null/empty bytes", () {
        final encoder = BinaryEncoder();
        encoder.writeBytes(1, null);
        encoder.writeBytes(2, Uint8List(0));
        encoder.writeBytes(3, Uint8List.fromList([0x01]));
        // Only field 3 should be written
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x03, 0x01, 0x01])));
      });
    });

    group("hash encoding", () {
      test("encodes 32-byte hash without length prefix", () {
        final hash = Uint8List(32);
        hash[0] = 0xAB;
        hash[31] = 0xCD;

        final encoder = BinaryEncoder();
        encoder.writeHash(1, hash);

        final bytes = encoder.toBytes();
        expect(bytes.length, equals(33)); // field + 32 bytes
        expect(bytes[0], equals(0x01)); // field 1
        expect(bytes[1], equals(0xAB)); // first byte of hash
        expect(bytes[32], equals(0xCD)); // last byte of hash
      });

      test("skips zero hash", () {
        final zeroHash = Uint8List(32);
        final encoder = BinaryEncoder();
        encoder.writeHash(1, zeroHash);
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x80]))); // empty
      });

      test("rejects non-32-byte hash", () {
        final encoder = BinaryEncoder();
        expect(
            () => encoder.writeHash(1, Uint8List(31)),
            throwsA(isA<ArgumentError>()));
        expect(
            () => encoder.writeHash(1, Uint8List(33)),
            throwsA(isA<ArgumentError>()));
      });
    });

    group("BigInt encoding", () {
      test("encodes BigInt as length-prefixed big-endian bytes", () {
        final encoder = BinaryEncoder();
        encoder.writeBigInt(1, BigInt.from(256));
        // 256 = 0x0100 = 2 bytes
        expect(encoder.toBytes(),
            equals(Uint8List.fromList([0x01, 0x02, 0x01, 0x00])));
      });

      test("skips zero BigInt", () {
        final encoder = BinaryEncoder();
        encoder.writeBigInt(1, BigInt.zero);
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x80]))); // empty
      });

      test("encodes large BigInt", () {
        final encoder = BinaryEncoder();
        final bigValue = BigInt.parse("1000000000000"); // 1 trillion
        encoder.writeBigInt(1, bigValue);

        final bytes = encoder.toBytes();
        expect(bytes[0], equals(0x01)); // field 1
        // Verify the BigInt was encoded correctly
        expect(bytes.length, greaterThan(1));
      });
    });

    group("bool encoding", () {
      test("encodes true as 1", () {
        final encoder = BinaryEncoder();
        encoder.writeBool(1, true);
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x01, 0x01])));
      });

      test("skips false", () {
        final encoder = BinaryEncoder();
        encoder.writeBool(1, false);
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x80]))); // empty
      });
    });

    group("enum encoding", () {
      test("always writes enum field (even if zero)", () {
        final encoder = BinaryEncoder();
        encoder.writeEnum(1, 0);
        // Enum always written even if 0
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x01, 0x00])));
      });

      test("encodes enum value", () {
        final encoder = BinaryEncoder();
        encoder.writeEnum(1, 5);
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x01, 0x05])));
      });
    });

    group("empty object", () {
      test("returns 0x80 for empty encoder", () {
        final encoder = BinaryEncoder();
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x80])));
      });
    });

    group("reset", () {
      test("clears encoder state", () {
        final encoder = BinaryEncoder();
        encoder.writeUint(1, 5);
        expect(encoder.toBytes().length, greaterThan(1));

        encoder.reset();
        expect(encoder.toBytes(), equals(Uint8List.fromList([0x80])));
      });
    });
  });

  group("TransactionHeaderMarshaler", () {
    test("marshals header with principal only", () {
      final bytes = TransactionHeaderMarshaler.marshal({
        "principal": "acc://test.acme",
      });

      expect(bytes[0], equals(0x01)); // field 1
      expect(bytes[1], equals(15)); // length of URL
    });

    test("marshals header with multiple fields", () {
      final bytes = TransactionHeaderMarshaler.marshal({
        "principal": "acc://test.acme",
        "memo": "test memo",
      });

      // Should contain both fields
      expect(bytes.length, greaterThan(20));
      expect(bytes[0], equals(0x01)); // field 1 (principal)
    });

    test("marshals header with initiator hash", () {
      final initiator = Uint8List(32);
      initiator[0] = 0xAB;
      initiator[31] = 0xCD;

      final bytes = TransactionHeaderMarshaler.marshal({
        "principal": "acc://test.acme",
        "initiator": initiator,
      });

      // Should contain principal (field 1) and initiator (field 2)
      expect(bytes.length, greaterThan(40));
    });

    test("marshals header with authorities list", () {
      final bytes = TransactionHeaderMarshaler.marshal({
        "principal": "acc://test.acme",
        "authorities": ["acc://auth1.acme/book", "acc://auth2.acme/book"],
      });

      // Multiple authority fields (field 7 repeated)
      expect(bytes.length, greaterThan(30));
    });

    test("handles hex string initiator", () {
      final hexInitiator = "ab" * 32; // 64 hex chars = 32 bytes
      final bytes = TransactionHeaderMarshaler.marshal({
        "principal": "acc://test.acme",
        "initiator": hexInitiator,
      });

      expect(bytes.length, greaterThan(40));
    });
  });

  group("ED25519SignatureMarshaler", () {
    test("marshals signature metadata", () {
      final publicKey = Uint8List(32);
      publicKey[0] = 0x01;

      final bytes = ED25519SignatureMarshaler.marshalMetadata(
        publicKey: publicKey,
        signer: "acc://signer.acme/book/1",
        signerVersion: 1,
        timestamp: 1234567890,
      );

      // Should start with type field (1) = ED25519 (2)
      expect(bytes[0], equals(0x01)); // field 1
      expect(bytes[1], equals(0x02)); // ED25519 type
    });

    test("marshals full signature with vote", () {
      final publicKey = Uint8List(32);
      publicKey[0] = 0x01;
      final signature = Uint8List(64);
      signature[0] = 0xAA;

      final bytes = ED25519SignatureMarshaler.marshal(
        publicKey: publicKey,
        signature: signature,
        signer: "acc://signer.acme/book/1",
        signerVersion: 1,
        timestamp: 1234567890,
        vote: 1, // Accept
      );

      expect(bytes.length, greaterThan(100));
      expect(bytes[0], equals(0x01)); // field 1 (type)
      expect(bytes[1], equals(0x02)); // ED25519 type
    });

    test("marshals signature with memo and data", () {
      final publicKey = Uint8List(32);
      publicKey[0] = 0x01;

      final bytes = ED25519SignatureMarshaler.marshalMetadata(
        publicKey: publicKey,
        signer: "acc://signer.acme/book/1",
        memo: "test signature memo",
        data: Uint8List.fromList([0x01, 0x02, 0x03]),
      );

      expect(bytes.length, greaterThan(50));
    });

    test("omits zero transaction hash", () {
      final publicKey = Uint8List(32);
      publicKey[0] = 0x01;
      final zeroHash = Uint8List(32);

      final bytes = ED25519SignatureMarshaler.marshal(
        publicKey: publicKey,
        transactionHash: zeroHash,
      );

      // Zero hash should be omitted, so length should be small
      expect(bytes.length, lessThan(40));
    });
  });

  group("TransactionBodyMarshaler", () {
    group("AddCredits", () {
      test("marshals AddCredits transaction", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "addCredits",
          "recipient": "acc://recipient.acme/tokens",
          "amount": "1000000000",
          "oracle": 5000,
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
        expect(bytes[1], equals(0x0E)); // AddCredits = 14
      });

      test("handles BigInt amount", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "addCredits",
          "recipient": "acc://recipient.acme/tokens",
          "amount": BigInt.from(1000000000),
          "oracle": 5000,
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
      });

      test("handles int amount", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "addCredits",
          "recipient": "acc://recipient.acme/tokens",
          "amount": 1000000000,
          "oracle": 5000,
        });

        expect(bytes.length, greaterThan(10));
      });
    });

    group("SendTokens", () {
      test("marshals SendTokens transaction", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "sendTokens",
          "to": [
            {"url": "acc://recipient.acme/tokens", "amount": "1000000000"},
          ],
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
        expect(bytes[1], equals(0x03)); // SendTokens = 3
      });

      test("marshals multiple recipients", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "sendTokens",
          "to": [
            {"url": "acc://recipient1.acme/tokens", "amount": "500000000"},
            {"url": "acc://recipient2.acme/tokens", "amount": "500000000"},
          ],
        });

        expect(bytes.length, greaterThan(50));
      });
    });

    group("CreateIdentity", () {
      test("marshals CreateIdentity transaction", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createIdentity",
          "url": "acc://newidentity.acme",
          "publicKeyHash": "ab" * 32,
          "keyBookName": "book",
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
        expect(bytes[1], equals(0x01)); // CreateIdentity = 1
      });

      test("marshals with explicit keyBookUrl", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createIdentity",
          "url": "acc://newidentity.acme",
          "publicKeyHash": Uint8List(32),
          "keyBookUrl": "acc://newidentity.acme/book",
        });

        expect(bytes.length, greaterThan(30));
      });

      test("marshals with authorities", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createIdentity",
          "url": "acc://newidentity.acme",
          "publicKeyHash": "ab" * 32,
          "authorities": ["acc://auth.acme/book"],
        });

        expect(bytes.length, greaterThan(50));
      });
    });

    group("CreateTokenAccount", () {
      test("marshals CreateTokenAccount transaction", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createTokenAccount",
          "url": "acc://identity.acme/tokens",
          "tokenUrl": "acc://ACME",
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
        expect(bytes[1], equals(0x02)); // CreateTokenAccount = 2
      });

      test("handles token field alias", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createTokenAccount",
          "url": "acc://identity.acme/tokens",
          "token": "acc://ACME",
        });

        expect(bytes.length, greaterThan(20));
      });
    });

    group("CreateDataAccount", () {
      test("marshals CreateDataAccount transaction", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createDataAccount",
          "url": "acc://identity.acme/data",
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
        expect(bytes[1], equals(0x04)); // CreateDataAccount = 4
      });

      test("marshals with authorities", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "createDataAccount",
          "url": "acc://identity.acme/data",
          "authorities": ["acc://identity.acme/book"],
        });

        expect(bytes.length, greaterThan(30));
      });
    });

    group("WriteData", () {
      test("marshals WriteData transaction with entry", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "writeData",
          "entry": {"data": "SGVsbG8gV29ybGQ="}, // base64 "Hello World"
        });

        expect(bytes[0], equals(0x01)); // field 1 (type)
        expect(bytes[1], equals(0x05)); // WriteData = 5
      });

      test("marshals WriteData with writeToState", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "writeData",
          "entry": {"data": "SGVsbG8gV29ybGQ="},
          "writeToState": true,
        });

        expect(bytes.length, greaterThan(10));
      });

      test("marshals WriteData with entries list", () {
        final bytes = TransactionBodyMarshaler.marshal({
          "type": "writeData",
          "entries": [
            {"data": "SGVsbG8="},
            {"data": "V29ybGQ="},
          ],
        });

        expect(bytes.length, greaterThan(10));
      });
    });

    group("type resolution", () {
      test("getTypeValue returns correct values", () {
        expect(TransactionBodyMarshaler.getTypeValue("createIdentity"), equals(0x01));
        expect(TransactionBodyMarshaler.getTypeValue("createTokenAccount"), equals(0x02));
        expect(TransactionBodyMarshaler.getTypeValue("sendTokens"), equals(0x03));
        expect(TransactionBodyMarshaler.getTypeValue("createDataAccount"), equals(0x04));
        expect(TransactionBodyMarshaler.getTypeValue("writeData"), equals(0x05));
        expect(TransactionBodyMarshaler.getTypeValue("addCredits"), equals(0x0E));
      });

      test("getTypeValue is case insensitive", () {
        expect(TransactionBodyMarshaler.getTypeValue("CREATEIDENTITY"), equals(0x01));
        expect(TransactionBodyMarshaler.getTypeValue("SendTokens"), equals(0x03));
      });

      test("getTypeValue throws for unknown type", () {
        expect(
            () => TransactionBodyMarshaler.getTypeValue("unknownType"),
            throwsA(isA<ArgumentError>()));
      });
    });
  });

  group("Binary encoding consistency", () {
    test("same input produces same output", () {
      final input = {
        "type": "sendTokens",
        "to": [
          {"url": "acc://recipient.acme/tokens", "amount": "1000000000"},
        ],
      };

      final bytes1 = TransactionBodyMarshaler.marshal(input);
      final bytes2 = TransactionBodyMarshaler.marshal(input);

      expect(bytes1, equals(bytes2));
    });

    test("field order is consistent", () {
      final header = {
        "principal": "acc://test.acme",
        "memo": "test",
        "initiator": Uint8List(32)..[0] = 0x01,
      };

      final bytes1 = TransactionHeaderMarshaler.marshal(header);
      final bytes2 = TransactionHeaderMarshaler.marshal(header);

      expect(bytes1, equals(bytes2));
    });
  });
}
