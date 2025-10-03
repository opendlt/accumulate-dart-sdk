import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class ActivateProtocolVersion extends TransactionBody {
  final dynamic? Version;

  const ActivateProtocolVersion({
    this.Version,
  });

  @override
  String get $type => 'activateprotocolversion';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'activateprotocolversion',
    if (Version != null) 'Version': Version,
  };

  static ActivateProtocolVersion fromJson(Map<String, dynamic> j) {
    return ActivateProtocolVersion(
      Version: j['Version'] as dynamic?,
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
