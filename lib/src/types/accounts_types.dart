// GENERATED — Do not edit.
// Protocol types from accounts.yml

import '../enums.dart';
import '../runtime/validators.dart';

/// Protocol type: ADI
final class ADI {
  final String url;
  final dynamic auth;

  const ADI({required this.url, required this.auth});

  /// Create from JSON map
  factory ADI.fromJson(Map<String, dynamic> json) {
    return ADI(
    url: json['Url'] as String,
    auth: json['AccountAuth'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountAuth': auth,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: DataAccount
final class DataAccount {
  final String url;
  final dynamic auth;
  final dynamic entry;

  const DataAccount({required this.url, required this.auth, required this.entry});

  /// Create from JSON map
  factory DataAccount.fromJson(Map<String, dynamic> json) {
    return DataAccount(
    url: json['Url'] as String,
    auth: json['AccountAuth'] as dynamic,
    entry: json['Entry'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountAuth': auth,
    'Entry': entry,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: KeyBook
final class KeyBook {
  final String url;
  final BookType bookType;
  final dynamic auth;
  final int pageCount;

  const KeyBook({required this.url, required this.bookType, required this.auth, required this.pageCount});

  /// Create from JSON map
  factory KeyBook.fromJson(Map<String, dynamic> json) {
    return KeyBook(
    url: json['Url'] as String,
    bookType: json['BookType'] as BookType,
    auth: json['AccountAuth'] as dynamic,
    pageCount: json['PageCount'] as int,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountAuth': auth,
    'BookType': bookType,
    'PageCount': pageCount,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: KeyPage
final class KeyPage {
  final String keyBook;
  final String url;
  final int creditBalance;
  final int acceptThreshold;
  final int rejectThreshold;
  final int responseThreshold;
  final int blockThreshold;
  final int version;
  final dynamic keys;
  final dynamic transactionBlacklist;

  const KeyPage({required this.keyBook, required this.url, required this.creditBalance, required this.acceptThreshold, required this.rejectThreshold, required this.responseThreshold, required this.blockThreshold, required this.version, required this.keys, required this.transactionBlacklist});

  /// Create from JSON map
  factory KeyPage.fromJson(Map<String, dynamic> json) {
    return KeyPage(
    keyBook: json['KeyBook'] as String,
    url: json['Url'] as String,
    creditBalance: json['CreditBalance'] as int,
    acceptThreshold: json['AcceptThreshold'] as int,
    rejectThreshold: json['RejectThreshold'] as int,
    responseThreshold: json['ResponseThreshold'] as int,
    blockThreshold: json['BlockThreshold'] as int,
    version: json['Version'] as int,
    keys: json['Keys'] as dynamic,
    transactionBlacklist: json['TransactionBlacklist'] as dynamic,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AcceptThreshold': acceptThreshold,
    'BlockThreshold': blockThreshold,
    'CreditBalance': creditBalance,
    'KeyBook': keyBook,
    'Keys': keys,
    'RejectThreshold': rejectThreshold,
    'ResponseThreshold': responseThreshold,
    'TransactionBlacklist': transactionBlacklist,
    'Url': url,
    'Version': version,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(keyBook, 'keyBook');
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: LiteDataAccount
final class LiteDataAccount {
  final String url;

  const LiteDataAccount({required this.url});

  /// Create from JSON map
  factory LiteDataAccount.fromJson(Map<String, dynamic> json) {
    return LiteDataAccount(
    url: json['Url'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: LiteIdentity
final class LiteIdentity {
  final String url;
  final int creditBalance;
  final int lastUsedOn;

  const LiteIdentity({required this.url, required this.creditBalance, required this.lastUsedOn});

  /// Create from JSON map
  factory LiteIdentity.fromJson(Map<String, dynamic> json) {
    return LiteIdentity(
    url: json['Url'] as String,
    creditBalance: json['CreditBalance'] as int,
    lastUsedOn: json['LastUsedOn'] as int,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'CreditBalance': creditBalance,
    'LastUsedOn': lastUsedOn,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: LiteTokenAccount
final class LiteTokenAccount {
  final String url;
  final String tokenUrl;
  final BigInt balance;
  final int lockHeight;

  const LiteTokenAccount({required this.url, required this.tokenUrl, required this.balance, required this.lockHeight});

  /// Create from JSON map
  factory LiteTokenAccount.fromJson(Map<String, dynamic> json) {
    return LiteTokenAccount(
    url: json['Url'] as String,
    tokenUrl: json['TokenUrl'] as String,
    balance: BigInt.parse(json['Balance'] as String),
    lockHeight: json['LockHeight'] as int,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Balance': balance.toString(),
    'LockHeight': lockHeight,
    'TokenUrl': tokenUrl,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
    Validators.validateUrl(tokenUrl, 'tokenUrl');
    Validators.validateBigInt(balance, 'balance');
  }
}

/// Protocol type: TokenAccount
final class TokenAccount {
  final String url;
  final dynamic auth;
  final String tokenUrl;
  final BigInt balance;

  const TokenAccount({required this.url, required this.auth, required this.tokenUrl, required this.balance});

  /// Create from JSON map
  factory TokenAccount.fromJson(Map<String, dynamic> json) {
    return TokenAccount(
    url: json['Url'] as String,
    auth: json['AccountAuth'] as dynamic,
    tokenUrl: json['TokenUrl'] as String,
    balance: BigInt.parse(json['Balance'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountAuth': auth,
    'Balance': balance.toString(),
    'TokenUrl': tokenUrl,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
    Validators.validateUrl(tokenUrl, 'tokenUrl');
    Validators.validateBigInt(balance, 'balance');
  }
}

/// Protocol type: TokenIssuer
final class TokenIssuer {
  final String url;
  final dynamic auth;
  final String symbol;
  final int precision;
  final String properties;
  final BigInt issued;
  final BigInt supplyLimit;

  const TokenIssuer({required this.url, required this.auth, required this.symbol, required this.precision, required this.properties, required this.issued, required this.supplyLimit});

  /// Create from JSON map
  factory TokenIssuer.fromJson(Map<String, dynamic> json) {
    return TokenIssuer(
    url: json['Url'] as String,
    auth: json['AccountAuth'] as dynamic,
    symbol: json['Symbol'] as String,
    precision: json['Precision'] as int,
    properties: json['Properties'] as String,
    issued: BigInt.parse(json['Issued'] as String),
    supplyLimit: BigInt.parse(json['SupplyLimit'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'AccountAuth': auth,
    'Issued': issued.toString(),
    'Precision': precision,
    'Properties': properties,
    'SupplyLimit': supplyLimit.toString(),
    'Symbol': symbol,
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
    Validators.validateUrl(properties, 'properties');
    Validators.validateBigInt(issued, 'issued');
    Validators.validateBigInt(supplyLimit, 'supplyLimit');
  }
}

/// Protocol type: UnknownAccount
final class UnknownAccount {
  final String url;

  const UnknownAccount({required this.url});

  /// Create from JSON map
  factory UnknownAccount.fromJson(Map<String, dynamic> json) {
    return UnknownAccount(
    url: json['Url'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Url': url,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

/// Protocol type: UnknownSigner
final class UnknownSigner {
  final String url;
  final int version;

  const UnknownSigner({required this.url, required this.version});

  /// Create from JSON map
  factory UnknownSigner.fromJson(Map<String, dynamic> json) {
    return UnknownSigner(
    url: json['Url'] as String,
    version: json['Version'] as int,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
    'Url': url,
    'Version': version,
    };
  }

  /// Validate the object
  void validate() {
    Validators.validateUrl(url, 'url');
  }
}

