import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class UpdateKeyPage extends TransactionBody {
  final dynamic Operation;

  const UpdateKeyPage({
    required this.Operation,
  });

  @override
  String get $type => 'updatekeypage';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'updatekeypage',
    'Operation': Operation,
  };

  static UpdateKeyPage fromJson(Map<String, dynamic> j) {
    return UpdateKeyPage(
      Operation: j['Operation'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Operation, 'Operation');
      return true;
    } catch (e) {
      return false;
    }
  }
}
