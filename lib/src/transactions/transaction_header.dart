import 'dart:typed_data';
import '../runtime/validate.dart';
import '../runtime/bytes.dart';
import '../build/context.dart';

/// Transaction header structure
///
/// Matches Go: protocol/transaction.yml TransactionHeader
/// Fields:
/// - Principal: The account URL initiating the transaction
/// - Initiator: Hash of the signature metadata (computed automatically)
/// - Memo: Optional transaction memo
/// - Metadata: Optional arbitrary metadata bytes
/// - Expire: Optional expiration options
/// - HoldUntil: Optional hold until options
/// - Authorities: Optional list of additional authority URLs
class TransactionHeader {
  /// The account URL initiating the transaction
  final String Principal;

  /// Hash of the signature metadata (computed automatically)
  final dynamic Initiator;

  /// Optional transaction memo
  final String? Memo;

  /// Optional arbitrary metadata bytes
  final Uint8List? Metadata;

  /// Optional expiration options
  final ExpireOptions? Expire;

  /// Optional hold until options
  final HoldUntilOptions? HoldUntil;

  /// Optional list of additional authority URLs
  ///
  /// Fixed: Changed from String? to List<String>? to match Go core
  final List<String>? Authorities;

  const TransactionHeader({
    required this.Principal,
    required this.Initiator,
    this.Memo,
    this.Metadata,
    this.Expire,
    this.HoldUntil,
    this.Authorities,
  });

  Map<String, dynamic> toJson() => {
        'Principal': Principal,
        'Initiator': Initiator,
        if (Memo != null) 'Memo': Memo,
        if (Metadata != null) 'Metadata': ByteUtils.bytesToJson(Metadata!),
        if (Expire != null) 'Expire': Expire!.toJson(),
        if (HoldUntil != null) 'HoldUntil': HoldUntil!.toJson(),
        if (Authorities != null && Authorities!.isNotEmpty)
          'Authorities': Authorities,
      };

  static TransactionHeader fromJson(Map<String, dynamic> j) {
    return TransactionHeader(
      Principal: j['Principal'] as String,
      Initiator: j['Initiator'] as dynamic,
      Memo: j['Memo'] as String?,
      Metadata: j['Metadata'] != null
          ? ByteUtils.bytesFromJson(j['Metadata'] as String)
          : null,
      Expire: j['Expire'] != null
          ? ExpireOptions(
              atTime: j['Expire']['atTime'] != null
                  ? DateTime.parse(j['Expire']['atTime'] as String)
                  : null)
          : null,
      HoldUntil: j['HoldUntil'] != null
          ? HoldUntilOptions(minorBlock: j['HoldUntil']['minorBlock'] as int?)
          : null,
      Authorities: j['Authorities'] != null
          ? (j['Authorities'] as List).cast<String>()
          : null,
    );
  }

  bool validate() {
    try {
      Validate.required(Principal, 'Principal');
      if (!Principal.startsWith('acc://')) return false;
      Validate.required(Initiator, 'Initiator');
      if (Authorities != null) {
        for (final auth in Authorities!) {
          if (!auth.startsWith('acc://')) return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
