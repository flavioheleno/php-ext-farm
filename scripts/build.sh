#!/bin/bash
set -euo pipefail

# Build script for PHP extensions
# Usage: ./build.sh <extension> <php_version> <platform> <platform_version> <extension_version> [arch]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"

EXTENSION="${1:-}"
PHP_VERSION="${2:-}"
PLATFORM="${3:-}"
PLATFORM_VERSION="${4:-}"
EXTENSION_VERSION="${5:-}"
ARCH="${6:-amd64}"

if [[ -z "$EXTENSION" || -z "$PHP_VERSION" || -z "$PLATFORM" || -z "$PLATFORM_VERSION" || -z "$EXTENSION_VERSION" ]]; then
    echo "Usage: $0 <extension> <php_version> <platform> <platform_version> <extension_version> [arch]"
    echo "Example: $0 redis 8.3 alpine 3.20 6.0.2 amd64"
    echo "         $0 redis 8.3 alpine 3.20 6.0.2 arm64"
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
    *)
        echo "Error: Unsupported architecture: $ARCH (supported: amd64, arm64)"
        exit 1
        ;;
esac

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
EXTERNAL_LIBS=$(jq -c ".extensions.${EXTENSION}.external_libs // []" "$CONFIG_FILE")
CONFIGURE_OPTIONS=$(jq -r ".extensions.${EXTENSION}.configure_options | join(\" \") // empty" "$CONFIG_FILE")

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
OUTPUT_DIR="${ROOT_DIR}/output/${EXTENSION}/${PHP_VERSION}/${PLATFORM}/${PLATFORM_VERSION}/${ARCH}"
mkdir -p "$OUTPUT_DIR"

# Build image tag
IMAGE_TAG="php-ext-${EXTENSION}:${PHP_VERSION}-${PLATFORM}${PLATFORM_VERSION}-${ARCH}"

echo "Building ${EXTENSION} for PHP ${PHP_VERSION} on ${PLATFORM} ${PLATFORM_VERSION} (${ARCH})..."
echo "Source: ${TRACK_URL}"
echo "Build deps: ${BUILD_DEPS}"
echo "Runtime deps: ${RUNTIME_DEPS}"
echo "External libs: ${EXTERNAL_LIBS}"
echo "Configure options: ${CONFIGURE_OPTIONS}"
echo "Docker platform: ${DOCKER_PLATFORM}"

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

if [[ "$EXTERNAL_LIBS" != "[]" ]]; then
    BUILD_ARGS+=(--build-arg "EXTERNAL_LIBS=${EXTERNAL_LIBS}")
fi

if [[ -n "$CONFIGURE_OPTIONS" ]]; then
    BUILD_ARGS+=(--build-arg "CONFIGURE_OPTIONS=${CONFIGURE_OPTIONS}")
fi

# Build the image
docker build \
    --platform "$DOCKER_PLATFORM" \
    "${BUILD_ARGS[@]}" \
    -t "$IMAGE_TAG" \
    -f "$DOCKERFILE" \
    "$ROOT_DIR"

# Extract the extension
CONTAINER_ID=$(docker create --platform "$DOCKER_PLATFORM" "$IMAGE_TAG")
docker cp "${CONTAINER_ID}:/output/extension/${PECL_NAME}.so" "${OUTPUT_DIR}/${PECL_NAME}.so"

# Extract external libraries if they exist
if docker exec "$CONTAINER_ID" test -d /output/libs 2>/dev/null; then
    docker cp "${CONTAINER_ID}:/output/libs" "${OUTPUT_DIR}/" || true
fi

docker rm "$CONTAINER_ID"

# List external library files for metadata
EXTERNAL_LIB_FILES=""
if [[ -d "${OUTPUT_DIR}/libs" ]] && [[ -n "$(ls -A ${OUTPUT_DIR}/libs 2>/dev/null)" ]]; then
    EXTERNAL_LIB_FILES=$(cd "${OUTPUT_DIR}/libs" && ls -1 | jq -R -s -c 'split("\n") | map(select(length > 0))')
fi

# Generate metadata
cat > "${OUTPUT_DIR}/metadata.json" <<EOF
{
  "extension": "${EXTENSION}",
  "pecl_name": "${PECL_NAME}",
  "extension_version": "${EXTENSION_VERSION}",
  "php_version": "${PHP_VERSION}",
  "platform": "${PLATFORM}",
  "platform_version": "${PLATFORM_VERSION}",
  "arch": "${ARCH}",
  "build_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "runtime_deps": "${RUNTIME_DEPS}",
  "external_libs": ${EXTERNAL_LIBS},
  "external_lib_files": ${EXTERNAL_LIB_FILES:-null}
}
EOF

echo "Extension built successfully: ${OUTPUT_DIR}/${PECL_NAME}.so"
if [[ -d "${OUTPUT_DIR}/libs" ]]; then
    echo "External libraries: ${OUTPUT_DIR}/libs/"
    ls -lh "${OUTPUT_DIR}/libs/"
fi
echo "Metadata: ${OUTPUT_DIR}/metadata.json"
