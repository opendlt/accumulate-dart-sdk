import "dart:typed_data";
import "dart:convert";
import "package:crypto/crypto.dart";
import "binary_encoder.dart";

/// Transaction hashing facade that implements discovered rules from Go/TypeScript
///
/// Key discoveries:
/// - Go: protocol/transaction_hash.go:27-71 - SHA256(SHA256(header_binary) + SHA256(body_binary))
/// - Go: protocol/transaction_hash.go:91-114 - WriteData uses special Merkle hash
/// - Signing: protocol/signature_utils.go:50-57 - SHA256(signature_metadata_hash + transaction_hash)
///
/// IMPORTANT: Uses binary encoding (MarshalBinary) to match Go core, NOT JSON encoding.
/// IMPORTANT: WriteData/WriteDataTo use a special hash algorithm with Merkle trees.
class TransactionCodec {
  /// Encode transaction for signing - implements proper binary encoding
  ///
  /// Based on Go: protocol/transaction_hash.go:27-71
  /// Transaction hash = SHA256(SHA256(header_binary) + SHA256(body_binary))
  ///
  /// SPECIAL CASE: WriteData uses GetHash() method which computes a Merkle hash
  /// of the body (without entry) and the entry hash separately.
  /// See Go: protocol/transaction_hash.go:110-114
  ///
  /// Uses binary encoding (MarshalBinary) format matching Go core.
  // Debug flag to print binary encoding
  static bool debugPrintBinary = false;

