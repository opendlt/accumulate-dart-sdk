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

import 'dart:math' as math;

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

  /// Create from whole units of a **custom token** with the given [precision].
  ///
  /// Custom tokens declare their own precision at creation; the wire format is
  /// always base units. `Amount.token(1000, 8)` is 1000 whole tokens =
  /// `100000000000` base units.
  ///
  /// Without this the only options are hand-computing a power of ten or passing
  /// a raw base-unit string, and both are routinely got wrong: issuing `1000`
  /// against a precision-8 token mints `0.00001` tokens, not 1000 — and the
  /// transaction succeeds either way, so the mistake is silent.
  ///
  /// ```dart
  /// Amount.token(1000, 8).toWire(); // '100000000000'
  /// Amount.token(100, 2).toWire();  // '10000'
  /// Amount.token(1000, 0).toWire(); // '1000'
  /// ```
  factory Amount.token(num wholeTokens, int precision) {
    final scale = BigInt.from(10).pow(precision);
    if (wholeTokens is int) {
      return Amount(BigInt.from(wholeTokens) * scale);
    }
    return Amount(BigInt.from((wholeTokens * math.pow(10, precision)).round()));
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

  /// The amount in whole units of a token with the given [precision].
  ///
  /// ```dart
  /// Amount.baseUnitsOf('100000000000').toToken(8); // 1000.0
  /// ```
  double toToken(int precision) => baseUnits / BigInt.from(10).pow(precision);

  @override
  String toString() => toWire();

  @override
  bool operator ==(Object other) => other is Amount && other.baseUnits == baseUnits;

  @override
  int get hashCode => baseUnits.hashCode;
}
