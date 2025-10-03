import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class LockAccount extends TransactionBody {
  final int Height;

  const LockAccount({
    required this.Height,
  });

  @override
  String get $type => 'lockaccount';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'lockaccount',
    'Height': Height,
  };

  static LockAccount fromJson(Map<String, dynamic> j) {
    return LockAccount(
      Height: j['Height'] as int,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Height, 'Height');
      return true;
    } catch (e) {
      return false;
    }
  }
}
