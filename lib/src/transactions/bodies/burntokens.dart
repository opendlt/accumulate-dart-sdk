import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class BurnTokens extends TransactionBody {
  final BigInt Amount;

  const BurnTokens({
    required this.Amount,
  });

  @override
  String get $type => 'burntokens';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'burntokens',
    'Amount': Amount,
  };

  static BurnTokens fromJson(Map<String, dynamic> j) {
    return BurnTokens(
      Amount: j['Amount'] as BigInt,
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
