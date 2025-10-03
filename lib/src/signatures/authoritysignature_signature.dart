part of 'signatures.dart';
final class AuthoritySignature extends Signature {
  final String Origin;
  final String Authority;
  final dynamic? Vote;
  final Uint8List TxID;
  final Uint8List Cause;
  final List<String> Delegator;
  final String? Memo;

  const AuthoritySignature({
    required this.Origin,
    required this.Authority,
    this.Vote,
    required this.TxID,
    required this.Cause,
    required this.Delegator,
    this.Memo,
  });

  @override
  String get $type => 'authority';

  @override
  Map<String, dynamic> toJson() => {
      'type': $type,
      'Origin': Origin,
      'Authority': Authority,
      if (Vote != null) 'Vote': Vote,
      'TxID': ByteUtils.bytesToJson(TxID),
      'Cause': ByteUtils.bytesToJson(Cause),
      'Delegator': Delegator,
      if (Memo != null) 'Memo': Memo,
    };

  static AuthoritySignature fromJson(Map<String, dynamic> j, [int depth = 0]) {
    final instance = AuthoritySignature(
      Origin: j['Origin'] as String,
      Authority: j['Authority'] as String,
      Vote: j['Vote'] as dynamic?,
      TxID: (() { final bytes = ByteUtils.bytesFromJson(j['TxID'] as String); ByteUtils.validateLength(bytes, 32, 'TxID'); return bytes; })(),
      Cause: (() { final bytes = ByteUtils.bytesFromJson(j['Cause'] as String); ByteUtils.validateLength(bytes, 32, 'Cause'); return bytes; })(),
      Delegator: j['Delegator'] as List<String>,
      Memo: j['Memo'] as String?,
    );
    return instance;
  }

}
