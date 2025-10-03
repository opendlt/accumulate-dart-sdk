import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SyntheticForwardTransaction extends TransactionBody {
  final dynamic Signatures;
  final dynamic? Transaction;

  const SyntheticForwardTransaction({
    required this.Signatures,
    this.Transaction,
  });

  @override
  String get $type => 'syntheticforwardtransaction';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticforwardtransaction',
    'Signatures': Signatures,
    if (Transaction != null) 'Transaction': Transaction,
  };

  static SyntheticForwardTransaction fromJson(Map<String, dynamic> j) {
    return SyntheticForwardTransaction(
      Signatures: j['Signatures'] as dynamic,
      Transaction: j['Transaction'] as dynamic?,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Signatures, 'Signatures');
      return true;
    } catch (e) {
      return false;
    }
  }
}
