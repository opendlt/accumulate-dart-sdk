#!/usr/bin/env python3
"""
Test Reorg Engineer: Post-Reorganization Verifier

Validates that the test reorganization was successful:
- No files left in old phase directories
- All imports resolve correctly
- Basic dart test discovery works
"""

import json
import os
import re
import subprocess
from pathlib import Path
from datetime import datetime

# Fixed paths
TEST_ROOT = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk/UNIFIED/test")
REPO_ROOT = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk")

def check_empty_directories():
    """Check that old phase directories are empty or removed"""
    old_dirs = ["phase1", "phase2", "phase3", "serialization", "validation"]
    results = {
        "empty_dirs": [],
        "non_empty_dirs": [],
        "removed_dirs": []
    }

    for dir_name in old_dirs:
        dir_path = TEST_ROOT / dir_name
        if not dir_path.exists():
            results["removed_dirs"].append(dir_name)
        elif not any(dir_path.rglob("*")):
            results["empty_dirs"].append(dir_name)
        else:
            # List remaining files
            remaining_files = [str(f.relative_to(dir_path)) for f in dir_path.rglob("*") if f.is_file()]
            results["non_empty_dirs"].append({
                "directory": dir_name,
                "remaining_files": remaining_files
            })

    return results

def check_functional_structure():
    """Verify the new functional directory structure exists"""
    expected_dirs = [
        "unit/enums", "unit/runtime", "unit/codec", "unit/signatures",
        "unit/transactions", "unit/protocol_types", "unit/errors",
        "unit/api", "unit/builders",
        "conformance/codec", "conformance/json",
        "golden", "integration/network", "quarantine",
        "support", "support/legacy"
    ]

    results = {
        "existing_dirs": [],
        "missing_dirs": []
    }

    for dir_path in expected_dirs:
        full_path = TEST_ROOT / dir_path
        if full_path.exists():
            results["existing_dirs"].append(dir_path)
        else:
            results["missing_dirs"].append(dir_path)

    return results

def validate_imports():
    """Basic validation of import statements in all Dart files"""
    issues = []
    dart_files = list(TEST_ROOT.rglob("*.dart"))

    # Patterns that indicate problematic imports
    problematic_patterns = [
        (r"import\s+['\"][^'\"]*phase[123][^'\"]*['\"];", "References old phase directories"),
        (r"import\s+['\"][^'\"]*\.\./\.\./\.\./[^'\"]*['\"];", "Too many ../ levels"),
        (r"import\s+['\"][^'\"]*//[^'\"]*['\"];", "Double slashes in path"),
        (r"import\s+['\"][^'\"]*\\[^'\"]*['\"];", "Windows backslashes in import"),
        (r"import\s+['\"][^'\"]*serialization[^'\"]*['\"];", "References old serialization directory"),
        (r"import\s+['\"][^'\"]*validation[^'\"]*['\"];", "References old validation directory"),
    ]

    for dart_file in dart_files:
        try:
            with open(dart_file, 'r', encoding='utf-8') as f:
                content = f.read()

            file_issues = []
            for pattern, description in problematic_patterns:
                matches = re.findall(pattern, content)
                if matches:
                    file_issues.append({
                        "pattern": description,
                        "matches": matches
                    })

            if file_issues:
                issues.append({
                    "file": str(dart_file.relative_to(TEST_ROOT)),
                    "issues": file_issues
                })

        except Exception as e:
            issues.append({
                "file": str(dart_file.relative_to(TEST_ROOT)),
                "error": str(e)
            })

    return issues

def check_required_files():
    """Check that required files exist in correct locations"""
    required_files = [
        "support/test_paths.dart",
        "support/golden_loader.dart",
        "all_tests.dart",
    ]

    results = {
        "existing_files": [],
        "missing_files": []
    }

    for file_path in required_files:
        full_path = TEST_ROOT / file_path
        if full_path.exists():
            results["existing_files"].append(file_path)
        else:
            results["missing_files"].append(file_path)

    # Check dart_test.yaml at repo root
    dart_test_yaml = REPO_ROOT / "dart_test.yaml"
    if dart_test_yaml.exists():
        results["existing_files"].append("dart_test.yaml (repo root)")
    else:
        results["missing_files"].append("dart_test.yaml (repo root)")

    return results

def test_dart_discovery():
    """Test basic dart test discovery without running tests"""
    try:
        # Change to repo root for dart commands
        os.chdir(REPO_ROOT)

        # Try dry run to check discovery
        result = subprocess.run(
            ["dart", "test", "--help"],
            capture_output=True,
            text=True,
            timeout=30
        )

        if result.returncode == 0:
            # Try discovering tests
            discovery_result = subprocess.run(
                ["dart", "test", "-n", "*.dart"],
                capture_output=True,
                text=True,
                timeout=60,
                cwd=REPO_ROOT
            )

            return {
                "dart_available": True,
                "discovery_success": discovery_result.returncode == 0,
                "discovery_output": discovery_result.stdout,
                "discovery_errors": discovery_result.stderr
            }
        else:
            return {
                "dart_available": False,
                "error": result.stderr
            }

    except subprocess.TimeoutExpired:
        return {
            "dart_available": True,
            "discovery_success": False,
            "error": "Timeout during test discovery"
        }
    except Exception as e:
        return {
            "dart_available": False,
            "error": str(e)
        }

