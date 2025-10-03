part of 'signatures.dart';
final class ReceiptSignature extends Signature {
  final String SourceNetwork;
  final Uint8List Proof;
  final Uint8List? TransactionHash;

  const ReceiptSignature({
    required this.SourceNetwork,
    required this.Proof,
    this.TransactionHash,
  });

  @override
  String get $type => 'receipt';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'SourceNetwork': SourceNetwork,
      'Proof': ByteUtils.bytesToJson(Proof),
      if (TransactionHash != null) 'TransactionHash': ByteUtils.bytesToJson(TransactionHash!),
    };

  static ReceiptSignature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = ReceiptSignature(
      SourceNetwork: j['SourceNetwork'] as String,
      Proof: ByteUtils.bytesFromJson(j['Proof'] as String),
      TransactionHash: j['TransactionHash'] != null ? (() { final bytes = ByteUtils.bytesFromJson(j['TransactionHash'] as String); ByteUtils.validateLength(bytes, 32, 'TransactionHash'); return bytes; })() : null,
    );
    return instance;
  }

}
