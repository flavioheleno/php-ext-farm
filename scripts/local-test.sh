#!/bin/bash
# Local testing script
# Usage: ./local-test.sh <extension> <extension_version> <php_version> <platform> <platform_version> [arch]
#
# This script orchestrates building base images and extensions locally for testing.
# CI additionally packages artifacts and publishes reports; this script displays local output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXTENSION="${1:-}"
EXTENSION_VERSION="${2:-}"
PHP_VERSION="${3:-}"
PLATFORM="${4:-}"
PLATFORM_VERSION="${5:-}"
ARCH="${6:-amd64}"

show_usage() {
    cat << EOF
Usage: $0 <extension> <extension_version> <php_version> <platform> <platform_version> [arch]

Local testing workflow that builds base images and extensions.

Arguments:
  extension         Extension name (e.g., redis, imagick)
  extension_version Extension ref (e.g., 6.3.0, dev)
  php_version       PHP version (e.g., 8.3, 8.4, next)
  platform          Platform (alpine or debian)
  platform_version  Platform version (e.g., 3.23, bookworm)
  arch              Architecture (default: amd64)

Examples:
  # Test redis extension with PHP 8.3 on Alpine 3.23
  $0 redis 6.3.0 8.3 alpine 3.23

  # Test imagick with PHP 8.4 on Debian bookworm for ARM64
  $0 imagick 3.8.1 8.4 debian bookworm arm64

  # Test with PHP next (bleeding edge)
  $0 redis 6.3.0 next alpine 3.23

Workflow:
  1. Check if base image exists locally
  2. Build base image if needed (with --local flag)
  3. Build extension using local base image
  4. Display metadata and files (the Dockerfile checks module loading)
  5. Show output location and installation pointers

Notes:
  - An existing base tag is not checked for architecture or source freshness
  - Rebuild the PHP base image before switching architectures
  - Reports use channel release; use build.sh directly for dev channel labels

EOF
}

if [[ -z "${EXTENSION}" || -z "${EXTENSION_VERSION}" || -z "${PHP_VERSION}" || -z "${PLATFORM}" || -z "${PLATFORM_VERSION}" ]]; then
    show_usage
    exit 1
fi

echo "=========================================="
echo "LOCAL TESTING WORKFLOW"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Extension: ${EXTENSION} v${EXTENSION_VERSION}"
echo "  PHP: ${PHP_VERSION}"
echo "  Platform: ${PLATFORM} ${PLATFORM_VERSION}"
echo "  Architecture: ${ARCH}"
echo ""

# Determine base image tag
if [[ "${PLATFORM}" == "alpine" ]]; then
    BASE_IMAGE_TAG="php-ext-farm/php:${PHP_VERSION}-alpine${PLATFORM_VERSION}"
else
    BASE_IMAGE_TAG="php-ext-farm/php:${PHP_VERSION}-${PLATFORM_VERSION}"
fi

echo "Step 1: Checking for base image..."
echo "  Required: ${BASE_IMAGE_TAG}"
echo ""

# Check if base image exists
if docker image inspect "${BASE_IMAGE_TAG}" &>/dev/null; then
    echo "✓ Base image found locally"
    echo ""
else
    echo "⚠ Base image not found locally"
    echo ""
    echo "Step 2: Building base image..."
    echo ""

    if "${SCRIPT_DIR}/build-base-image.sh" "${PHP_VERSION}" "${PLATFORM}" "${PLATFORM_VERSION}" "${ARCH}" --local; then
        echo ""
        echo "✓ Base image built successfully"
        echo ""
    else
        echo ""
        echo "✗ Failed to build base image"
        exit 1
    fi
fi

echo "Step 3: Building extension..."
echo ""

if "${SCRIPT_DIR}/build.sh" "${EXTENSION}" "${EXTENSION_VERSION}" "${PHP_VERSION}" "${PLATFORM}" "${PLATFORM_VERSION}" "${ARCH}" release --local; then
    echo ""
    echo "✓ Extension built successfully"
    echo ""
else
    echo ""
    echo "✗ Failed to build extension"
    exit 1
fi

# Locate the built extension
OUTPUT_DIR="${SCRIPT_DIR}/../output/${EXTENSION}/${PHP_VERSION}/${PLATFORM}/${PLATFORM_VERSION}/${ARCH}"

echo "Step 4: Verifying build artifacts..."
echo ""

if [[ -f "${OUTPUT_DIR}/metadata.json" ]]; then
    echo "Build artifacts:"
    echo "  Location: ${OUTPUT_DIR}"
    echo ""
    echo "  Metadata:"
    jq '.' "${OUTPUT_DIR}/metadata.json" 2>/dev/null || cat "${OUTPUT_DIR}/metadata.json"
    echo ""

    if [[ -f "${OUTPUT_DIR}/${EXTENSION}.so" ]]; then
        echo "  Extension file:"
        ls -lh "${OUTPUT_DIR}/${EXTENSION}.so"
        echo ""
    fi

    if [[ -d "${OUTPUT_DIR}/libs" ]] && [[ -n "$(ls -A "${OUTPUT_DIR}/libs" 2>/dev/null)" ]]; then
        echo "  External libraries:"
        ls -lh "${OUTPUT_DIR}/libs/"
        echo ""
    fi
else
    echo "⚠ Metadata not found at ${OUTPUT_DIR}/metadata.json"
    echo ""
fi

echo "=========================================="
echo "✓ LOCAL TEST COMPLETE"
echo "=========================================="
echo ""
echo "Extension binary: ${OUTPUT_DIR}/${EXTENSION}.so"
echo ""
echo "To install into a compatible PHP environment:"
echo "  Review ${OUTPUT_DIR}/metadata.json for pecl_name, runtime_deps, and zend_extension."
echo "  Follow README.md installation instructions, including libraries and the PHP INI scan directory."
echo ""
echo "To verify after installation:"
echo "  php --ri ${EXTENSION}"
echo ""
