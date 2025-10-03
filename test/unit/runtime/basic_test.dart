import "package:test/test.dart";
import "package:opendlt_accumulate/opendlt_accumulate.dart";

void main() {
  test("construct clients", () {
    final acc = Accumulate.network(NetworkEndpoint.testnet);
    expect(acc.v2, isNotNull);
    expect(acc.v3, isNotNull);
    acc.close();
  });
}
