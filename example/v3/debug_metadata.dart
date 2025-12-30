// Debug script to trace metadata TLV encoding
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'package:opendlt_accumulate/src/codec/binary_encoder.dart';
import 'package:opendlt_accumulate/src/codec/transaction_codec.dart';

Future<void> main() async {
  // Enable debug output
  TransactionCodec.debugPrintBinary = true;

  // Use fixed test data to make comparison easy
  final testPubKey = Uint8List(32);
  for (var i = 0; i < 32; i++) testPubKey[i] = i;

  final testSigner = "acc://test.acme/book/1";
  final testSignerVersion = 1;
  final testTimestamp = 1704067200000000; // Fixed timestamp

  print("=== Test Parameters ===");
  print("Public Key: ${toHex(testPubKey)}");
  print("Signer: $testSigner");
  print("SignerVersion: $testSignerVersion");
  print("Timestamp: $testTimestamp");

  print("\n=== Ed25519 Metadata (Type=2) ===");
  final ed25519Metadata = SignatureMarshaler.marshalMetadata(
    signatureType: SignatureTypeEnum.ed25519,
    publicKey: testPubKey,
    signer: testSigner,
    signerVersion: testSignerVersion,
    timestamp: testTimestamp,
  );
  print("Metadata bytes (${ed25519Metadata.length}): ${toHex(ed25519Metadata)}");
  final ed25519MetaHash = sha256.convert(ed25519Metadata);
  print("Metadata SHA256: ${ed25519MetaHash.toString()}");

  // Parse the TLV to verify structure
  print("\nTLV breakdown:");
  _parseTLV(ed25519Metadata);

  print("\n=== RCD1 Metadata (Type=3) ===");
  final rcd1Metadata = SignatureMarshaler.marshalMetadata(
    signatureType: SignatureTypeEnum.rcd1,
    publicKey: testPubKey,
    signer: testSigner,
    signerVersion: testSignerVersion,
    timestamp: testTimestamp,
  );
  print("Metadata bytes (${rcd1Metadata.length}): ${toHex(rcd1Metadata)}");
  final rcd1MetaHash = sha256.convert(rcd1Metadata);
  print("Metadata SHA256: ${rcd1MetaHash.toString()}");

  print("\nTLV breakdown:");
  _parseTLV(rcd1Metadata);

  print("\n=== BTC Metadata (Type=4) ===");
  // BTC uses 33-byte compressed public key
  final btcPubKey = Uint8List(33);
  btcPubKey[0] = 0x02; // compressed prefix
  for (var i = 1; i < 33; i++) btcPubKey[i] = i - 1;

  final btcMetadata = SignatureMarshaler.marshalMetadata(
    signatureType: SignatureTypeEnum.btc,
    publicKey: btcPubKey,
    signer: testSigner,
    signerVersion: testSignerVersion,
    timestamp: testTimestamp,
  );
  print("Metadata bytes (${btcMetadata.length}): ${toHex(btcMetadata)}");
  final btcMetaHash = sha256.convert(btcMetadata);
  print("Metadata SHA256: ${btcMetaHash.toString()}");

  print("\nTLV breakdown:");
  _parseTLV(btcMetadata);

  print("\n=== ETH Metadata (Type=6) ===");
  // ETH uses 65-byte uncompressed public key
  final ethPubKey = Uint8List(65);
  ethPubKey[0] = 0x04; // uncompressed prefix
  for (var i = 1; i < 65; i++) ethPubKey[i] = i - 1;

  final ethMetadata = SignatureMarshaler.marshalMetadata(
    signatureType: SignatureTypeEnum.eth,
    publicKey: ethPubKey,
    signer: testSigner,
    signerVersion: testSignerVersion,
    timestamp: testTimestamp,
  );
  print("Metadata bytes (${ethMetadata.length}): ${toHex(ethPubKey)}");
  print("ETH PubKey for wire (${ethPubKey.length}): ${toHex(ethPubKey)}");
  print("Metadata bytes (${ethMetadata.length}): ${toHex(ethMetadata)}");
  final ethMetaHash = sha256.convert(ethMetadata);
  print("Metadata SHA256: ${ethMetaHash.toString()}");

  print("\nTLV breakdown:");
  _parseTLV(ethMetadata);
}

void _parseTLV(Uint8List data) {
  int offset = 0;
  while (offset < data.length) {
    // Read field number (uvarint)
    var fieldNum = 0;
    var shift = 0;
    while (offset < data.length) {
      final b = data[offset++];
      fieldNum |= (b & 0x7F) << shift;
      if ((b & 0x80) == 0) break;
      shift += 7;
    }

    print("  Field $fieldNum:");

    // Determine field type based on field number
    if (fieldNum == 1) {
      // Type enum (uvarint)
      var value = 0;
      shift = 0;
      while (offset < data.length) {
        final b = data[offset++];
        value |= (b & 0x7F) << shift;
        if ((b & 0x80) == 0) break;
        shift += 7;
      }
      print("    Type enum: $value");
    } else if (fieldNum == 2 || fieldNum == 3 || fieldNum == 10) {
      // Bytes (length-prefixed)
      var length = 0;
      shift = 0;
      while (offset < data.length) {
        final b = data[offset++];
        length |= (b & 0x7F) << shift;
        if ((b & 0x80) == 0) break;
        shift += 7;
      }
      final value = data.sublist(offset, offset + length);
      offset += length;
      print("    Bytes ($length): ${toHex(Uint8List.fromList(value))}");
    } else if (fieldNum == 4 || fieldNum == 9) {
      // String (length-prefixed)
      var length = 0;
      shift = 0;
      while (offset < data.length) {
        final b = data[offset++];
        length |= (b & 0x7F) << shift;
        if ((b & 0x80) == 0) break;
        shift += 7;
      }
      final value = String.fromCharCodes(data.sublist(offset, offset + length));
      offset += length;
      print("    String ($length): $value");
    } else if (fieldNum == 5 || fieldNum == 6 || fieldNum == 7) {
      // Uint (uvarint)
      var value = 0;
      shift = 0;
      while (offset < data.length) {
        final b = data[offset++];
        value |= (b & 0x7F) << shift;
        if ((b & 0x80) == 0) break;
        shift += 7;
      }
      print("    Uint: $value");
    } else if (fieldNum == 8) {
      // Hash (32 bytes, no length prefix)
      final value = data.sublist(offset, offset + 32);
      offset += 32;
      print("    Hash: ${toHex(Uint8List.fromList(value))}");
    } else {
      print("    Unknown field type");
      break;
    }
  }
}
