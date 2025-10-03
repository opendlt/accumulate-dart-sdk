/// LegacyED25519Signature signature implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// LegacyED25519Signature signature
final class LegacyED25519Signature extends Signature {
  const LegacyED25519Signature({
    required this.timestamp,
    required this.publicKey,
    required this.signature,
    required this.signer,
    required this.signerVersion,
    this.vote,
    this.transactionHash,
  });

  final int timestamp;
  final Uint8List publicKey;
  final Uint8List signature;
  final String signer;
  final int signerVersion;
  final VoteType? vote;
  final Uint8List? transactionHash;

  @override
  String get $type => 'LegacyED25519Signature';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['Timestamp'] = timestamp;
    json['PublicKey'] = ByteUtils.bytesToJson(publicKey);
    json['Signature'] = ByteUtils.bytesToJson(signature);
    json['Signer'] = signer;
    json['SignerVersion'] = signerVersion;
      if (vote != null) {
      json['Vote'] = vote;
    }
      if (transactionHash != null) {
      json['TransactionHash'] = ByteUtils.bytesToJson(transactionHash!);
    }
    return json;
  }

  /// Parse from JSON
  static LegacyED25519Signature? fromJson(Map<String, dynamic> json, [int depth = 0]) {
    try {
      final timestamp = json['Timestamp'] as int;
      final publicKey = ByteUtils.bytesFromJson(json['PublicKey'] as String);
      final signature = ByteUtils.bytesFromJson(json['Signature'] as String);
      final signer = json['Signer'] as String;
      final signerVersion = json['SignerVersion'] as int;
      final vote = json['Vote'];
      final transactionHash = json['TransactionHash'] != null ? ByteUtils.bytesFromJson(json['TransactionHash'] as String) : null;

      return LegacyED25519Signature(
        timestamp: timestamp,
        publicKey: publicKey,
        signature: signature,
        signer: signer,
        signerVersion: signerVersion,
        vote: vote,
        transactionHash: transactionHash,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature fields
  bool validate() {
    try {
      if (publicKey.isEmpty) return false;
      if (signature.isEmpty) return false;
      if (!AccumulateUrl.isValid(signer)) return false;
      if (transactionHash != null && transactionHash!.isEmpty) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
