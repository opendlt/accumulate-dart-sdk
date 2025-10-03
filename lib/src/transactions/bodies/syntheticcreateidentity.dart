import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SyntheticCreateIdentity extends TransactionBody {
  final dynamic Accounts;

  const SyntheticCreateIdentity({
    required this.Accounts,
  });

  @override
  String get $type => 'syntheticcreateidentity';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticcreateidentity',
    'Accounts': Accounts,
  };

  static SyntheticCreateIdentity fromJson(Map<String, dynamic> j) {
    return SyntheticCreateIdentity(
      Accounts: j['Accounts'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Accounts, 'Accounts');
      return true;
    } catch (e) {
      return false;
    }
  }
}
