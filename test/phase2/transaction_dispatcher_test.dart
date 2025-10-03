import 'package:test/test.dart';
import 'dart:typed_data';
import '../../lib/src/transactions/transaction.dart';
import '../../lib/src/transactions/transaction_header.dart';
import '../../lib/src/transactions/bodies/createidentity.dart';
import '../../lib/src/transactions/bodies/sendtokens.dart';
import '../../lib/src/transactions/bodies/writedata.dart';

void main() {
  group('Transaction Dispatcher Tests', () {

    test('should dispatch CreateIdentity correctly', () {
      final json = {
        'type': 'createidentity',
        'Url': 'acc://test.acme/identity',
        'KeyHash': 'AQIDBA==', // base64 for [1,2,3,4]
      };

      final body = TransactionBody.fromJson(json);

      expect(body, isA<CreateIdentity>());
      final createIdentity = body as CreateIdentity;
      expect(createIdentity.Url, equals('acc://test.acme/identity'));
      expect(createIdentity.KeyHash, equals(Uint8List.fromList([1, 2, 3, 4])));
      expect(createIdentity.$type, equals('createidentity'));
    });

    test('should dispatch SendTokens correctly', () {
      final json = {
        'type': 'sendtokens',
        'To': 'acc://recipient.acme/tokens',
      };

      final body = TransactionBody.fromJson(json);

      expect(body, isA<SendTokens>());
      final sendTokens = body as SendTokens;
      expect(sendTokens.To, equals('acc://recipient.acme/tokens'));
      expect(sendTokens.$type, equals('sendtokens'));
    });

    test('should dispatch WriteData correctly', () {
      final json = {
        'type': 'writedata',
        'Entry': 'test data entry',
        'Scratch': true,
        'WriteToState': false,
      };

      final body = TransactionBody.fromJson(json);

      expect(body, isA<WriteData>());
      final writeData = body as WriteData;
      expect(writeData.Entry, equals('test data entry'));
      expect(writeData.Scratch, isTrue);
      expect(writeData.WriteToState, isFalse);
      expect(writeData.$type, equals('writedata'));
    });

    test('should throw error for unknown transaction type', () {
      final json = {
        'type': 'unknowntransaction',
        'SomeField': 'value',
      };

      expect(() => TransactionBody.fromJson(json), throwsA(isA<ArgumentError>()));
    });

    test('should throw error for missing type field', () {
      final json = {
        'SomeField': 'value',
      };

      expect(() => TransactionBody.fromJson(json), throwsA(isA<ArgumentError>()));
    });

    test('should handle null type field', () {
      final json = {
        'type': null,
        'SomeField': 'value',
      };

      expect(() => TransactionBody.fromJson(json), throwsA(isA<ArgumentError>()));
    });

    group('All 33 Transaction Types Dispatch Tests', () {
      final dispatchTestCases = [
        {'type': 'createidentity', 'Url': 'acc://test.acme/identity'},
        {'type': 'createtokenaccount', 'Url': 'acc://test.acme/tokens', 'TokenUrl': 'acc://ACME'},
        {'type': 'sendtokens', 'To': 'acc://recipient.acme/tokens'},
        {'type': 'createdataaccount', 'Url': 'acc://test.acme/data'},
        {'type': 'writedata', 'Entry': 'test data'},
        {'type': 'writedatato', 'Recipient': 'acc://recipient.acme/data', 'Entry': 'test data'},
        {'type': 'acmefaucet', 'Url': 'acc://faucet.acme/tokens'},
        {'type': 'createtoken', 'Url': 'acc://test.acme/token', 'Symbol': 'TEST', 'Precision': 8},
        {'type': 'issuetokens', 'Recipient': 'acc://recipient.acme/tokens', 'Amount': BigInt.from(1000), 'To': 'acc://recipient.acme/tokens'},
        {'type': 'burntokens', 'Amount': BigInt.from(500)},
        {'type': 'createlitetokenaccount', 'Url': 'acc://lite.acme/tokens'},
        {'type': 'createkeypage', 'Keys': []},
        {'type': 'createkeybook', 'Url': 'acc://test.acme/book', 'PublicKeyHash': 'AQIDBA=='},
        {'type': 'addcredits', 'Recipient': 'acc://test.acme/page', 'Amount': BigInt.from(1000), 'Oracle': 'acc://test.acme/oracle'},
        {'type': 'updatekeypage', 'Operation': 'add'},
        {'type': 'lockaccount', 'Height': 12345},
        {'type': 'burncredits', 'Amount': 100},
        {'type': 'transfercredits', 'Recipient': 'acc://recipient.acme/page', 'Amount': 500},
        {'type': 'updatekey', 'NewKeyHash': 'AQIDBA=='},
        {'type': 'updateaccountauth', 'Operations': []},
        {'type': 'remotetransaction', 'Hash': 'AQIDBA=='},
        {'type': 'syntheticcreateidentity', 'Accounts': ['acc://synthetic.acme/identity']},
        {'type': 'syntheticwritedata', 'Entry': 'synthetic data'},
        {'type': 'syntheticdeposittokens', 'Token': 'acc://ACME', 'Amount': BigInt.from(1000), 'IsIssuer': false, 'IsRefund': false},
        {'type': 'syntheticdepositcredits', 'Amount': 500, 'AcmeRefundAmount': BigInt.from(100), 'IsRefund': false},
        {'type': 'syntheticburntokens', 'Amount': BigInt.from(300), 'IsRefund': false},
        {'type': 'syntheticforwardtransaction', 'Hash': 'AQIDBA=='},
        {'type': 'systemgenesis'},
        {'type': 'systemwritedata', 'Entry': 'system data'},
        {'type': 'directoryanchor', 'Updates': [], 'Receipts': [], 'MakeMajorBlock': 0, 'MakeMajorBlockTime': 1640995200},
        {'type': 'blockvalidatoranchor', 'AcmeBurnt': BigInt.from(100)},
        {'type': 'activateprotocolversion', 'Version': 1},
        {'type': 'networkmaintenance', 'Operations': []},
      ];

      for (final testCase in dispatchTestCases) {
        final txType = testCase['type'] as String;
        test('should dispatch $txType correctly', () {
          final body = TransactionBody.fromJson(testCase);
          expect(body.$type, equals(txType));
        });
      }

      test('all 33 transaction types should dispatch successfully', () {
        expect(dispatchTestCases, hasLength(33));

        for (final testCase in dispatchTestCases) {
          final body = TransactionBody.fromJson(testCase);
          expect(body, isNotNull);
          expect(body.$type, equals(testCase['type']));

          // Verify round-trip consistency
          final json = body.toJson();
          expect(json['type'], equals(testCase['type']));

          // Verify re-dispatch works
          final redispatched = TransactionBody.fromJson(json);
          expect(redispatched.$type, equals(body.$type));
        }
      });
    });

    group('Complete Transaction Tests', () {
      test('should create complete transaction with header and body', () {
        final transaction = Transaction(
          header: TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: Uint8List.fromList([1, 2, 3, 4]),
            Memo: 'test transaction',
          ),
          body: CreateIdentity(
            Url: 'acc://test.acme/new-identity',
          ),
        );

        expect(transaction.header.Principal, equals('acc://test.acme/identity'));
        expect(transaction.body.$type, equals('createidentity'));
        expect(transaction.validate(), isTrue);
      });

      test('should serialize complete transaction to JSON', () {
        final transaction = Transaction(
          header: TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: Uint8List.fromList([1, 2, 3, 4]),
          ),
          body: SendTokens(
            To: 'acc://recipient.acme/tokens',
          ),
        );

        final json = transaction.toJson();

        expect(json['Principal'], equals('acc://test.acme/identity'));
        expect(json['body']['type'], equals('sendtokens'));
      });

      test('should deserialize complete transaction from JSON', () {
        final json = {
          'Principal': 'acc://test.acme/identity',
          'Initiator': 'AQIDBA==',
          'Memo': 'test memo',
          'body': {
            'type': 'createidentity',
            'Url': 'acc://test.acme/new-identity',
          },
        };

        final transaction = Transaction.fromJson(json);

        expect(transaction.header.Principal, equals('acc://test.acme/identity'));
        expect(transaction.body.$type, equals('createidentity'));

        final createIdentity = transaction.body as CreateIdentity;
        expect(createIdentity.Url, equals('acc://test.acme/new-identity'));
      });

      test('should handle transaction validation correctly', () {
        final validTransaction = Transaction(
          header: TransactionHeader(
            Principal: 'acc://test.acme/identity',
            Initiator: Uint8List.fromList([1, 2, 3, 4]),
          ),
          body: CreateIdentity(
            Url: 'acc://test.acme/new-identity',
          ),
        );

        expect(validTransaction.validate(), isTrue);
      });
    });
  });
}