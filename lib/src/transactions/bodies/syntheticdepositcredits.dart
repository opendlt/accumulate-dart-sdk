import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SyntheticDepositCredits extends TransactionBody {
  final dynamic Amount;
  final BigInt AcmeRefundAmount;
  final bool IsRefund;

  const SyntheticDepositCredits({
    required this.Amount,
    required this.AcmeRefundAmount,
    required this.IsRefund,
  });

  @override
  String get $type => 'syntheticdepositcredits';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticdepositcredits',
    'Amount': Amount,
    'AcmeRefundAmount': AcmeRefundAmount,
    'IsRefund': IsRefund,
  };

  static SyntheticDepositCredits fromJson(Map<String, dynamic> j) {
    return SyntheticDepositCredits(
      Amount: j['Amount'] as dynamic,
      AcmeRefundAmount: j['AcmeRefundAmount'] as BigInt,
      IsRefund: j['IsRefund'] as bool,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Amount, 'Amount');
      Validate.required(AcmeRefundAmount, 'AcmeRefundAmount');
      Validate.required(IsRefund, 'IsRefund');
      return true;
    } catch (e) {
      return false;
    }
  }
}
