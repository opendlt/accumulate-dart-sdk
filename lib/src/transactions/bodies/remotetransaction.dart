import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class RemoteTransaction extends TransactionBody {
  final dynamic? Hash;

  const RemoteTransaction({
    this.Hash,
  });

  @override
  String get $type => 'remotetransaction';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'remotetransaction',
    if (Hash != null) 'Hash': Hash,
  };

  static RemoteTransaction fromJson(Map<String, dynamic> j) {
    return RemoteTransaction(
      Hash: j['Hash'] as dynamic?,
    );
  }

  @override
  bool validate() {
    try {

      return true;
    } catch (e) {
      return false;
    }
  }
}
