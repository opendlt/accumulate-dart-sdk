#!/usr/bin/env python3
"""
Test Reorg Engineer: Plan and Move Script

Reorganizes Dart SDK test tree by functional concern instead of Phases.
Creates backup, builds move plan, and executes idempotent file moves.
"""

import json
import os
import shutil
from pathlib import Path
from datetime import datetime

# Fixed paths
TEST_ROOT = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk/UNIFIED/test")
REPO_ROOT = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk")
BACKUP_DIR = Path("C:/Accumulate_Stuff/opendlt-dart-v2v3-sdk/UNIFIED/test/_backup_pre_reorg")

# Functional layout mapping: old_path -> new_path
MOVE_PLAN = {
    # Root level files
    "basic_test.dart": "unit/runtime/basic_test.dart",
    "parity_ts_surface.txt": "quarantine/parity_ts_surface.txt",

    # Builders
    "builders/builder_signing_test.dart": "unit/builders/builder_signing_test.dart",

    # Conformance
    "conformance/binary_encoding_test.dart": "conformance/codec/binary_encoding_test.dart",
    "conformance/binary_roundtrip_test.dart": "conformance/codec/binary_roundtrip_test.dart",
    "conformance/canonical_json_test.dart": "conformance/json/canonical_json_test.dart",
    "conformance/envelope_encoding_test.dart": "conformance/codec/envelope_encoding_test.dart",
    "conformance/golden_loader.dart": "support/golden_loader.dart",
    "conformance/hash_vectors_test.dart": "conformance/codec/hash_vectors_test.dart",

    # Enums
    "enums/enum_serialization_test.dart": "unit/enums/enum_serialization_test.dart",

    # Generated (quarantine)
    "generated/quarantined_client_test.dart": "quarantine/generated/quarantined_client_test.dart",

    # Integration
    "integration/devnet_e2e_test.dart": "integration/network/devnet_e2e_test.dart",
    "integration/smoke_endpoints_test.dart": "integration/network/smoke_endpoints_test.dart",
    "integration/zero_to_hero_devnet_test.dart": "integration/network/zero_to_hero_devnet_test.dart",

    # Phase2 -> split by concern
    "phase2/api_client_test.dart": "unit/api/api_client_test.dart",
    "phase2/error_handling_test.dart": "unit/errors/error_handling_test.dart",
    "phase2/field_validation_test.dart": "unit/transactions/field_validation_test.dart",
    "phase2/json_serialization_test.dart": "unit/codec/json_serialization_test.dart",
    "phase2/phase2_test_suite.dart": "support/legacy/phase2_test_suite.dart",
    "phase2/transaction_bodies_test.dart": "unit/transactions/transaction_bodies_test.dart",
    "phase2/transaction_dispatcher_test.dart": "unit/transactions/transaction_dispatcher_test.dart",
    "phase2/transaction_header_test.dart": "unit/transactions/transaction_header_test.dart",

    # Phase3 -> split by concern
    "phase3/canonical_json_conformance_test.dart": "conformance/json/canonical_json_conformance_test.dart",
    "phase3/hash_validation_test.dart": "unit/protocol_types/hash_validation_test.dart",
    "phase3/phase3_test_suite.dart": "support/legacy/phase3_test_suite.dart",
    "phase3/protocol_types_validation_test.dart": "unit/protocol_types/protocol_types_validation_test.dart",
    "phase3/runtime_helpers_test.dart": "unit/runtime/runtime_helpers_test.dart",
    "phase3/type_serialization_test.dart": "unit/protocol_types/type_serialization_test.dart",

    # Signatures
    "signatures/delegation_depth_test.dart": "unit/signatures/delegation_depth_test.dart",
    "signatures/signature_structure_test.dart": "unit/signatures/signature_structure_test.dart",
}

def create_backup():
    """Create timestamped backup if not already exists"""
    if BACKUP_DIR.exists():
        print(f"Backup already exists: {BACKUP_DIR}")
        return False

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = BACKUP_DIR / timestamp
    backup_path.mkdir(parents=True, exist_ok=True)

    # Copy entire test directory, excluding backup directories to avoid recursion
    print(f"Creating backup: {backup_path}")

    def ignore_backups(dir, files):
        return [f for f in files if f.startswith('_backup')]

    shutil.copytree(TEST_ROOT, backup_path / "test", dirs_exist_ok=True, ignore=ignore_backups)

    # Create backup info
    backup_info = {
        "created": datetime.now().isoformat(),
        "original_path": str(TEST_ROOT),
        "backup_path": str(backup_path)
    }

    with open(backup_path / "backup_info.json", 'w') as f:
        json.dump(backup_info, f, indent=2)

    print(f"Backup created successfully")
    return True

def scan_existing_files():
    """Scan current test directory for files that match our move plan"""
    existing_files = {}

    for old_path in MOVE_PLAN.keys():
        full_old_path = TEST_ROOT / old_path
        if full_old_path.exists():
            existing_files[old_path] = MOVE_PLAN[old_path]

    # Also scan for any additional .dart files in directories we're processing
    additional_files = {}

    # Scan serialization/ and validation/ directories
    for scan_dir in ["serialization", "validation"]:
        scan_path = TEST_ROOT / scan_dir
        if scan_path.exists():
            for dart_file in scan_path.rglob("*.dart"):
                rel_path = str(dart_file.relative_to(TEST_ROOT)).replace("\\", "/")
                if rel_path not in MOVE_PLAN:
                    # Map serialization -> conformance/codec, validation -> unit/errors
                    if rel_path.startswith("serialization/"):
                        new_path = rel_path.replace("serialization/", "conformance/codec/")
                    elif rel_path.startswith("validation/"):
                        new_path = rel_path.replace("validation/", "unit/errors/")
                    else:
                        new_path = f"quarantine/{rel_path}"
                    additional_files[rel_path] = new_path

    # Merge additional files into main plan
    existing_files.update(additional_files)

    return existing_files

