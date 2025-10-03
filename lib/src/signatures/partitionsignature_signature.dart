part of 'signatures.dart';
final class PartitionSignature extends Signature {
  final String SourceNetwork;
  final String DestinationNetwork;
  final int SequenceNumber;
  final Uint8List? TransactionHash;

  const PartitionSignature({
    required this.SourceNetwork,
    required this.DestinationNetwork,
    required this.SequenceNumber,
    this.TransactionHash,
  });

  @override
  String get $type => 'Partition';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'SourceNetwork': SourceNetwork,
      'DestinationNetwork': DestinationNetwork,
      'SequenceNumber': SequenceNumber,
      if (TransactionHash != null) 'TransactionHash': ByteUtils.bytesToJson(TransactionHash!),
    };

  static PartitionSignature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = PartitionSignature(
      SourceNetwork: j['SourceNetwork'] as String,
      DestinationNetwork: j['DestinationNetwork'] as String,
      SequenceNumber: j['SequenceNumber'] as int,
      TransactionHash: j['TransactionHash'] != null ? (() { final bytes = ByteUtils.bytesFromJson(j['TransactionHash'] as String); ByteUtils.validateLength(bytes, 32, 'TransactionHash'); return bytes; })() : null,
    );
    return instance;
  }

}
