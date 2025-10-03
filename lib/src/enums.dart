library enums;

enum ExecutorVersion {
  V1('1'),
  V1SignatureAnchoring('2'),
  V1DoubleHashEntries('3'),
  V1Halt('4'),
  V2('5'),
  V2Baikonur('6'),
  V2Vandenberg('7'),
  V2Jiuquan('8'),
  VNext('9')
;

  const ExecutorVersion(this.value);

  final String value;

  String toJson() => value;

  static ExecutorVersion fromJson(String v) {
    switch (v) {
      case '1':
        return ExecutorVersion.V1;
      case '2':
        return ExecutorVersion.V1SignatureAnchoring;
      case '3':
        return ExecutorVersion.V1DoubleHashEntries;
      case '4':
        return ExecutorVersion.V1Halt;
      case '5':
        return ExecutorVersion.V2;
      case '6':
        return ExecutorVersion.V2Baikonur;
      case '7':
        return ExecutorVersion.V2Vandenberg;
      case '8':
        return ExecutorVersion.V2Jiuquan;
      case '9':
        return ExecutorVersion.VNext;
      default:
        throw ArgumentError('ExecutorVersion: unknown value $v');
    }
  }
}

enum PartitionType {
  Directory('1'),
  BlockValidator('2'),
  BlockSummary('3'),
  Bootstrap('4')
;

  const PartitionType(this.value);

  final String value;

  String toJson() => value;

  static PartitionType fromJson(String v) {
    switch (v) {
      case '1':
        return PartitionType.Directory;
      case '2':
        return PartitionType.BlockValidator;
      case '3':
        return PartitionType.BlockSummary;
      case '4':
        return PartitionType.Bootstrap;
      default:
        throw ArgumentError('PartitionType: unknown value $v');
    }
  }
}

enum DataEntryType {
  Unknown('0'),
  Factom('1'),
  Accumulate('2'),
  DoubleHash('3')
;

  const DataEntryType(this.value);

  final String value;

  String toJson() => value;

  static DataEntryType fromJson(String v) {
    switch (v) {
      case '0':
        return DataEntryType.Unknown;
      case '1':
        return DataEntryType.Factom;
      case '2':
        return DataEntryType.Accumulate;
      case '3':
        return DataEntryType.DoubleHash;
      default:
        throw ArgumentError('DataEntryType: unknown value $v');
    }
  }
}

enum ObjectType {
  Unknown('0'),
  Account('0x01'),
  Transaction('0x02')
;

  const ObjectType(this.value);

  final String value;

  String toJson() => value;

  static ObjectType fromJson(String v) {
    switch (v) {
      case '0':
        return ObjectType.Unknown;
      case '0x01':
        return ObjectType.Account;
      case '0x02':
        return ObjectType.Transaction;
      default:
        throw ArgumentError('ObjectType: unknown value $v');
    }
  }
}

enum SignatureType {
  Unknown('0'),
  LegacyED25519('1'),
  ED25519('2'),
  RCD1('3'),
  Receipt('4'),
  Partition('5'),
  Set('6'),
  Remote('7'),
  BTC('8'),
  BTCLegacy('9'),
  ETH('10'),
  Delegated('11'),
  Internal('12'),
  Authority('13'),
  RsaSha256('14'),
  EcdsaSha256('15'),
  TypedData('16')
;

  const SignatureType(this.value);

  final String value;

  String toJson() => value;

  static SignatureType fromJson(String v) {
    switch (v) {
      case '0':
        return SignatureType.Unknown;
      case '1':
        return SignatureType.LegacyED25519;
      case '2':
        return SignatureType.ED25519;
      case '3':
        return SignatureType.RCD1;
      case '4':
        return SignatureType.Receipt;
      case '5':
        return SignatureType.Partition;
      case '6':
        return SignatureType.Set;
      case '7':
        return SignatureType.Remote;
      case '8':
        return SignatureType.BTC;
      case '9':
        return SignatureType.BTCLegacy;
      case '10':
        return SignatureType.ETH;
      case '11':
        return SignatureType.Delegated;
      case '12':
        return SignatureType.Internal;
      case '13':
        return SignatureType.Authority;
      case '14':
        return SignatureType.RsaSha256;
      case '15':
        return SignatureType.EcdsaSha256;
      case '16':
        return SignatureType.TypedData;
      default:
        throw ArgumentError('SignatureType: unknown value $v');
    }
  }
}

enum KeyPageOperationType {
  Unknown('0'),
  Update('1'),
  Remove('2'),
  Add('3'),
  SetThreshold('4'),
  UpdateAllowed('5'),
  SetRejectThreshold('6'),
  SetResponseThreshold('7')
;

  const KeyPageOperationType(this.value);

