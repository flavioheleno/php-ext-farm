#!/bin/bash
# Unit tests for normalize-version.sh
# Run with: ./test-normalize-version.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NORMALIZE_VERSION="${SCRIPT_DIR}/normalize-version.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
    local test_name="$1"
    local extension="$2"
    local input="$3"
    local expected="$4"

    TESTS_RUN=$((TESTS_RUN + 1))

    local output
    output=$("${NORMALIZE_VERSION}" "$extension" "$input")

    if [[ "$output" == "$expected" ]]; then
        echo "✓ $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $test_name (expected '$expected', got '$output')"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "Running normalize-version.sh tests..."
echo

# Basic prefix stripping
run_test "Strip v prefix" "redis" "v6.0.2" "6.0.2"
run_test "Strip extension name prefix" "yar" "yar-2.3.3" "2.3.3"
run_test "Strip release- prefix" "ext" "release-1.0.0" "1.0.0"
run_test "Strip release_ prefix" "ext" "release_1_0_0" "1.0.0"

# Underscore to dot conversion
run_test "Convert underscores to dots" "ext" "1_2_3" "1.2.3"
run_test "Mixed underscores" "ext" "v1_2_3" "1.2.3"

# Complex cases
run_test "PECL-style version (yac)" "yac" "yac-2.3.1" "2.3.1"
run_test "PECL-style version (yaf)" "yaf" "yaf-3.3.6" "3.3.6"
run_test "Tag-style version" "ext" "tags/VLD_0_11_0" "tags/VLD.0.11.0"
run_test "PHP_ZIP style" "zip" "PHP_ZIP-1.12.1" "PHP.ZIP-1.12.1"

# No transformation needed
run_test "Already normalized" "redis" "6.0.2" "6.0.2"
run_test "Semantic version" "ext" "1.2.3" "1.2.3"

# Edge cases
run_test "Empty version" "ext" "" ""
run_test "Dev version" "ext" "dev-abc1234" "dev-abc1234"

# Combined prefixes
run_test "v + extension prefix (should strip v first)" "ext" "vext-1.0.0" "ext-1.0.0"

echo
echo "================================"
echo "Tests run: ${TESTS_RUN}"
echo "Passed: ${TESTS_PASSED}"
echo "Failed: ${TESTS_FAILED}"
echo "================================"

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
