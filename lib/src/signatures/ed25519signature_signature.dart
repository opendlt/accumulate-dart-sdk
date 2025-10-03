part of 'signatures.dart';
final class ED25519Signature extends Signature {
  final Uint8List PublicKey;
  final Uint8List Signature;
  final String Signer;
  final int SignerVersion;
  final int? Timestamp;
  final dynamic? Vote;
  final Uint8List? TransactionHash;
  final String? Memo;
  final Uint8List? Data;

  const ED25519Signature({
    required this.PublicKey,
    required this.Signature,
    required this.Signer,
    required this.SignerVersion,
    this.Timestamp,
    this.Vote,
    this.TransactionHash,
    this.Memo,
    this.Data,
  });

  @override
  String get $type => 'ed25519';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'PublicKey': ByteUtils.bytesToJson(PublicKey),
      'Signature': ByteUtils.bytesToJson(Signature),
      'Signer': Signer,
      'SignerVersion': SignerVersion,
      if (Timestamp != null) 'Timestamp': Timestamp,
      if (Vote != null) 'Vote': Vote,
      if (TransactionHash != null) 'TransactionHash': ByteUtils.bytesToJson(TransactionHash!),
      if (Memo != null) 'Memo': Memo,
      if (Data != null) 'Data': ByteUtils.bytesToJson(Data!),
    };

  static ED25519Signature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = ED25519Signature(
      PublicKey: ByteUtils.bytesFromJson(j['PublicKey'] as String),
      Signature: ByteUtils.bytesFromJson(j['Signature'] as String),
      Signer: j['Signer'] as String,
      SignerVersion: j['SignerVersion'] as int,
      Timestamp: j['Timestamp'] as int?,
      Vote: j['Vote'] as dynamic?,
      TransactionHash: j['TransactionHash'] != null ? (() { final bytes = ByteUtils.bytesFromJson(j['TransactionHash'] as String); ByteUtils.validateLength(bytes, 32, 'TransactionHash'); return bytes; })() : null,
      Memo: j['Memo'] as String?,
      Data: j['Data'] != null ? ByteUtils.bytesFromJson(j['Data'] as String) : null,
    );
    return instance;
  }

}
