/// Input validation utilities for Accumulate SDK
///
/// Provides validation functions for common input types used in transaction builders.

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  final String? field;

  const ValidationException(this.message, [this.field]);

  @override
  String toString() => field != null
      ? 'ValidationException: $message (field: $field)'
      : 'ValidationException: $message';
}

/// Validation utilities for Accumulate SDK inputs
class Validate {
  /// Validate that a URL is a valid Accumulate URL
  ///
  /// Accumulate URLs must:
  /// - Start with "acc://"
  /// - Have at least one path component
  /// - Not be empty
  ///
  /// Throws [ValidationException] if invalid.
  static void accUrl(String? url, [String fieldName = 'url']) {
    if (url == null || url.isEmpty) {
      throw ValidationException('URL cannot be empty', fieldName);
    }
    if (!url.startsWith('acc://')) {
      throw ValidationException('URL must start with "acc://"', fieldName);
    }
    final path = url.substring(6); // Remove "acc://"
    if (path.isEmpty) {
      throw ValidationException('URL must have a path after "acc://"', fieldName);
    }
  }

  /// Validate that a URL is a valid Accumulate URL (returns bool)
  static bool isValidAccUrl(String? url) {
    try {
      accUrl(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate that a string is a valid amount (positive number string)
  ///
  /// Amounts must:
  /// - Not be empty
  /// - Be a valid positive integer (as a string)
  /// - Be greater than 0 (optional, controlled by allowZero)
  ///
  /// Throws [ValidationException] if invalid.
  static void amount(String? amount, {String fieldName = 'amount', bool allowZero = false}) {
    if (amount == null || amount.isEmpty) {
      throw ValidationException('Amount cannot be empty', fieldName);
    }

    final parsed = BigInt.tryParse(amount);
    if (parsed == null) {
      throw ValidationException('Amount must be a valid integer string', fieldName);
    }

    if (!allowZero && parsed <= BigInt.zero) {
      throw ValidationException('Amount must be greater than 0', fieldName);
    }

    if (parsed < BigInt.zero) {
      throw ValidationException('Amount cannot be negative', fieldName);
    }
  }

  /// Validate that a string is a valid positive integer
  static void positiveInt(int? value, {String fieldName = 'value', bool allowZero = false}) {
    if (value == null) {
      throw ValidationException('Value cannot be null', fieldName);
    }
    if (!allowZero && value <= 0) {
      throw ValidationException('Value must be greater than 0', fieldName);
    }
    if (value < 0) {
      throw ValidationException('Value cannot be negative', fieldName);
    }
  }

  /// Validate that a string is a valid hex string
  ///
  /// Hex strings must:
  /// - Not be empty
  /// - Have even length
  /// - Contain only valid hex characters (0-9, a-f, A-F)
  /// - Optionally be a specific length in bytes
  ///
  /// Throws [ValidationException] if invalid.
  static void hexString(String? hex, {String fieldName = 'hex', int? expectedBytes}) {
    if (hex == null || hex.isEmpty) {
      throw ValidationException('Hex string cannot be empty', fieldName);
    }

    // Remove 0x prefix if present
    var cleanHex = hex;
    if (hex.startsWith('0x') || hex.startsWith('0X')) {
      cleanHex = hex.substring(2);
    }

    if (cleanHex.length % 2 != 0) {
      throw ValidationException('Hex string must have even length', fieldName);
    }

    // Check for valid hex characters
    final validHexPattern = RegExp(r'^[0-9a-fA-F]+$');
    if (!validHexPattern.hasMatch(cleanHex)) {
      throw ValidationException('Hex string contains invalid characters', fieldName);
    }

    if (expectedBytes != null && cleanHex.length != expectedBytes * 2) {
      throw ValidationException(
        'Hex string must be exactly $expectedBytes bytes (${expectedBytes * 2} chars)',
        fieldName
      );
    }
  }

  /// Validate that a string is a valid token symbol
  ///
  /// Token symbols must:
  /// - Not be empty
  /// - Be 1-10 characters long
  /// - Contain only alphanumeric characters
  ///
  /// Throws [ValidationException] if invalid.
  static void tokenSymbol(String? symbol, [String fieldName = 'symbol']) {
    if (symbol == null || symbol.isEmpty) {
      throw ValidationException('Token symbol cannot be empty', fieldName);
    }
    if (symbol.length > 10) {
      throw ValidationException('Token symbol must be 10 characters or less', fieldName);
    }
    final validPattern = RegExp(r'^[a-zA-Z0-9]+$');
    if (!validPattern.hasMatch(symbol)) {
      throw ValidationException('Token symbol must be alphanumeric', fieldName);
    }
  }

  /// Validate that a token precision is valid
  ///
  /// Precision must be between 0 and 18 (inclusive)
  static void tokenPrecision(int? precision, [String fieldName = 'precision']) {
    if (precision == null) {
      throw ValidationException('Precision cannot be null', fieldName);
    }
    if (precision < 0 || precision > 18) {
      throw ValidationException('Precision must be between 0 and 18', fieldName);
    }
  }

  /// Validate that a list is not empty
  static void notEmpty<T>(List<T>? list, [String fieldName = 'list']) {
    if (list == null || list.isEmpty) {
      throw ValidationException('List cannot be empty', fieldName);
    }
  }

  /// Validate that a string is not empty
  static void notBlank(String? value, [String fieldName = 'value']) {
    if (value == null || value.trim().isEmpty) {
      throw ValidationException('Value cannot be empty or blank', fieldName);
    }
  }

  /// Validate that a public key hash is valid (32 bytes hex)
  static void publicKeyHash(String? hash, [String fieldName = 'publicKeyHash']) {
    if (hash == null || hash.isEmpty) {
      throw ValidationException('Public key hash cannot be empty', fieldName);
    }
    hexString(hash, fieldName: fieldName, expectedBytes: 32);
  }

  /// Validate a threshold value (must be at least 1)
  static void threshold(int? value, {String fieldName = 'threshold', int? maxValue}) {
    if (value == null) {
      throw ValidationException('Threshold cannot be null', fieldName);
    }
    if (value < 1) {
      throw ValidationException('Threshold must be at least 1', fieldName);
    }
    if (maxValue != null && value > maxValue) {
      throw ValidationException('Threshold cannot exceed $maxValue', fieldName);
    }
  }
}
