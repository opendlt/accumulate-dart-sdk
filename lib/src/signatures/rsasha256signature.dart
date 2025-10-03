/// RsaSha256Signature signature implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// RsaSha256Signature signature
final class RsaSha256Signature extends Signature {
  const RsaSha256Signature({
    required this.publicKey,
    required this.signature,
    required this.signer,
    required this.signerVersion,
    this.timestamp,
    this.vote,
    this.transactionHash,
    this.memo,
    this.data,
  });

  final Uint8List publicKey;
  final Uint8List signature;
  final String signer;
  final int signerVersion;
  final int? timestamp;
  final VoteType? vote;
  final Uint8List? transactionHash;
  final String? memo;
  final Uint8List? data;

  @override
  String get $type => 'RsaSha256Signature';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['PublicKey'] = ByteUtils.bytesToJson(publicKey);
    json['Signature'] = ByteUtils.bytesToJson(signature);
    json['Signer'] = signer;
    json['SignerVersion'] = signerVersion;
      if (timestamp != null) {
      json['Timestamp'] = timestamp;
    }
      if (vote != null) {
      json['Vote'] = vote;
    }
      if (transactionHash != null) {
      json['TransactionHash'] = ByteUtils.bytesToJson(transactionHash!);
    }
      if (memo != null) {
      json['Memo'] = memo;
    }
      if (data != null) {
      json['Data'] = ByteUtils.bytesToJson(data!);
    }
    return json;
  }

  /// Parse from JSON
  static RsaSha256Signature? fromJson(Map<String, dynamic> json, [int depth = 0]) {
    try {
      final publicKey = ByteUtils.bytesFromJson(json['PublicKey'] as String);
      final signature = ByteUtils.bytesFromJson(json['Signature'] as String);
      final signer = json['Signer'] as String;
      final signerVersion = json['SignerVersion'] as int;
      final timestamp = json['Timestamp'] as int?;
      final vote = json['Vote'];
      final transactionHash = json['TransactionHash'] != null ? ByteUtils.bytesFromJson(json['TransactionHash'] as String) : null;
      final memo = json['Memo'] as String?;
      final data = json['Data'] != null ? ByteUtils.bytesFromJson(json['Data'] as String) : null;

      return RsaSha256Signature(
        publicKey: publicKey,
        signature: signature,
        signer: signer,
        signerVersion: signerVersion,
        timestamp: timestamp,
        vote: vote,
        transactionHash: transactionHash,
        memo: memo,
        data: data,
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
