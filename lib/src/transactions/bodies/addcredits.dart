import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class AddCredits extends TransactionBody {
  final String Recipient;
  final BigInt Amount;
  final dynamic Oracle;

  const AddCredits({
    required this.Recipient,
    required this.Amount,
    required this.Oracle,
  });

  @override
  String get $type => 'addcredits';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'addcredits',
    'Recipient': Recipient,
    'Amount': Amount,
    'Oracle': Oracle,
  };

  static AddCredits fromJson(Map<String, dynamic> j) {
    return AddCredits(
      Recipient: j['Recipient'] as String,
      Amount: j['Amount'] as BigInt,
      Oracle: j['Oracle'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Recipient, 'Recipient');
      if (!Recipient.startsWith('acc://')) return false;
      Validate.required(Amount, 'Amount');
      Validate.required(Oracle, 'Oracle');
      return true;
    } catch (e) {
      return false;
    }
  }
}
