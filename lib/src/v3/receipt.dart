/// A v3 API receipt: a merkle receipt together with the block it was produced
/// against.
///
/// Matches Go: pkg/api/v3/types.yml Receipt. Query results are untyped; call
/// [Receipt.fromJson] on the `receipt` object for typed access. Every new field
/// is optional so responses from older nodes still parse.
class Receipt {
  // ---- the embedded merkle receipt ----

  /// Hex of the hash the receipt starts at.
  final String? start;
  final int startIndex;

  /// Hex of the hash the receipt ends at.
  final String? end;
  final int endIndex;

  /// Hex of the anchor (the root the receipt proves into).
  final String? anchor;

  /// Merkle path entries, each `{"right": bool, "hash": hex}`.
  final List<Map<String, dynamic>> entries;

  // ---- block context ----

  final int localBlock;
  final DateTime? localBlockTime;
  final int majorBlock;

  /// The minor block height the receipt was produced against; 0 means the
  /// current state.
  final int forHeight;

  /// The receipt terminates at a directory root, so there is no second call to
  /// make. When false, [partition] names the BPT root it ends at and the caller
  /// continues with `anchorReceipt`.
  final bool complete;

  /// When not [complete], whose BPT root the receipt terminates at.
  final String? partition;

  /// Set only on a historical receipt: the receipt starts at a plain hash of
  /// the account's main state, and the account served beside it is that state as
  /// of [forHeight]. Without it the receipt starts at the account's whole BPT
  /// entry and no account body is served.
  final bool startsAtMainState;

  const Receipt({
    this.start,
    this.startIndex = 0,
    this.end,
    this.endIndex = 0,
    this.anchor,
    this.entries = const [],
    this.localBlock = 0,
    this.localBlockTime,
    this.majorBlock = 0,
    this.forHeight = 0,
    this.complete = false,
    this.partition,
    this.startsAtMainState = false,
  });

  factory Receipt.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) => v == null ? 0 : (v as num).toInt();
    return Receipt(
      start: j["start"] as String?,
      startIndex: asInt(j["startIndex"]),
      end: j["end"] as String?,
      endIndex: asInt(j["endIndex"]),
      anchor: j["anchor"] as String?,
      entries: ((j["entries"] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      localBlock: asInt(j["localBlock"]),
      localBlockTime: j["localBlockTime"] != null
          ? DateTime.parse(j["localBlockTime"] as String)
          : null,
      majorBlock: asInt(j["majorBlock"]),
      forHeight: asInt(j["forHeight"]),
      complete: j["complete"] == true,
      partition: j["partition"] as String?,
      startsAtMainState: j["startsAtMainState"] == true,
    );
  }
}
