#!/bin/sh
# Install script for pre-built PHP extensions from php-ext-farm
# Usage: ./install.sh <extension> <extension_version>
# Example: ./install.sh redis 6.3.0
#
# Note: This script uses POSIX sh for maximum portability across target systems
# (Alpine, Debian, Ubuntu, etc.) where bash may not be available.

set -eu

# Get script directory (POSIX compatible)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CONFIG_FILE="${ROOT_DIR}/extensions.json"
GITHUB_REPO="flavioheleno/php-ext-farm"  # Update with actual repo owner/name
TEMP_DIR=""

# Colors for output (using printf for POSIX compatibility)
log_info() {
    printf '\033[0;32m[INFO]\033[0m %s\n' "$1"
}

log_warn() {
    printf '\033[1;33m[WARN]\033[0m %s\n' "$1"
}

log_error() {
    printf '\033[0;31m[ERROR]\033[0m %s\n' "$1"
}

cleanup() {
    if [ -n "${TEMP_DIR}" ] && [ -d "${TEMP_DIR}" ]; then
        log_info "Cleaning up temporary files..."
        rm -rf "${TEMP_DIR}"
    fi
}

trap cleanup EXIT INT TERM

show_usage() {
    echo "Usage: $0 <extension> <extension_version>"
    echo ""
    echo "Install a pre-built PHP extension from GitHub releases."
    echo ""
    echo "Arguments:"
    echo "  extension         Name of the extension (e.g., redis, imagick, xdebug)"
    echo "  extension_version Version of the extension (e.g., 6.3.0)"
    echo ""
    echo "Example:"
    echo "  $0 redis 6.3.0"
    echo "  $0 imagick 3.7.0"
    echo ""
    echo "Supported extensions can be found in extensions.json"
    exit 1
}

# Check for required arguments
EXTENSION="${1:-}"
EXTENSION_VERSION="${2:-}"

if [ -z "${EXTENSION}" ] || [ -z "${EXTENSION_VERSION}" ]; then
    show_usage
fi

# Check for jq
if ! command -v jq >/dev/null 2>&1; then
    log_error "jq is required but not installed."
    exit 1
fi

# Check for PHP
if ! command -v php >/dev/null 2>&1; then
    log_error "PHP is not installed or not in PATH."
    exit 1
fi

# Step 1: Get PHP version
log_info "Detecting PHP version..."
PHP_FULL_VERSION=$(php -r 'echo PHP_VERSION;')
PHP_MAJOR_MINOR=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
log_info "PHP version: ${PHP_FULL_VERSION} (using ${PHP_MAJOR_MINOR} for matching)"

# Step 2: Detect architecture
log_info "Detecting architecture..."
MACHINE_ARCH=$(uname -m)
case "${MACHINE_ARCH}" in
    x86_64|amd64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    armv6l|armv6)
        ARCH="arm32v6"
        ;;
    armv7l|armv7)
        ARCH="arm32v7"
        ;;
    *)
        log_error "Unsupported architecture: ${MACHINE_ARCH}"
        log_error "Supported: x86_64/amd64, aarch64/arm64, armv6l, armv7l"
        exit 1
        ;;
esac
log_info "Architecture: ${ARCH}"

# Step 3: Detect OS and version
log_info "Detecting operating system..."
PLATFORM=""
PLATFORM_VERSION=""

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID}" in
            alpine)
                PLATFORM="alpine"
                # Extract major.minor from VERSION_ID (e.g., 3.20.0 -> 3.20)
                PLATFORM_VERSION=$(echo "${VERSION_ID}" | cut -d. -f1,2)
                ;;
            debian)
                PLATFORM="debian"
                PLATFORM_VERSION="${VERSION_CODENAME}"
                ;;
            ubuntu)
                # Map Ubuntu to closest Debian version
                PLATFORM="debian"
                case "${VERSION_ID}" in
                    22.04|22.10|23.04|23.10|24.04|24.10|25.04|25.10|26.04)
                        PLATFORM_VERSION="bookworm"
                        ;;
                    20.04|20.10|21.04|21.10)
                        PLATFORM_VERSION="bullseye"
                        ;;
                    *)
                        PLATFORM_VERSION="bookworm"
                        log_warn "Unknown Ubuntu version ${VERSION_ID}, defaulting to Debian bookworm"
                        ;;
                esac
                ;;
            *)
                # Try to determine if it's Debian-based
                if command -v apt-get >/dev/null 2>&1; then
                    PLATFORM="debian"
                    PLATFORM_VERSION="bookworm"
                    log_warn "Unknown Debian-based distro, defaulting to bookworm"
                elif command -v apk >/dev/null 2>&1; then
                    PLATFORM="alpine"
                    PLATFORM_VERSION="3.20"
                    log_warn "Unknown Alpine-based distro, defaulting to Alpine 3.20"
                else
                    log_error "Unsupported operating system: ${ID}"
                    exit 1
                fi
                ;;
        esac
    else
        log_error "Cannot detect operating system. /etc/os-release not found."
        exit 1
    fi
}

