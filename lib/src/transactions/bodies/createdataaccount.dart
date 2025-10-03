import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateDataAccount extends TransactionBody {
  final String Url;
  final String? Authorities;

  const CreateDataAccount({
    required this.Url,
    this.Authorities,
  });

  @override
  String get $type => 'createdataaccount';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createdataaccount',
    'Url': Url,
    if (Authorities != null) 'Authorities': Authorities,
  };

  static CreateDataAccount fromJson(Map<String, dynamic> j) {
    return CreateDataAccount(
      Url: j['Url'] as String,
      Authorities: j['Authorities'] as String?,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Url, 'Url');
      if (!Url.startsWith('acc://')) return false;
      if (Authorities != null && !Authorities!.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
