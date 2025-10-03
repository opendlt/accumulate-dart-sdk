import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class UpdateAccountAuth extends TransactionBody {
  final dynamic Operations;

  const UpdateAccountAuth({
    required this.Operations,
  });

  @override
  String get $type => 'updateaccountauth';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'updateaccountauth',
    'Operations': Operations,
  };

  static UpdateAccountAuth fromJson(Map<String, dynamic> j) {
    return UpdateAccountAuth(
      Operations: j['Operations'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Operations, 'Operations');
      return true;
    } catch (e) {
      return false;
    }
  }
}
