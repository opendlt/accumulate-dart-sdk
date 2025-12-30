import "dart:convert";
import "dart:typed_data";

/// Binary encoder that matches Go's encoding/binary format for Accumulate protocol
///
/// This implements the exact binary encoding format used by the Go core:
/// - Fields are written as: field_number (uvarint) + value
/// - Hash: 32 raw bytes (no length prefix)
/// - Uint: uvarint
/// - String: length (uvarint) + UTF-8 bytes
/// - Bytes: length (uvarint) + raw bytes
/// - BigInt: length (uvarint) + big-endian bytes
/// - Nested value: length (uvarint) + marshaled bytes
/// - Empty object marker: 0x80
class BinaryEncoder {
  final List<int> _buffer = [];
  int _lastField = 0;
  bool _hasContent = false;

  /// Empty object marker constant
  static const int emptyObject = 0x80;

  /// Write field number as uvarint
  void _writeField(int field) {
    if (field < 1 || field > 32) {
      throw ArgumentError("Field number must be 1-32, got: $field");
    }
    _writeUvarintRaw(field);
    _lastField = field;
    _hasContent = true;
  }

  /// Write uvarint (unsigned variable-length integer)
  void _writeUvarintRaw(int value) {
    var v = value;
    while (v >= 0x80) {
      _buffer.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    _buffer.add(v & 0x7F);
  }

  /// Write varint (signed variable-length integer with zigzag encoding)
  void _writeVarintRaw(int value) {
    // Zigzag encoding: (value << 1) ^ (value >> 63)
    final unsigned = (value << 1) ^ (value >> 63);
    _writeUvarintRaw(unsigned);
  }

  /// Write raw bytes without length prefix
  void _writeRaw(Uint8List bytes) {
    _buffer.addAll(bytes);
  }

  /// Write a hash field (32 bytes, no length prefix)
  void writeHash(int field, Uint8List hash) {
    if (hash.length != 32) {
      throw ArgumentError("Hash must be 32 bytes, got: ${hash.length}");
    }
    // Check for zero hash - don't write if all zeros
    bool isZero = hash.every((b) => b == 0);
    if (isZero) return;

    _writeField(field);
    _writeRaw(hash);
  }

  /// Write an unsigned integer field
  void writeUint(int field, int value) {
    if (value == 0) return; // Don't write zero values
    _writeField(field);
    _writeUvarintRaw(value);
  }

  /// Write a signed integer field
  void writeInt(int field, int value) {
    if (value == 0) return; // Don't write zero values
    _writeField(field);
    _writeVarintRaw(value);
  }

  /// Write an enum field (as uint)
  void writeEnum(int field, int value) {
    // Always write Type field even if zero for transaction bodies
    _writeField(field);
    _writeUvarintRaw(value);
  }

  /// Write a string field (length-prefixed UTF-8)
  void writeString(int field, String value) {
    if (value.isEmpty) return; // Don't write empty strings
    _writeField(field);
    // Use proper UTF-8 encoding, not codeUnits (which is UTF-16)
    final bytes = Uint8List.fromList(utf8.encode(value));
    _writeUvarintRaw(bytes.length);
    _writeRaw(bytes);
  }

  /// Write a URL field (as string)
  void writeUrl(int field, String? url) {
    if (url == null || url.isEmpty) return;
    writeString(field, url);
  }

  /// Write a bytes field (length-prefixed)
  void writeBytes(int field, Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return;
    _writeField(field);
    _writeUvarintRaw(bytes.length);
    _writeRaw(bytes);
  }

  /// Write a BigInt field (as length-prefixed big-endian bytes)
  void writeBigInt(int field, BigInt value) {
    if (value == BigInt.zero) return;
    if (value < BigInt.zero) {
      throw ArgumentError("Cannot write negative BigInt");
    }

    // Convert to big-endian bytes
    var hex = value.toRadixString(16);
    if (hex.length % 2 == 1) hex = "0$hex";
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }

    writeBytes(field, bytes);
  }

  /// Write a nested value field (length-prefixed marshaled bytes)
  void writeValue(int field, Uint8List marshaled) {
    if (marshaled.isEmpty) return;
    _writeField(field);
    _writeUvarintRaw(marshaled.length);
    _writeRaw(marshaled);
  }

