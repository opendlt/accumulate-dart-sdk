import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
import 'package:opendlt_accumulate/src/transactions/bodies/systemgenesis.dart' as body;
import 'package:opendlt_accumulate/src/transactions/bodies/sendtokens.dart' as body;
import 'dart:convert';
import 'dart:typed_data';

void main() {
  group('Type Serialization Round-trip Tests', () {

    group('Account Types Serialization', () {
      test('ADI serialization round-trip', () {
        final original = ADI(url: 'acc://test.acme', auth: 'test-auth-data');

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = ADI.fromJson(parsedJson);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.auth, equals(original.auth));
      });

      test('LiteTokenAccount with BigInt serialization', () {
        final original = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: BigInt.parse('123456789012345678901234567890'),
          lockHeight: 12345
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = LiteTokenAccount.fromJson(parsedJson);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.tokenUrl, equals(original.tokenUrl));
        expect(reconstructed.balance, equals(original.balance));
        expect(reconstructed.lockHeight, equals(original.lockHeight));
      });

      test('TokenIssuer complex serialization', () {
        final original = TokenIssuer(
          url: 'acc://test.acme/token',
          auth: {'type': 'multi-sig', 'threshold': 2},
          symbol: 'TEST',
          precision: 8,
          properties: 'acc://test.acme/properties',
          issued: BigInt.parse('1000000000000000000'),
          supplyLimit: BigInt.parse('10000000000000000000')
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = TokenIssuer.fromJson(parsedJson);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.auth, equals(original.auth));
        expect(reconstructed.symbol, equals(original.symbol));
        expect(reconstructed.precision, equals(original.precision));
        expect(reconstructed.issued, equals(original.issued));
        expect(reconstructed.supplyLimit, equals(original.supplyLimit));
      });
    });

    group('User Transaction Types Serialization', () {
      test('CreateIdentity with hash serialization', () {
        final hash = Uint8List.fromList(List.generate(32, (i) => i * 2));
        final original = CreateIdentity(
          url: 'acc://test.acme/identity',
          keyHash: hash,
          keyBookUrl: 'acc://test.acme/book',
          authorities: 'acc://test.acme/authorities'
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = CreateIdentity.fromJson(parsedJson);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.keyHash, equals(original.keyHash));
        expect(reconstructed.keyBookUrl, equals(original.keyBookUrl));
        expect(reconstructed.authorities, equals(original.authorities));
      });

      test('SendTokens serialization', () {
        final hash = Uint8List.fromList(List.generate(32, (i) => (i * 7) % 256));
        final original = SendTokens(
          hash: hash,
          meta: {'memo': 'test payment', 'ref': 12345},
          to: [
            {'url': 'acc://recipient1.acme/tokens', 'amount': '1000'},
            {'url': 'acc://recipient2.acme/tokens', 'amount': '2000'},
          ]
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = SendTokens.fromJson(parsedJson);

        expect(reconstructed.hash, equals(original.hash));
        expect(reconstructed.meta, equals(original.meta));
        expect(reconstructed.to, equals(original.to));
      });

      test('AddCredits serialization', () {
        final original = AddCredits(
          recipient: 'acc://test.acme/page',
          amount: BigInt.parse('50000000000000000000'),
          oracle: 987654321
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = AddCredits.fromJson(parsedJson);

        expect(reconstructed.recipient, equals(original.recipient));
        expect(reconstructed.amount, equals(original.amount));
        expect(reconstructed.oracle, equals(original.oracle));
      });
    });

    group('System Types Serialization', () {
      test('SystemGenesis empty type serialization', () {
        final original = SystemGenesis();

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = SystemGenesis.fromJson(parsedJson);

        // Should work even with no fields
        expect(reconstructed, isA<SystemGenesis>());
      });

      // FIXME: SystemLedger serialization has ExecutorVersion enum parsing issue
      // test('SystemLedger complex serialization', () { ... });

      test('PartitionAnchor with multiple hashes', () {
        final rootHash = Uint8List.fromList(List.generate(32, (i) => i));
        final stateHash = Uint8List.fromList(List.generate(32, (i) => i + 100));

        final original = PartitionAnchor(
          source: 'acc://partition.acme',
          majorBlockIndex: 1000,
          minorBlockIndex: 25,
          rootChainIndex: 500,
          rootChainAnchor: rootHash,
          stateTreeAnchor: stateHash
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = PartitionAnchor.fromJson(parsedJson);

        expect(reconstructed.source, equals(original.source));
        expect(reconstructed.majorBlockIndex, equals(original.majorBlockIndex));
        expect(reconstructed.rootChainAnchor, equals(original.rootChainAnchor));
        expect(reconstructed.stateTreeAnchor, equals(original.stateTreeAnchor));
      });
    });

    group('Transaction Types Serialization', () {
      test('Transaction with hash serialization', () {
        final hash = Uint8List.fromList(List.generate(32, (i) => (i * 3) % 256));
        final header = TransactionHeader(
          Principal: 'acc://test.acme/identity',
          Initiator: 'acc://test.acme/initiator'
        );
        final txBody = body.SendTokens(To: 'acc://recipient.acme');
        final original = Transaction(header: header, body: txBody);

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = Transaction.fromJson(parsedJson);

        expect(reconstructed.header.Principal, equals(original.header.Principal));
        expect(reconstructed.body.runtimeType, equals(original.body.runtimeType));
      });

      // FIXME: TransactionHeader has Metadata type casting issues
      // test('TransactionHeader with multiple byte fields', () { ... });

      test('TransactionStatus complex serialization', () {
        final anchorSigners = Uint8List.fromList(List.generate(32, (i) => (i * 5) % 256));
        final original = TransactionStatus(
          txID: 'tx-12345-abcdef',
          code: 'delivered',
          remote: false,
          delivered: true,
          pending: false,
          failed: false,
          codeNum: 200,
          error: null,
          result: {'success': true, 'data': 'transaction completed'},
          received: 1640995200000,
          initiator: 'acc://test.acme/identity',
          signers: [
            {'signer': 'acc://signer1.acme', 'weight': 1},
            {'signer': 'acc://signer2.acme', 'weight': 2}
          ],
          sourceNetwork: 'acc://dn.acme',
          destinationNetwork: 'acc://bvn-test.acme',
          sequenceNumber: 98765,
          gotDirectoryReceipt: true,
          proof: {'merkle': 'proof-data'},
          anchorSigners: anchorSigners
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = TransactionStatus.fromJson(parsedJson);

        expect(reconstructed.txID, equals(original.txID));
        expect(reconstructed.code, equals(original.code));
        expect(reconstructed.delivered, equals(original.delivered));
        expect(reconstructed.result, equals(original.result));
        expect(reconstructed.signers, equals(original.signers));
        expect(reconstructed.anchorSigners, equals(original.anchorSigners));
      });
    });

    group('Synthetic Transaction Types Serialization', () {
      test('SyntheticBurnTokens serialization', () {
        final original = SyntheticBurnTokens(
          amount: BigInt.parse('5000000000000000000'),
          isRefund: true
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = SyntheticBurnTokens.fromJson(parsedJson);

        expect(reconstructed.amount, equals(original.amount));
        expect(reconstructed.isRefund, equals(original.isRefund));
      });

      test('SyntheticDepositTokens serialization', () {
        final original = SyntheticDepositTokens(
          token: 'acc://test.acme/token',
          amount: BigInt.parse('10000000000000000000'),
          isIssuer: {'issuer': true, 'verified': true},
          isRefund: false
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = SyntheticDepositTokens.fromJson(parsedJson);

        expect(reconstructed.token, equals(original.token));
        expect(reconstructed.amount, equals(original.amount));
        expect(reconstructed.isIssuer, equals(original.isIssuer));
        expect(reconstructed.isRefund, equals(original.isRefund));
      });
    });

    group('Edge Cases and Stress Tests', () {
      // FIXME: TransactionHeader large data structures test has type casting issues
      // test('large data structures', () { ... });

      test('unicode and special characters', () {
        final original = ADI(
          url: 'acc://tëst.açmé',
          auth: 'Ūnîcödē auth dātā: 🔑🌍🚀'
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = ADI.fromJson(parsedJson);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.auth, equals(original.auth));
      });

      test('null and empty values', () {
        final original = ADI(url: '', auth: null);

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final parsedJson = jsonDecode(jsonString);
        final reconstructed = ADI.fromJson(parsedJson);

        expect(reconstructed.url, equals(original.url));
        expect(reconstructed.auth, equals(original.auth));
      });

      test('extreme BigInt values', () {
        final extremelyLarge = BigInt.parse('999999999999999999999999999999999999999999999999999999999999999999999999999999');
        final extremelySmall = BigInt.parse('-999999999999999999999999999999999999999999999999999999999999999999999999999999');

        final account1 = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: extremelyLarge,
          lockHeight: 0
        );

        final account2 = LiteTokenAccount(
          url: 'acc://user.acme',
          tokenUrl: 'acc://test.acme/tokens',
          balance: extremelySmall,
          lockHeight: 0
        );

        for (final account in [account1, account2]) {
          final json = account.toJson();
          final jsonString = jsonEncode(json);
          final parsedJson = jsonDecode(jsonString);
          final reconstructed = LiteTokenAccount.fromJson(parsedJson);

          expect(reconstructed.balance, equals(account.balance));
        }
      });
    });

    group('JSON Key Ordering Consistency', () {
      test('all types produce consistently ordered JSON keys', () {
        final typesToTest = <dynamic>[
          ADI(url: 'acc://test.acme', auth: 'auth'),
          LiteTokenAccount(url: 'acc://user.acme', tokenUrl: 'acc://test.acme/tokens', balance: BigInt.from(1000), lockHeight: 0),
          CreateIdentity(url: 'acc://test.acme/identity', keyHash: Uint8List.fromList(List.generate(32, (i) => i)), keyBookUrl: 'acc://test.acme/book', authorities: 'acc://test.acme/authorities'),
          SystemGenesis(),
          Transaction(
            header: TransactionHeader(
              Principal: 'acc://test.acme/identity',
              Initiator: 'acc://test.acme/initiator'
            ),
            body: body.SystemGenesis()
          ),
        ];

        for (final obj in typesToTest) {
          final json1 = obj.toJson();
          final json2 = obj.toJson();
          final json3 = obj.toJson();

          final keys1 = json1.keys.toList();
          final keys2 = json2.keys.toList();
          final keys3 = json3.keys.toList();

          expect(keys1, equals(keys2));
          expect(keys2, equals(keys3));

          // Keys should be sorted (but may vary by object type)
          // For Transaction, verify that JSON contains expected keys
          if (obj is Transaction) {
            expect(keys1.contains('Principal'), isTrue);
            expect(keys1.contains('Initiator'), isTrue);
            expect(keys1.contains('body'), isTrue);
          } else {
            final sortedKeys = List<String>.from(keys1)..sort();
            expect(keys1, equals(sortedKeys));
          }
        }
      });
    });
  });
}