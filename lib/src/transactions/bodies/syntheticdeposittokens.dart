import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SyntheticDepositTokens extends TransactionBody {
  final String Token;
  final BigInt Amount;
  final dynamic IsIssuer;
  final bool IsRefund;

  const SyntheticDepositTokens({
    required this.Token,
    required this.Amount,
    required this.IsIssuer,
    required this.IsRefund,
  });

  @override
  String get $type => 'syntheticdeposittokens';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticdeposittokens',
    'Token': Token,
    'Amount': Amount,
    'IsIssuer': IsIssuer,
    'IsRefund': IsRefund,
  };

  static SyntheticDepositTokens fromJson(Map<String, dynamic> j) {
    return SyntheticDepositTokens(
      Token: j['Token'] as String,
      Amount: j['Amount'] as BigInt,
      IsIssuer: j['IsIssuer'] as dynamic,
      IsRefund: j['IsRefund'] as bool,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Token, 'Token');
      if (!Token.startsWith('acc://')) return false;
      Validate.required(Amount, 'Amount');
      Validate.required(IsIssuer, 'IsIssuer');
      Validate.required(IsRefund, 'IsRefund');
      return true;
    } catch (e) {
      return false;
    }
  }
}
