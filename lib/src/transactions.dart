import 'dart:typed_data';
import 'runtime/bytes.dart';

final class TransactionHeader {
  const TransactionHeader({
    required this.principal,
    required this.initiator,
    this.memo,
  });

  final String principal;
  final Uint8List initiator;
  final String? memo;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'Principal': principal,
      'Initiator': ByteUtils.bytesToJson(initiator),
    };
    if (memo != null) json['Memo'] = memo;
    return json;
  }

  static TransactionHeader? fromJson(Map<String, dynamic> json) {
    try {
      return TransactionHeader(
        principal: json['Principal'] as String,
        initiator: ByteUtils.bytesFromJson(json['Initiator'] as String),
        memo: json['Memo'] as String?,
      );
    } catch (e) {
      return null;
    }
  }
}

sealed class TransactionBody {
  const TransactionBody();

  String get type;
  Map<String, dynamic> toJson();

  static TransactionBody? fromJson(Map<String, dynamic> json) {
    // Add transaction body type dispatch here
    return null;
  }
}

final class SendTokens extends TransactionBody {
  const SendTokens({required this.to});

  final List<Map<String, dynamic>> to;

  @override
  String get type => 'SendTokens';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'To': to,
    };
  }

  static SendTokens? fromJson(Map<String, dynamic> json) {
    try {
      final to = (json['To'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return SendTokens(to: to);
    } catch (e) {
      return null;
    }
  }
}

final class Transaction {
  const Transaction({
    required this.header,
    required this.body,
  });

  final TransactionHeader header;
  final TransactionBody body;

  Map<String, dynamic> toJson() {
    return {
      'Header': header.toJson(),
      'Body': body.toJson(),
    };
  }

  static Transaction? fromJson(Map<String, dynamic> json) {
    try {
      final header = TransactionHeader.fromJson(
        json['Header'] as Map<String, dynamic>
      );
      final body = TransactionBody.fromJson(
        json['Body'] as Map<String, dynamic>
      );

      if (header == null || body == null) return null;

      return Transaction(header: header, body: body);
    } catch (e) {
      return null;
    }
  }
}
