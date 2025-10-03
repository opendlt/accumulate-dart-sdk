/// TransactionHeader implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';

/// Transaction header with all metadata fields
final class TransactionHeader {
  const TransactionHeader({
    required this.principal,
    required this.initiator,
    this.memo,
    this.metadata,
    this.expire,
    this.holdUntil,
    this.authorities,
  });

  final String principal;
  final Uint8List initiator;
  final String? memo;
  final Uint8List? metadata;
  final ExpireOptions? expire;
  final HoldUntilOptions? holdUntil;
  final String? authorities;

  /// Convert to JSON representation
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['Principal'] = principal;
    json['Initiator'] = ByteUtils.bytesToJson(initiator);
    if (memo != null) {
      json['Memo'] = memo;
    }
    if (metadata != null) {
      json['Metadata'] = ByteUtils.bytesToJson(metadata!);
    }
    if (expire != null) {
      json['Expire'] = expire;
    }
    if (holdUntil != null) {
      json['HoldUntil'] = holdUntil;
    }
    if (authorities != null) {
      json['Authorities'] = authorities;
    }
    return json;
  }

  /// Parse from JSON
  static TransactionHeader? fromJson(Map<String, dynamic> json) {
    try {
      final principal = json['Principal'] as String;
      final initiator = ByteUtils.bytesFromJson(json['Initiator'] as String);
      final memo = json['Memo'] as String?;
      final metadata = json['Metadata'] != null ? ByteUtils.bytesFromJson(json['Metadata'] as String) : null;
      final expire = json['Expire'];
      final holdUntil = json['HoldUntil'];
      final authorities = json['Authorities'] as String?;

      return TransactionHeader(
        principal: principal,
        initiator: initiator,
        memo: memo,
        metadata: metadata,
        expire: expire,
        holdUntil: holdUntil,
        authorities: authorities,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate header fields
  bool validate() {
    if (!AccumulateUrl.isValid(principal)) return false;
    if (!ByteUtils.validateHash(initiator)) return false;
    if (authorities != null && !AccumulateUrl.isValid(authorities)) return false;
    return true;
  }
}