  final String value;

  String toJson() => value;

  static KeyPageOperationType fromJson(String v) {
    switch (v) {
      case '0':
        return KeyPageOperationType.Unknown;
      case '1':
        return KeyPageOperationType.Update;
      case '2':
        return KeyPageOperationType.Remove;
      case '3':
        return KeyPageOperationType.Add;
      case '4':
        return KeyPageOperationType.SetThreshold;
      case '5':
        return KeyPageOperationType.UpdateAllowed;
      case '6':
        return KeyPageOperationType.SetRejectThreshold;
      case '7':
        return KeyPageOperationType.SetResponseThreshold;
      default:
        throw ArgumentError('KeyPageOperationType: unknown value $v');
    }
  }
}

enum AccountAuthOperationType {
  Unknown('0'),
  Enable('1'),
  Disable('2'),
  AddAuthority('3'),
  RemoveAuthority('4')
;

  const AccountAuthOperationType(this.value);

  final String value;

  String toJson() => value;

  static AccountAuthOperationType fromJson(String v) {
    switch (v) {
      case '0':
        return AccountAuthOperationType.Unknown;
      case '1':
        return AccountAuthOperationType.Enable;
      case '2':
        return AccountAuthOperationType.Disable;
      case '3':
        return AccountAuthOperationType.AddAuthority;
      case '4':
        return AccountAuthOperationType.RemoveAuthority;
      default:
        throw ArgumentError('AccountAuthOperationType: unknown value $v');
    }
  }
}

enum NetworkMaintenanceOperationType {
  Unknown('0'),
  PendingTransactionGC('1')
;

  const NetworkMaintenanceOperationType(this.value);

  final String value;

  String toJson() => value;

  static NetworkMaintenanceOperationType fromJson(String v) {
    switch (v) {
      case '0':
        return NetworkMaintenanceOperationType.Unknown;
      case '1':
        return NetworkMaintenanceOperationType.PendingTransactionGC;
      default:
        throw ArgumentError('NetworkMaintenanceOperationType: unknown value $v');
    }
  }
}

enum TransactionMax {
  User('0x30'),
  Synthetic('0x5F'),
  System('0xFF')
;

  const TransactionMax(this.value);

  final String value;

  String toJson() => value;

  static TransactionMax fromJson(String v) {
    switch (v) {
      case '0x30':
        return TransactionMax.User;
      case '0x5F':
        return TransactionMax.Synthetic;
      case '0xFF':
        return TransactionMax.System;
      default:
        throw ArgumentError('TransactionMax: unknown value $v');
    }
  }
}

enum TransactionType {
  Unknown('0'),
  CreateIdentity('0x01'),
  CreateTokenAccount('0x02'),
  SendTokens('0x03'),
  CreateDataAccount('0x04'),
  WriteData('0x05'),
  WriteDataTo('0x06'),
  AcmeFaucet('0x07'),
  CreateToken('0x08'),
  IssueTokens('0x09'),
  BurnTokens('0x0A'),
  CreateLiteTokenAccount('0x0B'),
  CreateKeyPage('0x0C'),
  CreateKeyBook('0x0D'),
  AddCredits('0x0E'),
  UpdateKeyPage('0x0F'),
  LockAccount('0x10'),
  BurnCredits('0x11'),
  TransferCredits('0x12'),
  UpdateAccountAuth('0x15'),
  UpdateKey('0x16'),
  NetworkMaintenance('0x2E'),
  ActivateProtocolVersion('0x2F'),
  Remote('0x30'),
  SyntheticCreateIdentity('0x31'),
  SyntheticWriteData('0x32'),
  SyntheticDepositTokens('0x33'),
  SyntheticDepositCredits('0x34'),
  SyntheticBurnTokens('0x35'),
  SyntheticForwardTransaction('0x36'),
  SystemGenesis('0x60'),
  DirectoryAnchor('0x61'),
  BlockValidatorAnchor('0x62'),
  SystemWriteData('0x63')
;

  const TransactionType(this.value);

  final String value;

  String toJson() => value;

