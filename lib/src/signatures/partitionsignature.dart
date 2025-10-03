/// PartitionSignature signature implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// PartitionSignature signature
final class PartitionSignature extends Signature {
  const PartitionSignature({
    required this.sourceNetwork,
    required this.destinationNetwork,
    required this.sequenceNumber,
    this.transactionHash,
  });

  final String sourceNetwork;
  final String destinationNetwork;
  final int sequenceNumber;
  final Uint8List? transactionHash;

  @override
  String get $type => 'Partition';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['SourceNetwork'] = sourceNetwork;
    json['DestinationNetwork'] = destinationNetwork;
    json['SequenceNumber'] = sequenceNumber;
    if (transactionHash != null) {
      json['TransactionHash'] = ByteUtils.bytesToJson(transactionHash!);
    }
    return json;
  }

  /// Parse from JSON
  static {sig_name}? fromJson(Map<String, dynamic> json) {{
    try {{
      final sourceNetwork = json['SourceNetwork'] as String;
      final destinationNetwork = json['DestinationNetwork'] as String;
      final sequenceNumber = json['SequenceNumber'] as int;
      final transactionHash = json['TransactionHash'] != null ? ByteUtils.bytesFromJson(json['TransactionHash'] as String) : null;

      return PartitionSignature(
        sourceNetwork: sourceNetwork,
        destinationNetwork: destinationNetwork,
        sequenceNumber: sequenceNumber,
        transactionHash: transactionHash,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature fields
  bool validate() {
    if (!AccumulateUrl.isValid(sourceNetwork)) return false;
    if (!AccumulateUrl.isValid(destinationNetwork)) return false;
    if (!ByteUtils.validateHash(transactionHash)) return false;
    return true;
  }
}
