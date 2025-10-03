import 'package:test/test.dart';

// Import all Phase 2 test modules
import 'transaction_header_test.dart' as header_tests;
import 'transaction_bodies_test_fixed.dart' as body_tests;
import 'transaction_dispatcher_test_fixed.dart' as dispatcher_tests;
import 'api_client_test_fixed.dart' as api_tests;
import 'field_validation_test_fixed.dart' as validation_tests;
import 'json_serialization_test.dart' as json_tests;
import 'error_handling_test.dart' as error_tests;

void main() {
  group('Phase 2 Comprehensive Test Suite', () {
    // Test all Phase 2 components for 100% coverage

    group('1. Transaction Header Tests', () {
      header_tests.main();
    });

    group('2. Transaction Bodies Tests (33 types)', () {
      body_tests.main();
    });

    group('3. Transaction Dispatcher Tests', () {
      dispatcher_tests.main();
    });

    group('4. API Client Tests (35 methods)', () {
      api_tests.main();
    });

    group('5. Field Validation Tests', () {
      validation_tests.main();
    });

    group('6. JSON Serialization Tests', () {
      json_tests.main();
    });

    group('7. Error Handling Tests', () {
      error_tests.main();
    });
  });
}