#!/bin/bash
# Script to check for new releases of extensions
# Outputs JSON with latest versions
#
# Note: This script uses bash (not POSIX sh) because it runs in CI environments
# and uses bash features like local variables and [[ ]].

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"

check_github_release() {
    local repo_url="$1"

    # Only works for GitHub URLs
    if [[ "$repo_url" != *"github.com"* ]]; then
        echo ""
        return
    fi

    local repo_path
    repo_path=$(echo "$repo_url" | sed 's|https://github.com/||')

    # Use GitHub API to get latest release
    local response
    response=$(curl -s "https://api.github.com/repos/${repo_path}/releases/latest")

    # Check if response contains an error
    if echo "$response" | jq -e '.message' > /dev/null 2>&1; then
        echo ""
        return
    fi

    echo "$response" | jq -r '.tag_name // empty'
}

check_github_tags() {
    local repo_url="$1"

    # Only works for GitHub URLs
    if [[ "$repo_url" != *"github.com"* ]]; then
        echo ""
        return
    fi

    local repo_path
    repo_path=$(echo "$repo_url" | sed 's|https://github.com/||')

    # Get latest tag
    local response
    response=$(curl -s "https://api.github.com/repos/${repo_path}/tags?per_page=1")

    # Check if response is valid array
    if ! echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo ""
        return
    fi

    echo "$response" | jq -r '.[0].name // empty'
}

echo "{"
echo '  "checked_at": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",'
echo '  "extensions": {'

EXTENSIONS=$(jq -r '.extensions | keys[]' "${CONFIG_FILE}")
FIRST=true

for ext in ${EXTENSIONS}; do
    TRACK_URL=$(jq -r ".extensions.${ext}.track_url" "${CONFIG_FILE}")

    # Try releases first, then tags
    VERSION=$(check_github_release "${TRACK_URL}")
    if [[ -z "${VERSION}" ]]; then
        VERSION=$(check_github_tags "${TRACK_URL}")
    fi

    if [[ "${FIRST}" == "true" ]]; then
        FIRST=false
    else
        echo ","
    fi

    echo -n "    \"${ext}\": {\"latest_version\": \"${VERSION:-unknown}\", \"track_url\": \"${TRACK_URL}\"}"
done

echo ""
echo "  }"
echo "}"
