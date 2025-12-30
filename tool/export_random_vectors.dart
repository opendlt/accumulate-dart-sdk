#!/usr/bin/env dart

/// Random Transaction Vector Exporter
///
/// Generates deterministic random transaction envelopes for cross-language testing.
/// Exports to JSON lines format with binary encoding, canonical JSON, and hashes.
///
/// Usage:
///   dart run tool/export_random_vectors.dart [count] > tests/golden/rand_vectors.jsonl
///   dart run tool/export_random_vectors.dart 1000 > tests/golden/rand_vectors.jsonl

import "dart:convert";
import "dart:io";
import "dart:math";
import "dart:typed_data";
import "package:opendlt_accumulate/src/build/builders.dart";
import "package:opendlt_accumulate/src/build/context.dart";
import "package:opendlt_accumulate/src/build/tx_types.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";
import "package:opendlt_accumulate/src/codec/binary.dart";
import "package:opendlt_accumulate/src/codec/transaction_codec.dart";
import "package:opendlt_accumulate/src/protocol/envelope.dart";
import "package:opendlt_accumulate/src/util/bytes.dart";
import "package:opendlt_accumulate/src/util/json_canonical.dart";

void main(List<String> args) async {
  final count = args.isNotEmpty ? int.parse(args[0]) : 1000;
  final seed = 42; // Fixed seed for deterministic output

  stderr.writeln("Generating $count random transaction vectors with seed $seed");

  final rng = Random(seed);
  final generator = RandomVectorGenerator(rng);

  for (int i = 0; i < count; i++) {
    final vector = await generator.generateVector(i);
    print(jsonEncode(vector));
  }

  stderr.writeln("Generated $count vectors successfully");
}

class RandomVectorGenerator {
  final Random rng;

  RandomVectorGenerator(this.rng);

  /// Generate a single test vector
  Future<Map<String, dynamic>> generateVector(int index) async {
    // Generate random keypair
    final keypair = await generateRandomKeypair();

    // Generate random transaction
    final envelope = await generateRandomTransaction(index, keypair);

    // Encode to binary
    final binaryData = encodeToBinary(envelope);

    // Generate canonical JSON
    final canonicalJson = canonicalJsonString(envelope.toJson());

    // Compute transaction hash
    final txHash = TransactionCodec.encodeTxForSigning(
      envelope.transaction["header"],
      envelope.transaction["body"]
    );

    return {
      "hexBin": toHex(binaryData),
      "canonicalJson": canonicalJson,
      "txHashHex": toHex(txHash),
      "meta": {
        "index": index,
        "txType": envelope.transaction["body"]["type"],
        "timestamp": envelope.transaction["header"]["timestamp"],
        "sigCount": envelope.signatures.length,
      }
    };
  }

