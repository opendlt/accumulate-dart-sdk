/// RemoteSignature signature implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// RemoteSignature signature
final class RemoteSignature extends Signature {
  const RemoteSignature({
    required this.destination,
    required this.signature,
    required this.cause,
  });

  final String destination;
  final Signature signature;
  final Uint8List cause;

  @override
  String get $type => 'RemoteSignature';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['Destination'] = destination;
    json['Signature'] = signature;
    json['Cause'] = ByteUtils.bytesToJson(cause);
    return json;
  }

  /// Parse from JSON
  static {sig_name}? fromJson(Map<String, dynamic> json) {{
    try {{
      final destination = json['Destination'] as String;
      final signature = json['Signature'];
      final cause = ByteUtils.bytesFromJson(json['Cause'] as String);

      return RemoteSignature(
        destination: destination,
        signature: signature,
        cause: cause,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature fields
  bool validate() {
    if (!AccumulateUrl.isValid(destination)) return false;
    if (!ByteUtils.validateHash(cause)) return false;
    return true;
  }
}
