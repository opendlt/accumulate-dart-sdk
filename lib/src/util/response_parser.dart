/// Response parsing utilities for Accumulate API responses
///
/// Provides helper functions to extract common data from V2 and V3 API responses.

import 'dart:typed_data';
import 'bytes.dart';

/// Utility class for parsing Accumulate API responses
class ResponseParser {
  /// Extract transaction ID from V3 submit response
  ///
  /// V3 submit returns an array of results, each with a status object.
  static String? extractTxId(dynamic response) {
    if (response is List && response.isNotEmpty) {
      final firstResult = response[0];
      if (firstResult is Map && firstResult["status"] != null) {
        return firstResult["status"]["txID"]?.toString();
      }
    } else if (response is Map) {
      return (response["txid"] ?? response["transactionHash"])?.toString();
    }
    return null;
  }

  /// Extract all transaction IDs from V3 submit response
  ///
  /// Useful when submitting multiple transactions.
  static List<String> extractAllTxIds(dynamic response) {
    final txIds = <String>[];
    if (response is List) {
      for (final result in response) {
        if (result is Map && result["status"] != null) {
          final txId = result["status"]["txID"]?.toString();
          if (txId != null) txIds.add(txId);
        }
      }
    }
    return txIds;
  }

  /// Extract account data from V3 query response
  static Map<String, dynamic>? extractAccount(Map<String, dynamic> response) {
    return response["account"] as Map<String, dynamic>?;
  }

  /// Extract account type from query response
  static String? extractAccountType(Map<String, dynamic> response) {
    final account = extractAccount(response);
    return account?["type"] as String?;
  }

  /// Extract balance from token account query response
  ///
  /// Returns BigInt.zero if no balance is found.
  static BigInt extractBalance(Map<String, dynamic> response) {
    final account = extractAccount(response);
    if (account == null) return BigInt.zero;

    final balance = account["balance"];
    if (balance is String) return BigInt.tryParse(balance) ?? BigInt.zero;
    if (balance is int) return BigInt.from(balance);
    return BigInt.zero;
  }

  /// Extract credit balance from lite identity or key page query response
  ///
  /// Returns 0 if no credit balance is found.
  static int extractCreditBalance(Map<String, dynamic> response) {
    final account = extractAccount(response);
    if (account == null) return 0;

    return account["creditBalance"] as int? ?? account["credits"] as int? ?? 0;
  }

  /// Extract version from key page query response
  ///
  /// Returns 1 if no version is found.
  static int extractVersion(Map<String, dynamic> response) {
    final account = extractAccount(response);
    return account?["version"] as int? ?? 1;
  }

  /// Extract threshold from key page query response
  ///
  /// Returns 1 if no threshold is found.
  static int extractThreshold(Map<String, dynamic> response) {
    final account = extractAccount(response);
    return account?["acceptThreshold"] as int? ?? account?["threshold"] as int? ?? 1;
  }

  /// Extract keys from key page query response
  ///
  /// Returns list of public key hashes as hex strings.
  static List<String> extractKeys(Map<String, dynamic> response) {
    final account = extractAccount(response);
    if (account == null) return [];

    final keys = account["keys"] as List?;
    if (keys == null) return [];

    return keys.map((k) {
      if (k is Map) {
        return k["publicKeyHash"] as String? ?? k["publicKey"] as String? ?? "";
      }
      return k.toString();
    }).where((s) => s.isNotEmpty).toList();
  }

  /// Extract oracle price from network status response
  ///
  /// Returns 0 if oracle price is not found.
  static int extractOraclePrice(Map<String, dynamic> response) {
    final oracle = response["oracle"];
    if (oracle is Map) {
      return oracle["price"] as int? ?? 0;
    }
    return 0;
  }

  /// Extract transaction status (delivered, pending, failed)
  static TxDeliveryStatus extractTxStatus(Map<String, dynamic> response) {
    final status = response["status"];
    if (status == null) return TxDeliveryStatus.unknown;

    final delivered = status["delivered"] as bool? ?? false;
    final failed = status["failed"] as bool? ?? false;
    final pending = status["pending"] as bool? ?? false;

    if (failed) return TxDeliveryStatus.failed;
    if (delivered) return TxDeliveryStatus.delivered;
    if (pending) return TxDeliveryStatus.pending;
    return TxDeliveryStatus.unknown;
  }

  /// Extract error message from response
  static String? extractError(Map<String, dynamic> response) {
    if (response.containsKey("error")) {
      final error = response["error"];
      if (error is String) return error;
      if (error is Map) {
        return error["message"] as String? ?? error.toString();
      }
    }
    final status = response["status"];
    if (status is Map && status["error"] != null) {
      final error = status["error"];
      if (error is String) return error;
      if (error is Map) return error["message"] as String?;
    }
    return null;
  }

  /// Check if response indicates success
  static bool isSuccess(dynamic response) {
    if (response is List && response.isNotEmpty) {
      final firstResult = response[0];
      if (firstResult is Map<String, dynamic>) {
        return extractError(firstResult) == null;
      }
    } else if (response is Map<String, dynamic>) {
      return extractError(response) == null;
    }
    return false;
  }

  /// Extract data entries from data account query response
  ///
  /// Returns list of data entry contents as Uint8List.
  static List<Uint8List> extractDataEntries(Map<String, dynamic> response) {
    final account = extractAccount(response);
    if (account == null) return [];

    final entry = account["entry"];
    if (entry == null) return [];

    if (entry is Map) {
      final data = entry["data"];
      if (data is List) {
        return data
            .whereType<String>()
            .map((hex) {
              try {
                return hexTo(hex);
              } catch (e) {
                return Uint8List(0);
              }
            })
            .where((bytes) => bytes.isNotEmpty)
            .toList();
      }
    }

    return [];
  }

  /// Extract token symbol from token issuer or token account query response
  static String? extractTokenSymbol(Map<String, dynamic> response) {
    final account = extractAccount(response);
    return account?["symbol"] as String?;
  }

  /// Extract token precision from token issuer query response
  static int? extractTokenPrecision(Map<String, dynamic> response) {
    final account = extractAccount(response);
    return account?["precision"] as int?;
  }

  /// Extract token URL from token account query response
  static String? extractTokenUrl(Map<String, dynamic> response) {
    final account = extractAccount(response);
    return account?["tokenUrl"] as String?;
  }
}

/// Transaction delivery status enum
enum TxDeliveryStatus {
  unknown,
  pending,
  delivered,
  failed,
}