  /// Generate random Ed25519 keypair
  Future<Ed25519KeyPair> generateRandomKeypair() async {
    final seed = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seed[i] = rng.nextInt(256);
    }
    return Ed25519KeyPair.fromSeed(seed);
  }

  /// Generate random transaction envelope
  Future<Envelope> generateRandomTransaction(int index, Ed25519KeyPair keypair) async {
    // Random timestamp in reasonable range
    final baseTimestamp = DateTime(2024, 1, 1).millisecondsSinceEpoch;
    final maxRange = 365 * 24 * 60 * 60 * 1000; // 1 year in milliseconds
    // Ensure range fits in int32
    final safeRange = maxRange > 2147483647 ? 2147483647 : maxRange;
    final timestamp = baseTimestamp + rng.nextInt(safeRange);

    // Random principal
    final principal = generateRandomPrincipal();

    // Optional memo (50% chance)
    final memo = rng.nextBool() ? generateRandomMemo() : null;

    final ctx = BuildContext(
      principal: principal,
      timestamp: timestamp,
      memo: memo,
    );

    // Generate random transaction body
    final body = generateRandomTxBody(index);

    // Optional signer URL (30% chance)
    final signerUrl = rng.nextDouble() < 0.3 ? generateRandomSignerUrl() : null;

    return TxSigner.buildAndSign(
      ctx: ctx,
      body: body,
      keypair: keypair,
      signerUrl: signerUrl,
    );
  }

  /// Generate random transaction body covering all types
  Map<String, dynamic> generateRandomTxBody(int index) {
    // Cycle through transaction types deterministically while adding randomness
    final txTypes = [
      TxTypes.sendTokens,
      TxTypes.createIdentity,
      TxTypes.createTokenAccount,
      TxTypes.createDataAccount,
      TxTypes.writeData,
      TxTypes.burnTokens,
    ];

    final txType = txTypes[index % txTypes.length];

    switch (txType) {
      case TxTypes.sendTokens:
        return generateSendTokensBody();
      case TxTypes.createIdentity:
        return generateCreateIdentityBody();
      case TxTypes.createTokenAccount:
        return generateCreateTokenAccountBody();
      case TxTypes.createDataAccount:
        return generateCreateDataAccountBody();
      case TxTypes.writeData:
        return generateWriteDataBody();
      case TxTypes.burnTokens:
        return generateBurnTokensBody();
      default:
        throw ArgumentError("Unknown transaction type: $txType");
    }
  }

  Map<String, dynamic> generateSendTokensBody() {
    final recipientCount = 1 + rng.nextInt(3); // 1-3 recipients
    final recipients = <Map<String, dynamic>>[];

    for (int i = 0; i < recipientCount; i++) {
      recipients.add({
        "url": generateRandomTokenUrl(),
        "amount": generateRandomAmount(),
      });
    }

    return {
      "type": TxTypes.sendTokens,
      "to": recipients,
    };
  }

  Map<String, dynamic> generateCreateIdentityBody() {
    return TxBody.createIdentity(
      url: generateRandomAdiUrl(),
      keyBookName: generateRandomKeyBookName(),
      publicKeyHash: generateRandomHex(64), // 32 bytes as hex
    );
  }

  Map<String, dynamic> generateCreateTokenAccountBody() {
    return TxBody.createTokenAccount(
      url: generateRandomTokenUrl(),
      tokenUrl: generateRandomTokenIssuer(),
    );
  }

  Map<String, dynamic> generateCreateDataAccountBody() {
    return TxBody.createDataAccount(
      url: generateRandomDataUrl(),
    );
  }

  Map<String, dynamic> generateWriteDataBody() {
    final entryCount = 1 + rng.nextInt(4); // 1-4 entries
    final entries = <String>[];

    for (int i = 0; i < entryCount; i++) {
      final data = generateRandomData();
      // Convert to hex (entriesHex expects hex-encoded data)
      entries.add(data.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
    }

    return TxBody.writeData(entriesHex: entries);
  }

  Map<String, dynamic> generateBurnTokensBody() {
    return TxBody.buyCredits(
      recipientUrl: generateRandomKeyPageUrl(),
      amount: generateRandomAmount(),
    );
  }

  /// Generate random principal URL
  String generateRandomPrincipal() {
    final types = ["adi", "lite"];
    final type = types[rng.nextInt(types.length)];

    if (type == "adi") {
      return generateRandomKeyPageUrl();
    } else {
      return generateRandomLiteUrl() + "/book";
    }
  }

  /// Generate random ADI URL
  String generateRandomAdiUrl() {
    final names = ["alice", "bob", "charlie", "david", "eve", "frank", "grace", "helen"];
    final domains = ["acme", "test", "example", "demo", "corp"];
    final name = names[rng.nextInt(names.length)];
    final domain = domains[rng.nextInt(domains.length)];
    return "acc://$name.$domain";
  }

  /// Generate random token URL
  String generateRandomTokenUrl() {
    final base = rng.nextBool() ? generateRandomAdiUrl() : generateRandomLiteUrl();
    final tokens = ["tokens", "ACME", "credits"];
    final token = tokens[rng.nextInt(tokens.length)];
    return "$base/$token";
  }

  /// Generate random data URL
  String generateRandomDataUrl() {
    final base = generateRandomAdiUrl();
    final paths = ["data", "files", "documents", "records"];
    final path = paths[rng.nextInt(paths.length)];
    return "$base/$path";
  }

  /// Generate random key page URL
  String generateRandomKeyPageUrl() {
    final base = generateRandomAdiUrl();
    final books = ["book", "keybook", "keys"];
    final book = books[rng.nextInt(books.length)];
    final page = rng.nextInt(10);
    return "$base/$book/$page";
  }

  /// Generate random signer URL
  String generateRandomSignerUrl() {
    return generateRandomKeyPageUrl();
  }

  /// Generate random lite URL
  String generateRandomLiteUrl() {
    final hash = generateRandomHex(40); // 20 bytes as hex
    final checksum = generateRandomHex(8); // 4 bytes as hex
    return "acc://$hash$checksum";
  }

  /// Generate random token issuer
  String generateRandomTokenIssuer() {
    final issuers = ["acc://acme", "acc://test.acme", "acc://tokens.example"];
    return issuers[rng.nextInt(issuers.length)];
  }

  /// Generate random key book name
  String generateRandomKeyBookName() {
    final names = ["book", "keybook", "keys", "primary"];
    return names[rng.nextInt(names.length)];
  }

  /// Generate random amount string
  String generateRandomAmount() {
    final amounts = [
      "1000", "500", "250", "100", "50", "25", "10", "5", "1",
      "1000000", "500000", "100000", "10000",
      "1234567890", "9876543210",
    ];
    return amounts[rng.nextInt(amounts.length)];
  }

  /// Generate random memo
  String generateRandomMemo() {
    final memos = [
      "Test transaction",
      "Random test",
      "Fuzz test data",
      "Generated transaction",
      "Cross-language test",
      "",
      "🚀 Accumulate transaction",
      "Multi-language compatibility test",
    ];
    return memos[rng.nextInt(memos.length)];
  }

  /// Generate random hex string
  String generateRandomHex(int length) {
    final hex = StringBuffer();
    for (int i = 0; i < length; i++) {
      hex.write(rng.nextInt(16).toRadixString(16));
    }
    return hex.toString();
  }

  /// Generate random data bytes
  Uint8List generateRandomData() {
    final length = 1 + rng.nextInt(100); // 1-100 bytes
    final data = Uint8List(length);
    for (int i = 0; i < length; i++) {
      data[i] = rng.nextInt(256);
    }
    return data;
  }

  /// Encode envelope to binary using Accumulate binary codec
  Uint8List encodeToBinary(Envelope envelope) {
    // For this fuzzing test, we'll encode the envelope as canonical JSON bytes
    // This tests the JSON serialization path which is the primary encoding method
    // In the future, this could be extended to use the actual binary codec
    // when it's implemented for envelopes

    final canonicalJson = canonicalJsonString(envelope.toJson());
    return utf8Bytes(canonicalJson);
  }
}