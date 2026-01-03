#!/bin/bash
set -euo pipefail

# Build script for PHP extensions
# Usage: ./build.sh <extension> <php_version> <platform> <platform_version> <extension_version>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"

EXTENSION="${1:-}"
PHP_VERSION="${2:-}"
PLATFORM="${3:-}"
PLATFORM_VERSION="${4:-}"
EXTENSION_VERSION="${5:-}"

if [[ -z "$EXTENSION" || -z "$PHP_VERSION" || -z "$PLATFORM" || -z "$PLATFORM_VERSION" || -z "$EXTENSION_VERSION" ]]; then
    echo "Usage: $0 <extension> <php_version> <platform> <platform_version> <extension_version>"
    echo "Example: $0 redis 8.3 alpine 3.20 6.0.2"
    exit 1
fi

# Read extension config
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi

EXT_TYPE=$(jq -r ".extensions.${EXTENSION}.type" "$CONFIG_FILE")
PECL_NAME=$(jq -r ".extensions.${EXTENSION}.pecl_name" "$CONFIG_FILE")
TRACK_URL=$(jq -r ".extensions.${EXTENSION}.track_url" "$CONFIG_FILE")
BUILD_PATH=$(jq -r ".extensions.${EXTENSION}.build_path // empty" "$CONFIG_FILE")
BUILD_DEPS=$(jq -r ".extensions.${EXTENSION}.dependencies.${PLATFORM}.build | join(\" \")" "$CONFIG_FILE")
RUNTIME_DEPS=$(jq -r ".extensions.${EXTENSION}.dependencies.${PLATFORM}.runtime | join(\" \")" "$CONFIG_FILE")

if [[ "$EXT_TYPE" == "null" ]]; then
    echo "Error: Extension '$EXTENSION' not found in config"
    exit 1
fi

# Determine dockerfile
DOCKERFILE="${ROOT_DIR}/docker/Dockerfile.${PLATFORM}"
if [[ ! -f "$DOCKERFILE" ]]; then
    echo "Error: Dockerfile not found for platform: $PLATFORM"
    exit 1
fi

# Create output directory
OUTPUT_DIR="${ROOT_DIR}/output/${EXTENSION}/${PHP_VERSION}/${PLATFORM}/${PLATFORM_VERSION}"
mkdir -p "$OUTPUT_DIR"

# Build image tag
IMAGE_TAG="php-ext-${EXTENSION}:${PHP_VERSION}-${PLATFORM}${PLATFORM_VERSION}"

echo "Building ${EXTENSION} for PHP ${PHP_VERSION} on ${PLATFORM} ${PLATFORM_VERSION}..."
echo "Source: ${TRACK_URL}"
echo "Build deps: ${BUILD_DEPS}"
echo "Runtime deps: ${RUNTIME_DEPS}"

# Build arguments
BUILD_ARGS=(
    --build-arg "PHP_VERSION=${PHP_VERSION}"
    --build-arg "EXTENSION_NAME=${PECL_NAME}"
    --build-arg "EXTENSION_REPO_URL=${TRACK_URL}"
    --build-arg "BUILD_DEPS=${BUILD_DEPS}"
    --build-arg "RUNTIME_DEPS=${RUNTIME_DEPS}"
)

if [[ -n "$BUILD_PATH" ]]; then
    BUILD_ARGS+=(--build-arg "EXTENSION_BUILD_PATH=${BUILD_PATH}")
fi

if [[ "$PLATFORM" == "alpine" ]]; then
    BUILD_ARGS+=(--build-arg "ALPINE_VERSION=${PLATFORM_VERSION}")
elif [[ "$PLATFORM" == "debian" ]]; then
    BUILD_ARGS+=(--build-arg "DEBIAN_VERSION=${PLATFORM_VERSION}")
fi

if [[ -n "$EXTENSION_VERSION" ]]; then
    BUILD_ARGS+=(--build-arg "EXTENSION_VERSION=${EXTENSION_VERSION}")
fi

# Build the image
docker build \
    "${BUILD_ARGS[@]}" \
    -t "$IMAGE_TAG" \
    -f "$DOCKERFILE" \
    "$ROOT_DIR"

# Extract the extension
CONTAINER_ID=$(docker create "$IMAGE_TAG")
docker cp "${CONTAINER_ID}:/output/${PECL_NAME}.so" "${OUTPUT_DIR}/${PECL_NAME}.so"
docker rm "$CONTAINER_ID"

# Generate metadata
cat > "${OUTPUT_DIR}/metadata.json" <<EOF
{
  "extension": "${EXTENSION}",
  "pecl_name": "${PECL_NAME}",
  "extension_version": "${EXTENSION_VERSION}",
  "php_version": "${PHP_VERSION}",
  "platform": "${PLATFORM}",
  "platform_version": "${PLATFORM_VERSION}",
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "runtime_deps": "${RUNTIME_DEPS}"
}
EOF

echo "Extension built successfully: ${OUTPUT_DIR}/${PECL_NAME}.so"
echo "Metadata: ${OUTPUT_DIR}/metadata.json"
