/// Account auth operation type enum
///
/// Matches Go: protocol/enums.yml AccountAuthOperationType
enum AccountAuthOperationType {
  unknown(0),
  enable(1),
  disable(2),
  addAuthority(3),
  removeAuthority(4);

  const AccountAuthOperationType(this.value);

  final int value;

  String get jsonValue => value.toString();
}

/// Base class for account auth operations
///
/// Matches Go: protocol/operations.yml
abstract class AccountAuthOperation {
  /// Get the operation type
  AccountAuthOperationType get type;

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson();

  /// Create an AccountAuthOperation from a JSON map
  static AccountAuthOperation fromJson(Map<String, dynamic> json) {
    final opType = json['type'] as String;
    final authority = json['authority'] as String? ?? '';
    switch (opType) {
      case 'enable':
        return EnableAccountAuthOperation(authority: authority);
      case 'disable':
        return DisableAccountAuthOperation(authority: authority);
      case 'addAuthority':
        return AddAccountAuthorityOperation(authority: authority);
      case 'removeAuthority':
        return RemoveAccountAuthorityOperation(authority: authority);
      default:
        throw ArgumentError('Unknown account auth operation type: $opType');
    }
  }
}

/// Enable authorization checking for an authority
///
/// Matches Go: protocol/operations.yml EnableAccountAuthOperation
class EnableAccountAuthOperation extends AccountAuthOperation {
  /// The authority URL to enable
  final String authority;

  EnableAccountAuthOperation({required this.authority});

  @override
  AccountAuthOperationType get type => AccountAuthOperationType.enable;

  @override
  Map<String, dynamic> toJson() => {
        "type": "enable",
        "authority": authority,
      };
}

/// Disable authorization checking for an authority
///
/// Matches Go: protocol/operations.yml DisableAccountAuthOperation
class DisableAccountAuthOperation extends AccountAuthOperation {
  /// The authority URL to disable
  final String authority;

  DisableAccountAuthOperation({required this.authority});

  @override
  AccountAuthOperationType get type => AccountAuthOperationType.disable;

  @override
  Map<String, dynamic> toJson() => {
        "type": "disable",
        "authority": authority,
      };
}

/// Add an authority to the account
///
/// Matches Go: protocol/operations.yml AddAccountAuthorityOperation
class AddAccountAuthorityOperation extends AccountAuthOperation {
  /// The authority URL to add
  final String authority;

  AddAccountAuthorityOperation({required this.authority});

  @override
  AccountAuthOperationType get type => AccountAuthOperationType.addAuthority;

  @override
  Map<String, dynamic> toJson() => {
        "type": "addAuthority",
        "authority": authority,
      };
}

/// Remove an authority from the account
///
/// Matches Go: protocol/operations.yml RemoveAccountAuthorityOperation
class RemoveAccountAuthorityOperation extends AccountAuthOperation {
  /// The authority URL to remove
  final String authority;

  RemoveAccountAuthorityOperation({required this.authority});

  @override
  AccountAuthOperationType get type => AccountAuthOperationType.removeAuthority;

  @override
  Map<String, dynamic> toJson() => {
        "type": "removeAuthority",
        "authority": authority,
      };
}

/// Network maintenance operation type enum
///
/// Matches Go: protocol/enums.yml NetworkMaintenanceOperationType
enum NetworkMaintenanceOperationType {
  unknown(0),
  pendingTransactionGC(1);

  const NetworkMaintenanceOperationType(this.value);

  final int value;

  String get jsonValue => value.toString();
}

/// Base class for network maintenance operations
abstract class NetworkMaintenanceOperation {
  /// Get the operation type
  NetworkMaintenanceOperationType get type;

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson();
}

/// Garbage collect pending transactions for an account
///
/// Matches Go: protocol/operations.yml PendingTransactionGCOperation
class PendingTransactionGCOperation extends NetworkMaintenanceOperation {
  /// The account URL to garbage collect
  final String account;

  PendingTransactionGCOperation({required this.account});

  @override
  NetworkMaintenanceOperationType get type =>
      NetworkMaintenanceOperationType.pendingTransactionGC;

  @override
  Map<String, dynamic> toJson() => {
        "type": "pendingTransactionGC",
        "account": account,
      };
}
