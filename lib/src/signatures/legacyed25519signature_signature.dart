part of 'signatures.dart';
final class LegacyED25519Signature extends Signature {
  final int Timestamp;
  final Uint8List PublicKey;
  final Uint8List Signature;
  final String Signer;
  final int SignerVersion;
  final dynamic? Vote;
  final Uint8List? TransactionHash;

  const LegacyED25519Signature({
    required this.Timestamp,
    required this.PublicKey,
    required this.Signature,
    required this.Signer,
    required this.SignerVersion,
    this.Vote,
    this.TransactionHash,
  });

  @override
  String get $type => 'legacyed25519';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'Timestamp': Timestamp,
      'PublicKey': ByteUtils.bytesToJson(PublicKey),
      'Signature': ByteUtils.bytesToJson(Signature),
      'Signer': Signer,
      'SignerVersion': SignerVersion,
      if (Vote != null) 'Vote': Vote,
      if (TransactionHash != null) 'TransactionHash': ByteUtils.bytesToJson(TransactionHash!),
    };

  static LegacyED25519Signature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = LegacyED25519Signature(
      Timestamp: j['Timestamp'] as int,
      PublicKey: ByteUtils.bytesFromJson(j['PublicKey'] as String),
      Signature: ByteUtils.bytesFromJson(j['Signature'] as String),
      Signer: j['Signer'] as String,
      SignerVersion: j['SignerVersion'] as int,
      Vote: j['Vote'] as dynamic?,
      TransactionHash: j['TransactionHash'] != null ? (() { final bytes = ByteUtils.bytesFromJson(j['TransactionHash'] as String); ByteUtils.validateLength(bytes, 32, 'TransactionHash'); return bytes; })() : null,
    );
    return instance;
  }

}
