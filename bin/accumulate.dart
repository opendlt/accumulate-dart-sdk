#!/usr/bin/env dart
// Accumulate SDK command-line interface (RB-04).
//
// Contract: docs/ai-agent-readiness/CLI-SPEC.md in accumulate-studio.
//   * Under --json, stdout carries EXACTLY ONE envelope object. Logs go to stderr.
//   * Exit codes: 0 ok · 1 operation failed · 2 usage error · 3 network unreachable.
//   * Errors carry canonical ACC_* codes so `retryable` tells an agent whether a
//     retry is productive instead of leaving it to guess.
//   * Never prompts. Mainnet needs --network mainnet AND ACCUMULATE_ALLOW_MAINNET=1.

import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:opendlt_accumulate/opendlt_accumulate.dart";

const envelopeVersion = "1";
const sdkName = "dart";
// Bump with pubspec.yaml on each release; Dart cannot read pubspec at runtime.
const sdkVersion = "2.3.7";

const exitOk = 0;
const exitFailed = 1;
const exitUsage = 2;
const exitNetwork = 3;

const defaultNetwork = "kermit";

class CatalogEntry {
  const CatalogEntry(this.category, this.retryable, this.protocolCodes,
      this.patterns, this.hint, this.remediation);
  final String category;
  final bool retryable;
  final List<int> protocolCodes;
  final List<String> patterns;
  final String hint;
  final String remediation;
}

/// Mirrors packages/codegen/src/manifests/errors.catalog.json. Wire codes were
/// verified against a live node by tools/agent-harness/negative-cases.mjs.
const catalog = <String, CatalogEntry>{
  "ACC_ACCOUNT_NOT_FOUND": CatalogEntry(
    "not_found",
    false,
    [-32807, -33404],
    ["accumulate error not found", "not found", "-32807", "-33404"],
    "The account URL does not exist on this network.",
    "Verify the URL and the network. If you just created the account, wait for its "
        "creating transaction to reach 'delivered' first. Note that on the V2 API a "
        "malformed URL is also reported as not-found.",
  ),
  "ACC_INVALID_PARAMS": CatalogEntry(
    "validation",
    false,
    [-32802, -32602],
    ["validation error", "field validation for", "invalid params", "-32802", "-32602"],
    "The request parameters were rejected by the node.",
    "Check the operation's declared inputs. Hashes are 32-byte hex; amounts are base-unit integers.",
  ),
  "ACC_METHOD_NOT_FOUND": CatalogEntry(
    "validation",
    false,
    [-32601],
    ["method not found", "-32601"],
    "The node does not expose the RPC method that was called.",
    "Use the SDK's canonical client rather than raw RPC; it targets the right API version.",
  ),
  "ACC_ROUTING_FAILED": CatalogEntry(
    "validation",
    false,
    [-33400],
    ["cannot route request", "nothing to route", "-33400"],
    "The node could not determine which partition should handle the request.",
    "Every transaction needs a header with a valid `principal` — that URL is the routing "
        "key. Build envelopes with TxBody + SmartSigner rather than by hand.",
  ),
  "ACC_INSUFFICIENT_CREDITS": CatalogEntry(
    "insufficient_credits",
    false,
    [],
    ["insufficientcredits", "insufficient credits"],
    "The signing key page does not hold enough credits to pay for this transaction.",
    "Call add_credits for the SIGNING key page, then wait for the credits to settle.",
  ),
  "ACC_UNAUTHORIZED_SIGNER": CatalogEntry(
    "auth",
    false,
    [403],
    ["unauthorized", "key does not belong to signer"],
    "The signing key is not on the key page that authorizes this principal.",
    "Sign with a key on the principal's authorizing key page (after create_identity, `<adi>/book/1`).",
  ),
  "ACC_INSUFFICIENT_BALANCE": CatalogEntry(
    "insufficient_balance",
    false,
    [],
    ["insufficient balance", "insufficient funds", "exceeds balance"],
    "The source account does not hold enough tokens for this transfer.",
    "Confirm the balance first. 1 ACME = 1e8 base units; custom tokens carry their own precision.",
  ),
  "ACC_NETWORK_UNAVAILABLE": CatalogEntry(
    "network",
    true,
    [],
    [
      "econnrefused",
      "econnreset",
      "etimedout",
      "timeout",
      "connection closed",
      "connection reset",
      "connection refused",
      "service unavailable",
      "socketexception",
      "handshakeexception",
      "failed host lookup",
      "connection attempt failed",
      "clientexception",
    ],
    "The endpoint could not be reached, or the request timed out.",
    "Retry with exponential backoff. This is the only class where a bare retry is productive.",
  ),
  "ACC_INTERNAL": CatalogEntry(
    "internal",
    true,
    [-32603],
    ["internal error", "-32603"],
    "The node reported an internal error.",
    "Retry once with backoff. If it persists, re-check the request shape.",
  ),
  "ACC_USAGE": CatalogEntry(
    "validation",
    false,
    [],
    [],
    "The command was invoked incorrectly.",
    "Run `accumulate --help --json` for the full command tree, flags and required arguments.",
  ),
};