  /// Write a boolean field
  void writeBool(int field, bool value) {
    if (!value) return; // Don't write false
    _writeField(field);
    _writeUvarintRaw(1);
  }

  /// Get the encoded bytes
  Uint8List toBytes() {
    if (!_hasContent) {
      // Empty object
      return Uint8List.fromList([emptyObject]);
    }
    return Uint8List.fromList(_buffer);
  }

  /// Reset the encoder
  void reset() {
    _buffer.clear();
    _lastField = 0;
    _hasContent = false;
  }
}

/// Binary marshaler for transaction headers
class TransactionHeaderMarshaler {
  /// Marshal a transaction header to binary format
  ///
  /// Field order matches Go: pkg/protocol/types_gen.go TransactionHeader.MarshalBinary
  /// - Field 1: Principal (URL as string)
  /// - Field 2: Initiator (32-byte hash)
  /// - Field 3: Memo (string)
  /// - Field 4: Metadata (bytes)
  /// - Field 5: Expire (nested)
  /// - Field 6: HoldUntil (nested)
  /// - Field 7: Authorities (repeated URLs)
  static Uint8List marshal(Map<String, dynamic> header) {
    final encoder = BinaryEncoder();

    // Field 1: Principal
    if (header["principal"] != null) {
      encoder.writeUrl(1, header["principal"] as String);
    }

    // Field 2: Initiator (32-byte hash)
    if (header["initiator"] != null) {
      final initiator = header["initiator"];
      Uint8List initiatorBytes;
      if (initiator is String) {
        initiatorBytes = _hexToBytes(initiator);
      } else if (initiator is Uint8List) {
        initiatorBytes = initiator;
      } else {
        throw ArgumentError("Initiator must be String or Uint8List");
      }
      if (initiatorBytes.length == 32 && !initiatorBytes.every((b) => b == 0)) {
        encoder.writeHash(2, initiatorBytes);
      }
    }

    // Field 3: Memo
    if (header["memo"] != null) {
      encoder.writeString(3, header["memo"] as String);
    }

    // Field 4: Metadata
    if (header["metadata"] != null) {
      final metadata = header["metadata"];
      if (metadata is Uint8List) {
        encoder.writeBytes(4, metadata);
      } else if (metadata is String) {
        encoder.writeBytes(4, _hexToBytes(metadata));
      }
    }

    // Field 5: Expire (skip for now - complex nested type)
    // Field 6: HoldUntil (skip for now - complex nested type)

    // Field 7: Authorities (repeated URLs)
    if (header["authorities"] != null) {
      final authorities = header["authorities"];
      if (authorities is List) {
        for (final auth in authorities) {
          encoder.writeUrl(7, auth as String);
        }
      }
    }

    return encoder.toBytes();
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.startsWith("0x") ? hex.substring(2) : hex;
    final bytes = Uint8List(cleaned.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }
}

/// Signature type enum values matching Go: protocol/enums_gen.go
/// CRITICAL: These values MUST match the Go core exactly or signatures will fail!
class SignatureTypeEnum {
  static const int unknown = 0;
  static const int legacyED25519 = 1;
  static const int ed25519 = 2;
  static const int rcd1 = 3;
  static const int receipt = 4;
  static const int partition = 5;
  static const int set = 6;
  static const int remote = 7;
  static const int btc = 8;
  static const int btcLegacy = 9;
  static const int eth = 10;
  static const int delegated = 11;
  static const int internal = 12;
  static const int authority = 13;
  static const int rsaSha256 = 14;
  static const int ecdsaSha256 = 15;
  static const int typedData = 16;
}

/// Generic signature marshaler that works for all key-based signature types
///
/// All key signatures have the same field structure but different Type values.
/// Matches Go: protocol/types_gen.go for each signature type.
class SignatureMarshaler {
  /// Marshal signature metadata to binary format for any signature type
  ///
  /// Field order matches Go's MarshalBinary for all key signatures:
  /// - Field 1: Type (enum)
  /// - Field 2: PublicKey (bytes)
  /// - Field 3: Signature (bytes) - OMITTED for metadata
  /// - Field 4: Signer (URL as string)
  /// - Field 5: SignerVersion (uint)
  /// - Field 6: Timestamp (uint)
  /// - Field 7: Vote (enum)
  /// - Field 8: TransactionHash (hash) - OMITTED for metadata (zeros)
  /// - Field 9: Memo (string)
  /// - Field 10: Data (bytes)
  static Uint8List marshalMetadata({
    required int signatureType,
    required Uint8List publicKey,
    String? signer,
    int signerVersion = 0,
    int timestamp = 0,
    int vote = 0,
    String? memo,
    Uint8List? data,
  }) {
    final encoder = BinaryEncoder();

    // Field 1: Type (signature type enum)
    encoder.writeEnum(1, signatureType);

    // Field 2: PublicKey
    if (publicKey.isNotEmpty) {
      encoder.writeBytes(2, publicKey);
    }

    // Field 3: Signature - OMITTED for metadata (nil)

    // Field 4: Signer
    if (signer != null && signer.isNotEmpty) {
      encoder.writeUrl(4, signer);
    }

    // Field 5: SignerVersion
    if (signerVersion != 0) {
      encoder.writeUint(5, signerVersion);
    }

    // Field 6: Timestamp
    if (timestamp != 0) {
      encoder.writeUint(6, timestamp);
    }

    // Field 7: Vote
    if (vote != 0) {
      encoder.writeEnum(7, vote);
    }

    // Field 8: TransactionHash - OMITTED for metadata (zeros)

    // Field 9: Memo
    if (memo != null && memo.isNotEmpty) {
      encoder.writeString(9, memo);
    }

    // Field 10: Data
    if (data != null && data.isNotEmpty) {
      encoder.writeBytes(10, data);
    }

    return encoder.toBytes();
  }
}

/// Binary marshaler for ED25519 signatures (for metadata hash)
class ED25519SignatureMarshaler {
  /// Marshal an ED25519 signature to binary format
  ///
  /// Field order matches Go: pkg/protocol/types_gen.go ED25519Signature.MarshalBinary
  /// - Field 1: Type (enum = 2 for ED25519)
  /// - Field 2: PublicKey (bytes)
  /// - Field 3: Signature (bytes) - OMITTED for metadata
  /// - Field 4: Signer (URL as string)
  /// - Field 5: SignerVersion (uint)
  /// - Field 6: Timestamp (uint)
  /// - Field 7: Vote (enum)
  /// - Field 8: TransactionHash (hash) - OMITTED for metadata (zeros)
  /// - Field 9: Memo (string)
  /// - Field 10: Data (bytes)
  static Uint8List marshal({
    required Uint8List publicKey,
    Uint8List? signature,
    String? signer,
    int signerVersion = 0,
    int timestamp = 0,
    int vote = 0,
    Uint8List? transactionHash,
    String? memo,
    Uint8List? data,
  }) {
    final encoder = BinaryEncoder();

    // Field 1: Type (always ED25519 = 2)
    encoder.writeEnum(1, SignatureTypeEnum.ed25519);

    // Field 2: PublicKey
    if (publicKey.isNotEmpty) {
      encoder.writeBytes(2, publicKey);
    }

    // Field 3: Signature (omitted for metadata hash)
    if (signature != null && signature.isNotEmpty) {
      encoder.writeBytes(3, signature);
    }

    // Field 4: Signer
    if (signer != null && signer.isNotEmpty) {
      encoder.writeUrl(4, signer);
    }

    // Field 5: SignerVersion
    if (signerVersion != 0) {
      encoder.writeUint(5, signerVersion);
    }

    // Field 6: Timestamp
    if (timestamp != 0) {
      encoder.writeUint(6, timestamp);
    }

    // Field 7: Vote
    if (vote != 0) {
      encoder.writeEnum(7, vote);
    }

    // Field 8: TransactionHash (omitted for metadata - all zeros)
    if (transactionHash != null &&
        transactionHash.length == 32 &&
        !transactionHash.every((b) => b == 0)) {
      encoder.writeHash(8, transactionHash);
    }

    // Field 9: Memo
    if (memo != null && memo.isNotEmpty) {
      encoder.writeString(9, memo);
    }

    // Field 10: Data
    if (data != null && data.isNotEmpty) {
      encoder.writeBytes(10, data);
    }

    return encoder.toBytes();
  }

