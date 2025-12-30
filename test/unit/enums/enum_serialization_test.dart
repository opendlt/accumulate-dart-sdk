import 'package:test/test.dart';
import 'package:opendlt_accumulate/opendlt_accumulate.dart';
// Import enums directly to access hidden types for testing
import 'package:opendlt_accumulate/src/enums.dart' as enums;

void main() {
  group('Enum Serialization Tests', () {
    group('ExecutorVersion', () {
      test('should serialize to correct values', () {
        expect(ExecutorVersion.V1.toJson(), equals('1'));
        expect(ExecutorVersion.V1SignatureAnchoring.toJson(), equals('2'));
        expect(ExecutorVersion.V1DoubleHashEntries.toJson(), equals('3'));
        expect(ExecutorVersion.V1Halt.toJson(), equals('4'));
        expect(ExecutorVersion.V2.toJson(), equals('5'));
        expect(ExecutorVersion.V2Baikonur.toJson(), equals('6'));
        expect(ExecutorVersion.V2Vandenberg.toJson(), equals('7'));
        expect(ExecutorVersion.V2Jiuquan.toJson(), equals('8'));
        expect(ExecutorVersion.VNext.toJson(), equals('9'));
      });

      test('should deserialize from correct values', () {
        expect(ExecutorVersion.fromJson('1'), equals(ExecutorVersion.V1));
        expect(ExecutorVersion.fromJson('2'), equals(ExecutorVersion.V1SignatureAnchoring));
        expect(ExecutorVersion.fromJson('3'), equals(ExecutorVersion.V1DoubleHashEntries));
        expect(ExecutorVersion.fromJson('4'), equals(ExecutorVersion.V1Halt));
        expect(ExecutorVersion.fromJson('5'), equals(ExecutorVersion.V2));
        expect(ExecutorVersion.fromJson('6'), equals(ExecutorVersion.V2Baikonur));
        expect(ExecutorVersion.fromJson('7'), equals(ExecutorVersion.V2Vandenberg));
        expect(ExecutorVersion.fromJson('8'), equals(ExecutorVersion.V2Jiuquan));
        expect(ExecutorVersion.fromJson('9'), equals(ExecutorVersion.VNext));
      });

      test('should round-trip correctly', () {
        for (final value in ExecutorVersion.values) {
          final serialized = value.toJson();
          final deserialized = ExecutorVersion.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });

      test('should throw on invalid values', () {
        expect(() => ExecutorVersion.fromJson('invalid'), throwsArgumentError);
        expect(() => ExecutorVersion.fromJson('0'), throwsArgumentError);
        expect(() => ExecutorVersion.fromJson('10'), throwsArgumentError);
      });
    });

    group('PartitionType', () {
      test('should serialize to correct values', () {
        expect(PartitionType.Directory.toJson(), equals('1'));
        expect(PartitionType.BlockValidator.toJson(), equals('2'));
        expect(PartitionType.BlockSummary.toJson(), equals('3'));
        expect(PartitionType.Bootstrap.toJson(), equals('4'));
      });

      test('should deserialize from correct values', () {
        expect(PartitionType.fromJson('1'), equals(PartitionType.Directory));
        expect(PartitionType.fromJson('2'), equals(PartitionType.BlockValidator));
        expect(PartitionType.fromJson('3'), equals(PartitionType.BlockSummary));
        expect(PartitionType.fromJson('4'), equals(PartitionType.Bootstrap));
      });

      test('should round-trip correctly', () {
        for (final value in PartitionType.values) {
          final serialized = value.toJson();
          final deserialized = PartitionType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('AccountType', () {
      test('should serialize to correct values', () {
        expect(AccountType.Unknown.toJson(), equals('0'));
        expect(AccountType.AnchorLedger.toJson(), equals('1'));
        expect(AccountType.Identity.toJson(), equals('2'));
        expect(AccountType.TokenIssuer.toJson(), equals('3'));
        expect(AccountType.TokenAccount.toJson(), equals('4'));
        expect(AccountType.LiteTokenAccount.toJson(), equals('5'));
        expect(AccountType.BlockLedger.toJson(), equals('6'));
        expect(AccountType.KeyPage.toJson(), equals('9'));
        expect(AccountType.KeyBook.toJson(), equals('10'));
        expect(AccountType.DataAccount.toJson(), equals('11'));
        expect(AccountType.LiteDataAccount.toJson(), equals('12'));
        expect(AccountType.UnknownSigner.toJson(), equals('13'));
        expect(AccountType.SystemLedger.toJson(), equals('14'));
        expect(AccountType.LiteIdentity.toJson(), equals('15'));
        expect(AccountType.SyntheticLedger.toJson(), equals('16'));
      });

      test('should round-trip correctly', () {
        for (final value in AccountType.values) {
          final serialized = value.toJson();
          final deserialized = AccountType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('TransactionType', () {
      test('should serialize to correct values', () {
        expect(TransactionType.Unknown.toJson(), equals('0'));
        expect(TransactionType.CreateIdentity.toJson(), equals('0x01'));
        expect(TransactionType.CreateTokenAccount.toJson(), equals('0x02'));
        expect(TransactionType.SendTokens.toJson(), equals('0x03'));
        expect(TransactionType.CreateDataAccount.toJson(), equals('0x04'));
        expect(TransactionType.WriteData.toJson(), equals('0x05'));
        expect(TransactionType.WriteDataTo.toJson(), equals('0x06'));
        expect(TransactionType.AcmeFaucet.toJson(), equals('0x07'));
        expect(TransactionType.CreateToken.toJson(), equals('0x08'));
        expect(TransactionType.IssueTokens.toJson(), equals('0x09'));
        expect(TransactionType.BurnTokens.toJson(), equals('0x0A'));
        expect(TransactionType.CreateLiteTokenAccount.toJson(), equals('0x0B'));
        expect(TransactionType.CreateKeyPage.toJson(), equals('0x0C'));
        expect(TransactionType.CreateKeyBook.toJson(), equals('0x0D'));
        expect(TransactionType.AddCredits.toJson(), equals('0x0E'));
        expect(TransactionType.UpdateKeyPage.toJson(), equals('0x0F'));
        expect(TransactionType.LockAccount.toJson(), equals('0x10'));
        expect(TransactionType.BurnCredits.toJson(), equals('0x11'));
        expect(TransactionType.TransferCredits.toJson(), equals('0x12'));
        expect(TransactionType.UpdateAccountAuth.toJson(), equals('0x15'));
        expect(TransactionType.UpdateKey.toJson(), equals('0x16'));
        expect(TransactionType.NetworkMaintenance.toJson(), equals('0x2E'));
        expect(TransactionType.ActivateProtocolVersion.toJson(), equals('0x2F'));
        expect(TransactionType.Remote.toJson(), equals('0x30'));
        expect(TransactionType.SyntheticCreateIdentity.toJson(), equals('0x31'));
        expect(TransactionType.SyntheticWriteData.toJson(), equals('0x32'));
        expect(TransactionType.SyntheticDepositTokens.toJson(), equals('0x33'));
        expect(TransactionType.SyntheticDepositCredits.toJson(), equals('0x34'));
        expect(TransactionType.SyntheticBurnTokens.toJson(), equals('0x35'));
        expect(TransactionType.SyntheticForwardTransaction.toJson(), equals('0x36'));
        expect(TransactionType.SystemGenesis.toJson(), equals('0x60'));
        expect(TransactionType.DirectoryAnchor.toJson(), equals('0x61'));
        expect(TransactionType.BlockValidatorAnchor.toJson(), equals('0x62'));
        expect(TransactionType.SystemWriteData.toJson(), equals('0x63'));
      });

      test('should round-trip correctly', () {
        for (final value in TransactionType.values) {
          final serialized = value.toJson();
          final deserialized = TransactionType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('SignatureType', () {
      test('should serialize to correct values', () {
        expect(SignatureType.Unknown.toJson(), equals('0'));
        expect(SignatureType.LegacyED25519.toJson(), equals('1'));
        expect(SignatureType.ED25519.toJson(), equals('2'));
        expect(SignatureType.RCD1.toJson(), equals('3'));
        expect(SignatureType.Receipt.toJson(), equals('4'));
        expect(SignatureType.Partition.toJson(), equals('5'));
        expect(SignatureType.Set.toJson(), equals('6'));
        expect(SignatureType.Remote.toJson(), equals('7'));
        expect(SignatureType.BTC.toJson(), equals('8'));
        expect(SignatureType.BTCLegacy.toJson(), equals('9'));
        expect(SignatureType.ETH.toJson(), equals('10'));
        expect(SignatureType.Delegated.toJson(), equals('11'));
        expect(SignatureType.Internal.toJson(), equals('12'));
        expect(SignatureType.Authority.toJson(), equals('13'));
        expect(SignatureType.RsaSha256.toJson(), equals('14'));
        expect(SignatureType.EcdsaSha256.toJson(), equals('15'));
        expect(SignatureType.TypedData.toJson(), equals('16'));
      });

      test('should round-trip correctly', () {
        for (final value in SignatureType.values) {
          final serialized = value.toJson();
          final deserialized = SignatureType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('VoteType', () {
      test('should serialize to correct values', () {
        expect(enums.VoteType.Accept.toJson(), equals('0x0'));
        expect(enums.VoteType.Reject.toJson(), equals('0x1'));
        expect(enums.VoteType.Abstain.toJson(), equals('0x2'));
        expect(enums.VoteType.Suggest.toJson(), equals('0x3'));
      });

      test('should round-trip correctly', () {
        for (final value in enums.VoteType.values) {
          final serialized = value.toJson();
          final deserialized = enums.VoteType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('KeyPageOperationType', () {
      test('should serialize to correct values', () {
        expect(enums.KeyPageOperationType.Unknown.toJson(), equals('0'));
        expect(enums.KeyPageOperationType.Update.toJson(), equals('1'));
        expect(enums.KeyPageOperationType.Remove.toJson(), equals('2'));
        expect(enums.KeyPageOperationType.Add.toJson(), equals('3'));
        expect(enums.KeyPageOperationType.SetThreshold.toJson(), equals('4'));
        expect(enums.KeyPageOperationType.UpdateAllowed.toJson(), equals('5'));
        expect(enums.KeyPageOperationType.SetRejectThreshold.toJson(), equals('6'));
        expect(enums.KeyPageOperationType.SetResponseThreshold.toJson(), equals('7'));
      });

      test('should round-trip correctly', () {
        for (final value in enums.KeyPageOperationType.values) {
          final serialized = value.toJson();
          final deserialized = enums.KeyPageOperationType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('AllowedTransactionBit', () {
      test('should serialize to correct values', () {
        expect(AllowedTransactionBit.UpdateKeyPage.toJson(), equals('1'));
        expect(AllowedTransactionBit.UpdateAccountAuth.toJson(), equals('2'));
      });

      test('should round-trip correctly', () {
        for (final value in AllowedTransactionBit.values) {
          final serialized = value.toJson();
          final deserialized = AllowedTransactionBit.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('NetworkEndpoint', () {
      test('should have correct base URLs', () {
        expect(NetworkEndpoint.mainnet.baseUrl, equals('https://mainnet.accumulatenetwork.io'));
        expect(NetworkEndpoint.testnet.baseUrl, equals('https://testnet.accumulatenetwork.io'));
        expect(NetworkEndpoint.devnet.baseUrl, equals('http://localhost:26660'));
      });

      test('should generate correct v2 endpoints', () {
        expect(NetworkEndpoint.mainnet.v2(), equals('https://mainnet.accumulatenetwork.io/v2'));
        expect(NetworkEndpoint.testnet.v2(), equals('https://testnet.accumulatenetwork.io/v2'));
        expect(NetworkEndpoint.devnet.v2(), equals('http://localhost:26660/v2'));
      });

      test('should generate correct v3 endpoints', () {
        expect(NetworkEndpoint.mainnet.v3(), equals('https://mainnet.accumulatenetwork.io/v3'));
        expect(NetworkEndpoint.testnet.v3(), equals('https://testnet.accumulatenetwork.io/v3'));
        expect(NetworkEndpoint.devnet.v3(), equals('http://localhost:26660/v3'));
      });
    });

    group('DataEntryType', () {
      test('should serialize to correct values', () {
        expect(DataEntryType.Unknown.toJson(), equals('0'));
        expect(DataEntryType.Factom.toJson(), equals('1'));
        expect(DataEntryType.Accumulate.toJson(), equals('2'));
        expect(DataEntryType.DoubleHash.toJson(), equals('3'));
      });

      test('should round-trip correctly', () {
        for (final value in DataEntryType.values) {
          final serialized = value.toJson();
          final deserialized = DataEntryType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });

    group('BookType', () {
      test('should serialize to correct values', () {
        expect(BookType.Normal.toJson(), equals('0'));
        expect(BookType.Validator.toJson(), equals('0x01'));
        expect(BookType.Operator.toJson(), equals('0x02'));
      });

      test('should round-trip correctly', () {
        for (final value in BookType.values) {
          final serialized = value.toJson();
          final deserialized = BookType.fromJson(serialized);
          expect(deserialized, equals(value), reason: 'Failed round-trip for $value');
        }
      });
    });
  });
}