import 'dart:typed_data';
import '../../enums.dart' show HashAlgorithm;
import '../../runtime/validate.dart';
import '../transaction.dart';

/// SyntheticLockedDeposit (synthetic transaction, type 0x37, Accumulate 1.4.6.7)
///
/// Matches Go: protocol/synthetic_transactions.yml SyntheticLockedDeposit.
/// Embeds SyntheticOrigin (Cause txid, Initiator url, FeeRefund, Index).
/// Binary fields: 1 Type, 2 SyntheticOrigin, 3 Token, 4 Amount, 5 Sender,
/// 6 HashAlgorithm, 7 Hash, 8 Expiration, 9 IsIssuer.
/// JSON uses hex for [Hash], as Go does.
class SyntheticLockedDeposit extends TransactionBody {
  // SyntheticOrigin
  final String Cause;
  final String Initiator;
  final int FeeRefund;
  final int Index;

  final String Token;
  final BigInt Amount;
  final String Sender;
  final HashAlgorithm HashAlgorithmValue;
  final Uint8List Hash;
  final DateTime? Expiration;
  final bool IsIssuer;

  const SyntheticLockedDeposit({
    required this.Cause,
    required this.Initiator,
    this.FeeRefund = 0,
    this.Index = 0,
    required this.Token,
    required this.Amount,
    required this.Sender,
    required this.HashAlgorithmValue,
    required this.Hash,
    this.Expiration,
    this.IsIssuer = false,
  });

  @override
  String get $type => 'syntheticlockeddeposit';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'syntheticlockeddeposit',
    'cause': Cause,
    'initiator': Initiator,
    if (FeeRefund != 0) 'feeRefund': FeeRefund,
    if (Index != 0) 'index': Index,
    'token': Token,
    'amount': Amount.toString(),
    'sender': Sender,
    'hashAlgorithm': HashAlgorithmValue.toJson(),
    'hash': Hash.map((x) => x.toRadixString(16).padLeft(2, '0')).join(),
    if (Expiration != null) 'expiration': Expiration!.toUtc().toIso8601String(),
    if (IsIssuer) 'isIssuer': true,
  };

  static SyntheticLockedDeposit fromJson(Map<String, dynamic> j) {
    final h = j['hash'];
    final a = j['amount'];
    return SyntheticLockedDeposit(
      Cause: j['cause'] as String,
      Initiator: j['initiator'] as String,
      FeeRefund: (j['feeRefund'] as num?)?.toInt() ?? 0,
      Index: (j['index'] as num?)?.toInt() ?? 0,
      Token: j['token'] as String,
      Amount: a is BigInt ? a : BigInt.parse(a.toString()),
      Sender: j['sender'] as String,
      HashAlgorithmValue: HashAlgorithm.fromJson(j['hashAlgorithm'] as Object),
      Hash: h is Uint8List
          ? h
          : Uint8List.fromList(List<int>.generate((h as String).length ~/ 2,
              (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16))),
      Expiration:
          j['expiration'] != null ? DateTime.parse(j['expiration'] as String) : null,
      IsIssuer: (j['isIssuer'] as bool?) ?? false,
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(Cause, 'Cause');
      Validate.required(Token, 'Token');
      if (!Token.startsWith('acc://')) return false;
      Validate.required(Sender, 'Sender');
      if (!Sender.startsWith('acc://')) return false;
      if (Amount <= BigInt.zero) return false;
      if (HashAlgorithmValue == HashAlgorithm.Unknown) return false;
      if (Hash.isEmpty) return false;
      return true;
    } catch (e) {
      return false;
    }
  }
}