  static TransactionType fromJson(String v) {
    switch (v) {
      case '0':
        return TransactionType.Unknown;
      case '0x01':
        return TransactionType.CreateIdentity;
      case '0x02':
        return TransactionType.CreateTokenAccount;
      case '0x03':
        return TransactionType.SendTokens;
      case '0x04':
        return TransactionType.CreateDataAccount;
      case '0x05':
        return TransactionType.WriteData;
      case '0x06':
        return TransactionType.WriteDataTo;
      case '0x07':
        return TransactionType.AcmeFaucet;
      case '0x08':
        return TransactionType.CreateToken;
      case '0x09':
        return TransactionType.IssueTokens;
      case '0x0A':
        return TransactionType.BurnTokens;
      case '0x0B':
        return TransactionType.CreateLiteTokenAccount;
      case '0x0C':
        return TransactionType.CreateKeyPage;
      case '0x0D':
        return TransactionType.CreateKeyBook;
      case '0x0E':
        return TransactionType.AddCredits;
      case '0x0F':
        return TransactionType.UpdateKeyPage;
      case '0x10':
        return TransactionType.LockAccount;
      case '0x11':
        return TransactionType.BurnCredits;
      case '0x12':
        return TransactionType.TransferCredits;
      case '0x15':
        return TransactionType.UpdateAccountAuth;
      case '0x16':
        return TransactionType.UpdateKey;
      case '0x2E':
        return TransactionType.NetworkMaintenance;
      case '0x2F':
        return TransactionType.ActivateProtocolVersion;
      case '0x30':
        return TransactionType.Remote;
      case '0x31':
        return TransactionType.SyntheticCreateIdentity;
      case '0x32':
        return TransactionType.SyntheticWriteData;
      case '0x33':
        return TransactionType.SyntheticDepositTokens;
      case '0x34':
        return TransactionType.SyntheticDepositCredits;
      case '0x35':
        return TransactionType.SyntheticBurnTokens;
      case '0x36':
        return TransactionType.SyntheticForwardTransaction;
      case '0x60':
        return TransactionType.SystemGenesis;
      case '0x61':
        return TransactionType.DirectoryAnchor;
      case '0x62':
        return TransactionType.BlockValidatorAnchor;
      case '0x63':
        return TransactionType.SystemWriteData;
      default:
        throw ArgumentError('TransactionType: unknown value $v');
    }
  }
}

enum AccountType {
  Unknown('0'),
  AnchorLedger('1'),
  Identity('2'),
  TokenIssuer('3'),
  TokenAccount('4'),
  LiteTokenAccount('5'),
  BlockLedger('6'),
  KeyPage('9'),
  KeyBook('10'),
  DataAccount('11'),
  LiteDataAccount('12'),
  UnknownSigner('13'),
  SystemLedger('14'),
  LiteIdentity('15'),
  SyntheticLedger('16')
;

  const AccountType(this.value);

  final String value;

  String toJson() => value;

  static AccountType fromJson(String v) {
    switch (v) {
      case '0':
        return AccountType.Unknown;
      case '1':
        return AccountType.AnchorLedger;
      case '2':
        return AccountType.Identity;
      case '3':
        return AccountType.TokenIssuer;
      case '4':
        return AccountType.TokenAccount;
      case '5':
        return AccountType.LiteTokenAccount;
      case '6':
        return AccountType.BlockLedger;
      case '9':
        return AccountType.KeyPage;
      case '10':
        return AccountType.KeyBook;
      case '11':
        return AccountType.DataAccount;
      case '12':
        return AccountType.LiteDataAccount;
      case '13':
        return AccountType.UnknownSigner;
      case '14':
        return AccountType.SystemLedger;
      case '15':
        return AccountType.LiteIdentity;
      case '16':
        return AccountType.SyntheticLedger;
      default:
        throw ArgumentError('AccountType: unknown value $v');
    }
  }
}

enum AllowedTransactionBit {
  UpdateKeyPage('1'),
  UpdateAccountAuth('2')
;

  const AllowedTransactionBit(this.value);

  final String value;

  String toJson() => value;

  static AllowedTransactionBit fromJson(String v) {
    switch (v) {
      case '1':
        return AllowedTransactionBit.UpdateKeyPage;
      case '2':
        return AllowedTransactionBit.UpdateAccountAuth;
      default:
        throw ArgumentError('AllowedTransactionBit: unknown value $v');
    }
  }
}

enum VoteType {
  Accept('0x0'),
  Reject('0x1'),
  Abstain('0x2'),
  Suggest('0x3')
;

  const VoteType(this.value);

  final String value;

  String toJson() => value;

  static VoteType fromJson(String v) {
    switch (v) {
      case '0x0':
        return VoteType.Accept;
      case '0x1':
        return VoteType.Reject;
      case '0x2':
        return VoteType.Abstain;
      case '0x3':
        return VoteType.Suggest;
      default:
        throw ArgumentError('VoteType: unknown value $v');
    }
  }
}

enum BookType {
  Normal('0'),
  Validator('0x01'),
  Operator('0x02')
;

  const BookType(this.value);

  final String value;

  String toJson() => value;

  static BookType fromJson(String v) {
    switch (v) {
      case '0':
        return BookType.Normal;
      case '0x01':
        return BookType.Validator;
      case '0x02':
        return BookType.Operator;
      default:
        throw ArgumentError('BookType: unknown value $v');
    }
  }
}