/// Longest pattern wins, so "key does not belong to signer" beats bare "unauthorized".
final _patternIndex = () {
  final out = <List<String>>[];
  catalog.forEach((code, e) {
    for (final p in e.patterns) {
      out.add([p, code]);
    }
  });
  out.sort((a, b) => b[0].length.compareTo(a[0].length));
  return out;
}();

/// Map a raw error string onto a catalog code. Unrecognized errors fall back to a
/// NON-retryable code on purpose: unknown failures are far more often malformed
/// requests than transient faults, and defaulting to retryable is how an agent
/// burns its turn budget in a loop.
String classify(String raw) {
  final text = raw.toLowerCase();
  for (final pair in _patternIndex) {
    if (text.contains(pair[0])) return pair[1];
  }
  return "ACC_INVALID_PARAMS";
}

class UsageException implements Exception {
  UsageException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Verb {
  const Verb(this.name, this.summary, this.network, this.signs, this.args, this.flags);
  final String name;
  final String summary;
  final bool network;
  final bool signs;
  final List<Map<String, Object?>> args;
  final List<Map<String, Object?>> flags;

  Map<String, Object?> toJson() => {
        "name": name,
        "summary": summary,
        "network": network,
        "signs": signs,
        "args": args,
        "flags": flags,
      };
}

const verbs = <Verb>[
  Verb("query", "Query any Accumulate account", true, false,
      [{"name": "url", "type": "string", "required": true}], []),
  Verb("balance", "Get a token account balance", true, false,
      [{"name": "url", "type": "string", "required": true}], []),
  Verb("chain", "Read chain entries for an account", true, false,
      [{"name": "url", "type": "string", "required": true}], [
    {"name": "--chain", "type": "string", "required": false, "default": "main"},
    {"name": "--start", "type": "integer", "required": false, "default": 0},
    {"name": "--count", "type": "integer", "required": false, "default": 10},
  ]),
  Verb("faucet", "Request testnet ACME for a lite token account", true, false,
      [{"name": "url", "type": "string", "required": true}], []),
  Verb("credits estimate", "Estimate credits purchased for an ACME amount", true, false,
      [{"name": "url", "type": "string", "required": true}],
      [{"name": "--amount", "type": "number", "required": true}]),
  Verb("tx build", "Build an unsigned transaction body", false, false,
      [{"name": "op", "type": "string", "required": true}],
      [{"name": "--param", "type": "key=value", "required": false, "repeatable": true},
       {"name": "--out", "type": "path", "required": false}]),
  Verb("tx sign", "Sign a transaction body into a submittable envelope", true, true, [], [
    {"name": "--body", "type": "path", "required": true},
    {"name": "--principal", "type": "string", "required": true},
    {"name": "--signer", "type": "string", "required": true},
    {"name": "--key-file", "type": "path", "required": false},
    {"name": "--key-env", "type": "string", "required": false},
    {"name": "--out", "type": "path", "required": false},
  ]),
  Verb("tx submit", "Submit an ALREADY-SIGNED envelope (does not sign)", true, false, [], [
    {"name": "--envelope", "type": "path", "required": true},
  ]),
  Verb("tx wait", "Poll a transaction until it reaches a final state", true, false,
      [{"name": "txid", "type": "string", "required": true}],
      [{"name": "--timeout", "type": "integer", "required": false, "default": 60}]),
  Verb("tx status", "Read a transaction's current status", true, false,
      [{"name": "txid", "type": "string", "required": true}], []),
  Verb("keys generate", "Generate a keypair (never written to disk)", false, false, [],
      [{"name": "--algorithm", "type": "string", "required": false, "default": "ed25519"}]),
  Verb("net list", "List known networks", false, false, [], []),
  Verb("net status", "Check the selected network's reachability", true, false, [], []),
  Verb("version", "Report SDK and envelope versions", false, false, [], []),
];

const globalFlags = [
  {"name": "--json", "type": "boolean", "summary": "Emit one envelope object on stdout"},
  {
    "name": "--network",
    "type": "string",
    "default": defaultNetwork,
    "summary": "Target network; mainnet also requires ACCUMULATE_ALLOW_MAINNET=1",
  },
  {"name": "--help", "type": "boolean", "summary": "Show help; with --json returns the command tree"},
];

const groups = {"credits", "tx", "keys", "net"};

List<int> _hexToBytes(String hex) {
  final clean = hex.startsWith("0x") ? hex.substring(2) : hex;
  if (clean.length % 2 != 0) {
    throw UsageException("private key hex must have an even number of characters");
  }
  return [
    for (var i = 0; i < clean.length; i += 2)
      int.parse(clean.substring(i, i + 2), radix: 16)
  ];
}

/// Owns stdout. Exactly one object is ever written to it.
class Emitter {
  Emitter(this.asJson, this.network, this.started);
  final bool asJson;
  final String? network;
  final Stopwatch started;
  bool _emitted = false;

