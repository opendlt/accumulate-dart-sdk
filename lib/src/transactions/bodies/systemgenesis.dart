import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class SystemGenesis extends TransactionBody {


  const SystemGenesis();

  @override
  String get $type => 'systemgenesis';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'systemgenesis',
  };

  static SystemGenesis fromJson(Map<String, dynamic> j) {
    return SystemGenesis(

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
