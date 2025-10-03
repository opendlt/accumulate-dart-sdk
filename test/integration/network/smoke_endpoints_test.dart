import "package:test/test.dart";
import "package:opendlt_accumulate/opendlt_accumulate.dart";

void main() {
  group("Endpoint smoke (offline friendly)", () {
    test("construct mainnet/testnet clients", () {
      final acc = Accumulate.network(NetworkEndpoint.mainnet);
      expect(acc.v2, isNotNull);
      expect(acc.v3, isNotNull);
      acc.close();
    });

    test("construct custom endpoints", () {
      final acc = Accumulate.custom(
        v2Endpoint: "https://custom.example.com/v2",
        v3Endpoint: "https://custom.example.com/v3",
      );
      expect(acc.v2, isNotNull);
      expect(acc.v3, isNotNull);
      acc.close();
    });

    test("options are passed through", () {
      final opts =
          AccumulateOptions(timeoutMs: 5000, headers: {"X-Test": "true"});
      final acc =
          Accumulate.network(NetworkEndpoint.testnet, v2: opts, v3: opts);
      expect(acc.v2, isNotNull);
      expect(acc.v3, isNotNull);
      acc.close();
    });
  });
}