def create_target_directories(move_plan):
    """Create all target directories"""
    created_dirs = set()

    for new_path in move_plan.values():
        target_dir = TEST_ROOT / Path(new_path).parent
        if not target_dir.exists():
            target_dir.mkdir(parents=True, exist_ok=True)
            created_dirs.add(str(target_dir))

    # Also create the main functional directories
    functional_dirs = [
        "unit/enums", "unit/runtime", "unit/codec", "unit/signatures",
        "unit/transactions", "unit/protocol_types", "unit/errors",
        "unit/api", "unit/builders",
        "conformance/codec", "conformance/json",
        "golden", "integration/network", "quarantine/generated",
        "support", "support/legacy"
    ]

    for func_dir in functional_dirs:
        dir_path = TEST_ROOT / func_dir
        if not dir_path.exists():
            dir_path.mkdir(parents=True, exist_ok=True)
            created_dirs.add(str(dir_path))

    return list(created_dirs)

def execute_moves(move_plan):
    """Execute the file moves idempotently"""
    results = {
        "moved": [],
        "skipped": [],
        "errors": []
    }

    for old_path, new_path in move_plan.items():
        old_full = TEST_ROOT / old_path
        new_full = TEST_ROOT / new_path

        # Skip if source doesn't exist
        if not old_full.exists():
            results["skipped"].append({
                "file": old_path,
                "reason": "source_not_found"
            })
            continue

        # Skip if already moved (idempotent)
        if new_full.exists():
            # Check if it's the same file (simple size check)
            if old_full.stat().st_size == new_full.stat().st_size:
                results["skipped"].append({
                    "file": old_path,
                    "reason": "already_moved"
                })
                continue

        try:
            # Ensure target directory exists
            new_full.parent.mkdir(parents=True, exist_ok=True)

            # Move the file
            shutil.move(str(old_full), str(new_full))
            results["moved"].append({
                "from": old_path,
                "to": new_path
            })
            print(f"Moved: {old_path} -> {new_path}")

        except Exception as e:
            results["errors"].append({
                "file": old_path,
                "error": str(e)
            })
            print(f"ERROR moving {old_path}: {e}")

    return results

def move_golden_directory():
    """Move golden directory to root level if needed"""
    old_golden = TEST_ROOT / "golden"
    new_golden = TEST_ROOT / "golden"  # Same location, but ensure it's at root

    if old_golden.exists() and old_golden != new_golden:
        # If golden is in a subdirectory, move it to root
        try:
            if new_golden.exists():
                shutil.rmtree(new_golden)
            shutil.move(str(old_golden), str(new_golden))
            print(f"Moved golden directory to test root")
            return True
        except Exception as e:
            print(f"ERROR moving golden directory: {e}")
            return False

    return True

def cleanup_empty_directories():
    """Remove empty phase directories after moves"""
    cleanup_dirs = ["phase1", "phase2", "phase3", "serialization", "validation"]
    removed_dirs = []

    for dir_name in cleanup_dirs:
        dir_path = TEST_ROOT / dir_name
        if dir_path.exists():
            try:
                # Check if directory is empty or only contains empty subdirs
                if not any(dir_path.rglob("*")):
                    shutil.rmtree(dir_path)
                    removed_dirs.append(dir_name)
                    print(f"Removed empty directory: {dir_name}")
                else:
                    print(f"Directory {dir_name} not empty, keeping it")
            except Exception as e:
                print(f"ERROR removing directory {dir_name}: {e}")

    return removed_dirs

def main():
    """Main reorganization function"""
    print("=== Test Reorg Engineer: Plan and Move ===")

    # Check paths exist
    if not TEST_ROOT.exists():
        print(f"ERROR: Test root not found: {TEST_ROOT}")
        return 1

    # Create backup
    backup_created = create_backup()

    # Scan existing files
    print("\nScanning existing test files...")
    move_plan = scan_existing_files()
    print(f"Found {len(move_plan)} files to process")

    # Create target directories
    print("\nCreating target directory structure...")
    created_dirs = create_target_directories(move_plan)
    print(f"Created {len(created_dirs)} directories")

    # Execute moves
    print("\nExecuting file moves...")
    results = execute_moves(move_plan)

    # Move golden directory
    move_golden_directory()

    # Write move log
    log_file = TEST_ROOT / "_reorg" / "move_log.json"
    log_data = {
        "timestamp": datetime.now().isoformat(),
        "backup_created": backup_created,
        "total_files": len(move_plan),
        "results": results,
        "created_directories": created_dirs
    }

    with open(log_file, 'w') as f:
        json.dump(log_data, f, indent=2)

    # Print summary
    print(f"\n=== Move Summary ===")
    print(f"Files moved: {len(results['moved'])}")
    print(f"Files skipped: {len(results['skipped'])}")
    print(f"Errors: {len(results['errors'])}")

    if results['errors']:
        print("\nErrors encountered:")
        for error in results['errors']:
            print(f"  {error['file']}: {error['error']}")

    # Cleanup empty directories
    print("\nCleaning up empty directories...")
    removed_dirs = cleanup_empty_directories()

    print(f"\nMove operation completed. Log: {log_file}")
    return 0 if len(results['errors']) == 0 else 1

if __name__ == "__main__":
    exit(main())