#!/bin/bash
# Script to check for new releases of extensions
# Outputs JSON with latest versions
#
# Note: This script uses bash (not POSIX sh) because it runs in CI environments
# and uses bash features like local variables and [[ ]].
#
# Environment variables:
#   GITHUB_TOKEN - Optional GitHub token for authenticated requests (higher rate limits)
#   CHECK_RELEASES_DELAY - Delay between API calls in seconds (default: 1)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"

# Rate limiting configuration
API_DELAY="${CHECK_RELEASES_DELAY:-1}"
REQUEST_COUNT=0
RATE_LIMIT_REMAINING=""

# Build curl command with optional authentication
build_curl_cmd() {
    local url="$1"
    local cmd="curl -s"

    # Add authentication if GITHUB_TOKEN is set
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        cmd="$cmd -H 'Authorization: token ${GITHUB_TOKEN}'"
    fi

    # Add headers to get rate limit info
    cmd="$cmd -H 'Accept: application/vnd.github.v3+json'"

    echo "$cmd '$url'"
}

# Check and handle rate limiting
check_rate_limit() {
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        local rate_info
        rate_info=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/rate_limit" 2>/dev/null || echo "{}")

        RATE_LIMIT_REMAINING=$(echo "$rate_info" | jq -r '.resources.core.remaining // "unknown"')

        if [[ "$RATE_LIMIT_REMAINING" != "unknown" ]] && [[ "$RATE_LIMIT_REMAINING" -lt 10 ]]; then
            local reset_time
            reset_time=$(echo "$rate_info" | jq -r '.resources.core.reset // 0')
            local now
            now=$(date +%s)
            local wait_time=$((reset_time - now + 5))

            if [[ $wait_time -gt 0 ]] && [[ $wait_time -lt 3600 ]]; then
                echo "Rate limit nearly exhausted ($RATE_LIMIT_REMAINING remaining). Waiting ${wait_time}s..." >&2
                sleep "$wait_time"
            fi
        fi
    fi
}

# Make API request with rate limiting
api_request() {
    local url="$1"

    # Add delay between requests
    if [[ $REQUEST_COUNT -gt 0 ]]; then
        sleep "$API_DELAY"
    fi
    REQUEST_COUNT=$((REQUEST_COUNT + 1))

    # Check rate limit every 50 requests
    if [[ $((REQUEST_COUNT % 50)) -eq 0 ]]; then
        check_rate_limit
    fi

    # Make the request
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            "$url" 2>/dev/null
    else
        curl -s -H "Accept: application/vnd.github.v3+json" \
            "$url" 2>/dev/null
    fi
}

check_github_release() {
    local repo_url="$1"

    # Only works for GitHub URLs
    if [[ "$repo_url" != *"github.com"* ]]; then
        echo ""
        return
    fi

    local repo_path
    repo_path="${repo_url#https://github.com/}"

    # Use GitHub API to get latest release
    local response
    response=$(api_request "https://api.github.com/repos/${repo_path}/releases/latest")

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
    repo_path="${repo_url#https://github.com/}"

    # Fetch all tags (the /tags endpoint does not guarantee date-based ordering,
    # so we retrieve them all and resolve each commit date to find the newest)
    local page=1
    local all_tags="[]"
    while true; do
        local response
        response=$(api_request "https://api.github.com/repos/${repo_path}/tags?per_page=100&page=${page}")

        # Check if response is a valid non-empty array
        if ! echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
            break
        fi

        all_tags=$(echo "$all_tags" "$response" | jq -s '.[0] + .[1]')

        local count
        count=$(echo "$response" | jq 'length')
        if [[ "$count" -lt 100 ]]; then
            break
        fi

        page=$((page + 1))
    done

    # Check if we found any tags
    local total
    total=$(echo "$all_tags" | jq 'length')
    if [[ "$total" -eq 0 ]]; then
        echo ""
        return
    fi

    # If there's only one tag, return it directly
    if [[ "$total" -eq 1 ]]; then
        echo "$all_tags" | jq -r '.[0].name // empty'
        return
    fi

    # For each tag, fetch the commit date and find the most recent
    local latest_tag=""
    local latest_date="0000-00-00T00:00:00Z"

    for row in $(echo "$all_tags" | jq -r '.[] | @base64'); do
        local name sha commit_date
        name=$(echo "$row" | base64 -d | jq -r '.name')
        sha=$(echo "$row" | base64 -d | jq -r '.commit.sha')

        local commit_info
        commit_info=$(api_request "https://api.github.com/repos/${repo_path}/git/commits/${sha}")
        commit_date=$(echo "$commit_info" | jq -r '.committer.date // "0000-00-00T00:00:00Z"')

        if [[ "$commit_date" > "$latest_date" ]]; then
            latest_date="$commit_date"
            latest_tag="$name"
        fi
    done

    echo "$latest_tag"
}

