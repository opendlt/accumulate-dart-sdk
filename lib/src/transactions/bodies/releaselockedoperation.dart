import 'dart:typed_data';
import '../../runtime/validate.dart';
import '../transaction.dart';

/// ReleaseLockedOperation (user transaction, type 0x18, Accumulate 1.4.6.7)
///
/// Matches Go: protocol/user_transactions.yml ReleaseLockedOperation
/// Fields: 1 Type, 2 LockedTxID (txid), 3 Preimage (bytes).
/// JSON uses hex for [Preimage], as Go does.
class ReleaseLockedOperation extends TransactionBody {
  /// Transaction ID of the locked transaction (acc://<hash>@<account>)
  final String LockedTxID;

  /// Preimage of the hash lock
  final Uint8List Preimage;

  const ReleaseLockedOperation({
    required this.LockedTxID,
    required this.Preimage,
  });

  @override
  String get $type => 'releaselockedoperation';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'releaselockedoperation',
    'lockedTxID': LockedTxID,
    'preimage': _hex(Preimage),
  };

  static ReleaseLockedOperation fromJson(Map<String, dynamic> j) {
    final p = j['preimage'] ?? j['Preimage'];
    return ReleaseLockedOperation(
      LockedTxID: (j['lockedTxID'] ?? j['LockedTxID']) as String,
      Preimage: p is Uint8List ? p : _unhex(p as String),
    );
  }

  @override
  bool validate() {
    try {
      Validate.required(LockedTxID, 'LockedTxID');
      if (!LockedTxID.startsWith('acc://')) return false;
      if (Preimage.isEmpty) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static String _hex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _unhex(String h) => Uint8List.fromList(List<int>.generate(
      h.length ~/ 2, (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16)));
}