  /// Marshal signature metadata (for computing metadata hash)
  /// This is the signature with Signature=nil and TransactionHash=[32]byte{}
  static Uint8List marshalMetadata({
    required Uint8List publicKey,
    String? signer,
    int signerVersion = 0,
    int timestamp = 0,
    int vote = 0,
    String? memo,
    Uint8List? data,
  }) {
    // For metadata, Signature is nil and TransactionHash is zeros (both omitted)
    return marshal(
      publicKey: publicKey,
      signature: null,
      signer: signer,
      signerVersion: signerVersion,
      timestamp: timestamp,
      vote: vote,
      transactionHash: null, // Zeros = omitted
      memo: memo,
      data: data,
    );
  }
}

/// Binary marshaler for transaction bodies
class TransactionBodyMarshaler {
  /// Transaction type numeric values
  static const txTypeCreateIdentity = 0x01;
  static const txTypeCreateTokenAccount = 0x02;
  static const txTypeSendTokens = 0x03;
  static const txTypeCreateDataAccount = 0x04;
  static const txTypeWriteData = 0x05;
  static const txTypeWriteDataTo = 0x06;
  static const txTypeAcmeFaucet = 0x07;
  static const txTypeCreateToken = 0x08;
  static const txTypeIssueTokens = 0x09;
  static const txTypeBurnTokens = 0x0A;
  static const txTypeCreateLiteTokenAccount = 0x0B;
  static const txTypeCreateKeyPage = 0x0C;
  static const txTypeCreateKeyBook = 0x0D;
  static const txTypeAddCredits = 0x0E;
  static const txTypeUpdateKeyPage = 0x0F;
  static const txTypeLockAccount = 0x10;
  static const txTypeBurnCredits = 0x11;
  static const txTypeTransferCredits = 0x12;
  static const txTypeUpdateAccountAuth = 0x15;
  static const txTypeUpdateKey = 0x16;