  static Uint8List encodeTxForSigning(
      Map<String, dynamic> header, Map<String, dynamic> body) {
    // Encode header to binary format (MarshalBinary)
    final headerBytes = TransactionHeaderMarshaler.marshal(header);

    if (debugPrintBinary) {
      print("DEBUG: Body type: ${body['type']}");
      print("DEBUG: Header bytes (${headerBytes.length}): ${headerBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
    }

    // Hash header
    final headerHash = sha256.convert(headerBytes).bytes;

    // Compute body hash - WriteData uses special algorithm
    final Uint8List bodyHash;
    final bodyType = (body['type'] as String?)?.toLowerCase();
    if (bodyType == 'writedata' || bodyType == 'writedatato') {
      bodyHash = _computeWriteDataBodyHash(body);
    } else {
      // Standard: SHA256 of marshaled body
      final bodyBytes = TransactionBodyMarshaler.marshal(body);
      if (debugPrintBinary) {
        print("DEBUG: Body bytes (${bodyBytes.length}): ${bodyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
      }
      bodyHash = Uint8List.fromList(sha256.convert(bodyBytes).bytes);
    }

    if (debugPrintBinary) {
      print("DEBUG: Body hash: ${bodyHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
    }

    // Transaction hash = SHA256(SHA256(header) + SHA256(body))
    final combined = Uint8List.fromList([...headerHash, ...bodyHash]);
    return Uint8List.fromList(sha256.convert(combined).bytes);
  }

  /// Compute WriteData body hash using special Merkle algorithm
  ///
  /// Based on Go: protocol/transaction_hash.go:91-114
  /// 1. Marshal WriteData body with Entry=nil (only Type, Scratch, WriteToState)
  /// 2. Compute Merkle hash of [SHA256(marshaledBody), entryHash]
  static Uint8List _computeWriteDataBodyHash(Map<String, dynamic> body) {
    // Marshal body WITHOUT entry (Entry = nil)
    final bodyWithoutEntry = Map<String, dynamic>.from(body);
    bodyWithoutEntry.remove('entry');
    bodyWithoutEntry.remove('entries');
    final bodyBytes = TransactionBodyMarshaler.marshal(bodyWithoutEntry);

    if (debugPrintBinary) {
      print("DEBUG: WriteData body (no entry) bytes (${bodyBytes.length}): ${bodyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
    }

    // SHA256 of body without entry
    final bodyPartHash = Uint8List.fromList(sha256.convert(bodyBytes).bytes);

    // Compute entry hash
    final entry = body['entry'] ?? body['entries'];
    Uint8List entryHash;
    if (entry == null) {
      // No entry = zero hash
      entryHash = Uint8List(32);
    } else {
      entryHash = _computeDataEntryHash(entry);
    }

    if (debugPrintBinary) {
      print("DEBUG: WriteData bodyPartHash: ${bodyPartHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
      print("DEBUG: WriteData entryHash: ${entryHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
    }

    // Merkle hash of [bodyPartHash, entryHash]
    return _merkleHash([bodyPartHash, entryHash]);
  }

  /// Compute hash for a DataEntry
  ///
  /// Based on Go: protocol/data_entry.go
  /// DoubleHashDataEntry: SHA256(MerkleHash(SHA256(data1), SHA256(data2), ...))
  /// AccumulateDataEntry: MerkleHash(SHA256(data1), SHA256(data2), ...)
  static Uint8List _computeDataEntryHash(dynamic entry) {
    if (entry is! Map) {
      return Uint8List(32);
    }

    final entryType = (entry['type']?.toString() ?? 'doublehash').toLowerCase();
    final data = entry['data'];

    if (data == null) {
      return Uint8List(32);
    }

    // Collect data hashes
    final List<Uint8List> dataHashes = [];
    if (data is List) {
      for (final item in data) {
        final bytes = _dataItemToBytes(item);
        final hash = Uint8List.fromList(sha256.convert(bytes).bytes);
        dataHashes.add(hash);
      }
    } else {
      final bytes = _dataItemToBytes(data);
      final hash = Uint8List.fromList(sha256.convert(bytes).bytes);
      dataHashes.add(hash);
    }

    if (dataHashes.isEmpty) {
      return Uint8List(32);
    }

    // Compute Merkle hash of data hashes
    final merkleRoot = _merkleHash(dataHashes);

    if (debugPrintBinary) {
      print("DEBUG: Entry merkleRoot: ${merkleRoot.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
    }

    // For DoubleHash: return SHA256(merkleRoot) - double hash!
    // For Accumulate: return merkleRoot directly
    if (entryType == 'doublehash') {
      return Uint8List.fromList(sha256.convert(merkleRoot).bytes);
    } else {
      return merkleRoot;
    }
  }

  /// Convert data item to bytes
  static Uint8List _dataItemToBytes(dynamic item) {
    if (item is Uint8List) {
      return item;
    } else if (item is String) {
      // Hex string
      return _hexToBytes(item);
    } else if (item is List<int>) {
      return Uint8List.fromList(item);
    }
    return Uint8List(0);
  }

  /// Compute Merkle hash of a list of hashes
  ///
  /// Based on Go: pkg/database/merkle/hasher.go MerkleHash()
  /// Uses a cascading binary tree algorithm
  static Uint8List _merkleHash(List<Uint8List> hashes) {
    if (hashes.isEmpty) {
      return Uint8List(32);
    }

    if (hashes.length == 1) {
      return hashes[0];
    }

    // Use the Merkle cascade algorithm from Go
    // Each hash is added and combined with pending hashes at each level
    List<Uint8List?> pending = [];

    for (final hash in hashes) {
      var current = hash;
      for (int i = 0; ; i++) {
        // Extend pending if needed
        if (i >= pending.length) {
          pending.add(current);
          break;
        }

        // If slot is empty, put hash there
        if (pending[i] == null) {
          pending[i] = current;
          break;
        }

        // Combine hashes and carry to next level
        current = _combineHashes(pending[i]!, current);
        pending[i] = null;
      }
    }

    // Combine remaining pending hashes
    Uint8List? anchor;
    for (final v in pending) {
      if (anchor == null) {
        anchor = v;
      } else if (v != null) {
        anchor = _combineHashes(v, anchor);
      }
    }

    return anchor ?? Uint8List(32);
  }

  /// Combine two hashes: SHA256(left + right)
  static Uint8List _combineHashes(Uint8List left, Uint8List right) {
    final combined = Uint8List.fromList([...left, ...right]);
    return Uint8List.fromList(sha256.convert(combined).bytes);
  }

  static Uint8List _hexToBytes(String hex) {
    final cleaned = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (cleaned.isEmpty) return Uint8List(0);
    final bytes = Uint8List(cleaned.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(cleaned.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  /// Create signing preimage - implements discovered signing rules
  ///
  /// Based on Go: protocol/signature_utils.go:50-57
  /// signingHash = SHA256(sigMdHash + txnHash)
  static Uint8List createSigningPreimage(
      Uint8List signatureMetadataHash, Uint8List transactionHash) {
    final combined =
        Uint8List.fromList([...signatureMetadataHash, ...transactionHash]);
    return Uint8List.fromList(sha256.convert(combined).bytes);
  }

  /// Compute the initiator hash using Merkle hash algorithm
  ///
  /// Based on Go: protocol/signature.go Initiator() method
  /// The initiator is the Merkle hash of [SHA256(publicKey), SHA256(signer), SHA256(uvarint(signerVersion)), SHA256(uvarint(timestamp))]
  ///
  /// This is used in the transaction header's initiator field.
  static Uint8List computeInitiatorHash({
    required Uint8List publicKey,
    required String signer,
    required int signerVersion,
    required int timestamp,
  }) {
    // Build list of hashes for Merkle computation
    final hashes = <Uint8List>[];

    // 1. SHA256(publicKey)
    hashes.add(Uint8List.fromList(sha256.convert(publicKey).bytes));

    // 2. SHA256(signer URL string)
    final signerBytes = utf8.encode(signer);
    hashes.add(Uint8List.fromList(sha256.convert(signerBytes).bytes));

    // 3. SHA256(uvarint(signerVersion))
    final versionBytes = _encodeUvarint(signerVersion);
    hashes.add(Uint8List.fromList(sha256.convert(versionBytes).bytes));

    // 4. SHA256(uvarint(timestamp))
    final timestampBytes = _encodeUvarint(timestamp);
    hashes.add(Uint8List.fromList(sha256.convert(timestampBytes).bytes));

    // Compute Merkle hash of these 4 hashes
    return _merkleHash(hashes);
  }

  /// Encode unsigned integer as uvarint
  static Uint8List _encodeUvarint(int value) {
    final result = <int>[];
    var v = value;
    while (v >= 0x80) {
      result.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    result.add(v & 0x7F);
    return Uint8List.fromList(result);
  }

  /// Compute signature metadata hash for ED25519 (default)
  ///
  /// Based on Go: protocol/signature.go Metadata() method
  /// The metadata is the signature with Signature=nil and TransactionHash=[32]byte{}
  static Uint8List computeSignatureMetadataHash({
    required Uint8List publicKey,
    String? signer,
    int signerVersion = 0,
    int timestamp = 0,
    int vote = 0,
    String? memo,
    Uint8List? data,
  }) {
    return computeSignatureMetadataHashForType(
      signatureType: SignatureTypeEnum.ed25519,
      publicKey: publicKey,
      signer: signer,
      signerVersion: signerVersion,
      timestamp: timestamp,
      vote: vote,
      memo: memo,
      data: data,
    );
  }

  /// Compute signature metadata hash for any signature type
  ///
  /// Based on Go: protocol/signature.go Metadata() method
  /// The metadata is the signature with Signature=nil and TransactionHash=[32]byte{}
  ///
  /// IMPORTANT: Each signature type has a different Type enum value in field 1,
  /// which affects the metadata hash and thus the signing preimage.
  static Uint8List computeSignatureMetadataHashForType({
    required int signatureType,
    required Uint8List publicKey,
    String? signer,
    int signerVersion = 0,
    int timestamp = 0,
    int vote = 0,
    String? memo,
    Uint8List? data,
  }) {
    final metadataBytes = SignatureMarshaler.marshalMetadata(
      signatureType: signatureType,
      publicKey: publicKey,
      signer: signer,
      signerVersion: signerVersion,
      timestamp: timestamp,
      vote: vote,
      memo: memo,
      data: data,
    );

    if (debugPrintBinary) {
      print("DEBUG: Sig type $signatureType metadata bytes (${metadataBytes.length}): ${metadataBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}");
    }

    return Uint8List.fromList(sha256.convert(metadataBytes).bytes);
  }
}
