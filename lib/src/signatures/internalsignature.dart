/// InternalSignature signature implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// InternalSignature signature
final class InternalSignature extends Signature {
  const InternalSignature({
    required this.cause,
    required this.transactionHash,
  });

  final Uint8List cause;
  final Uint8List transactionHash;

  @override
  String get $type => 'InternalSignature';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['Cause'] = ByteUtils.bytesToJson(cause);
    json['TransactionHash'] = ByteUtils.bytesToJson(transactionHash);
    return json;
  }

  /// Parse from JSON
  static {sig_name}? fromJson(Map<String, dynamic> json) {{
    try {{
      final cause = ByteUtils.bytesFromJson(json['Cause'] as String);
      final transactionHash = ByteUtils.bytesFromJson(json['TransactionHash'] as String);

      return InternalSignature(
        cause: cause,
        transactionHash: transactionHash,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature fields
  bool validate() {
    if (!ByteUtils.validateHash(cause)) return false;
    if (!ByteUtils.validateHash(transactionHash)) return false;
    return true;
  }
}
