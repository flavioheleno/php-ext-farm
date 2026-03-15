#!/bin/bash
# Build script for PHP extensions
# Usage: ./build.sh <extension> <extension_version> <php_version> <platform> <platform_version> [arch] [channel] [--local]
#
# Note: This script uses bash (not POSIX sh) because it runs in CI environments
# (GitHub Actions, Ubuntu) where bash is always available and we need features
# like [[ ]], arrays, and pipefail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"
OS_VERSIONS_FILE="${ROOT_DIR}/os-versions.json"
PHP_VERSIONS_FILE="${ROOT_DIR}/php-versions.json"

EXTENSION="${1:-}"
EXTENSION_VERSION="${2:-}"
PHP_VERSION="${3:-}"
PLATFORM="${4:-}"
PLATFORM_VERSION="${5:-}"
ARCH="${6:-amd64}"
CHANNEL="${7:-release}"
USE_LOCAL_REGISTRY=false

# Check for --local flag in any position
for arg in "$@"; do
    if [[ "$arg" == "--local" ]]; then
        USE_LOCAL_REGISTRY=true
    fi
done

# Remove --local from args if present
if [[ "${ARCH}" == "--local" ]]; then
    ARCH="amd64"
fi
if [[ "${CHANNEL}" == "--local" ]]; then
    CHANNEL="release"
fi

# Generate a skip report and exit
# Usage: generate_skip_report <reason>
generate_skip_report() {
    local reason="$1"
    local report_dir="${ROOT_DIR}/reports/${EXTENSION}/${EXTENSION_VERSION}/php${PHP_VERSION}/${PLATFORM}-${PLATFORM_VERSION}"
    mkdir -p "$report_dir"

    jq -n \
      --arg extension "${EXTENSION}" \
      --arg extension_version "${EXTENSION_VERSION}" \
      --arg channel "${CHANNEL}" \
      --arg php_version "${PHP_VERSION}" \
      --arg platform "${PLATFORM}" \
      --arg platform_version "${PLATFORM_VERSION}" \
      --arg arch "${ARCH}" \
      --arg reason "$reason" \
      --arg git_sha "${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}" \
      --argjson workflow_run_id "${GITHUB_RUN_ID:-null}" \
      --argjson run_attempt "${GITHUB_RUN_ATTEMPT:-1}" \
      '{
        extension: $extension,
        extension_version: $extension_version,
        channel: $channel,
        php_version: $php_version,
        platform: $platform,
        platform_version: $platform_version,
        arch: $arch,
        status: "skipped",
        reason: $reason,
        started_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
        finished_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ")),
        workflow_run_id: $workflow_run_id,
        run_attempt: $run_attempt,
        git_sha: $git_sha,
        log_url: null,
        asset_name: null
      }' > "${report_dir}/${ARCH}.json"

    exit 0
}

if [[ -z "${EXTENSION}" || -z "${EXTENSION_VERSION}" || -z "${PHP_VERSION}" || -z "${PLATFORM}" || -z "${PLATFORM_VERSION}" ]]; then
    echo "Usage: $0 <extension> <extension_version> <php_version> <platform> <platform_version> [arch] [channel] [--local]"
    echo "Example: $0 redis 6.0.2 8.3 alpine 3.20 amd64 release"
    echo "         $0 redis 6.0.2 8.3 alpine 3.20 arm64 dev"
    echo "         $0 redis 6.0.2 8.3 alpine 3.20 --local"
    echo ""
    echo "Flags:"
    echo "  --local   Use local base images (php-ext-farm/php:*) instead of GHCR"
    exit 1
fi

# Read extension config
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    exit 1
fi

EXT_TYPE=$(jq -r ".extensions.${EXTENSION}.type" "${CONFIG_FILE}")
if [[ "${EXT_TYPE}" == "null" ]]; then
    echo "Error: Extension '${EXTENSION}' not found in config"
    exit 1
fi

# Check if PHP version is supported
SUPPORTED_PHP_VERSIONS=$(jq -r 'keys[]' "${PHP_VERSIONS_FILE}")
PHP_SUPPORTED=false
for v in ${SUPPORTED_PHP_VERSIONS}; do
    if [[ "$v" == "${PHP_VERSION}" ]]; then
        PHP_SUPPORTED=true
        break
    fi
done

if [[ "${PHP_SUPPORTED}" == "false" ]]; then
    echo "Error: PHP version ${PHP_VERSION} is not supported"
    echo "Supported versions: $(echo ${SUPPORTED_PHP_VERSIONS} | tr '\n' ' ')"
    generate_skip_report "unsupported_php"
fi

# Check if platform is supported
SUPPORTED_PLATFORMS=$(jq -r 'keys[]' "${OS_VERSIONS_FILE}")
PLATFORM_SUPPORTED=false
for p in ${SUPPORTED_PLATFORMS}; do
    if [[ "$p" == "${PLATFORM}" ]]; then
        PLATFORM_SUPPORTED=true
        break
    fi
