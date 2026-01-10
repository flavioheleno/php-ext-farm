#!/bin/bash
# Unit tests for check-exclusion.sh
# Run with: ./test-check-exclusion.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_EXCLUSION="${SCRIPT_DIR}/check-exclusion.sh"
TEST_CONFIG="${SCRIPT_DIR}/../test-config.json"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Create test config
cat > "$TEST_CONFIG" << 'EOF'
{
  "platforms": {
    "alpine": {
      "versions": ["3.19", "3.20", "3.21"],
      "exclude": [
        {"version": "3.19", "arch": "arm32*"},
        {"version": "3.20", "arch": "arm32v6"}
      ]
    },
    "debian": {
      "versions": ["bookworm", "bullseye"],
      "exclude": [
        {"version": "bullseye", "arch": "arm32v6"}
      ]
    }
  },
  "extensions": {
    "testext": {
      "exclude": [
        {"os": "alpine", "version": "3.21", "arch": "amd64"},
        {"os": "*", "version": "bullseye", "arch": "arm64"}
      ]
    },
    "normalext": {
      "exclude": []
    }
  }
}
EOF

# Test helper
run_test() {
    local test_name="$1"
    local extension="$2"
    local os="$3"
    local version="$4"
    local arch="$5"
    local expected_exit="$6"  # 0 = excluded, 1 = allowed
    local expected_msg="$7"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local output
    local exit_code
    output=$("$CHECK_EXCLUSION" "$extension" "$os" "$version" "$arch" "$TEST_CONFIG" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}
    
    if [[ $exit_code -eq $expected_exit ]]; then
        if [[ -z "$expected_msg" ]] || [[ "$output" == "$expected_msg" ]]; then
            echo "✓ $test_name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo "✗ $test_name (wrong message: expected '$expected_msg', got '$output')"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo "✗ $test_name (expected exit $expected_exit, got $exit_code)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "Running check-exclusion.sh tests..."
echo

# Platform-level exclusion tests
run_test "Platform: alpine 3.19 arm32v6 (excluded by arm32*)" \
    "normalext" "alpine" "3.19" "arm32v6" 0 "excluded_by_platform"

run_test "Platform: alpine 3.19 arm32v7 (excluded by arm32*)" \
    "normalext" "alpine" "3.19" "arm32v7" 0 "excluded_by_platform"

run_test "Platform: alpine 3.19 amd64 (allowed)" \
    "normalext" "alpine" "3.19" "amd64" 1 "allowed"

run_test "Platform: alpine 3.20 arm32v6 (excluded)" \
    "normalext" "alpine" "3.20" "arm32v6" 0 "excluded_by_platform"

run_test "Platform: alpine 3.20 arm32v7 (allowed)" \
    "normalext" "alpine" "3.20" "arm32v7" 1 "allowed"

run_test "Platform: debian bullseye arm32v6 (excluded)" \
    "normalext" "debian" "bullseye" "arm32v6" 0 "excluded_by_platform"

run_test "Platform: debian bullseye amd64 (allowed)" \
    "normalext" "debian" "bullseye" "amd64" 1 "allowed"

# Extension-level exclusion tests
run_test "Extension: testext alpine 3.21 amd64 (excluded)" \
    "testext" "alpine" "3.21" "amd64" 0 "excluded_by_extension"

run_test "Extension: testext alpine 3.21 arm64 (allowed)" \
    "testext" "alpine" "3.21" "arm64" 1 "allowed"

run_test "Extension: testext debian bullseye arm64 (excluded by wildcard os)" \
    "testext" "debian" "bullseye" "arm64" 0 "excluded_by_extension"

run_test "Extension: testext alpine bullseye arm64 (excluded by wildcard os)" \
    "testext" "alpine" "bullseye" "arm64" 0 "excluded_by_extension"

# Combined tests (extension overrides platform)
run_test "Extension overrides: testext alpine 3.19 arm32v6 (platform excludes, but extension rule checked first)" \
    "testext" "alpine" "3.19" "arm32v6" 0 "excluded_by_platform"

# No exclusions
run_test "No exclusions: normalext debian bookworm amd64 (allowed)" \
    "normalext" "debian" "bookworm" "amd64" 1 "allowed"

run_test "No exclusions: normalext alpine 3.21 arm64 (allowed)" \
    "normalext" "alpine" "3.21" "arm64" 1 "allowed"

# Cleanup
rm -f "$TEST_CONFIG"

echo
echo "================================"
echo "Tests run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "================================"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
