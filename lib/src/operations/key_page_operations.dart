import "dart:typed_data";
import "../util/bytes.dart";

/// Key specification parameters for key page operations
///
/// Matches Go: protocol/general.yml KeySpecParams
class KeySpecParams {
  /// The hash of the public key
  final Uint8List keyHash;

  /// Optional delegate URL for delegated signing
  final String? delegate;

  const KeySpecParams({
    required this.keyHash,
    this.delegate,
  });

  /// Create from hex-encoded key hash
  factory KeySpecParams.fromHex(String keyHashHex, {String? delegate}) {
    return KeySpecParams(
      keyHash: hexTo(keyHashHex),
      delegate: delegate,
    );
  }

  Map<String, dynamic> toJson() => {
        "keyHash": toHex(keyHash),
        if (delegate != null) "delegate": delegate,
      };
}

/// Key page operation type enum
///
/// Matches Go: protocol/enums.yml KeyPageOperationType
enum KeyPageOperationType {
  unknown(0),
  add(1),
  remove(2),
  update(3),
  setThreshold(4),
  updateAllowed(5),
  setRejectThreshold(6),
  setResponseThreshold(7);

  const KeyPageOperationType(this.value);

  final int value;

  String get jsonValue => value.toString();
}

/// Base class for key page operations
///
/// Matches Go: protocol/key_page_operations.yml
abstract class KeyPageOperation {
  /// Get the operation type
  KeyPageOperationType get type;

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson();
}

/// Add a key to the key page
///
/// Matches Go: protocol/key_page_operations.yml AddKeyOperation
class AddKeyOperation extends KeyPageOperation {
  /// The key entry to add
  final KeySpecParams entry;

  AddKeyOperation({required this.entry});

  @override
  KeyPageOperationType get type => KeyPageOperationType.add;

  @override
  Map<String, dynamic> toJson() => {
        "type": "add",
        "entry": entry.toJson(),
      };
}

/// Remove a key from the key page
///
/// Matches Go: protocol/key_page_operations.yml RemoveKeyOperation
class RemoveKeyOperation extends KeyPageOperation {
  /// The key entry to remove
  final KeySpecParams entry;

  RemoveKeyOperation({required this.entry});

  @override
  KeyPageOperationType get type => KeyPageOperationType.remove;

  @override
  Map<String, dynamic> toJson() => {
        "type": "remove",
        "entry": entry.toJson(),
      };
}

/// Update a key in the key page
///
/// Matches Go: protocol/key_page_operations.yml UpdateKeyOperation
class UpdateKeyOperation extends KeyPageOperation {
  /// The old key entry to replace
  final KeySpecParams oldEntry;

  /// The new key entry
  final KeySpecParams newEntry;

  UpdateKeyOperation({required this.oldEntry, required this.newEntry});

  @override
  KeyPageOperationType get type => KeyPageOperationType.update;

  @override
  Map<String, dynamic> toJson() => {
        "type": "update",
        "oldEntry": oldEntry.toJson(),
        "newEntry": newEntry.toJson(),
      };
}

/// Set the signature threshold for the key page
///
/// Matches Go: protocol/key_page_operations.yml SetThresholdKeyPageOperation
class SetThresholdKeyPageOperation extends KeyPageOperation {
  /// The new signature threshold (number of signatures required)
  final int threshold;

  SetThresholdKeyPageOperation({required this.threshold});

  @override
  KeyPageOperationType get type => KeyPageOperationType.setThreshold;

  @override
  Map<String, dynamic> toJson() => {
        "type": "setThreshold",
        "threshold": threshold,
      };
}

/// Set the reject threshold for the key page
///
/// Matches Go: protocol/key_page_operations.yml SetRejectThresholdKeyPageOperation
class SetRejectThresholdKeyPageOperation extends KeyPageOperation {
  /// The new reject threshold (number of rejections to reject)
  final int threshold;

  SetRejectThresholdKeyPageOperation({required this.threshold});

  @override
  KeyPageOperationType get type => KeyPageOperationType.setRejectThreshold;

  @override
  Map<String, dynamic> toJson() => {
        "type": "setRejectThreshold",
        "threshold": threshold,
      };
}

/// Set the response threshold for the key page
///
/// Matches Go: protocol/key_page_operations.yml SetResponseThresholdKeyPageOperation
class SetResponseThresholdKeyPageOperation extends KeyPageOperation {
  /// The new response threshold (signatures/rejections needed to complete)
  final int threshold;

  SetResponseThresholdKeyPageOperation({required this.threshold});

  @override
  KeyPageOperationType get type => KeyPageOperationType.setResponseThreshold;

  @override
  Map<String, dynamic> toJson() => {
        "type": "setResponseThreshold",
        "threshold": threshold,
      };
}

/// Update allowed transaction types for the key page
///
/// Matches Go: protocol/key_page_operations.yml UpdateAllowedKeyPageOperation
class UpdateAllowedKeyPageOperation extends KeyPageOperation {
  /// Transaction types to allow
  final List<String>? allow;

  /// Transaction types to deny
  final List<String>? deny;

  UpdateAllowedKeyPageOperation({this.allow, this.deny});

  @override
  KeyPageOperationType get type => KeyPageOperationType.updateAllowed;

  @override
  Map<String, dynamic> toJson() => {
        "type": "updateAllowed",
        if (allow != null && allow!.isNotEmpty) "allow": allow,
        if (deny != null && deny!.isNotEmpty) "deny": deny,
      };
}
