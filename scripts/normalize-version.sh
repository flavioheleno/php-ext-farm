#!/bin/sh
# Normalize extension version string
# Usage: ./normalize-version.sh <extension_name> <version>
# Example: ./normalize-version.sh redis v6.0.2 -> 6.0.2
#          ./normalize-version.sh yar yar-2.3.3 -> 2.3.3
#
# Note: This script uses POSIX sh for portability (runs on target systems)

set -eu

EXTENSION="${1:-}"
VERSION="${2:-}"

if [ -z "${VERSION}" ]; then
    echo ""
    exit 0
fi

# Strip extension name prefix if present (e.g., "yar-2.3.3" -> "2.3.3")
# shellcheck disable=SC2295 # Pattern matching is intentional here
VERSION="${VERSION#"${EXTENSION}"-}"

# Strip common prefixes
VERSION="${VERSION#v}"
VERSION="${VERSION#release-}"
VERSION="${VERSION#release_}"

# Replace underscores with dots
VERSION=$(echo "${VERSION}" | tr '_' '.')

echo "${VERSION}"
