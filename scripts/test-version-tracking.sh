#!/bin/bash
# Unit tests for version tracking edge cases
# Run with: ./test-version-tracking.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

echo "Running version tracking tests..."
echo

# Test 1: All extensions have required fields
echo "Test: All extensions have required fields"
TESTS_RUN=$((TESTS_RUN + 1))

MISSING_FIELDS=$(jq -r '
  .extensions | to_entries[] |
  select(
    .value.pecl_name == null or
    .value.track_url == null or
    .value.type == null
  ) | .key
' "${CONFIG_FILE}")

if [[ -z "$MISSING_FIELDS" ]]; then
    echo "✓ All extensions have required fields (pecl_name, track_url, type)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ Extensions missing required fields:"
    echo "$MISSING_FIELDS"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 2: All extensions have dependencies for both platforms
echo
echo "Test: All extensions have platform dependencies"
TESTS_RUN=$((TESTS_RUN + 1))

MISSING_DEPS=$(jq -r '
  .extensions | to_entries[] |
  select(
    .value.dependencies.alpine == null or
    .value.dependencies.debian == null
  ) | .key
' "${CONFIG_FILE}")

if [[ -z "$MISSING_DEPS" ]]; then
    echo "✓ All extensions have alpine and debian dependencies defined"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ Extensions missing platform dependencies:"
    echo "$MISSING_DEPS"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: Check for extensions without latest_version (warning only)
echo
echo "Test: Extensions with tracked latest_version"
TESTS_RUN=$((TESTS_RUN + 1))

MISSING_VERSION=$(jq -r '
  .extensions | to_entries[] |
  select(.value.latest_version == null) | .key
' "${CONFIG_FILE}")

MISSING_COUNT=$(echo "$MISSING_VERSION" | grep -c . || echo 0)
TOTAL_COUNT=$(jq '.extensions | keys | length' "${CONFIG_FILE}")

if [[ "$MISSING_COUNT" -eq 0 ]]; then
    echo "✓ All extensions have latest_version tracked"
    TESTS_PASSED=$((TESTS_PASSED + 1))
elif [[ "$MISSING_COUNT" -lt 20 ]]; then
    echo "⚠ $MISSING_COUNT/$TOTAL_COUNT extensions missing latest_version (acceptable):"
    echo "$MISSING_VERSION" | head -10
    TESTS_PASSED=$((TESTS_PASSED + 1))
    WARNINGS=$((WARNINGS + 1))
else
    echo "✗ Too many extensions ($MISSING_COUNT/$TOTAL_COUNT) missing latest_version:"
    echo "$MISSING_VERSION"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 4: Validate track_url format
echo
echo "Test: track_url format validation"
TESTS_RUN=$((TESTS_RUN + 1))

INVALID_URLS=$(jq -r '
  .extensions | to_entries[] |
  select(
    (.value.track_url | test("^https://github.com/") | not) and
    (.value.track_url | test("^https://gitlab.com/") | not) and
    (.value.track_url | test("^https://bitbucket.org/") | not)
  ) | "\(.key): \(.value.track_url)"
' "${CONFIG_FILE}")

if [[ -z "$INVALID_URLS" ]]; then
    echo "✓ All track_urls are valid Git hosting URLs"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "⚠ Some track_urls use non-standard hosting (may need manual version checking):"
    echo "$INVALID_URLS"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    WARNINGS=$((WARNINGS + 1))
fi

# Test 5: Check last_checked timestamps are not too old
echo
echo "Test: Version check freshness"
TESTS_RUN=$((TESTS_RUN + 1))

# Get current date minus 30 days in ISO format (cross-platform)
if date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
    THIRTY_DAYS_AGO=$(date -u -d "30 days ago" +"%Y-%m-%dT%H:%M:%SZ")
elif date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ" >/dev/null 2>&1; then
    THIRTY_DAYS_AGO=$(date -u -v-30d +"%Y-%m-%dT%H:%M:%SZ")
else
    # Fallback: just use a reasonable date
    THIRTY_DAYS_AGO="2025-12-01T00:00:00Z"
fi

STALE_CHECKS=$(jq -r --arg cutoff "$THIRTY_DAYS_AGO" '
  .extensions | to_entries[] |
  select(
    .value.last_checked != null and
    .value.last_checked < $cutoff
  ) | .key
' "${CONFIG_FILE}")

if [[ -z "$STALE_CHECKS" ]]; then
    STALE_COUNT=0
else
    STALE_COUNT=$(echo "$STALE_CHECKS" | wc -l | tr -d ' ')
fi

if [[ "$STALE_COUNT" -eq 0 ]]; then
    echo "✓ All version checks are recent (within 30 days)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "⚠ $STALE_COUNT extensions have stale version checks (older than 30 days)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    WARNINGS=$((WARNINGS + 1))
fi

# Test 6: Check for duplicate pecl_names
echo
echo "Test: Unique pecl_names"
TESTS_RUN=$((TESTS_RUN + 1))

DUPLICATE_PECL=$(jq -r '
  [.extensions[].pecl_name] | group_by(.) | map(select(length > 1)) | flatten | unique | .[]
' "${CONFIG_FILE}")

if [[ -z "$DUPLICATE_PECL" ]]; then
    echo "✓ All pecl_names are unique"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ Duplicate pecl_names found:"
    echo "$DUPLICATE_PECL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 7: Validate external_libs structure
echo
echo "Test: external_libs structure validation"
TESTS_RUN=$((TESTS_RUN + 1))

INVALID_EXTERNAL=$(jq -r '
  .extensions | to_entries[] |
  select(.value.external_libs != null) |
  select(
    (.value.external_libs | type != "array") or
    (.value.external_libs[] | select(
      .name == null or .repo_url == null or .build_commands == null
    ) | length > 0)
  ) | .key
' "${CONFIG_FILE}")

if [[ -z "$INVALID_EXTERNAL" ]]; then
    echo "✓ All external_libs entries have valid structure"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ Invalid external_libs structure in:"
    echo "$INVALID_EXTERNAL"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 8: Validate PHP version references
echo
echo "Test: PHP versions consistency"
TESTS_RUN=$((TESTS_RUN + 1))

PHP_VERSIONS_FILE="${ROOT_DIR}/php-versions.json"
PHP_VERSIONS=$(jq -r 'keys[]' "${PHP_VERSIONS_FILE}")
PHP_COUNT=$(echo "$PHP_VERSIONS" | wc -l | tr -d ' ')

if [[ "$PHP_COUNT" -ge 4 ]]; then
    echo "✓ PHP versions file has $PHP_COUNT versions defined"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ Expected at least 4 PHP versions, found $PHP_COUNT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo
echo "================================"
echo "Tests run: ${TESTS_RUN}"
echo "Passed: ${TESTS_PASSED}"
echo "Failed: ${TESTS_FAILED}"
echo "Warnings: ${WARNINGS}"
echo "================================"

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
