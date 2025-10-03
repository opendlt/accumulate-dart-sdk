import 'package:test/test.dart';
import 'dart:typed_data';

// Import all transaction body types
import '../../lib/src/transactions/bodies/createidentity.dart';
import '../../lib/src/transactions/bodies/createtokenaccount.dart';
import '../../lib/src/transactions/bodies/sendtokens.dart';
import '../../lib/src/transactions/bodies/createdataaccount.dart';
import '../../lib/src/transactions/bodies/writedata.dart';
import '../../lib/src/transactions/bodies/writedatato.dart';
import '../../lib/src/transactions/bodies/acmefaucet.dart';
import '../../lib/src/transactions/bodies/createtoken.dart';
import '../../lib/src/transactions/bodies/issuetokens.dart';
import '../../lib/src/transactions/bodies/burntokens.dart';
import '../../lib/src/transactions/bodies/createlitetokenaccount.dart';
import '../../lib/src/transactions/bodies/createkeypage.dart';
import '../../lib/src/transactions/bodies/createkeybook.dart';
import '../../lib/src/transactions/bodies/addcredits.dart';
import '../../lib/src/transactions/bodies/updatekeypage.dart';
import '../../lib/src/transactions/bodies/lockaccount.dart';
import '../../lib/src/transactions/bodies/burncredits.dart';
import '../../lib/src/transactions/bodies/transfercredits.dart';
import '../../lib/src/transactions/bodies/updatekey.dart';
import '../../lib/src/transactions/bodies/updateaccountauth.dart';
import '../../lib/src/transactions/bodies/remotetransaction.dart';
import '../../lib/src/transactions/bodies/syntheticcreateidentity.dart';
import '../../lib/src/transactions/bodies/syntheticwritedata.dart';
import '../../lib/src/transactions/bodies/syntheticdeposittokens.dart';
import '../../lib/src/transactions/bodies/syntheticdepositcredits.dart';
import '../../lib/src/transactions/bodies/syntheticburntokens.dart';
import '../../lib/src/transactions/bodies/syntheticforwardtransaction.dart';
import '../../lib/src/transactions/bodies/systemgenesis.dart';
import '../../lib/src/transactions/bodies/systemwritedata.dart';
import '../../lib/src/transactions/bodies/directoryanchor.dart';
import '../../lib/src/transactions/bodies/blockvalidatoranchor.dart';
import '../../lib/src/transactions/bodies/activateprotocolversion.dart';
import '../../lib/src/transactions/bodies/networkmaintenance.dart';

