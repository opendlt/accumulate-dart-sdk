import 'dart:typed_data';
import '../runtime/validate.dart';
import '../runtime/bytes.dart';

class TransactionHeader {
  final String Principal;
  final dynamic Initiator;
  final String? Memo;
  final Uint8List? Metadata;
  final dynamic? Expire;
  final dynamic? HoldUntil;
  final String? Authorities;

  const TransactionHeader({
    required this.Principal,
    required this.Initiator,
    this.Memo,
    this.Metadata,
    this.Expire,
    this.HoldUntil,
    this.Authorities,
  
  });

  Map<String, dynamic> toJson() => {
    'Principal': Principal,
    'Initiator': Initiator,
    if (Memo != null) 'Memo': Memo,
    if (Metadata != null) 'Metadata': Metadata,
    if (Expire != null) 'Expire': Expire,
    if (HoldUntil != null) 'HoldUntil': HoldUntil,
    if (Authorities != null) 'Authorities': Authorities,
  };

  static TransactionHeader fromJson(Map<String, dynamic> j) {
    return TransactionHeader(
      Principal: j['Principal'] as String,
      Initiator: j['Initiator'] as dynamic,
      Memo: j['Memo'] as String?,
      Metadata: j['Metadata'] != null ? ByteUtils.bytesFromJson(j['Metadata'] as String) : null,
      Expire: j['Expire'] as dynamic?,
      HoldUntil: j['HoldUntil'] as dynamic?,
      Authorities: j['Authorities'] as String?,
    );
  }

  bool validate() {
    try {
      Validate.required(Principal, 'Principal');
      if (!Principal.startsWith('acc://')) return false;
      Validate.required(Initiator, 'Initiator');
      if (Authorities != null && !Authorities!.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
