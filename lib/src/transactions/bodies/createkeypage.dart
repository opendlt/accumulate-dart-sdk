import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateKeyPage extends TransactionBody {
  final dynamic Keys;

  const CreateKeyPage({
    required this.Keys,
  });

  @override
  String get $type => 'createkeypage';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createkeypage',
    'Keys': Keys,
  };

  static CreateKeyPage fromJson(Map<String, dynamic> j) {
    return CreateKeyPage(
      Keys: j['Keys'] as dynamic,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Keys, 'Keys');
      return true;
    } catch (e) {
      return false;
    }
  }
}
