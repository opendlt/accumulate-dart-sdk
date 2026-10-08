import "dart:typed_data";
import "../enums.dart" show HashAlgorithm;

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

/// Hash lock options (TransactionHeader field 8, Accumulate 1.4.6.7)
///
/// Matches Go: protocol/transaction.yml HashLockOptions
/// JSON: `{"hashAlgorithm": "sha256", "hash": "<hex>", "expiration": "<RFC3339>"}`
class HashLockOptions {
  /// Hash algorithm (sha256 / sha256D / hash160)
  final HashAlgorithm hashAlgorithm;

  /// The locking hash (32 bytes for sha256/sha256D, 20 bytes for hash160)
  final Uint8List hash;

  /// Optional expiration of the lock
  final DateTime? expiration;

  const HashLockOptions({
    required this.hashAlgorithm,
    required this.hash,
    this.expiration,
  });

  /// Throws [ArgumentError] if the node would reject this lock outright.
  ///
  /// Mirrors the node's checks: a known algorithm, a hash of the right length
  /// (32 bytes for sha256/sha256D, 20 for hash160), and an expiration between
  /// 10 minutes and 30 days away. [now] is injectable for tests.
  void validateForSubmit({DateTime? now}) {
    final int want;
    switch (hashAlgorithm) {
      case HashAlgorithm.SHA256:
      case HashAlgorithm.SHA256D:
        want = 32;
        break;
      case HashAlgorithm.HASH160:
        want = 20;
        break;
      default:
        throw ArgumentError('unsupported hash algorithm: $hashAlgorithm');
    }
    if (hash.length != want) {
      throw ArgumentError(
          'hash must be $want bytes for ${hashAlgorithm.value}, got ${hash.length}');
    }
    if (expiration == null) {
      throw ArgumentError('expiration is required');
    }
    final delta = expiration!.difference(now ?? DateTime.now());
    if (delta < const Duration(minutes: 10)) {
      throw ArgumentError('expiration must be at least 10 minutes in the future');
    }
    if (delta > const Duration(days: 30)) {
      throw ArgumentError('expiration must be at most 30 days in the future');
    }
  }

  Map<String, dynamic> toJson() => {
        "hashAlgorithm": hashAlgorithm.toJson(),
        "hash": _hex(hash),
        if (expiration != null)
          "expiration": expiration!.toUtc().toIso8601String(),
      };

  static HashLockOptions fromJson(Map<String, dynamic> j) {
    final h = j["hash"];
    return HashLockOptions(
      hashAlgorithm: HashAlgorithm.fromJson(j["hashAlgorithm"] as Object),
      hash: h is Uint8List
          ? h
          : Uint8List.fromList(List<int>.generate(
              (h as String).length ~/ 2,
              (i) => int.parse(h.substring(i * 2, i * 2 + 2), radix: 16))),
      expiration:
          j["expiration"] != null ? DateTime.parse(j["expiration"] as String) : null,
    );
  }

  static String _hex(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
/// - hashLock: Optional hash lock (header field 8)
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

  /// Optional hash lock (header field 8)
  final HashLockOptions? hashLock;

  const BuildContext({
    required this.principal,
    required this.timestamp,
    this.memo,
    this.metadata,
    this.expire,
    this.holdUntil,
    this.authorities,
    this.hashLock,
  });

  /// Create a build context with current timestamp
  factory BuildContext.now({
    required String principal,
    String? memo,
    Uint8List? metadata,
    ExpireOptions? expire,
    HoldUntilOptions? holdUntil,
    List<String>? authorities,
    HashLockOptions? hashLock,
  }) {
    return BuildContext(
      principal: principal,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      memo: memo,
      metadata: metadata,
      expire: expire,
      holdUntil: holdUntil,
      authorities: authorities,
      hashLock: hashLock,
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
  /// - Field 8: hashLock (nested HashLockOptions)
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
        if (hashLock != null) "hashLock": hashLock!.toJson(),
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
    HashLockOptions? hashLock,
  }) {
    return BuildContext(
      principal: principal ?? this.principal,
      timestamp: timestamp ?? this.timestamp,
      memo: memo ?? this.memo,
      metadata: metadata ?? this.metadata,
      expire: expire ?? this.expire,
      holdUntil: holdUntil ?? this.holdUntil,
      authorities: authorities ?? this.authorities,
      hashLock: hashLock ?? this.hashLock,
    );
  }

  static String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
