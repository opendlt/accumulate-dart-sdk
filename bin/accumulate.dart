#!/usr/bin/env dart

import "dart:convert";
import "dart:io";
import "package:opendlt_accumulate/opendlt_accumulate.dart";
import "package:opendlt_accumulate/src/crypto/ed25519.dart";

void usage() {
  print("accumulate CLI");
  print("  acc keygen                 # print pubkey + LID/LTA");
  print("  acc query <acc://...>      # v3 query-account");
  print("  acc submit <file.json>     # v3 submit envelope");
  exit(1);
}

Future<int> main(List<String> args) async {
  if (args.isEmpty) usage();

  final acc = Accumulate.network(
    NetworkEndpoint.testnet,
    v2: const AccumulateOptions(timeoutMs: 20000),
    v3: const AccumulateOptions(timeoutMs: 20000),
  );

  try {
    switch (args.first) {
      case "keygen":
        final kp = await Ed25519KeyPair.generate();
        final lid = await kp.deriveLiteIdentityUrl();
        final lta = await kp.deriveLiteTokenAccountUrl();
        final pk = await kp.publicKeyBytes();
        print(jsonEncode({
          "publicKeyHex":
              pk.map((e) => e.toRadixString(16).padLeft(2, "0")).join(),
          "lid": lid.toString(),
          "lta": lta.toString()
        }));
        return 0;

      case "query":
        if (args.length < 2) usage();
        final res =
            await acc.v3.query({"type": "query-account", "url": args[1]});
        print(const JsonEncoder.withIndent("  ").convert(res));
        return 0;

      case "submit":
        if (args.length < 2) usage();
        final f = File(args[1]);
        if (!await f.exists()) {
          stderr.writeln("No such file: ${args[1]}");
          return 2;
        }
        final env = jsonDecode(await f.readAsString());
        final res = await acc.v3.submit(env);
        print(const JsonEncoder.withIndent("  ").convert(res));
        return 0;

      default:
        usage();
        return 1;
    }
  } catch (e) {
    stderr.writeln("Error: $e");
    return 1;
  } finally {
    acc.close();
  }
}