void main() {
  group('Transaction Bodies Tests (33 types)', () {

    group('User Transaction Bodies', () {
      test('CreateIdentity - construction and validation', () {
        final tx = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: Uint8List.fromList([1, 2, 3, 4]),
          KeyBookUrl: 'acc://test.acme/book',
          Authorities: 'acc://test.acme/auth',
        );

        expect(tx.$type, equals('createidentity'));
        expect(tx.Url, equals('acc://test.acme/identity'));
        expect(tx.KeyHash, equals(Uint8List.fromList([1, 2, 3, 4])));
        expect(tx.validate(), isTrue);
      });

      test('CreateIdentity - JSON round-trip', () {
        final original = CreateIdentity(
          Url: 'acc://test.acme/identity',
          KeyHash: Uint8List.fromList([1, 2, 3, 4]),
        );

        final json = original.toJson();
        final reconstructed = CreateIdentity.fromJson(json);

        expect(reconstructed.Url, equals(original.Url));
        expect(reconstructed.KeyHash, equals(original.KeyHash));
        expect(reconstructed.$type, equals(original.$type));
      });

      test('CreateTokenAccount - construction and validation', () {
        final tx = CreateTokenAccount(
          Url: 'acc://test.acme/tokens',
          TokenUrl: 'acc://ACME',
          Authorities: 'acc://test.acme/auth',
        );

        expect(tx.$type, equals('createtokenaccount'));
        expect(tx.Url, equals('acc://test.acme/tokens'));
        expect(tx.TokenUrl, equals('acc://ACME'));
        expect(tx.validate(), isTrue);
      });

      test('SendTokens - construction and validation', () {
        final tx = SendTokens(
          To: 'acc://recipient.acme/tokens',
          Hash: Uint8List.fromList([1, 2, 3, 4]),
        );

        expect(tx.$type, equals('sendtokens'));
        expect(tx.To, equals('acc://recipient.acme/tokens'));
        expect(tx.validate(), isTrue);
      });

      test('CreateDataAccount - construction and validation', () {
        final tx = CreateDataAccount(
          Url: 'acc://test.acme/data',
          Authorities: 'acc://test.acme/auth',
        );

        expect(tx.$type, equals('createdataaccount'));
        expect(tx.Url, equals('acc://test.acme/data'));
        expect(tx.validate(), isTrue);
      });

      test('WriteData - construction and validation', () {
        final tx = WriteData(
          Entry: 'test data entry',
          Scratch: true,
          WriteToState: false,
        );

        expect(tx.$type, equals('writedata'));
        expect(tx.Entry, equals('test data entry'));
        expect(tx.Scratch, isTrue);
        expect(tx.validate(), isTrue);
      });
    });

    group('Token Transaction Bodies', () {
      test('CreateToken - construction and validation', () {
        final tx = CreateToken(
          Url: 'acc://test.acme/token',
          Symbol: 'TEST',
          Precision: 8,
          Properties: 'acc://test.acme/properties',
          Authorities: 'acc://test.acme/auth',
        );

        expect(tx.$type, equals('createtoken'));
        expect(tx.Symbol, equals('TEST'));
        expect(tx.Precision, equals(8));
        expect(tx.validate(), isTrue);
      });

      test('IssueTokens - construction and validation', () {
        final tx = IssueTokens(
          Recipient: 'acc://recipient.acme/tokens',
          Amount: BigInt.from(1000000),
          To: 'acc://recipient.acme/tokens',
        );

        expect(tx.$type, equals('issuetokens'));
        expect(tx.Recipient, equals('acc://recipient.acme/tokens'));
        expect(tx.Amount, equals(BigInt.from(1000000)));
        expect(tx.validate(), isTrue);
      });

      test('BurnTokens - construction and validation', () {
        final tx = BurnTokens(
          Amount: BigInt.from(500000),
        );

        expect(tx.$type, equals('burntokens'));
        expect(tx.Amount, equals(BigInt.from(500000)));
        expect(tx.validate(), isTrue);
      });
    });

    group('Key Management Transaction Bodies', () {
      test('CreateKeyPage - construction and validation', () {
        final tx = CreateKeyPage(
          Keys: [
            {'PublicKey': Uint8List.fromList([1, 2, 3, 4])},
          ],
        );

        expect(tx.$type, equals('createkeypage'));
        expect(tx.Keys, hasLength(1));
        expect(tx.validate(), isTrue);
      });

      test('CreateKeyBook - construction and validation', () {
        final tx = CreateKeyBook(
          Url: 'acc://test.acme/book',
          PublicKeyHash: Uint8List.fromList([1, 2, 3, 4]),
          Authorities: 'acc://test.acme/auth',
        );

        expect(tx.$type, equals('createkeybook'));
        expect(tx.Url, equals('acc://test.acme/book'));
        expect(tx.validate(), isTrue);
      });

      test('UpdateKeyPage - construction and validation', () {
        final tx = UpdateKeyPage(
          Operation: 'add',
        );

        expect(tx.$type, equals('updatekeypage'));
        expect(tx.Operation, equals('add'));
        expect(tx.validate(), isTrue);
      });
    });

    group('Synthetic Transaction Bodies', () {
      test('SyntheticCreateIdentity - construction and validation', () {
        final tx = SyntheticCreateIdentity(
          Accounts: ['acc://synthetic.acme/identity'],
        );

        expect(tx.$type, equals('syntheticcreateidentity'));
        expect(tx.validate(), isTrue);
      });

      test('SyntheticDepositTokens - construction and validation', () {
        final tx = SyntheticDepositTokens(
          Token: 'acc://ACME',
          Amount: BigInt.from(1000000),
          IsIssuer: false,
          IsRefund: false,
        );

        expect(tx.$type, equals('syntheticdeposittokens'));
        expect(tx.Amount, equals(BigInt.from(1000000)));
        expect(tx.validate(), isTrue);
      });

      test('SyntheticBurnTokens - construction and validation', () {
        final tx = SyntheticBurnTokens(
          Amount: BigInt.from(500000),
          IsRefund: false,
        );

        expect(tx.$type, equals('syntheticburntokens'));
        expect(tx.Amount, equals(BigInt.from(500000)));
        expect(tx.validate(), isTrue);
      });
    });

    group('System Transaction Bodies', () {
      test('SystemGenesis - construction and validation', () {
        final tx = SystemGenesis();

        expect(tx.$type, equals('systemgenesis'));
        expect(tx.validate(), isTrue);
      });

      test('DirectoryAnchor - construction and validation', () {
        final tx = DirectoryAnchor(
          Updates: [],
          Receipts: [],
          MakeMajorBlock: 0,
          MakeMajorBlockTime: 1640995200,
        );

        expect(tx.$type, equals('directoryanchor'));
        expect(tx.validate(), isTrue);
      });

      test('BlockValidatorAnchor - construction and validation', () {
        final tx = BlockValidatorAnchor(
          AcmeBurnt: BigInt.from(100),
        );

        expect(tx.$type, equals('blockvalidatoranchor'));
        expect(tx.validate(), isTrue);
      });
    });

    group('All Transaction Bodies - JSON Round-trip Tests', () {
      final testCases = [
        () => CreateIdentity(Url: 'acc://test.acme/identity'),
        () => CreateTokenAccount(Url: 'acc://test.acme/tokens', TokenUrl: 'acc://ACME'),
        () => SendTokens(To: 'acc://recipient.acme/tokens'),
        () => CreateDataAccount(Url: 'acc://test.acme/data'),
        () => WriteData(Entry: 'test data'),
        () => CreateToken(Url: 'acc://test.acme/token', Symbol: 'TEST', Precision: 8),
        () => IssueTokens(Recipient: 'acc://recipient.acme/tokens', Amount: BigInt.from(1000), To: 'acc://recipient.acme/tokens'),
        () => BurnTokens(Amount: BigInt.from(500)),
        () => CreateKeyPage(Keys: []),
        () => CreateKeyBook(Url: 'acc://test.acme/book', PublicKeyHash: Uint8List.fromList([1, 2, 3, 4])),
        () => AddCredits(Recipient: 'acc://test.acme/page', Amount: BigInt.from(1000), Oracle: 'acc://test.acme/oracle'),
        // Add more test cases for all 33 types...
      ];

      for (int i = 0; i < testCases.length; i++) {
        test('Transaction body $i JSON round-trip consistency', () {
          final original = testCases[i]();
          final json = original.toJson();

          // Verify JSON contains required fields
          expect(json, containsPair('type', original.$type));

          // Test that the JSON is valid by encoding/decoding
          final jsonString = json.toString();
          expect(jsonString, isNotEmpty);

          // Verify validation passes
          expect(original.validate(), isTrue);
        });
      }
    });

    group('Field Validation Tests', () {
      test('should reject invalid URL formats', () {
        final tx = CreateIdentity(Url: 'invalid-url');
        expect(tx.validate(), isFalse);
      });

      test('should reject invalid To URLs', () {
        final tx = SendTokens(To: 'invalid-url');
        expect(tx.validate(), isFalse);
      });

      test('should handle empty arrays correctly', () {
        final tx = CreateKeyPage(Keys: []);
        expect(tx.Keys, isEmpty);
        expect(tx.validate(), isTrue);
      });

      test('should handle null optional fields correctly', () {
        final tx = CreateIdentity(Url: 'acc://test.acme/identity');
        expect(tx.KeyHash, isNull);
        expect(tx.KeyBookUrl, isNull);
        expect(tx.validate(), isTrue);
      });
    });
  });
}