  /// Get numeric transaction type from string
  static int getTypeValue(String type) {
    switch (type.toLowerCase()) {
      case "createidentity":
        return txTypeCreateIdentity;
      case "createtokenaccount":
        return txTypeCreateTokenAccount;
      case "sendtokens":
        return txTypeSendTokens;
      case "createdataaccount":
        return txTypeCreateDataAccount;
      case "writedata":
        return txTypeWriteData;
      case "writedatato":
        return txTypeWriteDataTo;
      case "acmefaucet":
        return txTypeAcmeFaucet;
      case "createtoken":
        return txTypeCreateToken;
      case "issuetokens":
        return txTypeIssueTokens;
      case "burntokens":
        return txTypeBurnTokens;
      case "createlitetokenaccount":
        return txTypeCreateLiteTokenAccount;
      case "createkeypage":
        return txTypeCreateKeyPage;
      case "createkeybook":
        return txTypeCreateKeyBook;
      case "addcredits":
        return txTypeAddCredits;
      case "updatekeypage":
        return txTypeUpdateKeyPage;
      case "lockaccount":
        return txTypeLockAccount;
      case "burncredits":
        return txTypeBurnCredits;
      case "transfercredits":
        return txTypeTransferCredits;
      case "updateaccountauth":
        return txTypeUpdateAccountAuth;
      case "updatekey":
        return txTypeUpdateKey;
      default:
        throw ArgumentError("Unknown transaction type: $type");
    }
  }

  /// Marshal a transaction body to binary format
  static Uint8List marshal(Map<String, dynamic> body) {
    final type = body["type"] as String;
    final typeValue = getTypeValue(type);

    switch (typeValue) {
      case txTypeAddCredits:
        return _marshalAddCredits(body, typeValue);
      case txTypeSendTokens:
        return _marshalSendTokens(body, typeValue);
      case txTypeCreateIdentity:
        return _marshalCreateIdentity(body, typeValue);
      case txTypeCreateTokenAccount:
        return _marshalCreateTokenAccount(body, typeValue);
      case txTypeCreateDataAccount:
        return _marshalCreateDataAccount(body, typeValue);
      case txTypeWriteData:
        return _marshalWriteData(body, typeValue);
      case txTypeCreateToken:
        return _marshalCreateToken(body, typeValue);
      case txTypeIssueTokens:
        return _marshalIssueTokens(body, typeValue);
      case txTypeCreateKeyPage:
        return _marshalCreateKeyPage(body, typeValue);
      case txTypeCreateKeyBook:
        return _marshalCreateKeyBook(body, typeValue);
      case txTypeUpdateKeyPage:
        return _marshalUpdateKeyPage(body, typeValue);
      default:
        throw ArgumentError(
            "Transaction type not yet supported for binary encoding: $type");
    }
  }

