import "dart:convert";
import "package:opendlt_accumulate/opendlt_accumulate.dart";

void main() async {
  final acc = Accumulate.network(
    NetworkEndpoint.mainnet,
    v2: const AccumulateOptions(timeoutMs: 20000),
    v3: const AccumulateOptions(timeoutMs: 20000),
  );

  try {
    // V3: preferred query
    final q = await acc.query({
      "type": "query-account",
      "url": "acc://accumulatenetwork.acme",
    });
    print("V3 query result:");
    print(const JsonEncoder.withIndent("  ").convert(q));

    // V3: submit (envelope)
    // final submitResp = await acc.submit({
    //   "envelope": { ... } // fill with a signed transaction envelope
    // });
    // print(submitResp);

    // V2: legacy example (status)
    final status = await acc.v2.status();
    print("V2 status:");
    print(status);
  } finally {
    acc.close();
  }
}
