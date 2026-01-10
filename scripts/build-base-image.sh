#!/bin/bash
# Build script for PHP base images
# Usage: ./build-base-image.sh <php_version> <platform> <platform_version> [arch] [--local]
#
# Examples:
#   ./build-base-image.sh 8.3 alpine 3.20
#   ./build-base-image.sh 8.3 debian bookworm amd64
#   ./build-base-image.sh next alpine 3.21 arm64 --local

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PHP_VERSIONS_FILE="${ROOT_DIR}/php-versions.json"

PHP_VERSION="${1:-}"
PLATFORM="${2:-}"
PLATFORM_VERSION="${3:-}"
ARCH="${4:-amd64}"
LOCAL_ONLY=false

# Check for --local flag in any position
for arg in "$@"; do
    if [[ "$arg" == "--local" ]]; then
        LOCAL_ONLY=true
    fi
done

# Remove --local from args if present
if [[ "${ARCH}" == "--local" ]]; then
    ARCH="amd64"
fi

if [[ -z "$PHP_VERSION" || -z "$PLATFORM" || -z "$PLATFORM_VERSION" ]]; then
    cat << EOF
Usage: $0 <php_version> <platform> <platform_version> [arch] [--local]

Build PHP base images locally.

Arguments:
  php_version       PHP version (e.g., 8.3, 8.4, next)
  platform          Platform (alpine or debian)
  platform_version  Platform version (e.g., 3.20, bookworm)
  arch              Architecture (default: amd64, options: amd64, arm64, arm32v7, arm32v6)
  --local           Use local registry tag instead of GHCR

Examples:
  $0 8.3 alpine 3.20
  $0 8.3 debian bookworm amd64
  $0 next alpine 3.21 --local
  $0 8.4 debian trixie arm64 --local

Notes:
  - Without --local: tags as ghcr.io/flavioheleno/php-ext-farm/php:8.3-alpine3.20
  - With --local: tags as php-ext-farm/php:8.3-alpine3.20
  - Local tags require modifying extension Dockerfiles to use local registry
EOF
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "Error: docker is required but not installed."
    exit 1
fi

# Validate platform
if [[ "$PLATFORM" != "alpine" && "$PLATFORM" != "debian" ]]; then
    echo "Error: Platform must be 'alpine' or 'debian'"
    exit 1
fi

# Map architecture names to Docker platform format
case "$ARCH" in
    amd64|x86_64)
        DOCKER_PLATFORM="linux/amd64"
        ARCH="amd64"
        ;;
    arm64|aarch64)
        DOCKER_PLATFORM="linux/arm64"
        ARCH="arm64"
        ;;
    arm32v7|armv7|armv7l)
        DOCKER_PLATFORM="linux/arm/v7"
        ARCH="arm32v7"
        ;;
    arm32v6|armv6|armv6l)
        DOCKER_PLATFORM="linux/arm/v6"
        ARCH="arm32v6"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH"
        echo "Supported: amd64, arm64, arm32v7, arm32v6"
        exit 1
        ;;
esac

# Read PHP version info from php-versions.json
if [[ ! -f "$PHP_VERSIONS_FILE" ]]; then
    echo "Error: php-versions.json not found at $PHP_VERSIONS_FILE"
    exit 1
fi

if ! jq -e ".\"$PHP_VERSION\"" "$PHP_VERSIONS_FILE" > /dev/null 2>&1; then
    echo "Error: PHP version '$PHP_VERSION' not found in php-versions.json"
    echo "Available versions: $(jq -r 'keys | join(", ")' "$PHP_VERSIONS_FILE")"
    exit 1
fi

PHP_VERSION_TAG=$(jq -r ".\"$PHP_VERSION\".tag // \"\"" "$PHP_VERSIONS_FILE")
PHP_VERSION_BRANCH=$(jq -r ".\"$PHP_VERSION\".branch // \"master\"" "$PHP_VERSIONS_FILE")

