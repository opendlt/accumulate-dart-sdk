library signatures;

import 'dart:typed_data';
import '../enums.dart';
import '../runtime/validate.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';

part 'authoritysignature_signature.dart';
part 'btclegacysignature_signature.dart';
part 'btcsignature_signature.dart';
part 'delegatedsignature_signature.dart';
part 'ecdsasha256signature_signature.dart';
part 'ed25519signature_signature.dart';
part 'ethsignature_signature.dart';
part 'internalsignature_signature.dart';
part 'legacyed25519signature_signature.dart';
part 'partitionsignature_signature.dart';
part 'rcd1signature_signature.dart';
part 'receiptsignature_signature.dart';
part 'remotesignature_signature.dart';
part 'rsasha256signature_signature.dart';
part 'signatureset_signature.dart';
part 'typeddatasignature_signature.dart';

abstract class Signature {
  const Signature();

  String get $type;

  Map<String, dynamic> toJson();

  static Signature fromJson(Map<String, dynamic> j, [int depth = 0]) => parseSignature(j, depth);

  static Signature parseSignature(Map<String, dynamic> j, [int depth = 0]) {
    final key = j.containsKey('type') ? 'type' : (j.containsKey(r'$type') ? r'$type' : null);
    if (key == null) {
      throw ArgumentError('Signature missing discriminant key');
    }

    switch (j[key]) {
        case 'legacyed25519': return LegacyED25519Signature.fromJson(j, depth);
        case 'rcd1': return RCD1Signature.fromJson(j, depth);
        case 'ed25519': return ED25519Signature.fromJson(j, depth);
        case 'btc': return BTCSignature.fromJson(j, depth);
        case 'btclegacy': return BTCLegacySignature.fromJson(j, depth);
        case 'eth': return ETHSignature.fromJson(j, depth);
        case 'rsa': return RsaSha256Signature.fromJson(j, depth);
        case 'ecdsa': return EcdsaSha256Signature.fromJson(j, depth);
        case 'typeddata': return TypedDataSignature.fromJson(j, depth);
        case 'receipt': return ReceiptSignature.fromJson(j, depth);
        case 'Partition': return PartitionSignature.fromJson(j, depth);
        case 'Set': return SignatureSet.fromJson(j, depth);
        case 'remote': return RemoteSignature.fromJson(j, depth);
        case 'delegated': return DelegatedSignature.fromJson(j, depth);
        case 'internal': return InternalSignature.fromJson(j, depth);
        case 'authority': return AuthoritySignature.fromJson(j, depth);
      default:
        throw ArgumentError('Unknown signature type: ${j[key]}');
    }
  }
}

// Type alias to avoid naming conflicts
typedef BaseSignature = Signature;
