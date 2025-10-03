/// AuthoritySignature signature implementation
library;

import 'dart:convert';
import 'dart:typed_data';
import '../runtime/canonical_json.dart';
import '../runtime/bytes.dart';
import '../runtime/url.dart';
import '../enums.dart';
import 'signatures.dart';

/// AuthoritySignature signature
final class AuthoritySignature extends Signature {
  const AuthoritySignature({
    required this.origin,
    required this.authority,
    this.vote,
    required this.txID,
    required this.cause,
    required this.delegator,
    this.memo,
  });

  final String origin;
  final String authority;
  final VoteType? vote;
  final String txID;
  final String cause;
  final String delegator;
  final String? memo;

  @override
  String get $type => 'AuthoritySignature';

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['\$type'] = $type;
    json['Origin'] = origin;
    json['Authority'] = authority;
    if (vote != null) {
      json['Vote'] = vote;
    }
    json['TxID'] = txID;
    json['Cause'] = cause;
    json['Delegator'] = delegator;
    if (memo != null) {
      json['Memo'] = memo;
    }
    return json;
  }

  /// Parse from JSON
  static {sig_name}? fromJson(Map<String, dynamic> json) {{
    try {{
      final origin = json['Origin'] as String;
      final authority = json['Authority'] as String;
      final vote = json['Vote'];
      final txID = json['TxID'];
      final cause = json['Cause'];
      final delegator = json['Delegator'] as String;
      final memo = json['Memo'] as String?;

      return AuthoritySignature(
        origin: origin,
        authority: authority,
        vote: vote,
        txID: txID,
        cause: cause,
        delegator: delegator,
        memo: memo,
      );
    } catch (e) {
      return null;
    }
  }

  /// Validate signature fields
  bool validate() {
    if (!AccumulateUrl.isValid(origin)) return false;
    if (!AccumulateUrl.isValid(authority)) return false;
    if (!AccumulateUrl.isValid(delegator)) return false;
    return true;
  }
}