detect_os
log_info "Detected platform: ${PLATFORM} ${PLATFORM_VERSION}"

# Step 4: Validate extension exists in config
if [ -f "${CONFIG_FILE}" ]; then
    EXT_CHECK=$(jq -r ".extensions.${EXTENSION}" "${CONFIG_FILE}")
    if [ "${EXT_CHECK}" = "null" ]; then
        log_error "Extension '${EXTENSION}' not found in extensions.json"
        log_info "Available extensions:"
        jq -r '.extensions | keys[]' "${CONFIG_FILE}" | head -20
        echo "  ... (see extensions.json for full list)"
        exit 1
    fi
    PECL_NAME=$(jq -r ".extensions.${EXTENSION}.pecl_name" "${CONFIG_FILE}")
else
    # If config not available, assume extension name is the pecl name
    log_warn "extensions.json not found, assuming pecl_name equals extension name"
    PECL_NAME="${EXTENSION}"
fi

# Step 5: Build download URL
RELEASE_TAG="${EXTENSION}-${EXTENSION_VERSION}"
ARCHIVE_NAME="${EXTENSION}-${EXTENSION_VERSION}-php${PHP_MAJOR_MINOR}-${PLATFORM}-${PLATFORM_VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${ARCHIVE_NAME}"

log_info "Release tag: ${RELEASE_TAG}"
log_info "Archive: ${ARCHIVE_NAME}"
log_info "Download URL: ${DOWNLOAD_URL}"

# Step 6: Create temp directory and download
TEMP_DIR=$(mktemp -d)
log_info "Created temporary directory: ${TEMP_DIR}"

download_file() {
    url="$1"
    output="$2"
    
    if command -v curl >/dev/null 2>&1; then
        log_info "Downloading with curl..."
        if ! curl -fsSL -o "$output" "$url"; then
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        log_info "Downloading with wget..."
        if ! wget -q -O "$output" "$url"; then
            return 1
        fi
    else
        log_error "Neither curl nor wget is available. Please install one of them."
        exit 1
    fi
    return 0
}

ARCHIVE_PATH="${TEMP_DIR}/${ARCHIVE_NAME}"

if ! download_file "${DOWNLOAD_URL}" "${ARCHIVE_PATH}"; then
    log_error "Failed to download extension archive."
    log_error "URL: ${DOWNLOAD_URL}"
    log_info "Possible reasons:"
    log_info "  - The extension version might not exist"
    log_info "  - The build for PHP ${PHP_MAJOR_MINOR} on ${PLATFORM} ${PLATFORM_VERSION} might not be available"
    log_info "  - Check available releases at: https://github.com/${GITHUB_REPO}/releases"
    exit 1
fi

log_info "Downloaded archive successfully"

# Step 7: Extract archive
log_info "Extracting archive..."
EXTRACT_DIR="${TEMP_DIR}/extracted"
mkdir -p "${EXTRACT_DIR}"
tar -xzf "${ARCHIVE_PATH}" -C "${EXTRACT_DIR}"

# Find the .so file and metadata.json
SO_FILE=$(find "${EXTRACT_DIR}" -name "*.so" -type f 2>/dev/null | head -1)
METADATA_FILE=$(find "${EXTRACT_DIR}" -name "metadata.json" -type f 2>/dev/null | head -1)

if [ -z "${SO_FILE}" ]; then
    log_error "No .so file found in the archive"
    exit 1
fi

SO_BASENAME=$(basename "${SO_FILE}")
log_info "Found extension file: ${SO_BASENAME}"

# Step 8: Get PHP extension directory
EXT_DIR=$(php -r "echo ini_get('extension_dir');")
log_info "PHP extension directory: ${EXT_DIR}"

# Step 9: Install runtime dependencies from metadata.json
if [ -n "${METADATA_FILE}" ] && [ -f "${METADATA_FILE}" ]; then
    RUNTIME_DEPS=$(jq -r '.runtime_deps // empty' "${METADATA_FILE}")
    
    if [ -n "${RUNTIME_DEPS}" ] && [ "${RUNTIME_DEPS}" != "null" ]; then
        log_info "Installing runtime dependencies: ${RUNTIME_DEPS}"
        
        # Check if running as root or with sudo
        SUDO=""
        if [ "$(id -u)" -ne 0 ]; then
            if command -v sudo >/dev/null 2>&1; then
                SUDO="sudo"
            else
                log_warn "Not running as root and sudo not available. You may need to install dependencies manually."
            fi
        fi
        
        case "${PLATFORM}" in
            alpine)
                # shellcheck disable=SC2086
                ${SUDO} apk add --no-cache ${RUNTIME_DEPS} || {
                    log_warn "Failed to install some runtime dependencies. You may need to install them manually:"
                    log_warn "  apk add --no-cache ${RUNTIME_DEPS}"
                }
                ;;
            debian)
                ${SUDO} apt-get update -qq || true
                # shellcheck disable=SC2086
                ${SUDO} apt-get install -y --no-install-recommends ${RUNTIME_DEPS} || {
                    log_warn "Failed to install some runtime dependencies. You may need to install them manually:"
                    log_warn "  apt-get install -y ${RUNTIME_DEPS}"
                }
                ;;
        esac
    else
        log_info "No runtime dependencies required"
    fi