# Determine Dockerfile
DOCKERFILE="${ROOT_DIR}/docker/base/Dockerfile.${PLATFORM}"

if [[ ! -f "$DOCKERFILE" ]]; then
    echo "Error: Dockerfile not found: $DOCKERFILE"
    exit 1
fi

# Generate image tag
if [[ "$PLATFORM" == "alpine" ]]; then
    TAG="${PHP_VERSION}-alpine${PLATFORM_VERSION}"
else
    TAG="${PHP_VERSION}-${PLATFORM_VERSION}"
fi

# Determine registry
if [[ "$LOCAL_ONLY" == "true" ]]; then
    REGISTRY="php-ext-farm/php"
    echo "Building local base image: ${REGISTRY}:${TAG}-${ARCH}"
else
    REGISTRY="ghcr.io/flavioheleno/php-ext-farm/php"
    echo "Building base image: ${REGISTRY}:${TAG}-${ARCH}"
fi

FULL_TAG="${REGISTRY}:${TAG}-${ARCH}"

echo ""
echo "Configuration:"
echo "  PHP Version: $PHP_VERSION"
echo "  PHP Tag: ${PHP_VERSION_TAG:-<none>}"
echo "  PHP Branch: $PHP_VERSION_BRANCH"
echo "  Platform: $PLATFORM $PLATFORM_VERSION"
echo "  Architecture: $ARCH"
echo "  Docker Platform: $DOCKER_PLATFORM"
echo "  Dockerfile: $DOCKERFILE"
echo "  Image Tag: $FULL_TAG"
echo ""

# Build arguments
BUILD_ARGS=(
    --build-arg "BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    --build-arg "PHP_VERSION=${PHP_VERSION}"
    --build-arg "PHP_VERSION_TAG=${PHP_VERSION_TAG}"
    --build-arg "PHP_VERSION_BRANCH=${PHP_VERSION_BRANCH}"
)

if [[ "$PLATFORM" == "alpine" ]]; then
    BUILD_ARGS+=(--build-arg "ALPINE_VERSION=${PLATFORM_VERSION}")
elif [[ "$PLATFORM" == "debian" ]]; then
    BUILD_ARGS+=(--build-arg "DEBIAN_VERSION=${PLATFORM_VERSION}")
fi

# Build the image
if docker buildx version &> /dev/null; then
    echo "Building with docker buildx..."
    
    if ! docker buildx build \
        --platform "$DOCKER_PLATFORM" \
        "${BUILD_ARGS[@]}" \
        --load \
        -t "$FULL_TAG" \
        -f "$DOCKERFILE" \
        "$ROOT_DIR"; then
        echo "Error: Docker build failed"
        exit 1
    fi
else
    echo "Building with standard docker build..."
    echo "Note: Cross-platform builds require docker buildx"
    
    if ! docker build \
        "${BUILD_ARGS[@]}" \
        -t "$FULL_TAG" \
        -f "$DOCKERFILE" \
        "$ROOT_DIR"; then
        echo "Error: Docker build failed"
        exit 1
    fi
fi

echo ""
echo "✓ Base image built successfully: $FULL_TAG"
echo ""

# Also tag without arch suffix for convenience
MULTI_ARCH_TAG="${REGISTRY}:${TAG}"
docker tag "$FULL_TAG" "$MULTI_ARCH_TAG"
echo "✓ Also tagged as: $MULTI_ARCH_TAG"
echo ""

# Verify the image
echo "Verifying image..."
if docker run --rm --platform "$DOCKER_PLATFORM" "$FULL_TAG" php --version; then
    echo ""
    echo "✓ Image verification successful"
else
    echo ""
    echo "✗ Image verification failed"
    exit 1
fi

echo ""
echo "Base image ready for use in extension builds."

if [[ "$LOCAL_ONLY" == "true" ]]; then
    echo ""
    echo "To use this local image with build.sh, run:"
    echo "  ./scripts/build.sh <extension> <version> $PHP_VERSION $PLATFORM $PLATFORM_VERSION $ARCH --local"
fi
