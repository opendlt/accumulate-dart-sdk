part of 'signatures.dart';
final class SignatureSet extends Signature {
  final dynamic? Vote;
  final String Signer;
  final Uint8List? TransactionHash;
  final List<Signature> Signatures;
  final String Authority;

  const SignatureSet({
    this.Vote,
    required this.Signer,
    this.TransactionHash,
    required this.Signatures,
    required this.Authority,
  });

  @override
  String get $type => 'Set';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      if (Vote != null) 'Vote': Vote,
      'Signer': Signer,
      if (TransactionHash != null) 'TransactionHash': ByteUtils.bytesToJson(TransactionHash!),
      'Signatures': Signatures.map((s) => s.toJson()).toList(),
      'Authority': Authority,
    };

  static SignatureSet fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = SignatureSet(
      Vote: j['Vote'] as dynamic?,
      Signer: j['Signer'] as String,
      TransactionHash: j['TransactionHash'] != null ? (() { final bytes = ByteUtils.bytesFromJson(j['TransactionHash'] as String); ByteUtils.validateLength(bytes, 32, 'TransactionHash'); return bytes; })() : null,
      Signatures: (j['Signatures'] as List).map((e) => Signature.fromJson(e as Map<String, dynamic>, depth)).toList(),
      Authority: j['Authority'] as String,
    );
    Validate.signatureSetNotEmpty(instance.Signatures, 'signatures');
    return instance;
  }

}
