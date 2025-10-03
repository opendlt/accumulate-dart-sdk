part of 'signatures.dart';
final class InternalSignature extends Signature {
  final Uint8List Cause;
  final Uint8List TransactionHash;

  const InternalSignature({
    required this.Cause,
    required this.TransactionHash,
  });

  @override
  String get $type => 'internal';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'Cause': ByteUtils.bytesToJson(Cause),
      'TransactionHash': ByteUtils.bytesToJson(TransactionHash),
    };

  static InternalSignature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = InternalSignature(
      Cause: (() { final bytes = ByteUtils.bytesFromJson(j['Cause'] as String); ByteUtils.validateLength(bytes, 32, 'Cause'); return bytes; })(),
      TransactionHash: (() { final bytes = ByteUtils.bytesFromJson(j['TransactionHash'] as String); ByteUtils.validateLength(bytes, 32, 'TransactionHash'); return bytes; })(),
    );
    return instance;
  }

}