done

if [[ "${PLATFORM_SUPPORTED}" == "false" ]]; then
    echo "Error: Platform ${PLATFORM} is not supported"
    echo "Supported platforms: $(echo ${SUPPORTED_PLATFORMS} | tr '\n' ' ')"
    generate_skip_report "unsupported_platform"
fi

# Map architecture names to Docker platform format
case "${ARCH}" in
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
        echo "Error: Unsupported architecture: ${ARCH} (supported: amd64, arm64, arm32v7, arm32v6)"
        generate_skip_report "unsupported_architecture"
        ;;
esac

# Check if this combination is excluded
EXCLUSION_CHECK="${SCRIPT_DIR}/check-exclusion.sh"
if [[ -f "${EXCLUSION_CHECK}" ]]; then
    EXCLUSION_REASON=$("${EXCLUSION_CHECK}" "${EXTENSION}" "${PLATFORM}" "${PLATFORM_VERSION}" "${ARCH}" "${CONFIG_FILE}" 2>&1)
    EXCLUSION_EXIT=$?
    if [[ $EXCLUSION_EXIT -eq 0 ]]; then
        echo "Build excluded: ${EXCLUSION_REASON}"
        generate_skip_report "${EXCLUSION_REASON}"
    fi
fi

PECL_NAME=$(jq -r ".extensions.${EXTENSION}.pecl_name" "${CONFIG_FILE}")
TRACK_URL=$(jq -r ".extensions.${EXTENSION}.track_url" "${CONFIG_FILE}")
BUILD_PATH=$(jq -r ".extensions.${EXTENSION}.build_path // empty" "${CONFIG_FILE}")
# Check for per-version dependency overrides, falling back to defaults
BUILD_DEPS=$(jq -r ".extensions.${EXTENSION}.dependencies.${PLATFORM}.version_overrides.\"${PLATFORM_VERSION}\".build // .extensions.${EXTENSION}.dependencies.${PLATFORM}.build // [] | join(\" \")" "${CONFIG_FILE}")
RUNTIME_DEPS=$(jq -r ".extensions.${EXTENSION}.dependencies.${PLATFORM}.version_overrides.\"${PLATFORM_VERSION}\".runtime // .extensions.${EXTENSION}.dependencies.${PLATFORM}.runtime // [] | join(\" \")" "${CONFIG_FILE}")
EXTERNAL_LIBS=$(jq -c ".extensions.${EXTENSION}.external_libs // []" "${CONFIG_FILE}")
CONFIGURE_OPTIONS=$(jq -r ".extensions.${EXTENSION}.configure_options // [] | join(\" \")" "${CONFIG_FILE}")
ZEND_EXTENSION=$(jq -r ".extensions.${EXTENSION}.zend_extension // false" "${CONFIG_FILE}")

# Determine dockerfile (all PHP versions use the same Dockerfile now)
DOCKERFILE="${ROOT_DIR}/docker/Dockerfile.${PLATFORM}"

if [[ ! -f "${DOCKERFILE}" ]]; then
    echo "Error: Dockerfile not found: ${DOCKERFILE}"
    exit 1
fi

# Create output directory
OUTPUT_DIR="${ROOT_DIR}/output/${EXTENSION}/${PHP_VERSION}/${PLATFORM}/${PLATFORM_VERSION}/${ARCH}"
mkdir -p "${OUTPUT_DIR}"

# Create reports directory
REPORT_DIR="${ROOT_DIR}/reports/${EXTENSION}/${EXTENSION_VERSION}/php${PHP_VERSION}/${PLATFORM}-${PLATFORM_VERSION}"
mkdir -p "${REPORT_DIR}"

# Capture build start time
BUILD_START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build image tag
IMAGE_TAG="php-ext-${EXTENSION}:${PHP_VERSION}-${PLATFORM}${PLATFORM_VERSION}-${ARCH}"

echo "Building ${EXTENSION} for PHP ${PHP_VERSION} on ${PLATFORM} ${PLATFORM_VERSION} (${ARCH})..."
echo "Source: ${TRACK_URL}"
echo "Build deps: ${BUILD_DEPS}"
echo "Runtime deps: ${RUNTIME_DEPS}"
echo "External libs: ${EXTERNAL_LIBS}"
echo "Configure options: ${CONFIGURE_OPTIONS}"
echo "Docker platform: ${DOCKER_PLATFORM}"
if [[ "${USE_LOCAL_REGISTRY}" == "true" ]]; then
    echo "Base image registry: LOCAL (php-ext-farm/php)"
else
    echo "Base image registry: GHCR (ghcr.io/flavioheleno/php-ext-farm/php)"
fi

