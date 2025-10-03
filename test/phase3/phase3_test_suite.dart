import 'package:test/test.dart';

// Import all Phase 3 test modules
import 'protocol_types_validation_test.dart' as validation_tests;
import 'canonical_json_conformance_test.dart' as json_tests;
import 'hash_validation_test.dart' as hash_tests;
import 'runtime_helpers_test.dart' as runtime_tests;
import 'type_serialization_test.dart' as serialization_tests;

void main() {
  group('Phase 3 Comprehensive Test Suite - Stages 2 & 3', () {
    // Test all Phase 3 Stages 2 & 3 components for 100% coverage

    group('1. Protocol Types Validation (88 types)', () {
      validation_tests.main();
    });

    group('2. Canonical JSON Conformance', () {
      json_tests.main();
    });

    group('3. Hash32 Validation Testing', () {
      hash_tests.main();
    });

    group('4. Runtime Helpers Testing', () {
      runtime_tests.main();
    });

    group('5. Type Serialization Round-trip Testing', () {
      serialization_tests.main();
    });
  });
}