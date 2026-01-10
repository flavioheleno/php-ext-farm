#!/bin/bash
# Check if a build combination is excluded
# Usage: ./check-exclusion.sh <extension> <os> <version> <arch> <config_file>
# Exit codes: 0 = excluded, 1 = allowed

set -euo pipefail

EXTENSION="${1:-}"
OS="${2:-}"
VERSION="${3:-}"
ARCH="${4:-}"
CONFIG_FILE="${5:-}"

if [[ -z "${EXTENSION}" || -z "${OS}" || -z "${VERSION}" || -z "${ARCH}" || -z "${CONFIG_FILE}" ]]; then
    echo "Usage: $0 <extension> <os> <version> <arch> <config_file>" >&2
    exit 2
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 2
fi

# Wildcard matching function
# Returns: 0 if matches, 1 if not
wildcard_match() {
    local pattern="$1"
    local value="$2"
    
    # Convert wildcard pattern to regex
    # Escape special regex chars except *
    local regex_pattern="${pattern//./\\.}"
    regex_pattern="${regex_pattern//\*/.*}"
    
    if [[ "$value" =~ ^${regex_pattern}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check platform-level exclusions (no 'os' field, implicit from context)
platform_excludes=$(jq -r --arg os "${OS}" '.platforms[$os].exclude // []' "${CONFIG_FILE}")

if [[ "$platform_excludes" != "[]" ]]; then
    # Parse each exclusion rule
    num_rules=$(echo "$platform_excludes" | jq 'length')
    for ((i=0; i<num_rules; i++)); do
        rule=$(echo "$platform_excludes" | jq ".[$i]")
        version_pattern=$(echo "$rule" | jq -r '.version')
        arch_pattern=$(echo "$rule" | jq -r '.arch')
        
        # Check if version matches
        if wildcard_match "$version_pattern" "${VERSION}"; then
            # Check if arch matches
            if wildcard_match "$arch_pattern" "${ARCH}"; then
                echo "excluded_by_platform"
                exit 0
            fi
        fi
    done
fi

# Check extension-level exclusions (must have 'os' field)
extension_excludes=$(jq -r --arg ext "${EXTENSION}" '.extensions[$ext].exclude // []' "${CONFIG_FILE}")

if [[ "$extension_excludes" != "[]" ]]; then
    # Parse each exclusion rule
    num_rules=$(echo "$extension_excludes" | jq 'length')
    for ((i=0; i<num_rules; i++)); do
        rule=$(echo "$extension_excludes" | jq ".[$i]")
        os_pattern=$(echo "$rule" | jq -r '.os')
        version_pattern=$(echo "$rule" | jq -r '.version')
        arch_pattern=$(echo "$rule" | jq -r '.arch')
        
        # Check if os matches
        if wildcard_match "$os_pattern" "${OS}"; then
            # Check if version matches
            if wildcard_match "$version_pattern" "${VERSION}"; then
                # Check if arch matches
                if wildcard_match "$arch_pattern" "${ARCH}"; then
                    echo "excluded_by_extension"
                    exit 0
                fi
            fi
        fi
    done
fi

# Not excluded
echo "allowed"
exit 1
