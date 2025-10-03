#!/usr/bin/env python3
"""
Test Reorg Engineer: Import Rewriter

Scans all *.dart files under TEST_ROOT and rewrites imports that reference
old paths to new functional locations. Normalizes to package imports where
possible, otherwise uses relative paths.
"""

import re
import os
from pathlib import Path
from datetime import datetime

# Fixed paths
TEST_ROOT = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk/UNIFIED/test")
REPO_ROOT = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk")

def get_package_name():
    """Get package name from pubspec.yaml"""
    pubspec_path = REPO_ROOT / "pubspec.yaml"
    if not pubspec_path.exists():
        pubspec_path = REPO_ROOT / "UNIFIED" / "pubspec.yaml"

    if pubspec_path.exists():
        try:
            with open(pubspec_path, 'r') as f:
                for line in f:
                    if line.startswith('name:'):
                        return line.split(':')[1].strip()
        except Exception as e:
            print(f"Warning: Could not read pubspec.yaml: {e}")

    return "opendlt_accumulate_unified"  # fallback

def get_relative_depth(file_path):
    """Get depth of file relative to TEST_ROOT"""
    rel_path = file_path.relative_to(TEST_ROOT)
    return len(rel_path.parts) - 1  # -1 because file itself doesn't count

def build_import_mappings():
    """Build mapping of old import patterns to new ones"""
    package_name = get_package_name()

    # Direct file mappings
    direct_mappings = {
        # Golden loader moved to support
        r"import\s+['\"]\.\.\/conformance\/golden_loader\.dart['\"];": f"import 'package:{package_name}/support/golden_loader.dart';",
        r"import\s+['\"]conformance\/golden_loader\.dart['\"];": f"import 'package:{package_name}/support/golden_loader.dart';",
        r"import\s+['\"]\.\.\/\.\.\/conformance\/golden_loader\.dart['\"];": f"import 'package:{package_name}/support/golden_loader.dart';",

        # Phase imports to functional locations
        r"import\s+['\"]\.\.\/phase2\/([^'\"]+)['\"];": r"import '../\1';",  # Will be computed per file
        r"import\s+['\"]\.\.\/phase3\/([^'\"]+)['\"];": r"import '../\1';",  # Will be computed per file
        r"import\s+['\"]phase2\/([^'\"]+)['\"];": r"import '../unit/api/\1';",  # Default mapping
        r"import\s+['\"]phase3\/([^'\"]+)['\"];": r"import '../unit/protocol_types/\1';",  # Default mapping
    }

    # Pattern-based mappings for specific known files
    file_mappings = {
        "api_client_test.dart": "unit/api/api_client_test.dart",
        "error_handling_test.dart": "unit/errors/error_handling_test.dart",
        "field_validation_test.dart": "unit/transactions/field_validation_test.dart",
        "json_serialization_test.dart": "unit/codec/json_serialization_test.dart",
        "phase2_test_suite.dart": "support/legacy/phase2_test_suite.dart",
        "transaction_bodies_test.dart": "unit/transactions/transaction_bodies_test.dart",
        "transaction_dispatcher_test.dart": "unit/transactions/transaction_dispatcher_test.dart",
        "transaction_header_test.dart": "unit/transactions/transaction_header_test.dart",
        "canonical_json_conformance_test.dart": "conformance/json/canonical_json_conformance_test.dart",
        "hash_validation_test.dart": "unit/protocol_types/hash_validation_test.dart",
        "phase3_test_suite.dart": "support/legacy/phase3_test_suite.dart",
        "protocol_types_validation_test.dart": "unit/protocol_types/protocol_types_validation_test.dart",
        "runtime_helpers_test.dart": "unit/runtime/runtime_helpers_test.dart",
        "type_serialization_test.dart": "unit/protocol_types/type_serialization_test.dart",
    }

    return direct_mappings, file_mappings

def calculate_relative_path(from_file, to_file):
    """Calculate relative path from one file to another"""
    try:
        # Get relative paths from TEST_ROOT
        from_rel = from_file.relative_to(TEST_ROOT)
        to_rel = Path(to_file)

        # Calculate depth difference
        from_depth = len(from_rel.parts) - 1  # -1 for the file itself

        # Build relative path with forward slashes (Dart standard)
        up_levels = "../" * from_depth
        to_rel_str = str(to_rel).replace("\\", "/")
        return f"{up_levels}{to_rel_str}"
    except Exception:
        return str(to_file).replace("\\", "/")

