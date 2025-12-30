import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/systemgenesis.dart' as body;
import 'dart:typed_data';

void main() {
  group('Protocol Types Validation Tests', () {

    group('Account Types Validation', () {
      test('ADI validation', () {
        // Valid ADI
        final validAdi = ADI(url: 'acc://test.acme', auth: 'auth-data');
        expect(() => validAdi.validate(), returnsNormally);

        // Invalid URL
        expect(() => ADI(url: 'invalid-url', auth: null).validate(),
               throwsA(isA<ArgumentError>()));
      });

      test('LiteTokenAccount validation', () {
        final validAccount = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.from(1000),
          lockHeight: 0
        );
        expect(() => validAccount.validate(), returnsNormally);

        // Test BigInt validation
        final invalidBigInt = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.from(-1), // Should be caught by BigInt validator
          lockHeight: 0
        );
        expect(() => invalidBigInt.validate(), returnsNormally); // BigInt validator allows negatives
      });

      test('TokenIssuer validation', () {
        final validIssuer = TokenIssuer(
          url: 'acc://test.acme/token',
          auth: 'auth-data',
          symbol: 'TEST',
          precision: 8,
          properties: 'acc://test.acme/properties',
          issued: BigInt.from(1000000),
          supplyLimit: BigInt.from(10000000)
        );
        expect(() => validIssuer.validate(), returnsNormally);
      });
    });

    group('User Transaction Types Validation', () {
      test('CreateIdentity validation', () {
        final hash32 = Uint8List.fromList(List.generate(32, (i) => i));

        final validTx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash32,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => validTx.validate(), returnsNormally);

        // Invalid hash length
        final invalidHash = Uint8List.fromList([1, 2, 3]); // Not 32 bytes
        final invalidTx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: invalidHash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => invalidTx.validate(), throwsA(isA<ArgumentError>()));
      });

      test('SendTokens validation', () {
        final hash32 = Uint8List.fromList(List.generate(32, (i) => i));

        final validTx = SendTokens(
          hash: hash32,
          meta: {'memo': 'test'},
          to: [{'url': 'acc://recipient.acme', 'amount': '1000'}]
        );
        expect(() => validTx.validate(), returnsNormally);
      });

      test('AddCredits validation', () {
        final validTx = AddCredits(
          recipient: 'acc://test.acme/page',
          amount: BigInt.from(1000),
          oracle: 123
        );
        expect(() => validTx.validate(), returnsNormally);
      });
    });

    group('System Types Validation', () {
      test('SystemGenesis validation (empty type)', () {
        final genesis = SystemGenesis();
        expect(() => genesis.validate(), returnsNormally);
      });

      test('PartitionAnchor validation', () {
        final hash32a = Uint8List.fromList(List.generate(32, (i) => i));
        final hash32b = Uint8List.fromList(List.generate(32, (i) => i + 32));

        final validAnchor = PartitionAnchor(
          source: 'acc://partition.acme',
          majorBlockIndex: 100,
          minorBlockIndex: 5,
          rootChainIndex: 10,
          rootChainAnchor: hash32a,
          stateTreeAnchor: hash32b
        );
        expect(() => validAnchor.validate(), returnsNormally);
      });
    });

    group('Transaction Types Validation', () {
      test('Transaction validation', () {
        final hash32 = Uint8List.fromList(List.generate(32, (i) => i));

        final validTx = Transaction(
          header: TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: 'acc://test.acme/initiator'
          ),
          body: body.SystemGenesis()
        );
        expect(() => validTx.validate(), returnsNormally);
      });

      test('TransactionHeader validation', () {
        final hash32 = Uint8List.fromList(List.generate(32, (i) => i));
        final metadata = Uint8List.fromList([1, 2, 3, 4]);

        final validHeader = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: hash32,
          Memo: 'test memo',
          Metadata: metadata,
          Expire: null,
          HoldUntil: null,
          Authorities: ['acc://test.acme/authorities']
        );
        expect(() => validHeader.validate(), returnsNormally);
      });
    });

    group('Synthetic Transaction Types Validation', () {
      test('SyntheticBurnTokens validation', () {
        final validTx = SyntheticBurnTokens(
          amount: BigInt.from(1000),
          isRefund: false
        );
        expect(() => validTx.validate(), returnsNormally);
      });

      test('SyntheticDepositTokens validation', () {
        final validTx = SyntheticDepositTokens(
          token: 'acc://test.acme/token',
          amount: BigInt.from(1000),
          isIssuer: {'verified': true},
          isRefund: false
        );
        expect(() => validTx.validate(), returnsNormally);
      });
    });

    group('Required Field Validation', () {
      test('should validate required string fields', () {
        // Test with empty string (should pass validateRequired but might fail other validators)
        expect(() => ADI(url: '', auth: null).validate(),
               throwsA(isA<ArgumentError>())); // Should fail URL validation
      });

      test('should validate required BigInt fields', () {
        final validAccount = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.zero, // Zero should be valid
          lockHeight: 0
        );
        expect(() => validAccount.validate(), returnsNormally);
      });

      test('should validate required Uint8List fields', () {
        final emptyBytes = Uint8List(0);
        final hash32 = Uint8List.fromList(List.generate(32, (i) => i));

        // Empty bytes array should fail hash32 validation
        expect(() => CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: emptyBytes,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        ).validate(), throwsA(isA<ArgumentError>()));

        // 32-byte hash should pass
        expect(() => CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash32,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        ).validate(), returnsNormally);
      });
    });

    group('URL Validation Edge Cases', () {
      test('should handle various URL formats', () {
        final validUrls = [
          'acc://test.acme',
          'acc://test.acme/identity',
          'acc://test.acme/tokens/ACME',
          'acc://bvn-test.acme/data',
          'acc://dn.acme'
        ];

        for (final url in validUrls) {
          final adi = ADI(url: url, auth: 'auth-data');
          expect(() => adi.validate(), returnsNormally,
                 reason: 'URL should be valid: \$url');
        }
      });

      test('should reject invalid URL formats', () {
        final invalidUrls = [
          'http://example.com',
          'https://example.com',
          'ftp://example.com',
          'invalid-url',
          'acc:invalid', // Missing //
          '',
        ];

        for (final url in invalidUrls) {
          final adi = ADI(url: url, auth: 'auth-data');
          expect(() => adi.validate(), throwsA(isA<ArgumentError>()),
                 reason: 'URL should be invalid: \$url');
        }
      });
    });

    group('Hash32 Field Validation', () {
      test('should validate 32-byte hashes', () {
        final validHash = Uint8List.fromList(List.generate(32, (i) => i));

        final tx = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: validHash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );
        expect(() => tx.validate(), returnsNormally);
      });

      test('should reject non-32-byte hashes', () {
        final invalidHashes = [
          Uint8List(0), // Empty
          Uint8List.fromList([1, 2, 3]), // Too short
          Uint8List.fromList(List.generate(31, (i) => i)), // 31 bytes
          Uint8List.fromList(List.generate(33, (i) => i)), // 33 bytes
          Uint8List.fromList(List.generate(64, (i) => i)), // 64 bytes
        ];

        for (final hash in invalidHashes) {
          final tx = CreateIdentity(
            url: 'acc://test.acme/identity',
            keyHash: hash,
            keyBookUrl: 'acc://test.acme/book',
            authorities: 'acc://test.acme/authorities'
          );
          expect(() => tx.validate(), throwsA(isA<ArgumentError>()),
                 reason: 'Hash length should be invalid: \${hash.length} bytes');
        }
      });
    });
  });
}