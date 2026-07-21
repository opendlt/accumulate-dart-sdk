/// ACME amount helpers.
///
/// Accumulate denominates ACME in *base units* where **1 ACME = 1e8 base
/// units**. Passing whole ACME where base units are expected is the single most
/// common integration bug. Use [Amount] to convert explicitly:
///
/// ```dart
/// final body = TxBody.sendTokensSingle(
///   toUrl: 'acc://bob.acme/tokens',
///   amount: Amount.acme(5).toWire(),   // 5 ACME -> "500000000"
/// );
/// ```
library;

/// Number of decimal places in ACME (1 ACME = 10^[acmePrecision] base units).
const int acmePrecision = 8;

/// Base units in one whole ACME (1e8).
final BigInt acmeBaseUnits = BigInt.from(100000000);

/// An ACME token amount, stored internally as integer base units.
class Amount {
  /// The amount as an integer number of base units.
  final BigInt baseUnits;

  const Amount(this.baseUnits);

  /// Create from whole ACME. `Amount.acme(1)` == 1e8 base units.
  ///
  /// Accepts int (exact) or double (scaled by 1e8 and rounded).
  factory Amount.acme(num wholeAcme) {
    if (wholeAcme is int) {
      return Amount(BigInt.from(wholeAcme) * acmeBaseUnits);
    }
    return Amount(BigInt.from((wholeAcme * 100000000).round()));
  }

  /// Create from raw base units (int, String, or BigInt).
  factory Amount.baseUnitsOf(Object units) {
    if (units is BigInt) return Amount(units);
    return Amount(BigInt.parse(units.toString()));
  }

  /// ACME base units needed to buy [creditCount] credits at [oraclePrice]
  /// (the integer oracle value from the network oracle query).
  factory Amount.credits(int creditCount, int oraclePrice) {
    final base =
        (BigInt.from(creditCount) * acmeBaseUnits * BigInt.from(100)) ~/ BigInt.from(oraclePrice);
    return Amount(base);
  }

  /// Wire representation: base units as a string (what `TxBody` expects).
  String toWire() => baseUnits.toString();

  /// The amount expressed in whole ACME.
  double toAcme() => baseUnits / acmeBaseUnits;

  @override
  String toString() => toWire();

  @override
  bool operator ==(Object other) => other is Amount && other.baseUnits == baseUnits;

  @override
  int get hashCode => baseUnits.hashCode;
}