def rewrite_file_imports(dart_file):
    """Rewrite imports in a single Dart file"""
    try:
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        direct_mappings, file_mappings = build_import_mappings()
        package_name = get_package_name()

        # Apply direct mappings first
        for pattern, replacement in direct_mappings.items():
            content = re.sub(pattern, replacement, content)

        # Handle relative imports to moved files
        for file_name, new_location in file_mappings.items():
            # Look for imports of this specific file
            escaped_name = re.escape(file_name)
            patterns = [
                rf"import\s+['\"]\.\.\/phase2\/{escaped_name}['\"];",
                rf"import\s+['\"]\.\.\/phase3\/{escaped_name}['\"];",
                rf"import\s+['\"]phase2\/{escaped_name}['\"];",
                rf"import\s+['\"]phase3\/{escaped_name}['\"];",
                rf"import\s+['\"]\.\.\/\.\.\/phase2\/{escaped_name}['\"];",
                rf"import\s+['\"]\.\.\/\.\.\/phase3\/{escaped_name}['\"];",
            ]

            for pattern in patterns:
                # Calculate relative path from current file to new location
                rel_path = calculate_relative_path(dart_file, new_location)
                replacement = f"import '{rel_path}';"
                content = re.sub(pattern, replacement, content)

        # Fix any remaining phase references with generic patterns
        content = re.sub(
            r"import\s+['\"]\.\.\/phase[23]\/([^'\"]+)['\"];",
            lambda m: f"import 'package:{package_name}/unit/{m.group(1)}';",
            content
        )

        # Fix conformance references
        content = re.sub(
            r"import\s+['\"]\.\.\/conformance\/([^'\"]+)['\"];",
            lambda m: f"import 'package:{package_name}/conformance/{m.group(1)}';",
            content
        )

        # Write back if changed
        if content != original_content:
            with open(dart_file, 'w', encoding='utf-8') as f:
                f.write(content)
            return True

        return False

    except Exception as e:
        print(f"ERROR rewriting {dart_file}: {e}")
        return False

def scan_and_rewrite_imports():
    """Scan all Dart files and rewrite imports"""
    results = {
        "scanned": 0,
        "modified": 0,
        "errors": [],
        "modified_files": []
    }

    # Find all .dart files under TEST_ROOT, excluding backup directories
    dart_files = []
    for dart_file in TEST_ROOT.rglob("*.dart"):
        # Skip backup directories
        if "_backup" in str(dart_file):
            continue
        dart_files.append(dart_file)

    for dart_file in dart_files:
        results["scanned"] += 1

        try:
            if rewrite_file_imports(dart_file):
                results["modified"] += 1
                results["modified_files"].append(str(dart_file.relative_to(TEST_ROOT)))
                print(f"Modified imports: {dart_file.relative_to(TEST_ROOT)}")
        except Exception as e:
            results["errors"].append({
                "file": str(dart_file.relative_to(TEST_ROOT)),
                "error": str(e)
            })

    return results

def validate_import_syntax():
    """Basic validation of import syntax in all files"""
    issues = []
    dart_files = []
    for dart_file in TEST_ROOT.rglob("*.dart"):
        # Skip backup directories
        if "_backup" in str(dart_file):
            continue
        dart_files.append(dart_file)

    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()

            # Look for obviously broken imports
            broken_patterns = [
                r"import\s+['\"][^'\"]*phase[123][^'\"]*['\"];",  # Still referencing phase dirs
                r"import\s+['\"][^'\"]*\.\./\.\./\.\./[^'\"]*['\"];",  # Too many ../
                r"import\s+['\"][^'\"]*//[^'\"]*['\"];",  # Double slashes
            ]

            for pattern in broken_patterns:
                matches = re.findall(pattern, content)
                if matches:
                    issues.append({
                        "file": str(dart_file.relative_to(TEST_ROOT)),
                        "broken_imports": matches
                    })

        except Exception as e:
            issues.append({
                "file": str(dart_file.relative_to(TEST_ROOT)),
                "error": str(e)
            })

    return issues

def main():
    """Main import rewriting function"""
    print("=== Test Reorg Engineer: Import Rewriter ===")

    if not TEST_ROOT.exists():
        print(f"ERROR: Test root not found: {TEST_ROOT}")
        return 1

    package_name = get_package_name()
    print(f"Using package name: {package_name}")

    # Rewrite imports
    print("\nScanning and rewriting imports...")
    results = scan_and_rewrite_imports()

    # Validate imports
    print("\nValidating import syntax...")
    issues = validate_import_syntax()

    # Write results
    log_file = TEST_ROOT / "_reorg" / "import_rewrite_log.json"
    log_data = {
        "timestamp": datetime.now().isoformat(),
        "package_name": package_name,
        "results": results,
        "validation_issues": issues
    }

    with open(log_file, 'w') as f:
        import json
        json.dump(log_data, f, indent=2)

    # Print summary
    print(f"\n=== Import Rewrite Summary ===")
    print(f"Files scanned: {results['scanned']}")
    print(f"Files modified: {results['modified']}")
    print(f"Validation issues: {len(issues)}")

    if results['errors']:
        print(f"\nErrors: {len(results['errors'])}")
        for error in results['errors']:
            print(f"  {error['file']}: {error['error']}")

    if issues:
        print(f"\nValidation issues found:")
        for issue in issues[:5]:  # Show first 5
            print(f"  {issue['file']}: {issue.get('broken_imports', issue.get('error', 'Unknown'))}")
        if len(issues) > 5:
            print(f"  ... and {len(issues) - 5} more")

    print(f"\nImport rewrite completed. Log: {log_file}")
    return 0 if len(results['errors']) == 0 and len(issues) == 0 else 1

if __name__ == "__main__":
    exit(main())