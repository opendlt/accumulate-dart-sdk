import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SyntheticBurnTokens extends TransactionBody {
  final BigInt Amount;
  final bool IsRefund;

  const SyntheticBurnTokens({
    required this.Amount,
    required this.IsRefund,
  });

  @override
  String get $type => 'syntheticburntokens';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticburntokens',
    'Amount': Amount,
    'IsRefund': IsRefund,
  };

  static SyntheticBurnTokens fromJson(Map<String, dynamic> j) {
    return SyntheticBurnTokens(
      Amount: j['Amount'] as BigInt,
      IsRefund: j['IsRefund'] as bool,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Amount, 'Amount');
      Validate.required(IsRefund, 'IsRefund');
      return true;
    } catch (e) {
      return false;
    }
  }
}
