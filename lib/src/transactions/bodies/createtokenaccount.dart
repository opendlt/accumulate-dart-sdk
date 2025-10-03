import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateTokenAccount extends TransactionBody {
  final String Url;
  final String TokenUrl;
  final String? Authorities;
  final dynamic? Proof;

  const CreateTokenAccount({
    required this.Url,
    required this.TokenUrl,
    this.Authorities,
    this.Proof,
  });

  @override
  String get $type => 'createtokenaccount';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createtokenaccount',
    'Url': Url,
    'TokenUrl': TokenUrl,
    if (Authorities != null) 'Authorities': Authorities,
    if (Proof != null) 'Proof': Proof,
  };

  static CreateTokenAccount fromJson(Map<String, dynamic> j) {
    return CreateTokenAccount(
      Url: j['Url'] as String,
      TokenUrl: j['TokenUrl'] as String,
      Authorities: j['Authorities'] as String?,
      Proof: j['Proof'] as dynamic?,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Url, 'Url');
      if (!Url.startsWith('acc://')) return false;
      Validate.required(TokenUrl, 'TokenUrl');
      if (!TokenUrl.startsWith('acc://')) return false;
      if (Authorities != null && !Authorities!.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