  Map<String, Object?> _meta() => {
        "network": network,
        "sdk": sdkName,
        "version": sdkVersion,
        "durationMs": started.elapsedMilliseconds,
      };

  int ok(Object? data) {
    assert(!_emitted, "envelope emitted twice");
    _emitted = true;
    if (asJson) {
      stdout.writeln(jsonEncode(
          {"envelope": envelopeVersion, "ok": true, "data": data, "meta": _meta()}));
    } else {
      stdout.writeln(const JsonEncoder.withIndent("  ").convert(data));
    }
    return exitOk;
  }

  int fail(String raw, {String? code, int? exitCode}) {
    assert(!_emitted, "envelope emitted twice");
    _emitted = true;
    final resolved = code ?? classify(raw);
    final e = catalog[resolved]!;
    final error = <String, Object?>{
      "code": resolved,
      "category": e.category,
      "retryable": e.retryable,
      "hint": e.hint,
      "remediation": e.remediation,
      "raw": raw,
    };
    if (e.protocolCodes.isNotEmpty) error["protocolCodes"] = e.protocolCodes;

    final ec = exitCode ??
        (resolved == "ACC_USAGE"
            ? exitUsage
            : resolved == "ACC_NETWORK_UNAVAILABLE"
                ? exitNetwork
                : exitFailed);
    if (asJson) {
      stdout.writeln(jsonEncode(
          {"envelope": envelopeVersion, "ok": false, "error": error, "meta": _meta()}));
    } else {
      stderr.writeln("error: $resolved: ${e.hint}");
      stderr.writeln("  retryable: ${e.retryable ? 'yes' : 'no'}");
      stderr.writeln("  fix: ${e.remediation}");
    }
    return ec;
  }
}


/// Case- and underscore-insensitive match, so snake_case and camelCase both work.
/// Op names differ per SDK (send_tokens_single vs sendTokensSingle) and making an
/// agent learn each one defeats having a single CLI spec.
String? _pick(Map<String, String> p, String wanted) {
  String norm(String x) => x.replaceAll("_", "").toLowerCase();
  final target = norm(wanted);
  for (final k in p.keys) {
    if (norm(k) == target) return p[k];
  }
  return null;
}

String _req(Map<String, String> p, String name, String op) {
  final v = _pick(p, name);
  if (v == null) throw UsageException("'$op' requires --param $name");
  return v;
}

/// Dart has no practical runtime reflection, so builder dispatch is explicit.
/// Every branch delegates to `TxBody`, which is what keeps the produced bytes
/// identical to the SDK path.
const _ops = <String>[
  "create_identity", "create_token_account", "create_data_account", "create_token",
  "send_tokens_single", "issue_tokens_single", "burn_tokens", "add_credits",
  "buy_credits", "write_data", "create_lite_token_account",
];

Map<String, dynamic> buildBody(String op, Map<String, String> p) {
  String n(String x) => x.replaceAll("_", "").toLowerCase();
  switch (n(op)) {
    case "createidentity":
      return TxBody.createIdentity(
        url: _req(p, "url", op),
        keyBookUrl: _pick(p, "key_book_url"),
        publicKeyHash: _pick(p, "public_key_hash"),
      );
    case "createtokenaccount":
      return TxBody.createTokenAccount(
        url: _req(p, "url", op), tokenUrl: _req(p, "token_url", op));
    case "createdataaccount":
      return TxBody.createDataAccount(url: _req(p, "url", op));
    case "createtoken":
      return TxBody.createToken(
        url: _req(p, "url", op),
        symbol: _req(p, "symbol", op),
        precision: int.parse(_req(p, "precision", op)));
    case "sendtokenssingle":
      return TxBody.sendTokensSingle(
        toUrl: _req(p, "to_url", op), amount: _req(p, "amount", op));
    case "issuetokenssingle":
      return TxBody.issueTokensSingle(
        toUrl: _req(p, "to_url", op), amount: _req(p, "amount", op));
    case "burntokens":
      return TxBody.burnTokens(amount: _req(p, "amount", op));
    case "addcredits":
      final oracle = _pick(p, "oracle");
      return TxBody.addCredits(
        recipient: _req(p, "recipient", op),
        amount: _req(p, "amount", op),
        oracle: oracle == null ? null : int.parse(oracle));
    case "buycredits":
      final oracle = _pick(p, "oracle");
      return TxBody.buyCredits(
        recipientUrl: _req(p, "recipient_url", op),
        amount: _req(p, "amount", op),
        oracle: oracle == null ? null : int.parse(oracle));
    case "writedata":
      // entriesHex is a LIST of hex strings; accept one --param data=<hex>.
      return TxBody.writeData(entriesHex: [_req(p, "data", op)]);
    case "createlitetokenaccount":
      return TxBody.createLiteTokenAccount();
    default:
      throw UsageException(
          "unknown transaction op '$op' — available: ${_ops.join(', ')}");
  }
}

/// Resolve the signing key from an EXPLICIT source only.
///
/// Never falls back to an ambient default: a CLI that quietly finds a key is a
/// CLI that signs something the caller did not intend. Keys are never positional
/// either, so they stay out of shell history.
Future<String> loadPrivateKey(Map<String, Object?> a) async {
  final keyFile = a["key_file"] as String?;
  final keyEnv = a["key_env"] as String?;
  if (keyFile != null && keyEnv != null) {
    throw UsageException("pass only one of --key-file or --key-env");
  }
  if (keyFile != null) {
    final f = File(keyFile);
    if (!await f.exists()) throw UsageException("could not read --key-file: $keyFile");
    return (await f.readAsString()).trim();
  }
  if (keyEnv != null) {
    final v = Platform.environment[keyEnv];
    if (v == null || v.isEmpty) {
      throw UsageException("--key-env '$keyEnv' is not set or empty");
    }
    return v.trim();
  }
  throw UsageException(
      "signing requires an explicit key source: --key-file <path> or --key-env <VAR>. "
      "No ambient default key is ever used.");
}

NetworkEndpoint resolveEndpoint(String network) {
  switch (network) {
    case "mainnet":
      if (Platform.environment["ACCUMULATE_ALLOW_MAINNET"] != "1") {
        throw UsageException("refusing to target mainnet: pass --network mainnet AND set "
            "ACCUMULATE_ALLOW_MAINNET=1. Both are required, deliberately.");
      }
      return NetworkEndpoint.mainnet;
    case "kermit":
    case "testnet":
      return NetworkEndpoint.testnet;
    case "local":
      return NetworkEndpoint.devnet;
    default:
      throw UsageException(
          "unknown network '$network' — known: kermit, testnet, mainnet, local");
  }
}

String _flagKey(String name) => name.replaceFirst("--", "").replaceAll("-", "_");

List<Object> parseVerb(List<String> tokens) {
  if (tokens.isEmpty) {
    throw UsageException(
        "no verb given — run `accumulate --help --json` for the command tree");
  }
  final head = tokens.first;
  if (groups.contains(head)) {
    if (tokens.length < 2) {
      throw UsageException("'$head' is a command group; it needs a subcommand");
    }
    final name = "$head ${tokens[1]}";
    if (!verbs.any((v) => v.name == name)) {
      throw UsageException("unknown subcommand '${tokens[1]}' for group '$head'");
    }
    return [name, tokens.sublist(2)];
  }
  if (!verbs.any((v) => v.name == head)) {
    throw UsageException(
        "unknown verb '$head' — run `accumulate --help --json` for the command tree");
  }
  return [head, tokens.sublist(1)];
}

Map<String, Object?> parseVerbArgs(String verb, List<String> tokens) {
  final spec = verbs.firstWhere((v) => v.name == verb);
  final out = <String, Object?>{};
  for (final f in spec.flags) {
    final key = _flagKey(f["name"] as String);
    if (f["default"] != null) out[key] = f["default"];
    if (f["repeatable"] == true) out[key] = <String>[];
  }
  final positional = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t.startsWith("--")) {
      final matches = spec.flags.where((x) => x["name"] == t).toList();
      if (matches.isEmpty) throw UsageException("unknown flag '$t' for '$verb'");
      final f = matches.first;
      if (i + 1 >= tokens.length) throw UsageException("flag '$t' expects a value");
      final raw = tokens[++i];
      final key = _flagKey(t);
      if (f["repeatable"] == true) {
        (out[key] as List<String>).add(raw);
      } else if (f["type"] == "integer") {
        final v = int.tryParse(raw);
        if (v == null) throw UsageException("flag '$t' expects an integer, got '$raw'");
        out[key] = v;
      } else if (f["type"] == "number") {
        final v = double.tryParse(raw);
        if (v == null) throw UsageException("flag '$t' expects a number, got '$raw'");
        out[key] = v;
      } else {
        out[key] = raw;
      }
    } else {
      positional.add(t);
    }
  }
  for (var i = 0; i < spec.args.length; i++) {
    if (i < positional.length) out[spec.args[i]["name"] as String] = positional[i];
  }
  if (positional.length > spec.args.length) {
    throw UsageException("unexpected arguments for '$verb': "
        "${positional.sublist(spec.args.length).join(' ')}");
  }
  for (final a in spec.args) {
    if (a["required"] == true && out[a["name"]] == null) {
      throw UsageException("'$verb' requires <${a["name"]}>");
    }
  }
  for (final f in spec.flags) {
    if (f["required"] == true && out[_flagKey(f["name"] as String)] == null) {
      throw UsageException("'$verb' requires ${f["name"]}");
    }
  }
  return out;
}

