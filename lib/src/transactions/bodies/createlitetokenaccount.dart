import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateLiteTokenAccount extends TransactionBody {


  const CreateLiteTokenAccount();

  @override
  String get $type => 'createlitetokenaccount';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createlitetokenaccount',
  };

  static CreateLiteTokenAccount fromJson(Map<String, dynamic> j) {
    return CreateLiteTokenAccount(

    );
  }

  @override
  bool validate() {
    try {

      return true;
    } catch (e) {
      return false;
    }
  }
}