# Build arguments
# BASE_IMAGE_REGISTRY and PHP_VERSION must be first as they're used in the FROM statement
if [[ "${USE_LOCAL_REGISTRY}" == "true" ]]; then
    BUILD_ARGS=(
        --build-arg "BASE_IMAGE_REGISTRY=php-ext-farm"
        --build-arg "PHP_VERSION=${PHP_VERSION}"
        --build-arg "EXTENSION_NAME=${PECL_NAME}"
        --build-arg "EXTENSION_REPO_URL=${TRACK_URL}"
        --build-arg "BUILD_DEPS=${BUILD_DEPS}"
        --build-arg "RUNTIME_DEPS=${RUNTIME_DEPS}"
        --build-arg "BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    )
else
    BUILD_ARGS=(
        --build-arg "PHP_VERSION=${PHP_VERSION}"
        --build-arg "EXTENSION_NAME=${PECL_NAME}"
        --build-arg "EXTENSION_REPO_URL=${TRACK_URL}"
        --build-arg "BUILD_DEPS=${BUILD_DEPS}"
        --build-arg "RUNTIME_DEPS=${RUNTIME_DEPS}"
        --build-arg "BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    )
fi

if [[ -n "${BUILD_PATH}" ]]; then
    BUILD_ARGS+=(--build-arg "EXTENSION_BUILD_PATH=${BUILD_PATH}")
fi

if [[ "${PLATFORM}" == "alpine" ]]; then
    BUILD_ARGS+=(--build-arg "ALPINE_VERSION=${PLATFORM_VERSION}")
elif [[ "${PLATFORM}" == "debian" ]]; then
    BUILD_ARGS+=(--build-arg "DEBIAN_VERSION=${PLATFORM_VERSION}")
fi

if [[ -n "${EXTENSION_VERSION}" ]]; then
    BUILD_ARGS+=(--build-arg "EXTENSION_VERSION=${EXTENSION_VERSION}")
fi

if [[ "${EXTERNAL_LIBS}" != "[]" ]]; then
    BUILD_ARGS+=(--build-arg "EXTERNAL_LIBS=${EXTERNAL_LIBS}")
fi

if [[ -n "${CONFIGURE_OPTIONS}" ]]; then
    BUILD_ARGS+=(--build-arg "CONFIGURE_OPTIONS=${CONFIGURE_OPTIONS}")
fi

if [[ "${ZEND_EXTENSION}" == "true" ]]; then
    BUILD_ARGS+=(--build-arg "ZEND_EXTENSION=1")
fi

# Track build status and reason
BUILD_STATUS="success"
BUILD_REASON=""
BUILD_ERROR=""

# Determine cache key components
CACHE_KEY="${EXTENSION}-${PHP_VERSION}-${PLATFORM}-${PLATFORM_VERSION}-${ARCH}"

# Build the image using buildx with caching
BUILD_LOG=$(mktemp)

# Set up cache options (only for CI, not for local builds)
CACHE_ARGS=()
if [[ "${USE_LOCAL_REGISTRY}" != "true" ]]; then
    # Check if we're in GitHub Actions (use GHA cache) or local (use local cache)
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        CACHE_ARGS=(
            --cache-from "type=gha,scope=${CACHE_KEY}"
            --cache-to "type=gha,mode=max,scope=${CACHE_KEY}"
        )
    else
        # Local builds without --local flag use local cache
        CACHE_ARGS=(
            --cache-from "type=local,src=/tmp/.buildx-cache-${CACHE_KEY}"
            --cache-to "type=local,dest=/tmp/.buildx-cache-${CACHE_KEY},mode=max"
        )
        mkdir -p "/tmp/.buildx-cache-${CACHE_KEY}"
    fi
fi

if ! docker buildx build \
    --platform "${DOCKER_PLATFORM}" \
    "${BUILD_ARGS[@]}" \
    "${CACHE_ARGS[@]}" \
    --load \
    -t "${IMAGE_TAG}" \
    -f "${DOCKERFILE}" \
    "${ROOT_DIR}" 2>&1 | tee "${BUILD_LOG}"; then
    BUILD_STATUS="failure"

    # Analyze build log to determine reason
    if grep -qiE "configure: error|configure: WARNING.*not found" "${BUILD_LOG}"; then
        BUILD_REASON="deps_missing"
        BUILD_ERROR="Build dependencies missing or configure failed"
    elif grep -qiE "error:|fatal error|compilation terminated|undefined reference" "${BUILD_LOG}"; then
        BUILD_REASON="compile_error"
        BUILD_ERROR="Compilation failed"
    elif grep -qiE "test.*failed|FAIL:|phpunit" "${BUILD_LOG}"; then
        BUILD_REASON="test_failed"
        BUILD_ERROR="Extension tests failed"
    else
        BUILD_REASON="compile_error"
        BUILD_ERROR="Docker build failed"
    fi
fi
rm -f "${BUILD_LOG}"

# Extract the extension
if [[ "${BUILD_STATUS}" == "success" ]]; then
    CONTAINER_ID=$(docker create --platform "${DOCKER_PLATFORM}" "${IMAGE_TAG}")
    if ! docker cp "${CONTAINER_ID}:/output/extension/${PECL_NAME}.so" "${OUTPUT_DIR}/${PECL_NAME}.so"; then
        BUILD_STATUS="failure"
        BUILD_REASON="compile_error"
        BUILD_ERROR="Failed to extract extension from container - extension may not have been compiled"
    fi

    # Extract external libraries if they exist (try to copy, ignore if not present)
    if [[ "${BUILD_STATUS}" == "success" ]]; then
        docker cp "${CONTAINER_ID}:/output/libs" "${OUTPUT_DIR}/" 2>/dev/null || true
    fi

    docker rm "${CONTAINER_ID}"
fi

# List external library files for metadata
EXTERNAL_LIB_FILES=""
if [[ "${BUILD_STATUS}" == "success" ]] && [[ -d "${OUTPUT_DIR}/libs" ]] && [[ -n "$(ls -A ${OUTPUT_DIR}/libs 2>/dev/null)" ]]; then
    EXTERNAL_LIB_FILES=$(cd "${OUTPUT_DIR}/libs" && ls -1 | jq -R -s -c 'split("\n") | map(select(length > 0))')
fi

# Generate metadata
if [[ "${BUILD_STATUS}" == "success" ]]; then
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
fi

# Generate build report
BUILD_END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Normalize extension version
NORMALIZED_VERSION=$("${SCRIPT_DIR}/normalize-version.sh" "${EXTENSION}" "${EXTENSION_VERSION}")

# Construct asset name
ASSET_NAME="${EXTENSION}-${NORMALIZED_VERSION}-php${PHP_VERSION}-${PLATFORM}-${PLATFORM_VERSION}-${ARCH}.tar.gz"

# Get GitHub Actions metadata if available
WORKFLOW_RUN_ID="${GITHUB_RUN_ID:-}"
WORKFLOW_JOB_ID="${GITHUB_JOB_ID:-}"
RUN_ATTEMPT="${GITHUB_RUN_ATTEMPT:-1}"
GIT_SHA="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "unknown")}"
LOG_URL=""
if [[ -n "${WORKFLOW_RUN_ID}" ]]; then
    REPO="${GITHUB_REPOSITORY:-}"
    if [[ -n "${WORKFLOW_JOB_ID}" ]]; then
        LOG_URL="https://github.com/${REPO}/actions/runs/${WORKFLOW_RUN_ID}/job/${WORKFLOW_JOB_ID}"
    else
        LOG_URL="https://github.com/${REPO}/actions/runs/${WORKFLOW_RUN_ID}"
    fi
fi

# Build JSON report using jq for proper escaping
jq -n \
  --arg extension "${EXTENSION}" \
  --arg extension_version "${NORMALIZED_VERSION}" \
  --arg channel "${CHANNEL}" \
  --arg php_version "${PHP_VERSION}" \
  --arg platform "${PLATFORM}" \
  --arg platform_version "${PLATFORM_VERSION}" \
  --arg arch "${ARCH}" \
  --arg status "${BUILD_STATUS}" \
  --arg reason "${BUILD_REASON}" \
  --arg started_at "${BUILD_START_TIME}" \
  --arg finished_at "${BUILD_END_TIME}" \
  --arg git_sha "${GIT_SHA}" \
  --arg log_url "${LOG_URL}" \
  --arg asset_name "${ASSET_NAME}" \
  --arg error "${BUILD_ERROR}" \
  --argjson workflow_run_id "${WORKFLOW_RUN_ID:-null}" \
  --argjson run_attempt "${RUN_ATTEMPT}" \
  '{
    extension: $extension,
    extension_version: $extension_version,
    channel: $channel,
    php_version: $php_version,
    platform: $platform,
    platform_version: $platform_version,
    arch: $arch,
    status: $status,
    started_at: $started_at,
    finished_at: $finished_at,
    workflow_run_id: $workflow_run_id,
    run_attempt: $run_attempt,
    git_sha: $git_sha,
    log_url: (if $log_url == "" then null else $log_url end),
    asset_name: $asset_name
  } + (if $reason != "" then {reason: $reason} else {} end) + (if $error != "" then {error: $error} else {} end)' \
  > "${REPORT_DIR}/${ARCH}.json"

echo "Build report: ${REPORT_DIR}/${ARCH}.json"

# Exit with error if build failed
if [[ "${BUILD_STATUS}" != "success" ]]; then
    echo "Build failed: ${BUILD_ERROR}"
    exit 1
fi
