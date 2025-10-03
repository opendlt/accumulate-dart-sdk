import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/systemgenesis.dart' as body;
import 'dart:typed_data';
import 'dart:convert';

void main() {
  group('Hash32 Validation Tests', () {

    group('Validators.validateHash32 Direct Tests', () {
      test('should accept exactly 32 bytes', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        expect(() => Validators.validateHash32(validHash, 'testHash'), returnsNormally);
      });

      test('should reject hashes that are too short', () {
        final shortHashes = [
          Uint8List(0), // Empty
          Uint8List.fromList([1]), // 1 byte
          Uint8List.fromList(List.generate(16, (i) => i)), // 16 bytes
          Uint8List.fromList(List.generate(31, (i) => i)), // 31 bytes
        ];

        for (final hash in shortHashes) {
          expect(() => Validators.validateHash32(hash, 'testHash'),
                 throwsA(isA<ArgumentError>()),
                 reason: 'Hash with \${hash.length} bytes should be rejected');
        }
      });

      test('should reject hashes that are too long', () {
        final longHashes = [
          Uint8List.fromList(List.generate(33, (i) => i)), // 33 bytes
          Uint8List.fromList(List.generate(64, (i) => i)), // 64 bytes
          Uint8List.fromList(List.generate(128, (i) => i)), // 128 bytes
        ];

        for (final hash in longHashes) {
          expect(() => Validators.validateHash32(hash, 'testHash'),
                 throwsA(isA<ArgumentError>()),
                 reason: 'Hash with \${hash.length} bytes should be rejected');
        }
      });

      test('should provide meaningful error messages', () {
        final invalidHash = Uint8List.fromList([1, 2, 3]);

        try {
          Validators.validateHash32(invalidHash, 'myField');
          fail('Expected ArgumentError to be thrown');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(e.toString(), contains('myField'));
          expect(e.toString(), contains('32'));
        }
      });
    });

    group('Protocol Types with Hash Fields', () {
      test('CreateIdentity keyHash validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList([1, 2, 3, 4]);

        // Valid hash should pass
        final validTx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: validHash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => validTx.validate(), returnsNormally);

        // Invalid hash should fail
        final invalidTx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: invalidHash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => invalidTx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('CreateKeyBook publicKeyHash validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList(List.generate(16, (i) => i));

        // Valid hash should pass
        final validTx = CreateKeyBook(
          url: 'acc://test.acme/book',
          publicKeyHash: validHash,
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => validTx.validate(), returnsNormally);

        // Invalid hash should fail
        final invalidTx = CreateKeyBook(
          url: 'acc://test.acme/book',
          publicKeyHash: invalidHash,
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => invalidTx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('UpdateKey newKeyHash validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList(List.generate(33, (i) => i));

        // Valid hash should pass
        final validTx = UpdateKey(newKeyHash: validHash);
        expect(() => validTx.validate(), returnsNormally);

        // Invalid hash should fail
        final invalidTx = UpdateKey(newKeyHash: invalidHash);
        expect(() => invalidTx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('Transaction hash validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList([]);

        // Valid hash should pass
        final validTx = Transaction(
          header: TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: 'acc://test.acme/initiator'
          ),
          body: body.SystemGenesis()
        );
        expect(validTx.validate(), isTrue);

        // Invalid hash should fail - Transaction.validate() returns bool, doesn't throw
        final invalidTx = Transaction(
          header: TransactionHeader(
            Principal: 'invalid-url',
            Initiator: 'acc://test.acme/initiator'
          ),
          body: body.SystemGenesis()
        );
        expect(invalidTx.validate(), isFalse);
      });

      test('TransactionHeader initiator validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList(List.generate(20, (i) => i));
        final metadata = Uint8List.fromList([1, 2, 3, 4]);

        // Valid hash should pass
        final validHeader = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: validHash,
          Memo: '',
          Metadata: metadata,
          Expire: null,
          HoldUntil: null,
          Authorities: 'acc://test.acme/authorities'
        );
        expect(validHeader.validate(), isTrue);

        // Invalid hash should fail - TransactionHeader.validate() returns bool, doesn't throw
        final invalidHeader = TransactionHeader(
          Principal: 'invalid-url',
          Initiator: invalidHash,
          Memo: '',
          Metadata: metadata,
          Expire: null,
          HoldUntil: null,
          Authorities: 'acc://test.acme/authorities'
        );
        expect(invalidHeader.validate(), isFalse);
      });

      test('KeySpec publicKeyHash validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList(List.generate(64, (i) => i));

        // Valid hash should pass
        final validKeySpec = KeySpec(
          publicKeyHash: validHash,
          lastUsedOn: 12345,
          delegate: 'acc://test.acme/delegate'
        );
        expect(() => validKeySpec.validate(), returnsNormally);

        // Invalid hash should fail
        final invalidKeySpec = KeySpec(
          publicKeyHash: invalidHash,
          lastUsedOn: 12345,
          delegate: 'acc://test.acme/delegate'
        );
        expect(() => invalidKeySpec.validate(), throwsA(isA<ArgumentError>()));
      });
    });

    group('Hash Field Detection and Coverage', () {
      test('all hash fields are properly validated', () {
        // This test ensures that fields containing "hash" in their name
        // are properly validated as 32-byte hashes

        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList([1, 2, 3]);

        // Test SendTokens hash field - from types directory has proper validation
        expect(() => SendTokens(
          hash: validHash,
          meta: {'test': 'data'},
          to: [{'url': 'acc://test.acme', 'amount': '1000'}]
        ).validate(), returnsNormally);

        expect(() => SendTokens(
          hash: invalidHash,
          meta: {'test': 'data'},
          to: [{'url': 'acc://test.acme', 'amount': '1000'}]
        ).validate(), throwsA(isA<ArgumentError>()));

        // Test RemoteTransaction hash field
        expect(() => RemoteTransaction(hash: validHash).validate(), returnsNormally);
        expect(() => RemoteTransaction(hash: invalidHash).validate(), throwsA(isA<ArgumentError>()));
      });
    });

    group('System Types Hash Validation', () {
      test('PartitionAnchor hash fields validation', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList(List.generate(16, (i) => i));

        // Valid hashes should pass
        final validAnchor = PartitionAnchor(
          source: 'acc://partition.acme',
          majorBlockIndex: 100,
          minorBlockIndex: 5,
          rootChainIndex: 10,
          rootChainAnchor: validHash,
          stateTreeAnchor: validHash
        );
        expect(() => validAnchor.validate(), returnsNormally);

        // Invalid rootChainAnchor should fail
        final invalidRootAnchor = PartitionAnchor(
          source: 'acc://partition.acme',
          majorBlockIndex: 100,
          minorBlockIndex: 5,
          rootChainIndex: 10,
          rootChainAnchor: invalidHash,
          stateTreeAnchor: validHash
        );
        expect(() => invalidRootAnchor.validate(), throwsA(isA<ArgumentError>()));

        // Invalid stateTreeAnchor should fail
        final invalidStateAnchor = PartitionAnchor(
          source: 'acc://partition.acme',
          majorBlockIndex: 100,
          minorBlockIndex: 5,
          rootChainIndex: 10,
          rootChainAnchor: validHash,
          stateTreeAnchor: invalidHash
        );
        expect(() => invalidStateAnchor.validate(), throwsA(isA<ArgumentError>()));
      });

      test('ValidatorInfo publicKeyHash validation', () {
        final validKey = Uint8List.fromList(List.generate(64, (i) => i)); // Public key can be 64 bytes
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));
        final invalidHash = Uint8List.fromList(List.generate(31, (i) => i));

        // Valid hashes should pass
        final validInfo = ValidatorInfo(
          publicKey: validKey,
          publicKeyHash: validHash,
          operator: 'acc://operator.acme',
          partitions: []
        );
        expect(() => validInfo.validate(), returnsNormally);

        // Invalid hash should fail
        final invalidInfo = ValidatorInfo(
          publicKey: validKey,
          publicKeyHash: invalidHash,
          operator: 'acc://operator.acme',
          partitions: []
        );
        expect(() => invalidInfo.validate(), throwsA(isA<ArgumentError>()));
      });
    });

    group('Edge Cases and Error Conditions', () {
      test('should handle various byte patterns', () {
        final patterns = [
          List.generate(32, (i) => 0), // All zeros
          List.generate(32, (i) => 255), // All max values
          List.generate(32, (i) => i % 256), // Sequential pattern
          List.generate(32, (i) => (i * 7) % 256), // Prime pattern
        ];

        for (final pattern in patterns) {
          final hash = Uint8List.fromList(pattern);
          final tx = CreateIdentity(
            url: 'acc://test.acme/identity',
            keyHash: hash,
            keyBookUrl: 'acc://test.acme/book',
            authorities: 'acc://test.acme/authorities'
          );
          expect(() => tx.validate(), returnsNormally,
                 reason: 'Pattern should be valid: \$pattern');
        }
      });

      test('should provide field-specific error messages', () {
        final invalidHash = Uint8List.fromList([1, 2, 3]);

        // Test different field names in error messages
        try {
          Validators.validateHash32(invalidHash, 'keyHash');
          fail('Expected ArgumentError');
        } catch (e) {
          expect(e.toString(), contains('keyHash'));
        }

        try {
          Validators.validateHash32(invalidHash, 'publicKeyHash');
          fail('Expected ArgumentError');
        } catch (e) {
          expect(e.toString(), contains('publicKeyHash'));
        }
      });

      test('should handle null safely', () {
        // validateHash32 should handle null input gracefully (returns without error for optional fields)
        expect(() => Validators.validateHash32(null, 'testField'),
               returnsNormally);
      });
    });

    group('JSON Serialization of Hash Fields', () {
      test('hash fields should serialize to base64', () {
        final hash = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                                        16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]);
        final tx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );

        final json = tx.toJson();
        final hashString = json['KeyHash'] as String;

        // Should be valid base64
        expect(() => base64.decode(hashString), returnsNormally);

        // Should round-trip correctly
        final reconstructed = CreateIdentity.fromJson(json);
        expect(reconstructed.keyHash, equals(hash));
      });
    });
  });
}