def count_test_files():
    """Count test files in each category"""
    categories = {
        "unit": TEST_ROOT / "unit",
        "conformance": TEST_ROOT / "conformance",
        "integration": TEST_ROOT / "integration",
        "quarantine": TEST_ROOT / "quarantine",
        "support": TEST_ROOT / "support",
        "golden": TEST_ROOT / "golden"
    }

    counts = {}
    for category, path in categories.items():
        if path.exists():
            if category == "golden":
                # Count JSON files in golden
                json_files = list(path.rglob("*.json"))
                counts[category] = len(json_files)
            else:
                # Count Dart files
                dart_files = list(path.rglob("*.dart"))
                counts[category] = len(dart_files)
        else:
            counts[category] = 0

    return counts

def main():
    """Main verification function"""
    print("=== Test Reorg Engineer: Post-Reorganization Verifier ===")

    if not TEST_ROOT.exists():
        print(f"ERROR: Test root not found: {TEST_ROOT}")
        return 1

    verification_results = {
        "timestamp": datetime.now().isoformat(),
        "empty_directories": None,
        "functional_structure": None,
        "import_validation": None,
        "required_files": None,
        "dart_discovery": None,
        "test_file_counts": None
    }

    # Check empty directories
    print("\n1. Checking old phase directories...")
    verification_results["empty_directories"] = check_empty_directories()
    empty_dirs = verification_results["empty_directories"]

    print(f"   Removed: {len(empty_dirs['removed_dirs'])}")
    print(f"   Empty: {len(empty_dirs['empty_dirs'])}")
    print(f"   Non-empty: {len(empty_dirs['non_empty_dirs'])}")

    if empty_dirs['non_empty_dirs']:
        print("   WARNING: Non-empty old directories:")
        for dir_info in empty_dirs['non_empty_dirs']:
            print(f"     {dir_info['directory']}: {len(dir_info['remaining_files'])} files")

    # Check functional structure
    print("\n2. Checking functional directory structure...")
    verification_results["functional_structure"] = check_functional_structure()
    structure = verification_results["functional_structure"]

    print(f"   Existing: {len(structure['existing_dirs'])}")
    print(f"   Missing: {len(structure['missing_dirs'])}")

    if structure['missing_dirs']:
        print("   WARNING: Missing directories:")
        for missing in structure['missing_dirs']:
            print(f"     {missing}")

    # Validate imports
    print("\n3. Validating import statements...")
    verification_results["import_validation"] = validate_imports()
    import_issues = verification_results["import_validation"]

    print(f"   Files with import issues: {len(import_issues)}")
    if import_issues:
        print("   WARNING: Import issues found:")
        for issue in import_issues[:3]:  # Show first 3
            print(f"     {issue['file']}: {len(issue.get('issues', []))} issues")
        if len(import_issues) > 3:
            print(f"     ... and {len(import_issues) - 3} more files")

    # Check required files
    print("\n4. Checking required files...")
    verification_results["required_files"] = check_required_files()
    required = verification_results["required_files"]

    print(f"   Existing: {len(required['existing_files'])}")
    print(f"   Missing: {len(required['missing_files'])}")

    if required['missing_files']:
        print("   ERROR: Missing required files:")
        for missing in required['missing_files']:
            print(f"     {missing}")

    # Test dart discovery
    print("\n5. Testing Dart test discovery...")
    verification_results["dart_discovery"] = test_dart_discovery()
    discovery = verification_results["dart_discovery"]

    if discovery['dart_available']:
        if discovery['discovery_success']:
            print("   OK: Dart test discovery successful")
        else:
            print(f"   WARNING: Dart test discovery failed")
            if 'error' in discovery:
                print(f"     Error: {discovery['error']}")
    else:
        print(f"   WARNING: Dart not available or failed")
        if 'error' in discovery:
            print(f"     Error: {discovery['error']}")

    # Count test files
    print("\n6. Counting test files...")
    verification_results["test_file_counts"] = count_test_files()
    counts = verification_results["test_file_counts"]

    total_tests = sum(v for k, v in counts.items() if k != "golden")
    print(f"   Unit: {counts['unit']}")
    print(f"   Conformance: {counts['conformance']}")
    print(f"   Integration: {counts['integration']}")
    print(f"   Quarantine: {counts['quarantine']}")
    print(f"   Support: {counts['support']}")
    print(f"   Golden files: {counts['golden']}")
    print(f"   Total test files: {total_tests}")

    # Write verification report
    report_file = TEST_ROOT / "_reorg" / "verification_report.json"
    with open(report_file, 'w') as f:
        json.dump(verification_results, f, indent=2)

    # Determine overall status
    issues_found = (
        len(empty_dirs['non_empty_dirs']) +
        len(structure['missing_dirs']) +
        len(import_issues) +
        len(required['missing_files'])
    )

    print(f"\n=== Verification Summary ===")
    print(f"Issues found: {issues_found}")

    if issues_found == 0 and discovery.get('discovery_success', False):
        print("OK: Test reorganization verification PASSED")
        print(f"Report: {report_file}")
        return 0
    else:
        print("WARNING: Test reorganization verification found issues")
        print(f"Report: {report_file}")
        return 1

if __name__ == "__main__":
    exit(main())