  /// Marshal AddCredits transaction body
  /// Field 1: Type (enum)
  /// Field 2: Recipient (URL)
  /// Field 3: Amount (BigInt)
  /// Field 4: Oracle (uint)
  static Uint8List _marshalAddCredits(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    if (body["recipient"] != null) {
      encoder.writeUrl(2, body["recipient"] as String);
    }

    if (body["amount"] != null) {
      final amount = body["amount"];
      BigInt amountValue;
      if (amount is String) {
        amountValue = BigInt.parse(amount);
      } else if (amount is int) {
        amountValue = BigInt.from(amount);
      } else if (amount is BigInt) {
        amountValue = amount;
      } else {
        throw ArgumentError("Amount must be String, int, or BigInt");
      }
      encoder.writeBigInt(3, amountValue);
    }

    if (body["oracle"] != null) {
      encoder.writeUint(4, body["oracle"] as int);
    }

    return encoder.toBytes();
  }

  /// Marshal SendTokens transaction body
  /// Field 1: Type (enum)
  /// Field 2: Hash (hash) - optional
  /// Field 3: Meta (bytes) - optional
  /// Field 4: To (repeated TokenRecipient)
  static Uint8List _marshalSendTokens(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    // Field 2: Hash (optional)
    // Field 3: Meta (optional)

    // Field 4: To (repeated TokenRecipient)
    if (body["to"] != null) {
      final recipients = body["to"] as List;
      for (final recipient in recipients) {
        final recipientBytes = _marshalTokenRecipient(recipient as Map<String, dynamic>);
        encoder.writeValue(4, recipientBytes);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal TokenRecipient
  /// Field 1: Url (URL)
  /// Field 2: Amount (BigInt)
  static Uint8List _marshalTokenRecipient(Map<String, dynamic> recipient) {
    final encoder = BinaryEncoder();

    if (recipient["url"] != null) {
      encoder.writeUrl(1, recipient["url"] as String);
    }

    if (recipient["amount"] != null) {
      final amount = recipient["amount"];
      BigInt amountValue;
      if (amount is String) {
        amountValue = BigInt.parse(amount);
      } else if (amount is int) {
        amountValue = BigInt.from(amount);
      } else if (amount is BigInt) {
        amountValue = amount;
      } else {
        throw ArgumentError("Amount must be String, int, or BigInt");
      }
      encoder.writeBigInt(2, amountValue);
    }

    return encoder.toBytes();
  }

  /// Marshal CreateIdentity transaction body
  /// Field 1: Type (enum)
  /// Field 2: Url (URL)
  /// Field 3: KeyHash (bytes)
  /// Field 4: KeyBookUrl (URL)
  /// Field 6: Authorities (repeated URLs) - note: field-number 6 per Go spec
  static Uint8List _marshalCreateIdentity(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    if (body["url"] != null) {
      encoder.writeUrl(2, body["url"] as String);
    }

    // Check both "keyHash" and "publicKeyHash" field names
    final keyHash = body["keyHash"] ?? body["publicKeyHash"];
    if (keyHash != null) {
      if (keyHash is String) {
        encoder.writeBytes(3, _hexToBytes(keyHash));
      } else if (keyHash is Uint8List) {
        encoder.writeBytes(3, keyHash);
      }
    }

    if (body["keyBookName"] != null || body["keyBookUrl"] != null) {
      // KeyBookName is a shorthand - construct URL
      final keyBookUrl = body["keyBookUrl"] ?? "${body["url"]}/${body["keyBookName"]}";
      encoder.writeUrl(4, keyBookUrl as String);
    }

    // Field 6 for authorities (per Go spec: field-number: 6)
    if (body["authorities"] != null) {
      final authorities = body["authorities"] as List;
      for (final auth in authorities) {
        encoder.writeUrl(6, auth as String);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal CreateTokenAccount transaction body
  /// Field 1: Type (enum)
  /// Field 2: Url (URL)
  /// Field 3: TokenUrl (URL)
  /// Field 4: Authorities (repeated URLs)
  static Uint8List _marshalCreateTokenAccount(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    if (body["url"] != null) {
      encoder.writeUrl(2, body["url"] as String);
    }

    if (body["token"] != null || body["tokenUrl"] != null) {
      encoder.writeUrl(3, (body["tokenUrl"] ?? body["token"]) as String);
    }

    if (body["authorities"] != null) {
      final authorities = body["authorities"] as List;
      for (final auth in authorities) {
        encoder.writeUrl(4, auth as String);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal CreateDataAccount transaction body
  /// Field 1: Type (enum)
  /// Field 2: Url (URL)
  /// Field 3: Authorities (repeated URLs)
  static Uint8List _marshalCreateDataAccount(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    if (body["url"] != null) {
      encoder.writeUrl(2, body["url"] as String);
    }

    if (body["authorities"] != null) {
      final authorities = body["authorities"] as List;
      for (final auth in authorities) {
        encoder.writeUrl(3, auth as String);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal WriteData transaction body
  /// Matches Go: protocol/types_gen.go WriteData.MarshalBinary
  /// Field 1: Type (enum)
  /// Field 2: Entry (nested DataEntry)
  /// Field 3: Scratch (bool, optional)
  /// Field 4: WriteToState (bool, optional)
  static Uint8List _marshalWriteData(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    // For WriteData, we need to marshal the entry
    // The entry format depends on its type (Accumulate, Factom, DoubleHash)
    if (body["entry"] != null || body["entries"] != null) {
      final entry = body["entry"] ?? body["entries"];
      final entryBytes = _marshalDataEntry(entry);
      encoder.writeValue(2, entryBytes);
    }

    // Field 3: Scratch (only written if true)
    if (body["scratch"] == true) {
      encoder.writeBool(3, true);
    }

    // Field 4: WriteToState (only written if true)
    if (body["writeToState"] == true) {
      encoder.writeBool(4, true);
    }

    return encoder.toBytes();
  }

  /// Marshal CreateToken transaction body
  /// Matches Go: protocol/user_transactions.yml CreateToken
  /// Field 1: Type (enum)
  /// Field 2: Url (URL)
  /// Field 4: Symbol (string) - note: field 3 is skipped per Go spec
  /// Field 5: Precision (uint)
  /// Field 6: Properties (URL, optional)
  /// Field 7: SupplyLimit (BigInt, optional)
  /// Field 8: Authorities (repeated URLs)
  static Uint8List _marshalCreateToken(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    if (body["url"] != null) {
      encoder.writeUrl(2, body["url"] as String);
    }

    // Field 4: Symbol (note: field 3 is not used)
    if (body["symbol"] != null) {
      encoder.writeString(4, body["symbol"] as String);
    }

    // Field 5: Precision
    if (body["precision"] != null) {
      encoder.writeUint(5, body["precision"] as int);
    }

    // Field 6: Properties (optional URL)
    if (body["properties"] != null) {
      encoder.writeUrl(6, body["properties"] as String);
    }

    // Field 7: SupplyLimit (optional BigInt)
    if (body["supplyLimit"] != null) {
      final supplyLimit = body["supplyLimit"];
      BigInt supplyLimitValue;
      if (supplyLimit is String) {
        supplyLimitValue = BigInt.parse(supplyLimit);
      } else if (supplyLimit is int) {
        supplyLimitValue = BigInt.from(supplyLimit);
      } else if (supplyLimit is BigInt) {
        supplyLimitValue = supplyLimit;
      } else {
        throw ArgumentError("SupplyLimit must be String, int, or BigInt");
      }
      encoder.writeBigInt(7, supplyLimitValue);
    }

    // Field 8: Authorities (repeated URLs)
    if (body["authorities"] != null) {
      final authorities = body["authorities"] as List;
      for (final auth in authorities) {
        encoder.writeUrl(8, auth as String);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal IssueTokens transaction body
  /// Matches Go: protocol/user_transactions.yml IssueTokens
  /// Field 1: Type (enum)
  /// Field 2: Recipient (deprecated URL)
  /// Field 3: Amount (deprecated BigInt)
  /// Field 4: To (repeated TokenRecipient)
  static Uint8List _marshalIssueTokens(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    // Field 4: To (repeated TokenRecipient) - use the same format as SendTokens
    if (body["to"] != null) {
      final recipients = body["to"] as List;
      for (final recipient in recipients) {
        final recipientBytes = _marshalTokenRecipient(recipient as Map<String, dynamic>);
        encoder.writeValue(4, recipientBytes);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal CreateKeyPage transaction body
  /// Matches Go: protocol/user_transactions.yml CreateKeyPage
  /// Field 1: Type (enum)
  /// Field 2: Keys (repeated KeySpecParams, marshal-as: reference)
  static Uint8List _marshalCreateKeyPage(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    // Field 2: Keys (repeated KeySpecParams)
    if (body["keys"] != null) {
      final keys = body["keys"] as List;
      for (final key in keys) {
        final keyBytes = _marshalKeySpecParams(key as Map<String, dynamic>);
        encoder.writeValue(2, keyBytes);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal CreateKeyBook transaction body
  /// Matches Go: protocol/user_transactions.yml CreateKeyBook
  /// Field 1: Type (enum)
  /// Field 2: Url (URL)
  /// Field 3: PublicKeyHash (bytes)
  /// Field 5: Authorities (repeated URLs, field-number: 5)
  static Uint8List _marshalCreateKeyBook(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    // Field 2: Url
    if (body["url"] != null) {
      encoder.writeUrl(2, body["url"] as String);
    }

    // Field 3: PublicKeyHash
    final keyHash = body["publicKeyHash"] ?? body["keyHash"];
    if (keyHash != null) {
      if (keyHash is String) {
        encoder.writeBytes(3, _hexToBytes(keyHash));
      } else if (keyHash is Uint8List) {
        encoder.writeBytes(3, keyHash);
      }
    }

    // Field 5: Authorities (field-number: 5 per Go spec)
    if (body["authorities"] != null) {
      final authorities = body["authorities"] as List;
      for (final auth in authorities) {
        encoder.writeUrl(5, auth as String);
      }
    }

    return encoder.toBytes();
  }

  /// KeyPageOperationType enum values
  static const keyPageOpUnknown = 0;
  static const keyPageOpUpdate = 1;
  static const keyPageOpRemove = 2;
  static const keyPageOpAdd = 3;
  static const keyPageOpSetThreshold = 4;
  static const keyPageOpUpdateAllowed = 5;
  static const keyPageOpSetRejectThreshold = 6;
  static const keyPageOpSetResponseThreshold = 7;

  /// Marshal UpdateKeyPage transaction body
  /// Matches Go: protocol/user_transactions.yml UpdateKeyPage
  /// Field 1: Type (enum)
  /// Field 2: Operation (repeated KeyPageOperation, marshal-as: union)
  static Uint8List _marshalUpdateKeyPage(Map<String, dynamic> body, int typeValue) {
    final encoder = BinaryEncoder();

    encoder.writeEnum(1, typeValue);

    // Field 2: Operation (repeated KeyPageOperation)
    if (body["operation"] != null) {
      final operations = body["operation"];
      if (operations is List) {
        for (final op in operations) {
          final opBytes = _marshalKeyPageOperation(op as Map<String, dynamic>);
          encoder.writeValue(2, opBytes);
        }
      } else if (operations is Map) {
        final opBytes = _marshalKeyPageOperation(operations as Map<String, dynamic>);
        encoder.writeValue(2, opBytes);
      }
    }

    return encoder.toBytes();
  }

  /// Marshal KeySpecParams
  /// Field 1: KeyHash (bytes)
  /// Field 2: Delegate (URL, optional)
  static Uint8List _marshalKeySpecParams(Map<String, dynamic> params) {
    final encoder = BinaryEncoder();

    // Field 1: KeyHash
    final keyHash = params["keyHash"];
    if (keyHash != null) {
      if (keyHash is String) {
        encoder.writeBytes(1, _hexToBytes(keyHash));
      } else if (keyHash is Uint8List) {
        encoder.writeBytes(1, keyHash);
      }
    }

    // Field 2: Delegate (optional)
    if (params["delegate"] != null) {
      encoder.writeUrl(2, params["delegate"] as String);
    }

    return encoder.toBytes();
  }

  /// Marshal KeyPageOperation (union type)
  /// Based on type, marshals the appropriate operation
  static Uint8List _marshalKeyPageOperation(Map<String, dynamic> op) {
    final encoder = BinaryEncoder();

    // Determine operation type from "type" field
    final typeStr = op["type"]?.toString().toLowerCase() ?? "";
    int opType;

    switch (typeStr) {
      case "addkeyoperation":
      case "add":
        opType = keyPageOpAdd;
        break;
      case "removekeyoperation":
      case "remove":
        opType = keyPageOpRemove;
        break;
      case "updatekeyoperation":
      case "update":
        opType = keyPageOpUpdate;
        break;
      case "setthresholdkeypageoperation":
      case "setthreshold":
        opType = keyPageOpSetThreshold;
        break;
      case "setrejectthresholdkeypageoperation":
      case "setrejectthreshold":
        opType = keyPageOpSetRejectThreshold;
        break;
      case "setresponsethresholdkeypageoperation":
      case "setresponsethreshold":
        opType = keyPageOpSetResponseThreshold;
        break;
      case "updateallowedkeypageoperation":
      case "updateallowed":
        opType = keyPageOpUpdateAllowed;
        break;
      default:
        throw ArgumentError("Unknown key page operation type: $typeStr");
    }

    // Field 1: Type (enum)
    encoder.writeEnum(1, opType);

    // Marshal remaining fields based on operation type
    switch (opType) {
      case keyPageOpAdd:
      case keyPageOpRemove:
        // Field 2: Entry (KeySpecParams)
        if (op["entry"] != null) {
          final entryBytes = _marshalKeySpecParams(op["entry"] as Map<String, dynamic>);
          encoder.writeValue(2, entryBytes);
        }
        break;
      case keyPageOpUpdate:
        // Field 2: OldEntry
        if (op["oldEntry"] != null) {
          final oldEntryBytes = _marshalKeySpecParams(op["oldEntry"] as Map<String, dynamic>);
          encoder.writeValue(2, oldEntryBytes);
        }
        // Field 3: NewEntry
        if (op["newEntry"] != null) {
          final newEntryBytes = _marshalKeySpecParams(op["newEntry"] as Map<String, dynamic>);
          encoder.writeValue(3, newEntryBytes);
        }
        break;
      case keyPageOpSetThreshold:
      case keyPageOpSetRejectThreshold:
      case keyPageOpSetResponseThreshold:
        // Field 2: Threshold
        if (op["threshold"] != null) {
          encoder.writeUint(2, op["threshold"] as int);
        }
        break;
      case keyPageOpUpdateAllowed:
        // Field 2: Allow (repeated TransactionType enum)
        if (op["allow"] != null) {
          final allow = op["allow"] as List;
          for (final txType in allow) {
            encoder.writeUint(2, txType as int);
          }
        }
        // Field 3: Deny (repeated TransactionType enum)
        if (op["deny"] != null) {
          final deny = op["deny"] as List;
          for (final txType in deny) {
            encoder.writeUint(3, txType as int);
          }
        }
        break;
    }

    return encoder.toBytes();
  }

  /// Marshal a data entry
  /// DataEntryType enum values (from Go protocol/enums_gen.go):
  ///   Unknown = 0, Factom = 1, Accumulate = 2, DoubleHash = 3
  static Uint8List _marshalDataEntry(dynamic entry) {
    final encoder = BinaryEncoder();

    // Determine the DataEntryType from the entry's "type" field
    int dataEntryType = 3; // Default to DoubleHash (recommended)
    if (entry is Map && entry["type"] != null) {
      final typeStr = entry["type"].toString().toLowerCase();
      switch (typeStr) {
        case "doublehash":
          dataEntryType = 3; // DataEntryType.DoubleHash
          break;
        case "accumulate":
          dataEntryType = 2; // DataEntryType.Accumulate (deprecated)
          break;
        case "factom":
          dataEntryType = 1; // DataEntryType.Factom
          break;
        default:
          dataEntryType = 3; // Default to DoubleHash
      }
    }

    encoder.writeEnum(1, dataEntryType);

    // Handle the data field - can be a List of hex strings or single hex string
    if (entry is Map && entry["data"] != null) {
      final data = entry["data"];
      if (data is List) {
        // List of hex-encoded data entries
        for (final item in data) {
          if (item is String) {
            encoder.writeBytes(2, _hexToBytes(item));
          } else if (item is Uint8List) {
            encoder.writeBytes(2, item);
          }
        }
      } else if (data is String) {
        // Single hex-encoded data entry
        encoder.writeBytes(2, _hexToBytes(data));
      } else if (data is Uint8List) {
        encoder.writeBytes(2, data);
      }
    }

    return encoder.toBytes();
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.startsWith("0x") ? hex.substring(2) : hex;
    final bytes = Uint8List(cleaned.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

}
