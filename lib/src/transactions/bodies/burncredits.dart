import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class BurnCredits extends TransactionBody {
  final int Amount;

  const BurnCredits({
    required this.Amount,
  });

  @override
  String get $type => 'burncredits';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'burncredits',
    'Amount': Amount,
  };

  static BurnCredits fromJson(Map<String, dynamic> j) {
    return BurnCredits(
      Amount: j['Amount'] as int,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Amount, 'Amount');
      return true;
    } catch (e) {
      return false;
    }
  }
}