else
    log_warn "metadata.json not found in archive, skipping dependency installation"
fi

# Step 10: Install external libraries if present
LIBS_DIR="${EXTRACT_DIR}/libs"
if [ -d "${LIBS_DIR}" ] && [ "$(ls -A "${LIBS_DIR}" 2>/dev/null)" ]; then
    log_info "Found external libraries, installing..."
    
    # Check if running as root or with sudo
    SUDO=""
    if [ "$(id -u)" -ne 0 ]; then
        if command -v sudo >/dev/null 2>&1; then
            SUDO="sudo"
        else
            log_warn "Not running as root and sudo not available. You may need to install libraries manually."
        fi
    fi
    
    # Install to /usr/local/lib (standard location)
    LIB_INSTALL_DIR="/usr/local/lib"
    log_info "Installing external libraries to ${LIB_INSTALL_DIR}..."
    
    for lib_file in "${LIBS_DIR}"/*; do
        if [ -f "$lib_file" ]; then
            lib_basename=$(basename "$lib_file")
            log_info "  Installing $lib_basename"
            ${SUDO} cp -P "$lib_file" "${LIB_INSTALL_DIR}/"
        fi
    done
    
    # Update library cache
    if command -v ldconfig >/dev/null 2>&1; then
        log_info "Updating library cache..."
        ${SUDO} ldconfig || log_warn "Failed to run ldconfig, libraries may not be found"
    fi
    
    log_info "External libraries installed successfully"
else
    log_info "No external libraries to install"
fi

# Step 11: Copy extension to PHP extension directory
log_info "Installing extension to ${EXT_DIR}..."

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        log_error "Not running as root and sudo not available. Cannot install extension."
        log_info "You can manually copy the extension:"
        log_info "  cp '${SO_FILE}' '${EXT_DIR}/'"
        exit 1
    fi
fi

${SUDO} cp "${SO_FILE}" "${EXT_DIR}/"
log_info "Extension copied successfully"

# Step 12: Enable the extension in conf.d
log_info "Enabling extension..."

# Find the conf.d directory
CONF_D_DIR=$(php --ini | grep "Scan for additional" | cut -d: -f2 | tr -d ' ')

if [ -n "${CONF_D_DIR}" ] && [ -d "${CONF_D_DIR}" ]; then
    INI_FILE="${CONF_D_DIR}/50-${PECL_NAME}.ini"
    
    # Check if extension is already enabled somewhere
    if [ -f "${INI_FILE}" ]; then
        log_info "Extension config already exists: ${INI_FILE}"
    else
        log_info "Creating extension config: ${INI_FILE}"
        echo "extension=${PECL_NAME}.so" | ${SUDO} tee "${INI_FILE}" > /dev/null
    fi
else
    log_error "Cannot find PHP conf.d directory"
    log_info "Expected location from 'php --ini': ${CONF_D_DIR}"
    log_info "You can manually enable the extension by creating a file in your PHP conf.d directory:"
    log_info "  echo 'extension=${PECL_NAME}.so' > /path/to/conf.d/${PECL_NAME}.ini"
    exit 1
fi

# Step 13: Verify installation
log_info "Verifying installation..."

if php -m 2>/dev/null | grep -qi "^${PECL_NAME}\$"; then
    log_info "Extension '${PECL_NAME}' is now loaded and working!"
    echo ""
    log_info "Installation complete!"
    echo ""
    # Show extension info if available
    php -r "if (extension_loaded('${PECL_NAME}')) { echo 'Extension version: ' . phpversion('${PECL_NAME}') . PHP_EOL; }" 2>/dev/null || true
else
    log_warn "Extension may not be loaded correctly."
    log_info "Checking for errors..."
    php -m 2>&1 | head -20
    echo ""
    log_info "You may need to:"
    log_info "  1. Restart your web server (apache, nginx+php-fpm, etc.)"
    log_info "  2. Check PHP error logs for more details"
    log_info "  3. Verify the extension file exists: ls -la ${EXT_DIR}/${PECL_NAME}.so"
fi

# Cleanup is handled by trap
