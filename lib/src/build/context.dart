import "dart:typed_data";

/// Options for transaction expiration
///
/// Matches Go: protocol/transaction.yml ExpireOptions
class ExpireOptions {
  /// Time at which the transaction expires
  final DateTime? atTime;

  const ExpireOptions({this.atTime});

  Map<String, dynamic> toJson() => {
        if (atTime != null) "atTime": atTime!.toUtc().toIso8601String(),
      };

  bool get isEmpty => atTime == null;
}

/// Options for holding a transaction until a specific block
///
/// Matches Go: protocol/transaction.yml HoldUntilOptions
class HoldUntilOptions {
  /// The minor block number to hold until
  final int? minorBlock;

  const HoldUntilOptions({this.minorBlock});

  Map<String, dynamic> toJson() => {
        if (minorBlock != null) "minorBlock": minorBlock,
      };

  bool get isEmpty => minorBlock == null;
}

/// Build context for transaction construction
///
/// Contains all fields from Go's TransactionHeader:
/// - principal: The account URL initiating the transaction
/// - timestamp: Transaction timestamp (microseconds since epoch)
/// - memo: Optional transaction memo
/// - metadata: Optional arbitrary metadata bytes
/// - expire: Optional expiration options
/// - holdUntil: Optional hold until options
/// - authorities: Optional list of additional authority URLs
class BuildContext {
  /// The account URL initiating the transaction
  final String principal;

  /// Transaction timestamp (microseconds since epoch)
  final int timestamp;

  /// Optional transaction memo
  final String? memo;

  /// Optional arbitrary metadata bytes
  final Uint8List? metadata;

  /// Optional expiration options
  final ExpireOptions? expire;

  /// Optional hold until options
  final HoldUntilOptions? holdUntil;

  /// Optional list of additional authority URLs
  final List<String>? authorities;

  const BuildContext({
    required this.principal,
    required this.timestamp,
    this.memo,
    this.metadata,
    this.expire,
    this.holdUntil,
    this.authorities,
  });

  /// Create a build context with current timestamp
  factory BuildContext.now({
    required String principal,
    String? memo,
    Uint8List? metadata,
    ExpireOptions? expire,
    HoldUntilOptions? holdUntil,
    List<String>? authorities,
  }) {
    return BuildContext(
      principal: principal,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      memo: memo,
      metadata: metadata,
      expire: expire,
      holdUntil: holdUntil,
      authorities: authorities,
    );
  }

  /// Convert to header JSON format
  ///
  /// Produces JSON matching Go's TransactionHeader structure:
  /// - Field 1: principal (URL)
  /// - Field 2: initiator (computed by signer)
  /// - Field 3: memo (string)
  /// - Field 4: metadata (bytes)
  /// - Field 5: expire (nested)
  /// - Field 6: holdUntil (nested)
  /// - Field 7: authorities (repeated URLs)
  ///
  /// NOTE: timestamp is NOT part of TransactionHeader - it's part of the signature!
  Map<String, dynamic> headerJson() => {
        "principal": principal,
        if (memo != null && memo!.isNotEmpty) "memo": memo,
        if (metadata != null && metadata!.isNotEmpty)
          "metadata": _toHex(metadata!),
        if (expire != null && !expire!.isEmpty) "expire": expire!.toJson(),
        if (holdUntil != null && !holdUntil!.isEmpty)
          "holdUntil": holdUntil!.toJson(),
        if (authorities != null && authorities!.isNotEmpty)
          "authorities": authorities,
      };

  /// Copy with modifications
  BuildContext copyWith({
    String? principal,
    int? timestamp,
    String? memo,
    Uint8List? metadata,
    ExpireOptions? expire,
    HoldUntilOptions? holdUntil,
    List<String>? authorities,
  }) {
    return BuildContext(
      principal: principal ?? this.principal,
      timestamp: timestamp ?? this.timestamp,
      memo: memo ?? this.memo,
      metadata: metadata ?? this.metadata,
      expire: expire ?? this.expire,
      holdUntil: holdUntil ?? this.holdUntil,
      authorities: authorities ?? this.authorities,
    );
  }

  static String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
