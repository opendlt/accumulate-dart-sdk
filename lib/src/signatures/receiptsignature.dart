/// ReceiptSignature signature implementation
library;

import 'dart:typed_data';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import 'signatures.dart';

/// ReceiptSignature signature
final class ReceiptSignature extends Signature {
  const ReceiptSignature({
    required this.sourceNetwork,
    required this.proof,
    this.transactionHash,
  });

  final String sourceNetwork;
  final Map<String, dynamic> proof;
  final Uint8List? transactionHash;

  @override
  String get $type => 'ReceiptSignature';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['SourceNetwork'] = sourceNetwork;
    json['Proof'] = proof;
      if (transactionHash != null) {
      json['TransactionHash'] = ByteUtils.bytesToJson(transactionHash!);
    }
    return json;
  }

  /// Parse from JSON
  static ReceiptSignature? fromJson(Map<String, dynamic> json, [int depth = 0]) {
    try {
      final sourceNetwork = json['SourceNetwork'] as String;
      final proof = json['Proof'];
      final transactionHash = json['TransactionHash'] != null ? ByteUtils.bytesFromJson(json['TransactionHash'] as String) : null;

      return ReceiptSignature(
        sourceNetwork: sourceNetwork,
        proof: proof,
        transactionHash: transactionHash,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature fields
  bool validate() {
    try {
      if (!AccumulateUrl.isValid(sourceNetwork)) return false;
      if (transactionHash != null && transactionHash!.isEmpty) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
