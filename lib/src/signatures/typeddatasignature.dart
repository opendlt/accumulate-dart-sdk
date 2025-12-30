/// TypedDataSignature signature implementation
library;

import 'dart:typed_data';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// TypedDataSignature signature
final class TypedDataSignature extends Signature {
  const TypedDataSignature({
    required this.publicKey,
    required this.signature,
    required this.signer,
    required this.signerVersion,
    this.timestamp,
    this.vote,
    this.transactionHash,
    this.memo,
    this.data,
    required this.chainID,
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
  final BigInt chainID;

  @override
  String get $type => 'TypedDataSignature';

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
    json['ChainID'] = chainID;
    return json;
  }

  /// Parse from JSON
  static TypedDataSignature? fromJson(Map<String, dynamic> json, [int depth = 0]) {
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
      final chainID = json['ChainID'];

      return TypedDataSignature(
        publicKey: publicKey,
        signature: signature,
        signer: signer,
        signerVersion: signerVersion,
        timestamp: timestamp,
        vote: vote,
        transactionHash: transactionHash,
        memo: memo,
        data: data,
        chainID: chainID,
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