check_gitlab_tags() {
    local repo_url="$1"

    # Only works for GitLab URLs
    if [[ "$repo_url" != *"gitlab.com"* ]]; then
        echo ""
        return
    fi

    local repo_path
    repo_path=$(echo "$repo_url" | sed 's|https://gitlab.com/||' | sed 's|/|%2F|g')

    # Get latest tag from GitLab API
    local response
    response=$(curl -s "https://gitlab.com/api/v4/projects/${repo_path}/repository/tags?per_page=1" 2>/dev/null)

    # Check if response is valid array
    if ! echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo ""
        return
    fi

    echo "$response" | jq -r '.[0].name // empty'
}

check_bitbucket_tags() {
    local repo_url="$1"

    # Only works for Bitbucket URLs
    if [[ "$repo_url" != *"bitbucket.org"* ]]; then
        echo ""
        return
    fi

    local repo_path
    repo_path="${repo_url#https://bitbucket.org/}"

    # Get latest tag from Bitbucket API
    local response
    response=$(curl -s "https://api.bitbucket.org/2.0/repositories/${repo_path}/refs/tags?sort=-target.date&pagelen=1" 2>/dev/null)

    # Check if response has values
    if ! echo "$response" | jq -e '.values[0]' > /dev/null 2>&1; then
        echo ""
        return
    fi

    echo "$response" | jq -r '.values[0].name // empty'
}

# Build result with jq (replaces the echo-based approach)
RESULT=$(jq -n --arg checked_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    '{"checked_at": $checked_at, "extensions": {}}')

EXTENSIONS=$(jq -r '.extensions | keys[]' "${CONFIG_FILE}")

for ext in ${EXTENSIONS}; do
    TRACK_URL=$(jq -r ".extensions.${ext}.track_url" "${CONFIG_FILE}")
    VERSION=""

    # Try different methods based on hosting platform
    if [[ "$TRACK_URL" == *"github.com"* ]]; then
        # Try releases first, then tags for GitHub
        VERSION=$(check_github_release "${TRACK_URL}")
        if [[ -z "${VERSION}" ]]; then
            VERSION=$(check_github_tags "${TRACK_URL}")
        fi
    elif [[ "$TRACK_URL" == *"gitlab.com"* ]]; then
        VERSION=$(check_gitlab_tags "${TRACK_URL}")
    elif [[ "$TRACK_URL" == *"bitbucket.org"* ]]; then
        VERSION=$(check_bitbucket_tags "${TRACK_URL}")
    fi

    RESULT=$(echo "${RESULT}" | jq \
        --arg ext "${ext}" \
        --arg version "${VERSION:-unknown}" \
        --arg track_url "${TRACK_URL}" \
        '.extensions[$ext] = {"latest_version": $version, "track_url": $track_url}')
done

echo "${RESULT}"

# Print summary to stderr
echo "Checked $REQUEST_COUNT extensions" >&2
if [[ -n "$RATE_LIMIT_REMAINING" ]]; then
    echo "GitHub API rate limit remaining: $RATE_LIMIT_REMAINING" >&2
fi
