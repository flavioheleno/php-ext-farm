#!/bin/bash
# Regression tests for three bug fixes (no Docker required):
# 1. check-exclusion.sh call sites in build.sh / build-base-image.sh must not abort
#    on exit code 1 (allowed) under set -e.
# 2. dev-<sha> version strings must be detected as dev builds in Dockerfiles.
# 3. install.sh must normalize the version before building artifact URLs.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CHECK_EXCLUSION="${SCRIPT_DIR}/check-exclusion.sh"
NORMALIZE="${SCRIPT_DIR}/normalize-version.sh"
EXTENSIONS_JSON="${ROOT_DIR}/extensions.json"
OS_VERSIONS_JSON="${ROOT_DIR}/os-versions.json"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

pass() { echo "✓ $1"; TESTS_PASSED=$((TESTS_PASSED + 1)); TESTS_RUN=$((TESTS_RUN + 1)); }
fail() { echo "✗ $1"; TESTS_FAILED=$((TESTS_FAILED + 1)); TESTS_RUN=$((TESTS_RUN + 1)); }

# ---------------------------------------------------------------------------
# 1. Exclusion call-site regression
#
# Replicates the exact if-cmd pattern from build.sh and build-base-image.sh
# inside a set -e context so we verify it no longer aborts on exit code 1.
# ---------------------------------------------------------------------------
echo "=== Exclusion call-site regression (set -e safe) ==="
echo

run_exclusion_check() {
    local ext="$1" os="$2" ver="$3" arch="$4"
    local reason="" excluded=""
    if reason=$("${CHECK_EXCLUSION}" "$ext" "$os" "$ver" "$arch" \
                "${EXTENSIONS_JSON}" "${OS_VERSIONS_JSON}" 2>&1); then
        excluded=yes
    else
        case $? in
            1) excluded=no ;;
            *) excluded=error ;;
        esac
    fi
    echo "$excluded"
}

result=$(run_exclusion_check amqp alpine 3.20 amd64)
if [[ "$result" == "no" ]]; then
    pass "alpine/3.20/amd64 allowed — if-cmd pattern survives exit code 1"
else
    fail "alpine/3.20/amd64 expected allowed, got: $result"
fi

result=$(run_exclusion_check amqp debian bookworm arm32v6)
if [[ "$result" == "yes" ]]; then
    pass "debian/bookworm/arm32v6 excluded — exit code 0 correctly detected"
else
    fail "debian/bookworm/arm32v6 expected excluded, got: $result"
fi

result=$(run_exclusion_check amqp debian bullseye arm32v6)
if [[ "$result" == "yes" ]]; then
    pass "debian/bullseye/arm32v6 excluded"
else
    fail "debian/bullseye/arm32v6 expected excluded, got: $result"
fi

result=$(run_exclusion_check amqp debian bookworm amd64)
if [[ "$result" == "no" ]]; then
    pass "debian/bookworm/amd64 allowed"
else
    fail "debian/bookworm/amd64 expected allowed, got: $result"
fi

result=$(run_exclusion_check amqp alpine 3.19 arm64)
if [[ "$result" == "no" ]]; then
    pass "alpine/3.19/arm64 allowed"
else
    fail "alpine/3.19/arm64 expected allowed, got: $result"
fi

# ---------------------------------------------------------------------------
# 2. Dev build version detection
#
# Verifies normalize-version.sh passes dev-<sha> strings through unchanged
# so they are available for the Dockerfile COMMIT_SHA extraction in build.sh.
# ---------------------------------------------------------------------------
echo
echo "=== Dev build version string handling ==="
echo

check_normalize() {
    local ext="$1" input="$2" expected="$3" label="$4"
    local actual
    actual=$("${NORMALIZE}" "$ext" "$input")
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label (expected '$expected', got '$actual')"
    fi
}

check_normalize redis "dev-abc1234" "dev-abc1234" \
    "dev-<sha> passes through normalize-version unchanged"
check_normalize redis "dev" "dev" \
    "literal dev passes through normalize-version unchanged"

# Verify the prefix extraction logic build.sh uses: dev-<sha> -> sha
COMMIT_SHA=""
EXTENSION_VERSION="dev-abc1234"
if [[ "${EXTENSION_VERSION}" == dev-* ]]; then
    COMMIT_SHA="${EXTENSION_VERSION#dev-}"
fi
if [[ "$COMMIT_SHA" == "abc1234" ]]; then
    pass "COMMIT_SHA extracted from dev-abc1234 -> abc1234"
else
    fail "COMMIT_SHA extraction failed (got '$COMMIT_SHA')"
fi

COMMIT_SHA=""
EXTENSION_VERSION="6.0.2"
if [[ "${EXTENSION_VERSION}" == dev-* ]]; then
    COMMIT_SHA="${EXTENSION_VERSION#dev-}"
fi
if [[ -z "$COMMIT_SHA" ]]; then
    pass "release version 6.0.2 does not set COMMIT_SHA"
else
    fail "release version should not set COMMIT_SHA (got '$COMMIT_SHA')"
fi

# ---------------------------------------------------------------------------
# 3. install.sh URL normalization
#
# Verifies that the normalize-version.sh call before URL construction produces
# artifact paths matching what release.yml/build.yml publish (no v- prefix).
# ---------------------------------------------------------------------------
echo
echo "=== install.sh URL normalization ==="
echo

check_install_url() {
    local ext="$1" raw_ver="$2" expected_ver="$3" label="$4"
    local actual_ver
    actual_ver=$("${NORMALIZE}" "$ext" "$raw_ver")
    local release_tag="${ext}-${actual_ver}"
    local expected_tag="${ext}-${expected_ver}"
    if [[ "$release_tag" == "$expected_tag" ]]; then
        pass "$label -> RELEASE_TAG=${release_tag}"
    else
        fail "$label: expected RELEASE_TAG=${expected_tag}, got ${release_tag}"
    fi
}

check_install_url redis "v6.0.2" "6.0.2" \
    "v6.0.2 normalizes to 6.0.2 for release tag"
check_install_url redis "6.0.2" "6.0.2" \
    "6.0.2 unchanged"
check_install_url yar "yar-2.3.3" "2.3.3" \
    "yar-2.3.3 strips extension-name prefix"
check_install_url imagick "v3.8.0" "3.8.0" \
    "v3.8.0 normalizes to 3.8.0"

# ---------------------------------------------------------------------------
echo
echo "================================"
echo "Tests run:  ${TESTS_RUN}"
echo "Passed:     ${TESTS_PASSED}"
echo "Failed:     ${TESTS_FAILED}"
echo "================================"

if [[ ${TESTS_FAILED} -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
