/// Transaction type constants for Accumulate v3
///
/// Matches Go: protocol/enums.yml TransactionType
/// All 23 user transaction types are defined here.
class TxTypes {
  // User transactions
  static const createIdentity = "createIdentity";
  static const createTokenAccount = "createTokenAccount";
  static const sendTokens = "sendTokens";
  static const createDataAccount = "createDataAccount";
  static const writeData = "writeData";
  static const writeDataTo = "writeDataTo";
  static const acmeFaucet = "acmeFaucet";
  static const createToken = "createToken";
  static const issueTokens = "issueTokens";
  static const burnTokens = "burnTokens";
  static const createLiteTokenAccount = "createLiteTokenAccount";
  static const createKeyPage = "createKeyPage";
  static const createKeyBook = "createKeyBook";
  static const addCredits = "addCredits";
  static const updateKeyPage = "updateKeyPage";
  static const lockAccount = "lockAccount";
  static const burnCredits = "burnCredits";
  static const transferCredits = "transferCredits";
  static const updateAccountAuth = "updateAccountAuth";
  static const updateKey = "updateKey";
  static const networkMaintenance = "networkMaintenance";
  static const activateProtocolVersion = "activateProtocolVersion";
  static const remoteTransaction = "remote";

  // Synthetic transactions (system-generated, not user-initiated)
  static const syntheticCreateIdentity = "syntheticCreateIdentity";
  static const syntheticWriteData = "syntheticWriteData";
  static const syntheticDepositTokens = "syntheticDepositTokens";
  static const syntheticDepositCredits = "syntheticDepositCredits";
  static const syntheticBurnTokens = "syntheticBurnTokens";
  static const syntheticForwardTransaction = "syntheticForwardTransaction";

  // System transactions (system-generated, not user-initiated)
  static const systemGenesis = "systemGenesis";
  static const directoryAnchor = "directoryAnchor";
  static const blockValidatorAnchor = "blockValidatorAnchor";
  static const systemWriteData = "systemWriteData";
}