Future<int> runVerb(String verb, Map<String, Object?> a, String network, Emitter em) async {
  if (verb == "version") {
    return em.ok({"sdk": sdkName, "version": sdkVersion, "envelope": envelopeVersion});
  }

  if (verb == "net list") {
    return em.ok({
      "networks": [
        {"id": "kermit", "endpoint": NetworkEndpoint.testnet.baseUrl, "faucet": true, "default": true},
        {"id": "testnet", "endpoint": NetworkEndpoint.testnet.baseUrl, "faucet": true, "default": false},
        {
          "id": "mainnet",
          "endpoint": NetworkEndpoint.mainnet.baseUrl,
          "faucet": false,
          "default": false,
          "requiresOptIn": true,
        },
        {"id": "local", "endpoint": NetworkEndpoint.devnet.baseUrl, "faucet": true, "default": false},
      ]
    });
  }

  if (verb == "keys generate") {
    final algorithm = (a["algorithm"] as String? ?? "ed25519").toLowerCase();
    if (algorithm != "ed25519") {
      throw UsageException("unsupported algorithm '$algorithm' — only ed25519 is supported");
    }
    final kp = await Ed25519KeyPair.generate();
    final pk = await kp.publicKeyBytes();
    return em.ok({
      "algorithm": "ed25519",
      "publicKey": pk.map((e) => e.toRadixString(16).padLeft(2, "0")).join(),
      "liteIdentity": (await kp.deriveLiteIdentityUrl()).toString(),
      "liteTokenAccount": (await kp.deriveLiteTokenAccountUrl()).toString(),
    });
  }

  if (verb == "tx build") {
    final params = <String, String>{};
    for (final raw in (a["param"] as List<String>? ?? const <String>[])) {
      final idx = raw.indexOf("=");
      if (idx < 0) throw UsageException("--param must be key=value, got '$raw'");
      params[raw.substring(0, idx)] = raw.substring(idx + 1);
    }
    final body = buildBody(a["op"] as String, params);
    final outPath = a["out"] as String?;
    if (outPath != null) {
      await File(outPath).writeAsString(jsonEncode(body));
    }
    return em.ok({
      "op": a["op"], "params": params, "body": body, "signed": false, "out": outPath,
      "note": "unsigned body; sign it with `tx sign --body <file>`, then `tx submit`",
    });
  }

  final endpoint = resolveEndpoint(network);
  final acc = Accumulate.network(
    endpoint,
    v2: const AccumulateOptions(timeoutMs: 20000),
    v3: const AccumulateOptions(timeoutMs: 20000),
  );

  try {
    switch (verb) {
      case "query":
        final res = await acc.v3.query({"scope": a["url"]});
        return em.ok({"url": a["url"], "account": res});

      case "balance":
        final res = await acc.v3.query({"scope": a["url"]});
        Object? balance;
        if (res is Map && res["account"] is Map) {
          balance = (res["account"] as Map)["balance"];
        }
        return em.ok({"url": a["url"], "balance": balance, "raw": res});

      case "chain":
        final res = await acc.v3.query({
          "scope": a["url"],
          "query": {
            "queryType": "chain",
            "name": a["chain"],
            "range": {"start": a["start"], "count": a["count"]},
          },
        });
        return em.ok({
          "url": a["url"],
          "chain": a["chain"],
          "start": a["start"],
          "count": a["count"],
          "entries": res,
        });

      case "faucet":
        final res = await acc.v2.faucet({"url": a["url"]});
        return em.ok({"url": a["url"], "result": res});

      case "credits estimate":
        final res =
            await acc.v3.query({"scope": "acc://dn.acme/oracle"});
        return em.ok({
          "url": a["url"],
          "acme": a["amount"],
          "oracle": res,
          "note": "credits = acme * oraclePrice / 1e8 (oracle is unscaled)",
        });

      case "tx status":
        final res = await acc.v3.query({"scope": a["txid"]});
        return em.ok({"txid": a["txid"], "status": res});

      case "tx wait":
        final deadline =
            DateTime.now().add(Duration(seconds: (a["timeout"] as int?) ?? 60));
        Object? last;
        while (DateTime.now().isBefore(deadline)) {
          last = await acc.v3.query({"scope": a["txid"]});
          String? status;
          if (last is Map && last["status"] is Map) {
            status = (last["status"] as Map)["code"] as String?;
          }
          if (status == "delivered" || status == "failed") {
            return em.ok({"txid": a["txid"], "final": true, "status": status, "raw": last});
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        return em.fail("timed out waiting for ${a["txid"]} to reach a final state",
            code: "ACC_NETWORK_UNAVAILABLE", exitCode: exitFailed);

      case "net status":
        // A protocol rejection still proves the node answered, so only a transport
        // failure counts as unreachable — that distinction is what exit 3 means.
        try {
          final probe =
              await acc.v3.query({"scope": "acc://dn.acme"});
          return em.ok(
              {"network": network, "endpoint": endpoint.baseUrl, "reachable": true, "probe": probe});
        } catch (e) {
          final raw = e.toString();
          if (classify(raw) == "ACC_NETWORK_UNAVAILABLE") {
            return em.fail(raw, code: "ACC_NETWORK_UNAVAILABLE", exitCode: exitNetwork);
          }
          return em.ok({
            "network": network,
            "endpoint": endpoint.baseUrl,
            "reachable": true,
            "probeError": raw,
          });
        }

      case "tx sign":
        // The ONLY verb that signs. Delegates to the SDK signer: signing bytes
        // are consensus-visible and a second implementation is how they drift.
        final privateHex = await loadPrivateKey(a);
        final bodyFile = File(a["body"] as String);
        if (!await bodyFile.exists()) {
          throw UsageException("no such body file: ${a["body"]}");
        }
        final body = jsonDecode(await bodyFile.readAsString()) as Map<String, dynamic>;
        final seed = Uint8List.fromList(_hexToBytes(privateHex));
        final kp = await Ed25519KeyPair.fromSeed(seed);
        final signer = SmartSigner(
          client: acc.v3,
          keypair: UnifiedKeyPair.fromEd25519(kp),
          signerUrl: a["signer"] as String,
        );
        final envelope = await signer.sign(
            principal: a["principal"] as String, body: body);
        final signedJson = envelope.toJson();
        final outPath = a["out"] as String?;
        if (outPath != null) {
          await File(outPath).writeAsString(jsonEncode(signedJson));
        }
        return em.ok({
          "signed": true, "principal": a["principal"], "signer": a["signer"],
          "envelope": signedJson, "out": outPath,
        });

      case "tx submit":
        // Deliberately does NOT sign, and no longer pretends to: it used to take
        // --key-file/--key-env and never use them.
        final f = File(a["envelope"] as String);
        if (!await f.exists()) {
          throw UsageException("no such envelope file: ${a["envelope"]}");
        }
        final env = jsonDecode(await f.readAsString());
        final res = await acc.v3.submit(env);
        return em.ok({"submitted": true, "result": res});

      default:
        throw UsageException("unknown verb '$verb'");
    }
  } finally {
    acc.close();
  }
}

Future<int> run(List<String> argv) async {
  final started = Stopwatch()..start();
  final asJson = argv.contains("--json");
  var network = defaultNetwork;
  final ni = argv.indexOf("--network");
  if (ni > -1) {
    if (ni + 1 >= argv.length) {
      return Emitter(asJson, null, started)
          .fail("flag '--network' expects a value", code: "ACC_USAGE");
    }
    network = argv[ni + 1];
  }
  final em = Emitter(asJson, network, started);

  final tokens = <String>[];
  for (var i = 0; i < argv.length; i++) {
    if (argv[i] == "--json") continue;
    if (i == ni) {
      i++; // skip the flag's value too
      continue;
    }
    tokens.add(argv[i]);
  }

  final wantsHelp = tokens.contains("--help") || tokens.contains("-h");
  final verbTokens =
      tokens.where((t) => t != "--help" && t != "-h" && t != "--version").toList();

  if (wantsHelp || verbTokens.isEmpty) {
    if (asJson) {
      return em.ok({
        "command": "accumulate",
        "envelopeVersion": envelopeVersion,
        "globalFlags": globalFlags,
        "verbs": verbs.map((v) => v.toJson()).toList(),
      });
    }
    stdout.writeln("accumulate — Accumulate SDK CLI\n");
    for (final v in verbs) {
      stdout.writeln("  ${v.name.padRight(20)} ${v.summary}");
    }
    stdout.writeln("\nRun with --json --help for the machine-readable command tree.");
    return exitOk;
  }

  try {
    final parsed = parseVerb(verbTokens);
    final a = parseVerbArgs(parsed[0] as String, parsed[1] as List<String>);
    return await runVerb(parsed[0] as String, a, network, em);
  } on UsageException catch (e) {
    return em.fail(e.message, code: "ACC_USAGE");
  } catch (e) {
    final raw = e.toString();
    final code = classify(raw);
    return em.fail(raw,
        code: code, exitCode: code == "ACC_NETWORK_UNAVAILABLE" ? exitNetwork : exitFailed);
  }
}

Future<void> main(List<String> args) async {
  exitCode = await run(args);
}
