import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../../runtime/bytes.dart';
import '../transaction.dart';

class CreateToken extends TransactionBody {
  final String Url;
  final String Symbol;
  final dynamic Precision;
  final String? Properties;
  final BigInt? SupplyLimit;
  final String? Authorities;

  const CreateToken({
    required this.Url,
    required this.Symbol,
    required this.Precision,
    this.Properties,
    this.SupplyLimit,
    this.Authorities,
  });

  @override
  String get $type => 'createtoken';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'createtoken',
    'Url': Url,
    'Symbol': Symbol,
    'Precision': Precision,
    if (Properties != null) 'Properties': Properties,
    if (SupplyLimit != null) 'SupplyLimit': SupplyLimit,
    if (Authorities != null) 'Authorities': Authorities,
  };

  static CreateToken fromJson(Map<String, dynamic> j) {
    return CreateToken(
      Url: j['Url'] as String,
      Symbol: j['Symbol'] as String,
      Precision: j['Precision'] as dynamic,
      Properties: j['Properties'] as String?,
      SupplyLimit: j['SupplyLimit'] as BigInt?,
      Authorities: j['Authorities'] as String?,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Url, 'Url');
      if (!Url.startsWith('acc://')) return false;
      Validate.required(Symbol, 'Symbol');
      Validate.required(Precision, 'Precision');
      if (Properties != null && !Properties!.startsWith('acc://')) return false;
      if (Authorities != null && !Authorities!.startsWith('acc://')) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
