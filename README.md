# PHP Extension Farm

PHP-Ext.com Build Farm

Automated build system for pre-compiled PHP extensions across multiple PHP versions, Linux distributions, and CPU architectures. Builds produce `.tar.gz` archives containing the extension binary, runtime dependency metadata, and any bundled external libraries.

Start with [installation](#-installation), [local building](#-local-building), or the [documentation index](#-documentation). The authoritative configuration is in [extensions.json](extensions.json), [php-versions.json](php-versions.json), and [os-versions.json](os-versions.json).

## 📦 Supported Extensions (106)

These are configured build targets, not a guarantee that every extension builds on every configuration. Check the actual assets in [GitHub Releases](https://github.com/flavioheleno/php-ext-farm/releases) and the [build dataset](#-build-reports--dataset) for availability and failures.

| Extension | Repository |
|-----------|------------|
| amqp | [php-amqp/php-amqp](https://github.com/php-amqp/php-amqp) |
| apcu | [krakjoe/apcu](https://github.com/krakjoe/apcu) |
| apcu_bc | [krakjoe/apcu-bc](https://github.com/krakjoe/apcu-bc) |
| apfd | [m6w6/ext-apfd](https://github.com/m6w6/ext-apfd) |
| aspect | [SolidWorx/aspect](https://github.com/SolidWorx/aspect) |
| ast | [nikic/php-ast](https://github.com/nikic/php-ast) |
| bitset | [php/pecl-numbers-bitset](https://github.com/php/pecl-numbers-bitset) |
| blake3 | [cypherbits/php-blake3](https://github.com/cypherbits/php-blake3) |
| brotli | [kjdev/php-ext-brotli](https://github.com/kjdev/php-ext-brotli) |
| bzip3 | [kjdev/php-ext-bzip3](https://github.com/kjdev/php-ext-bzip3) |
| cairo | [MarcelBolten/php-cairo](https://github.com/MarcelBolten/php-cairo) |
| corefill | [mailmug/corefill](https://github.com/mailmug/corefill) |
| crc_fast | [awesomized/crc-fast-php-ext](https://github.com/awesomized/crc-fast-php-ext) |
| csv | [Girgias/csv-php-extension](https://gitlab.com/Girgias/csv-php-extension) |
| dbus | [derickr/pecl-dbus](https://github.com/derickr/pecl-dbus) |
| decimal | [php-decimal/ext-decimal](https://github.com/php-decimal/ext-decimal) |
| dio | [php/pecl-system-dio](https://github.com/php/pecl-system-dio) |
| ds | [php-ds/ext-ds](https://github.com/php-ds/ext-ds) |
| ev | [rosmanov/pecl-ev](https://github.com/rosmanov/pecl-ev) |
| event | [osmanov/pecl-event](https://bitbucket.org/osmanov/pecl-event) |
| excimer | [wikimedia/php-excimer](https://github.com/wikimedia/php-excimer) |
| fastcsv | [csvtoolkit/FastCSV-ext](https://github.com/csvtoolkit/FastCSV-ext) |
| fnbind | [Danack/fnbind](https://github.com/Danack/fnbind) |
| geospatial | [php-geospatial/geospatial](https://github.com/php-geospatial/geospatial) |
| glfw | [mario-deluna/php-glfw](https://github.com/mario-deluna/php-glfw) |
| gnupg | [php-gnupg/php-gnupg](https://github.com/php-gnupg/php-gnupg) |
| gpio | [embedded-php/ext-gpio](https://github.com/embedded-php/ext-gpio) |
| grpc | [grpc/grpc](https://github.com/grpc/grpc) |
| hdrhistogram | [beberlei/hdrhistogram-php](https://github.com/beberlei/hdrhistogram-php) |
| i2c | [embedded-php/ext-i2c](https://github.com/embedded-php/ext-i2c) |
| identifier | [castor-labs/php-ext-identifier](https://github.com/castor-labs/php-ext-identifier) |
| igbinary | [igbinary/igbinary](https://github.com/igbinary/igbinary) |
| imagick | [Imagick/imagick](https://github.com/Imagick/imagick) |
| inotify | [arnaud-lb/php-inotify](https://github.com/arnaud-lb/php-inotify) |
| ip2location | [chrislim2888/IP2Location-PECL-Extension](https://github.com/chrislim2888/IP2Location-PECL-Extension) |
| ip2proxy | [ip2location/ip2proxy-pecl](https://github.com/ip2location/ip2proxy-pecl) |
| json_post | [m6w6/ext-json_post](https://github.com/m6w6/ext-json_post) |
| jsonpath | [supermetrics-public/pecl-jsonpath](https://github.com/supermetrics-public/pecl-jsonpath) |
| judy | [orieg/php-judy](https://github.com/orieg/php-judy) |
| lz4 | [kjdev/php-ext-lz4](https://github.com/kjdev/php-ext-lz4) |
| lzf | [php/pecl-file_formats-lzf](https://github.com/php/pecl-file_formats-lzf) |
| mailparse | [php/pecl-mail-mailparse](https://github.com/php/pecl-mail-mailparse) |
| maxminddb | [maxmind/MaxMind-DB-Reader-php](https://github.com/maxmind/MaxMind-DB-Reader-php) |
| mcrypt | [php/pecl-encryption-mcrypt](https://github.com/php/pecl-encryption-mcrypt) |
| memcache | [websupport-sk/pecl-memcache](https://github.com/websupport-sk/pecl-memcache) |
| memcached | [php-memcached-dev/php-memcached](https://github.com/php-memcached-dev/php-memcached) |
| memprof | [arnaud-lb/php-memory-profiler](https://github.com/arnaud-lb/php-memory-profiler) |
| mongodb | [mongodb/mongo-php-driver](https://github.com/mongodb/mongo-php-driver) |
| msgpack | [msgpack/msgpack-php](https://github.com/msgpack/msgpack-php) |
| mysqlnd_ed25519 | [mariadb-corporation/mysqlnd_ed25519](https://github.com/mariadb-corporation/mysqlnd_ed25519) |
| mysqlnd_parsec | [mariadb-corporation/mysqlnd_parsec](https://github.com/mariadb-corporation/mysqlnd_parsec) |
| oauth | [php/pecl-web_services-oauth](https://github.com/php/pecl-web_services-oauth) |
| oci8 | [php/pecl-database-oci8](https://github.com/php/pecl-database-oci8) |
| opentelemetry | [open-telemetry/opentelemetry-php-instrumentation](https://github.com/open-telemetry/opentelemetry-php-instrumentation) |
| oqs | [secudoc/php-liboqs](https://github.com/secudoc/php-liboqs) |
| parallel | [krakjoe/parallel](https://github.com/krakjoe/parallel) |
| pcov | [krakjoe/pcov](https://github.com/krakjoe/pcov) |
| pdo_oci | [php/pecl-database-pdo_oci](https://github.com/php/pecl-database-pdo_oci) |
| pecl_http | [m6w6/ext-http](https://github.com/m6w6/ext-http) |
| pg_query | [flow-php/pg-query-ext](https://github.com/flow-php/pg-query-ext) |
| pheme | [capotej/pheme](https://github.com/capotej/pheme) |
| phreakscope | [pakutoma/ext-phreakscope](https://github.com/pakutoma/ext-phreakscope) |
| pq | [m6w6/ext-pq](https://github.com/m6w6/ext-pq) |
| psr | [jbboehr/php-psr](https://github.com/jbboehr/php-psr) |
| quickhash | [derickr/quickhash](https://github.com/derickr/quickhash) |
| raphf | [m6w6/ext-raphf](https://github.com/m6w6/ext-raphf) |
| rdkafka | [arnaud-lb/php-rdkafka](https://github.com/arnaud-lb/php-rdkafka) |
| redis | [phpredis/phpredis](https://github.com/phpredis/phpredis) |
| relay | [cachewerk/relay](https://github.com/cachewerk/relay) |
| rpminfo | [remicollet/php-rpminfo](https://github.com/remicollet/php-rpminfo) |
| selinux | [php/pecl-security-selinux](https://github.com/php/pecl-security-selinux) |
| simdjson | [crazyxman/simdjson_php](https://github.com/crazyxman/simdjson_php) |
| simdutf | [awesomized/simdutf-php-ext](https://github.com/awesomized/simdutf-php-ext) |
| smbclient | [eduardok/libsmbclient-php](https://github.com/eduardok/libsmbclient-php) |
| snappy | [kjdev/php-ext-snappy](https://github.com/kjdev/php-ext-snappy) |
| solr | [php/pecl-search_engine-solr](https://github.com/php/pecl-search_engine-solr) |
| spi | [embedded-php/ext-spi](https://github.com/embedded-php/ext-spi) |
| spx | [NoiseByNorthwest/php-spx](https://github.com/NoiseByNorthwest/php-spx) |
| stomp | [php/pecl-tools-stomp](https://github.com/php/pecl-tools-stomp) |
| swoole | [swoole/swoole-src](https://github.com/swoole/swoole-src) |
| taint | [laruence/taint](https://github.com/laruence/taint) |
| timezonedb | [php/pecl-datetime-timezonedb](https://github.com/php/pecl-datetime-timezonedb) |
| traitify | [arshidkv12/traitify](https://github.com/arshidkv12/traitify) |
| translit | [derickr/pecl-translit](https://github.com/derickr/pecl-translit) |
| uart | [embedded-php/ext-uart](https://github.com/embedded-php/ext-uart) |
| uopz | [krakjoe/uopz](https://github.com/krakjoe/uopz) |
| uploadprogress | [php/pecl-php-uploadprogress](https://github.com/php/pecl-php-uploadprogress) |
| uuid | [php/pecl-networking-uuid](https://github.com/php/pecl-networking-uuid) |
| uv | [amphp/ext-uv](https://github.com/amphp/ext-uv) |
| vld | [derickr/vld](https://github.com/derickr/vld) |
| xattr | [php/pecl-file_system-xattr](https://github.com/php/pecl-file_system-xattr) |
| xdebug | [xdebug/xdebug](https://github.com/xdebug/xdebug) |
| xdiff | [php/pecl-text-xdiff](https://github.com/php/pecl-text-xdiff) |
| xhprof | [longxinH/xhprof](https://github.com/longxinH/xhprof) |
| xlswriter | [viest/php-ext-xlswriter](https://github.com/viest/php-ext-xlswriter) |
| xpass | [remicollet/php-xpass](https://github.com/remicollet/php-xpass) |
| xxtea | [xxtea/xxtea-pecl](https://github.com/xxtea/xxtea-pecl) |
| xz | [codemasher/php-ext-xz](https://github.com/codemasher/php-ext-xz) |
| yac | [laruence/yac](https://github.com/laruence/yac) |
| yaconf | [laruence/yaconf](https://github.com/laruence/yaconf) |
| yaf | [laruence/yaf](https://github.com/laruence/yaf) |
| yaml | [php/pecl-file_formats-yaml](https://github.com/php/pecl-file_formats-yaml) |
| yar | [laruence/yar](https://github.com/laruence/yar) |
| zip | [pierrejoye/php_zip](https://github.com/pierrejoye/php_zip) |
| zmq | [zeromq/php-zmq](https://github.com/zeromq/php-zmq) |
| zstd | [kjdev/php-ext-zstd](https://github.com/kjdev/php-ext-zstd) |

## 🎯 Supported Configurations

### PHP Versions

| Target | Configured source |
|--------|-------------------|
| PHP 8.2 | `php-8.2.34` |
| PHP 8.3 | `php-8.3.35` |
| PHP 8.4 | `php-8.4.26` |
| PHP 8.5 | `php-8.5.11` |
| PHP next | `php/php-src` branch `master` |

Tagged PHP sources are downloaded as `.tar.xz` files and verified against the SHA256 in `php-versions.json`. `next` is compiled from git. Patch versions change as the configuration is updated; existing image tags are not necessarily rebuilt automatically.

### Platforms
- **Alpine Linux**: 3.21, 3.22, 3.23, 3.24
- **Debian**: bullseye, bookworm, trixie

### Architectures
- amd64 (x86_64)
- arm64 (aarch64)
- arm32v6 (ARM 32-bit v6)
- arm32v7 (ARM 32-bit v7)

All three configured Debian versions exclude `arm32v6`. Alpine currently has no platform exclusions. With five PHP targets, four Alpine versions, and three Debian versions, the full extension matrix currently contains **125 combinations** before any extension-specific exclusions: 80 Alpine and 45 Debian builds.

### Build Channels
- **release** - Builds from an upstream tag or branch. This is not a stability guarantee: tracked tags can include prereleases.
- **dev** - Builds from the extension's default branch, optionally pinned to a commit (see the Dev Channel section below).

`build.yml` infers the channel from the version: `dev` and `dev-*` use `dev`; other values use `release`. For local builds, pass the channel explicitly when needed; `build.sh` defaults to `release`.

> **Version handling:** Ordinary versions are git tags/branches, `dev` clones the default branch, and `dev-<sha>` clones the default branch then checks out the SHA. The checkout is shallow, so an older commit that is not present in the clone can fail. Version normalization changes artifact and release names, not the upstream ref used to build.

## 📥 Installation

### Automatic Installation (Recommended)

From a repository checkout, use the install script to download an existing release asset and install it into the PHP installation on your `PATH`:

```text
./scripts/install.sh <extension> <version>
```

```bash
# Examples:
./scripts/install.sh redis 6.3.0
./scripts/install.sh imagick 3.8.1
./scripts/install.sh xdebug 3.6.0alpha1  # Example prerelease; confirm asset availability
```

The script will:
1. Detect your numeric PHP major/minor version, OS, and architecture
2. Download the appropriate pre-built extension from GitHub releases
3. Install runtime dependencies from `metadata.json`
4. Copy the extension to PHP's extension directory
5. Enable it via a config file in `conf.d`
6. Check whether the extension appears in `php -m`

**Requirements:** `php`, `jq`, `curl` or `wget`, `tar`, standard Unix utilities, and root access or `sudo`. PHP must have an existing INI scan directory reported by `php --ini`. The installer does not overwrite an existing `50-<pecl_name>.ini`.

**Compatibility limits:**
- Choose a release with an asset matching your PHP version, distribution version, and architecture. The farm's PHP builds are non-thread-safe (NTS); ZTS/debug builds or a different PHP ABI are not validated by the installer.
- Ubuntu is mapped to Debian assets: 20.04-21.10 to `bullseye`, and listed releases from 22.04 through 26.04 to `bookworm`. Unknown Debian-based systems also fall back to `bookworm`; these mappings are best-effort, not separately built or guaranteed Ubuntu support. Unknown Alpine-based systems fall back to the older `3.20` target, which is no longer in the current matrix.
- The installer does **not** map development PHP to `phpnext` assets. Install those manually using a matching PHP build.
- A downloaded `install.sh` can run without the checkout, but then assumes the extension key is its `pecl_name`. Download `normalize-version.sh` beside it to accept raw upstream tags; otherwise supply the already-normalized release version.
- Runtime package installation failures and an unloaded extension are reported as warnings in some paths. A zero exit status alone does not prove the module loaded. Check `php --ri <module>` and restart PHP-FPM/Apache as appropriate; their configuration may differ from CLI PHP.

### Manual Installation

1. Go to [Releases](https://github.com/flavioheleno/php-ext-farm/releases) and choose the exact PHP/OS/architecture asset.
2. Extract into a dedicated directory and inspect `metadata.json`.
3. Install the packages in `.runtime_deps` using the target system's package manager.
4. Install bundled libraries, copy the module, and enable it in the scan directory reported by `php --ini`.

```bash
mkdir -p redis-install
tar -xzf redis-6.3.0-php8.3-alpine-3.23-amd64.tar.gz -C redis-install
cd redis-install
jq '{pecl_name, php_version, platform, platform_version, arch, runtime_deps, zend_extension}' metadata.json

# Runtime packages for this Redis/Alpine example
sudo apk add --no-cache lz4-libs zstd-libs

# Install bundled libraries, if present
if [ -d libs ] && [ -n "$(ls -A libs)" ]; then
    sudo mkdir -p /usr/local/lib
    sudo cp -P libs/* /usr/local/lib/
    if command -v ldconfig >/dev/null 2>&1; then
        sudo ldconfig
    fi
fi

# Use the binary name and loading directive from metadata
PECL_NAME=$(jq -r '.pecl_name' metadata.json)
INI_KEY=$(jq -r 'if .zend_extension then "zend_extension" else "extension" end' metadata.json)
sudo cp "${PECL_NAME}.so" "$(php -r 'echo ini_get("extension_dir");')/"

# Inspect php --ini first; this path is for the official PHP Docker images
php --ini
CONF_D_DIR=/usr/local/etc/php/conf.d
printf '%s=%s.so\n' "${INI_KEY}" "${PECL_NAME}" | sudo tee "${CONF_D_DIR}/50-${PECL_NAME}.ini"

php --ri "${PECL_NAME}"
```

Change `CONF_D_DIR` for your PHP installation and inspect any existing INI file before replacing it. Use `zend_extension=` for Zend extensions such as Xdebug, not `extension=`. Do not copy a binary into a different OS, architecture, or PHP build just because its filename matches.

The manual commands assume `sudo`; omit it when running as root.

### External Libraries

`crc_fast`, `hdrhistogram`, `ip2location`, `ip2proxy`, and `xdiff` currently define source-built external libraries. Build output can include a `libs/` directory; the installer copies its files to `/usr/local/lib` and runs `ldconfig` when available.

On Alpine/musl, `ldconfig` is not the usual loader configuration mechanism. Ensure `/usr/local/lib` is in the loader search path; if needed, configure `LD_LIBRARY_PATH` for the PHP process. Inspect `ldd <extension.so>` when a module cannot find a shared library.

### Runtime Dependencies

Each successful build contains a `metadata.json`. Its `runtime_deps` is a **space-separated string**, not a JSON array. Install these packages before loading the module; they are distinct from bundled files in `libs/`.

**Alpine:**
```bash
apk add --no-cache lz4-libs zstd-libs  # Redis example; use your archive's metadata
```

**Debian:**
```bash
apt-get update
apt-get install -y --no-install-recommends liblz4-1 libzstd1  # Redis example
```

Dependencies can vary by OS version. For example, `zip` uses `libzip5` on Debian trixie instead of the default `libzip4`; builds resolve `version_overrides` before writing metadata.

An illustrative Redis archive contains metadata in this shape:

```json
{
  "extension": "redis",
  "pecl_name": "redis",
  "extension_version": "6.3.0",
  "php_version": "8.3",
  "platform": "alpine",
  "platform_version": "3.23",
  "arch": "amd64",
  "build_date": "2026-10-02T16:00:00Z",
  "runtime_deps": "lz4-libs zstd-libs",
  "zend_extension": false,
  "external_libs": [],
  "external_lib_files": null
}
```

`extension_version` here is the raw build ref. `external_libs` contains the configured library definitions; `external_lib_files` lists extracted library filenames, or is `null` when none were found. Build status/channel are recorded in reports, not this metadata.

### Using in a Dockerfile

Install pre-built extensions directly in your Docker images:

**Alpine:**
```dockerfile
FROM php:8.3-cli-alpine3.23

# Install dependencies for the install script
RUN apk add --no-cache jq curl

# Download the installer and its optional version-normalization helper
RUN curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/main/scripts/install.sh -o /tmp/install.sh \
    && curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/main/scripts/normalize-version.sh -o /tmp/normalize-version.sh \
    && chmod +x /tmp/install.sh /tmp/normalize-version.sh \
    && /tmp/install.sh redis 6.3.0 \
    && /tmp/install.sh imagick 3.8.1 \
    && rm /tmp/install.sh /tmp/normalize-version.sh

# Verify extensions are loaded
RUN php --ri redis && php --ri imagick
```

**Debian:**
```dockerfile
FROM php:8.3-cli-bookworm

# Install dependencies for the install script
RUN apt-get update && apt-get install -y --no-install-recommends jq curl \
    && rm -rf /var/lib/apt/lists/*

# Download and run the install script with normalized release versions
RUN curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/main/scripts/install.sh -o /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh redis 6.3.0 \
    && /tmp/install.sh imagick 3.8.1 \
    && rm /tmp/install.sh

# Verify extensions are loaded
RUN php --ri redis && php --ri imagick
```

**Multi-stage build (minimal final image):**
```dockerfile
FROM php:8.3-cli-alpine3.23 AS builder

RUN apk add --no-cache jq curl
RUN curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/main/scripts/install.sh -o /tmp/install.sh \
    && chmod +x /tmp/install.sh \
    && /tmp/install.sh redis 6.3.0

FROM php:8.3-cli-alpine3.23

# Copy extension and config from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/50-redis.ini /usr/local/etc/php/conf.d/

# Redis runtime packages from metadata (no jq/curl needed in the final image)
RUN apk add --no-cache lz4-libs zstd-libs

RUN php --ri redis
```

Keep both stages on the same PHP/OS/architecture. For extensions with bundled libraries, also copy the installed library files into the final image and configure its loader. Check release asset availability before choosing a base image tag.

## 🚀 Advanced Features

### PHP "next" - Bleeding Edge PHP

Build extensions against the upcoming PHP version from the master branch of php/php-src:

```bash
# Build locally
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 amd64
./scripts/build.sh redis 6.3.0 next alpine 3.23 amd64
```

**Use cases:**
- Test extensions against upcoming PHP features before stable release
- Catch compatibility issues early
- Help extension maintainers prepare for next PHP version
- CI/CD testing against future PHP

**How it works:**
- All PHP versions (including "next") use custom base images built from source
- Base images are stored in `ghcr.io/flavioheleno/php-ext-farm/php`
- PHP "next" tracks the master branch of php/php-src
- Reported as `php_version: "next"` in build reports
- Artifacts: `redis-6.3.0-phpnext-alpine-3.23-amd64.tar.gz`
- `install.sh` only selects numeric PHP versions; `phpnext` assets require manual installation
- A `next` image is a snapshot of master at build time, not a live PHP checkout

### Dev Channel - Default-Branch Builds

Build from the extension's default branch using the special version `dev`:

```bash
# Build default-branch version
gh workflow run build.yml \
  -f extension=redis \
  -f extension_version=dev
```

**Batch dev builds:**
- A manual `build-all.yml` run defaults `build_dev` to `true`
- It discovers default-branch HEADs for **GitHub repositories only** and uses `dev-{7-char-sha}` identifiers
- Those builds upload artifacts and reports without invoking `release.yml`
- Scheduled runs currently skip dev builds because the `inputs.build_dev != false` gate sees no dispatch input

`build.sh` extracts the SHA suffix into the `COMMIT_SHA` build argument. Both extension Dockerfiles clone the default branch and run `git checkout` when that argument is set. Because the clone has `--depth 1`, a commit that has fallen behind HEAD may not be available; use `dev` for the current branch tip or a reachable HEAD SHA.

### Combining PHP next + Dev Channel

Test bleeding-edge extension code against bleeding-edge PHP:

```bash
# Discover the current default-branch commit, then build it on PHP next
DEFAULT_BRANCH=$(gh api repos/phpredis/phpredis --jq '.default_branch')
SHA=$(gh api "repos/phpredis/phpredis/commits/${DEFAULT_BRANCH}" --jq '.sha')
./scripts/build.sh redis "dev-${SHA}" next alpine 3.23 amd64 dev
```

The output/report version is `dev-<sha>` and the artifact target is `phpnext`. GitHub API access requires an authenticated `gh` CLI.

## 🔧 Local Building

### Prerequisites
- Docker daemon with Buildx support
- jq
- bash
- GNU `find` for external-library metadata collection

### Build a single extension

```text
./scripts/build.sh <extension> <extension_version> <php_version> <platform> <platform_version> [arch] [channel] [--local]
```

```bash
# Examples:
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 arm64
./scripts/build.sh imagick 3.8.1 8.4 debian bookworm amd64

# Create the local PHP image before using --local
./scripts/build-base-image.sh 8.3 alpine 3.23 amd64 --local
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 amd64 release --local

# Build development version (for extensions without releases)
./scripts/build.sh corefill dev 8.3 alpine 3.23 amd64 dev
```

`build.sh` writes unpackaged files to `output/<extension>/<php_version>/<platform>/<platform_version>/<arch>/` and JSON reports to `reports/<extension>/<raw_version>/php<php_version>/<platform>-<platform_version>/<arch>.json`. CI creates the `.tar.gz` archives; a local build does not publish a release or update the dataset.

`--local` selects `php-ext-farm/php:*` images, but building those PHP images still uses GHCR OS base images. Select a Buildx builder that can resolve your local Docker image store. See [Local Testing](docs/LOCAL_TESTING.md) for architecture checks, cache behavior, and load verification.

> **Note:** When using GitHub workflows, if an extension has no `latest_version` in `extensions.json` but has a `last_checked` timestamp, the build system will automatically use version `"dev"` to build from the default branch.

### Check for new releases

```bash
./scripts/check-releases.sh
```

This is a read-only, network-dependent JSON report for all configured extensions. It does not update `extensions.json` or dispatch builds. The scheduled [Check Releases workflow](docs/CHECK_RELEASES.md) is a separate implementation that performs those mutations.

## 📁 Repository Structure

```
.
├── .github/
│   ├── workflows/
│   │   ├── build.yml               # Build single extension
│   │   ├── build-all.yml           # Weekly per-extension release dispatches
│   │   ├── build-os-base-images.yml   # Build OS base images (Alpine/Debian)
│   │   ├── build-php-base-images.yml  # Build PHP base images from source
│   │   ├── check-releases.yml      # Check for new extension releases
│   │   ├── check-php-releases.yml  # Daily check for new PHP releases
│   │   ├── check-os-releases.yml   # Weekly check for new OS releases
│   │   ├── cleanup-ghcr.yml        # Clean up container registry
│   │   ├── lint.yml                # Lint scripts and Dockerfiles
│   │   ├── tests.yml               # Run unit and integration tests
│   │   └── release.yml             # Create GitHub releases with artifacts
│   └── dependabot.yml              # Automated dependency updates
├── docker/
│   ├── base/
│   │   ├── os/
│   │   │   ├── Dockerfile.alpine   # OS base image: Alpine
│   │   │   └── Dockerfile.debian   # OS base image: Debian
│   │   └── php/
│   │       ├── Dockerfile.alpine   # PHP base image: Alpine (built from source)
│   │       └── Dockerfile.debian   # PHP base image: Debian (built from source)
│   ├── Dockerfile.alpine           # Extension build image (Alpine)
│   └── Dockerfile.debian           # Extension build image (Debian)
├── scripts/
│   ├── build.sh                   # Local build script
│   ├── build-base-image.sh        # Build base images locally
│   ├── install.sh                 # Install pre-built extensions
│   ├── local-test.sh              # Test builds locally
│   ├── check-releases.sh          # Check upstream releases
│   ├── check-exclusion.sh         # Check if build should be excluded
│   ├── exclusions.jq              # Shared exclusion rules + matrix generation
│   ├── normalize-version.sh       # Version string normalization
│   ├── release-all.sh             # Dispatch forced releases for every extension
│   ├── validate-config.sh         # Validate JSON configuration
│   ├── test-check-exclusion.sh    # Unit tests for check-exclusion
│   ├── test-normalize-version.sh  # Unit tests for normalize-version
│   ├── test-build-smoke.sh        # Docker-free build/install regression checks
│   └── test-version-tracking.sh   # Unit tests for version tracking
├── extensions.json                # Extension configuration
├── php-versions.json              # PHP version/tag/branch mapping
├── os-versions.json               # OS version configuration
├── docs/                          # Workflow and contributor guides
├── AGENTS.md                      # Guidance for coding agents
└── README.md
```

## 📚 Documentation

- Workflow docs:
  - [Build Extension](docs/BUILD.md)
  - [Release](docs/RELEASE.md)
  - [Build All Extensions](docs/BUILD_ALL.md)
  - [Lint](docs/LINT.md)
  - [Tests](docs/TESTS.md)
  - [Build OS Base Images](docs/BUILD_OS_BASE_IMAGES.md)
  - [Build PHP Base Images](docs/BUILD_PHP_BASE_IMAGES.md)
  - [Check Releases](docs/CHECK_RELEASES.md)
  - [Check PHP Releases](docs/CHECK_PHP_RELEASES.md)
  - [Check OS Releases](docs/CHECK_OS_RELEASES.md)
  - [Cleanup GHCR](docs/CLEANUP_GHCR.md)
- Development docs:
  - [Local Testing](docs/LOCAL_TESTING.md)
  - [Code Style](docs/CODE_STYLE.md)
- Agent/developer guidance: [AGENTS.md](AGENTS.md)

## ⚙️ Configuration

### extensions.json

The main configuration file defines:

- `base_image_registry`: PHP image repository recorded in configuration. It is currently informational: `build.sh` does not read it and uses the Dockerfiles' default registry, or `php-ext-farm` with `--local`.
- `architectures`: List of architectures to build for (amd64, arm64, arm32v6, arm32v7)
- `extensions`: Extension definitions including:
  - `type`: `pecl` or `git` classification. Both currently build by cloning `track_url` and running `phpize`; there is no PECL tarball build path.
  - `pecl_name`: Binary/configuration name used for `<pecl_name>.so` and its INI file
  - `track_url`: GitHub/GitLab/Bitbucket repository to track releases
  - `dependencies`: Build and runtime dependencies per platform
  - `dependencies.<platform>.version_overrides`: Optional per-OS-version replacements for build/runtime package lists
  - `build_path`: Optional directory within the source checkout containing `config.m4`
  - `exclude`: Optional array of extension-level exclusion rules (see below)
  - `external_libs`: Optional array of external libraries to build (see below)
  - `configure_options`: Optional array of configure flags
  - `zend_extension`: Optional boolean, set to `true` for Zend extensions (e.g., xdebug) that require `zend_extension=` instead of `extension=` in php.ini
  - `latest_version`: Cached, unmodified upstream tag/ref used when a workflow version is omitted
  - `last_checked`: Release-check timestamp; also permits the `dev` fallback when no release is known
  - `notes`: Contributor information; not consumed by the build script
  - `pin_version`: Optional boolean, set to `true` to stop `check-releases.yml` from overwriting `latest_version` (for repositories whose newest tag isn't buildable; `latest_version: "dev"` then builds the default branch)
  - `disabled`: Optional string explaining why the extension is skipped by `build-all.yml` and `check-releases.yml`; manual `release.yml`/`build.yml` runs still work. Currently 7 of 106 extensions are disabled (unbuilt extension dependencies, unpackaged or non-redistributable libraries, or ZTS-only)

`BASE_IMAGE_REGISTRY` is a Docker build argument for the namespace **without** `/php`; the Dockerfiles append `/php` in `FROM`. Do not pass the configuration's full PHP image repository as that argument.

Architecture lists drive matrices, but Docker/uname mappings are also hardcoded in the build/base-image/installer scripts and base-image workflows. Adding an architecture requires updating those mappings and runner/emulation routing, not just the JSON list.

Dependency overrides are resolved independently for `build` and `runtime`. An override array replaces the default array, including when it is empty; an omitted field inherits the default. For example, the current `.extensions.zip.dependencies.debian` is:

```json
{
  "build": ["libzip-dev"],
  "runtime": ["libzip4"],
  "version_overrides": {
    "trixie": {
      "runtime": ["libzip5"]
    }
  }
}
```

### os-versions.json

Defines supported OS versions and platform-level exclusions:

```json
{
  "alpine": {
    "versions": ["3.21", "3.22", "3.23", "3.24"],
    "exclude": []
  },
  "debian": {
    "versions": ["bullseye", "bookworm", "trixie"],
    "exclude": [
      {"version": "trixie", "arch": "arm32v6"},
      {"version": "bullseye", "arch": "arm32v6"},
      {"version": "bookworm", "arch": "arm32v6"}
    ]
  }
}
```

### php-versions.json

Maps PHP target names to tags, branches, and tarball SHA256 checksums. Inspect the current source selection with:

```bash
jq -r 'to_entries[] | "\(.key): \(.value.tag // .value.branch)"' php-versions.json
```

`check-php-releases.yml` updates only existing numeric PHP entries with a configured branch. It does not add new PHP minor versions or update `next`. Tagged entries require the checksum of the `.tar.xz` artifact. A null tag selects a git branch instead.

### Exclusion Rules

The build system supports excluding specific OS/architecture combinations that are incompatible. This uses a wildcard-based exclusion system with two levels:

#### Platform-Level Exclusions (os-versions.json)

Defined in `os-versions.json`, these apply to all extensions built on that platform. This is an illustrative example, not the current platform configuration:

```json
{
  "alpine": {
    "versions": ["3.21", "3.22", "3.23"],
    "exclude": [
      {"version": "3.21", "arch": "arm32*"},
      {"version": "3.22", "arch": "arm32v6"}
    ]
  },
  "debian": {
    "versions": ["bookworm", "bullseye"],
    "exclude": [
      {"version": "bullseye", "arch": "arm32v6"}
    ]
  }
}
```

**Note:** Platform-level excludes don't include an `os` field (it's implicit from the parent context).

#### Extension-Level Exclusions (extensions.json)

Defined within each extension, these add exclusions to the platform rules; they cannot re-enable a platform-excluded combination. For example, add this field to an extension definition:

```json
{
  "exclude": [
    {"os": "alpine", "version": "3.21", "arch": "amd64"},
    {"os": "*", "version": "bullseye", "arch": "arm64"}
  ]
}
```

**Note:** Extension-level excludes require an `os` field for cross-platform rules.

#### Wildcard Patterns

- `*` matches anything (e.g., `"os": "*"` matches all OSes)
- `arm32*` matches `arm32v6` and `arm32v7`
- `3.*` matches `3.21`, `3.22`, `3.23`, etc.
- Literal values match exactly

Extension matrix generation and per-build checks share `scripts/exclusions.jq`. Both platform- and extension-level rules are applied before jobs are queued, so excluded combinations normally produce no CI job or report. The OS/PHP base-image workflows still use their own **exact-match** platform filters; wildcard rules do not have identical behavior there.

#### Validation

Run the validation script to check your configuration:

```bash
./scripts/validate-config.sh
```

This validates JSON syntax for the extension/OS files and required exclusion fields (`version`, `arch`, and extension-level `os`). It rejects a platform-level `os` field and warns about unknown literal platform versions or architectures. It is not a full schema validator, does not validate `php-versions.json`, and does not detect conflicting rules or package availability.

To run the local configuration and Docker-free regression checks:

```bash
jq empty extensions.json php-versions.json os-versions.json
./scripts/validate-config.sh
./scripts/test-check-exclusion.sh
./scripts/test-normalize-version.sh
./scripts/test-version-tracking.sh
./scripts/test-build-smoke.sh
```

The smoke regression script exists locally but is not currently invoked by `tests.yml`. See [Tests](docs/TESTS.md) and [Lint](docs/LINT.md) for the exact CI coverage and trigger paths.

### Adding a New Extension

1. Add the extension to `extensions.json`:

```json
{
  "extensions": {
    "myext": {
      "type": "git",
      "pecl_name": "myext",
      "track_url": "https://github.com/owner/myext",
      "dependencies": {
        "alpine": {
          "build": [],
          "runtime": []
        },
        "debian": {
          "build": [],
          "runtime": []
        }
      }
    }
  }
}
```

2. Set `latest_version` to a real upstream tag/branch, or pass an explicit version (including `dev`) to `build.yml` for the initial build. Add only extension-specific packages; the OS base images already contain common compilers and PHP build tools.
3. Run the configuration checks and a local build, for example `./scripts/local-test.sh myext v1.0.0 8.3 alpine 3.23`. Replace the example name/ref with your real extension and upstream tag.
4. Update the extension table and count in this README.

`build-all.yml` reads every extension key without a `disabled` field dynamically and dispatches a separate `release.yml` run for each. PHP targets come from `php-versions.json`, OS versions from `os-versions.json`, and architectures from `extensions.json`; exclusions are applied when the extension matrix is generated. Compilation and load success must still be verified for each target.

> **Note for extensions without releases:** If your extension repository doesn't have any tags/releases yet, simply omit the `latest_version` field but include a `last_checked` timestamp. The build system will automatically build from the default branch (main/master) using version `"dev"`. Once upstream tags exist, `check-releases.yml` will start caching them; if those tags are not buildable, set `pin_version: true` (optionally with `latest_version: "dev"`) to keep the cached ref unchanged.

Example for an extension that has been checked but has no release yet (merge this entry into `.extensions`):
```json
{
  "myext": {
    "type": "git",
    "pecl_name": "myext",
    "track_url": "https://github.com/owner/myext",
    "last_checked": "2026-01-24T04:00:00Z",
    "dependencies": {
      "alpine": {"build": [], "runtime": []},
      "debian": {"build": [], "runtime": []}
    }
  }
}
```

### Adding Extensions with External Library Dependencies

Some extensions require external libraries (written in Rust, Go, C++, etc.) to be built first. The build system supports this through the `external_libs` configuration:

```json
{
  "extensions": {
    "myext": {
      "type": "git",
      "pecl_name": "myext",
      "track_url": "https://github.com/owner/myext",
      "external_libs": [
        {
          "name": "libmyext",
          "type": "rust",
          "repo_url": "https://github.com/owner/libmyext-rust",
          "version": "v1.0.0",
          "build_commands": [
            "cargo build --release --features=c-library",
            "mkdir -p /usr/local/include /usr/local/lib",
            "cp target/release/libmyext.so /usr/local/lib/",
            "cp include/libmyext.h /usr/local/include/"
          ]
        }
      ],
      "dependencies": {
        "alpine": {
          "build": ["autoconf", "gcc", "g++", "make", "cargo", "rust"],
          "runtime": []
        },
        "debian": {
          "build": ["autoconf", "gcc", "g++", "make", "cargo", "rustc"],
          "runtime": []
        }
      },
      "configure_options": ["--with-myext=/usr/local"]
    }
  }
}
```

**Key features:**
- `external_libs`: Array of external libraries to build before the extension
  - `name`: Library name used for logging and the temporary checkout directory
  - `type`: Library type (rust, go, cmake, etc.) - currently informational
  - `repo_url`: Git repository URL
  - `version`: Optional git tag/branch to checkout
  - `build_commands`: Array of shell commands to build and install the library
- `configure_options`: Array of additional options to pass to `./configure`
- `zend_extension`: Set to `true` for extensions that must be loaded as Zend extensions. Xdebug is the currently configured example; this selects `zend_extension=` in the generated INI file and archive metadata.

Libraries are built sequentially before `phpize`. Each `build_commands` entry runs in a **separate `sh -c` process** within the library checkout: `cd` or `export` in one entry does not persist into the next. Use self-contained commands or explicit build-directory arguments. `type` does not install a toolchain; list required tools in platform build dependencies.

External library `version` is a tag/branch passed to a shallow clone's `--branch`; omitting it follows the library's default branch. Pin it when reproducibility matters. When external libraries are configured, the Dockerfiles copy regular `.so*`/`.dylib*` files found under `/usr/local/lib` into `libs/`; inspect the actual archive rather than assuming it contains only one named library.

This approach works for any compiled library dependency. **Examples:**

**Rust library:**
```json
"build_commands": [
  "cargo build --release --features=c-library",
  "cp target/release/libmyext.so /usr/local/lib/",
  "cp include/myext.h /usr/local/include/"
]
```

**Go library:**
```json
"build_commands": [
  "go build -buildmode=c-shared -o libmyext.so .",
  "cp libmyext.so /usr/local/lib/",
  "cp myext.h /usr/local/include/"
]
```

**CMake library:**
```json
"build_commands": [
  "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local",
  "cmake --build build --parallel",
  "cmake --install build"
]
```

## 🔄 Automation

### Schedules and Side Effects

All schedules are UTC and run on the repository's default branch.

| Workflow | Schedule | Behavior |
|----------|----------|----------|
| `check-releases.yml` | Monday, hourly | Checks up to 20 eligible (not disabled or pinned) extensions, writes cached versions/timestamps directly, dispatches releases for changed tags |
| `check-php-releases.yml` | Daily 04:00 | Updates existing PHP patch tags/checksums and dispatches PHP base-image builds |
| `check-os-releases.yml` | Sunday 05:00 | Opens an OS-version update PR; does not directly build images |
| `build-os-base-images.yml` | Saturday 02:00 | Builds missing OS architecture tags and publishes manifests |
| `build-php-base-images.yml` | Saturday 03:00 | Builds missing PHP architecture tags and publishes manifests |
| `build-all.yml` | Sunday 02:00 | Dispatches one release run per enabled extension; existing releases are skipped |
| `cleanup-ghcr.yml` | Sunday 06:00 | Deletes ghost/partial images in the Alpine, Debian, and PHP packages |

Scheduled runs do **not** force rebuild existing image tags or releases. In particular, the PHP release checker dispatches without `force_rebuild=true`, so an existing minor-version image tag can retain an older PHP patch. Force OS images, then PHP images, then extension releases when you need a complete refresh. The Saturday workflows have independent schedules, not a dependency that waits for OS builds to finish.

A manual `build-all.yml` run can also build the dev channel; its current input gate skips dev builds on scheduled events. Base-image manifests refuse publication when a selected architecture tag is missing. Architecture-filtered runs publish a manifest for the selected subset, not automatically every configured architecture.

### Base Image Pipeline
The build system uses custom base images built from source:

1. **OS Base Images**: `build-os-base-images.yml` creates Alpine/Debian build environments
2. **PHP Release Detection**: `check-php-releases.yml` monitors php.net active releases for patch-tag changes
3. **PHP Base Images**: `build-php-base-images.yml` compiles PHP from source for configured, non-excluded targets
4. **Image Storage**: Base images are pushed to `ghcr.io/flavioheleno/php-ext-farm/{alpine,debian,php}`
5. **Extension Builds**: `build.yml` uses these base images to compile extensions

This approach provides:
- Full control over PHP compilation options
- Support for configured architectures, subject to platform exclusions
- Consistent build environments across configured PHP targets
- SHA256 verification for tagged PHP source downloads

Matrix Docker builds use `ubuntu-24.04` for amd64 and `ubuntu-24.04-arm` for ARM targets. QEMU is enabled only for arm32v6/arm32v7. Lightweight preparation, dispatch, and report jobs use `ubuntu-slim`; the release publication job uses `ubuntu-24.04` because large extensions exceed `ubuntu-slim`'s 15-minute job limit. Each matrix build job has a 60-minute timeout. Build/release workflows no longer expose a `runner` input.

Dependabot groups GitHub Actions updates weekly on Mondays and Docker updates weekly on Tuesdays for the OS, PHP, and extension Dockerfile directories. Its configuration is in `.github/dependabot.yml`.

### Manual Triggers
Build, release, and maintenance workflows accept manual dispatches. `lint.yml` and `tests.yml` only run on matching pushes/pull requests and do not expose `workflow_dispatch`. Run these commands from a checkout with an authenticated `gh` CLI:

```bash
# Build specific extension (all architectures)
gh workflow run build.yml -f extension=redis -f php_versions=8.3,8.4

# Build for specific architecture only
gh workflow run build.yml -f extension=redis -f php_versions=8.3 -f architectures=arm64

# Build extension without releases (automatic "dev" version)
gh workflow run build.yml -f extension=corefill -f php_versions=8.3

# Build specific version explicitly
gh workflow run build.yml -f extension=redis -f extension_version=6.3.0 -f php_versions=8.3

# Create release
gh workflow run release.yml -f extension=redis -f extension_version=6.3.0

# Rebuild all enabled extensions (one dispatched release run each)
gh workflow run build-all.yml -f force_rebuild=true

# Force OS images first; wait for completion before rebuilding PHP images
gh workflow run build-os-base-images.yml -f force_rebuild=true

# Rebuild base images for a specific PHP version
gh workflow run build-php-base-images.yml -f php_version=8.4 -f force_rebuild=true
```

For a forced release dispatch for every configured extension, including `disabled` ones, `./scripts/release-all.sh` invokes `release.yml` with `rebuild=true` and pauses one second between dispatches. This replaces existing releases/tags; it does not wait for builds to finish. See [Release](docs/RELEASE.md) before using it.

## 📋 Artifact Naming Convention

```
<extension>-<normalized_version>-php<php_version>-<platform>-<platform_version>-<arch>.tar.gz

Examples - Release channel:
- redis-6.3.0-php8.3-alpine-3.23-amd64.tar.gz
- redis-6.3.0-php8.3-alpine-3.23-arm64.tar.gz
- imagick-3.8.1-php8.4-debian-bookworm-amd64.tar.gz

Examples - Dev channel:
- redis-dev-abc1234-php8.4-alpine-3.23-amd64.tar.gz
- imagick-dev-def5678-php8.3-debian-bookworm-arm64.tar.gz

Examples - PHP next:
- redis-6.3.0-phpnext-alpine-3.23-amd64.tar.gz
- imagick-3.8.1-phpnext-debian-bookworm-amd64.tar.gz

Examples - Dev channel + PHP next:
- redis-dev-abc1234-phpnext-alpine-3.23-amd64.tar.gz
```

The filename version is normalized by `scripts/normalize-version.sh`: it strips an extension-name prefix, `tags/`, leading `v`, and `release-`/`release_` prefixes in that order, then changes underscores to dots. For example, `v6.3.0` becomes `6.3.0`, `yar-2.3.3` becomes `2.3.3`, and `tags/VLD_0_11_0` becomes `VLD.0.11.0`. Other prefixes and casing are retained.

Only the `tags/` path prefix is removed; other slash-containing refs can break artifact/release naming even when they are valid git branches.

## 🏷️ Release Naming Convention

```
<extension>-<normalized_version>

Examples:
- redis-6.3.0
- imagick-3.8.1
```

`build.yml` never creates a GitHub Release, including for dev builds. `build-all.yml` dev builds only dispatch that build workflow. However, `release.yml` has no channel restriction: explicitly releasing `dev`/`dev-<sha>`, or its no-release fallback to `dev`, can create a release with that version.

## 📊 Build Reports & Dataset

### Accessing Build Data

CI collects the reports that were produced and publishes them to the `dataset` branch as JSON files. Collection is attempted even when matrix builds fail. Local builds only write to `reports/`; excluded CI combinations are filtered before scheduling and normally have no report. Early failures can also leave no report.

#### Dataset Structure

```
dataset (branch)
├── latest.json                    # Last published summary per extension
├── reports/
│   └── {extension}/
│       └── {version}.json         # One history-file pointer per UTC day for a version
└── history/
    └── {year}/
        └── {month}/
            └── {day}/
                └── {ext}-{ver}-{run_id}.json  # Detailed build reports
```

The following JSON examples illustrate the schema, not live build results.

**latest.json** - Last published entry per extension, across release/dev channels:
```json
{
  "redis": {
    "path": "history/2026/01/21/redis-6.3.0-123456789.json",
    "version": "6.3.0",
    "updated_at": "2026-01-21T10:30:00Z",
    "pass": 123,
    "fail": 2,
    "total": 125
  }
}
```

**reports/{extension}/{version}.json** - Daily index for a version:
```json
{
  "last_updated": "2026-01-21T10:30:00Z",
  "builds": {
    "2026": {
      "01": {
        "21": "history/2026/01/21/redis-6.3.0-123456789.json"
      }
    }
  }
}
```

The daily index replaces that day's pointer on a later write; other history files remain available by path. History filenames contain a run ID but not a run attempt, so a same-day rerun of the same run can overwrite its history file. `latest.json` is not a channel-specific or all-versions compatibility matrix, and writes do not compare run times or versions to enforce chronological ordering. Counts cover collected reports only; `total` includes skipped reports, while `pass` and `fail` do not.

#### Accessing the Dataset

**Get latest build summary:**
```bash
curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/dataset/latest.json
```

**Get build history for specific extension version:**
```bash
curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/dataset/reports/redis/6.3.0.json
```

**Get detailed build reports:**
```bash
# Resolve an actual history path rather than copying the illustrative dates above
DATASET_URL=https://raw.githubusercontent.com/flavioheleno/php-ext-farm/dataset
HISTORY_PATH=$(curl -fsSL "${DATASET_URL}/latest.json" | jq -er '.redis.path')
curl -fsSL "${DATASET_URL}/${HISTORY_PATH}" -o history-file.json
```

**Clone dataset branch:**
```bash
git clone -b dataset --depth 1 https://github.com/flavioheleno/php-ext-farm.git dataset
```

#### Report Schema

Each report contains detailed build information:

**Successful build:**
```json
{
  "extension": "redis",
  "extension_version": "6.3.0",
  "channel": "release",
  "php_version": "8.4",
  "platform": "alpine",
  "platform_version": "3.23",
  "arch": "amd64",
  "status": "success",
  "started_at": "2026-01-07T20:10:11Z",
  "finished_at": "2026-01-07T20:14:52Z",
  "workflow_run_id": 123456789,
  "run_attempt": 1,
  "git_sha": "abc123def456",
  "log_url": "https://github.com/flavioheleno/php-ext-farm/actions/runs/123456789",
  "asset_name": "redis-6.3.0-php8.4-alpine-3.23-amd64.tar.gz"
}
```

**Failed build:**
```json
{
  "extension": "redis",
  "extension_version": "6.3.0",
  "channel": "release",
  "php_version": "8.4",
  "platform": "alpine",
  "platform_version": "3.23",
  "arch": "amd64",
  "status": "failure",
  "reason": "compile_error",
  "error": "Compilation failed",
  "started_at": "2026-01-07T20:10:11Z",
  "finished_at": "2026-01-07T20:14:52Z",
  "workflow_run_id": 123456789,
  "run_attempt": 1,
  "git_sha": "abc123def456",
  "log_url": "https://github.com/flavioheleno/php-ext-farm/actions/runs/123456789",
  "asset_name": "redis-6.3.0-php8.4-alpine-3.23-amd64.tar.gz"
}
```

**Skipped build:**
```json
{
  "extension": "redis",
  "extension_version": "6.3.0",
  "channel": "release",
  "php_version": "7.0",
  "platform": "alpine",
  "platform_version": "3.23",
  "arch": "amd64",
  "status": "skipped",
  "reason": "unsupported_php",
  "started_at": "2026-01-07T20:10:11Z",
  "finished_at": "2026-01-07T20:10:11Z",
  "workflow_run_id": 123456789,
  "run_attempt": 1,
  "git_sha": "abc123def456",
  "log_url": null,
  "asset_name": null
}
```

**Status values:**
- `success` - Build completed successfully
- `failure` - Docker build or binary extraction failed, including configure/compile/load-check failures
- `skipped` - A direct build invocation was skipped for an unsupported PHP/platform/architecture or an exclusion rule

**Reason values** (only present when status is `failure` or `skipped`):
- `compile_error` - Compilation failed
- `deps_missing` - Build dependencies missing or configure failed
- `test_failed` - Build-log classifier found test-failure text; this does not imply a test suite is run by default
- `unsupported_php` - PHP version not supported
- `unsupported_platform` - Platform not supported
- `unsupported_architecture` - Architecture not supported
- `excluded_by_platform` - Matched a platform rule
- `excluded_by_extension` - Matched an extension rule

Failure reasons are inferred from build-log text. The Dockerfiles verify loading with `php -m`; they do not run upstream extension test suites. `build.sh` exits nonzero for a failed build, but exits **zero after writing a skipped report** for unsupported targets or exclusions. Read the report status rather than using only the exit code.

**Additional fields:**
- `error` - Human-readable error message (only present when status is `failure`)
- `reason` - Machine-readable failure/skip reason (only present when status is `failure` or `skipped`)
- `asset_name` - Name of the build artifact (null when status is `skipped`)
- `extension_version` - Normalized for success/failure reports; skipped reports retain the raw version
- `workflow_run_id` - Numeric CI run ID, or `null` locally
- `run_attempt` - CI attempt number, defaulting to `1` locally
- `git_sha` - Commit of the farm repository, not the extension's upstream commit
- `log_url` - CI job/run URL when available; `null` locally and in skipped reports

For a failed build, `asset_name` is the intended filename, not proof that an artifact exists.

A success report describes compilation/extraction, not successful artifact upload or release publication. Check the publication jobs and actual release assets before relying on a download.

#### Querying Build Data

**Get extension summary from latest.json:**
```bash
# Get summary for a specific extension
curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/dataset/latest.json | \
  jq '.redis'

# List all extensions with their success rates
curl -fsSL https://raw.githubusercontent.com/flavioheleno/php-ext-farm/dataset/latest.json | \
  jq 'to_entries | map({ext: .key, pass: .value.pass, fail: .value.fail, rate: (.value.pass / .value.total * 100)})'
```

**Query detailed build reports (from history files):**
```bash
# Query the history-file.json downloaded above
jq '.[] | select(.status == "success")' history-file.json
```

**Find all successful PHP 8.4 builds (from history):**
```bash
jq '.[] | select(.php_version == "8.4" and .status == "success")' history-file.json
```

**Filter by channel (from history):**
```bash
# All dev channel builds
jq '.[] | select(.channel == "dev")' history-file.json

# All release channel builds
jq '.[] | select(.channel == "release")' history-file.json

# All PHP next builds
jq '.[] | select(.php_version == "next")' history-file.json

# Dev channel on PHP next (bleeding edge × bleeding edge)
jq '.[] | select(.channel == "dev" and .php_version == "next")' history-file.json
```

**Compare PHP versions (from history):**
```bash
# Success rate by PHP version
jq 'group_by(.php_version) | map({
  php: .[0].php_version,
  total: length,
  success: [.[] | select(.status == "success")] | length,
  success_rate: ([.[] | select(.status == "success")] | length) / length * 100
})' history-file.json
```

**Count builds by platform (from history):**
```bash
jq 'group_by(.platform) | map({platform: .[0].platform, count: length})' history-file.json
```

**List all failed builds (from history):**
```bash
jq '.[] | select(.status == "failure")' history-file.json
```

**Group failures by reason (from history):**
```bash
jq '[.[] | select(.status == "failure")] |
    group_by(.reason) | map({reason: .[0].reason, count: length})' history-file.json
```

**Find compile errors (from history):**
```bash
jq '.[] | select(.reason == "compile_error") | {extension, php_version, platform, arch, error}' history-file.json
```

**Track success rate over time:**
```bash
git clone -b dataset --depth 1 https://github.com/flavioheleno/php-ext-farm.git dataset
cd dataset
for file in history/*/*/*/*.json; do
  total=$(jq 'length' "$file")
  success=$(jq '[.[] | select(.status == "success")] | length' "$file")
  echo "$file: $success/$total successful"
done
```

#### Use Cases

- **CI/CD Integration**: Check build status before deployments
- **Monitoring Dashboards**: Track build success rates and trends
- **Compatibility Matrix**: Verify which PHP versions/platforms are supported
- **Historical Analysis**: Compare build performance over time
- **Automated Testing**: Download specific builds based on metadata
- **PHP Next Testing**: Test extensions against upcoming PHP versions
- **Dev Channel Tracking**: Monitor bleeding-edge extension development
- **Multi-dimensional Analysis**: Filter by channel, PHP version, platform, architecture

## 🎯 Common Workflows

### Testing Extensions Against PHP Next

```bash
# Build one extension on PHP next (extension is required)
gh workflow run build.yml -f extension=redis -f php_versions=next

# Check for successful PHP next builds in this extension's run
jq '[.[] | select(.php_version == "next" and .status == "success")] |
    unique_by(.extension) | .[].extension' history-file.json

# Inspect failed PHP next targets; failures are not necessarily source incompatibility
jq '.[] | select(.php_version == "next" and .status == "failure") |
    {extension, platform, platform_version, arch, reason}' history-file.json
```

### Monitoring Dev Channel Builds

```bash
# Get latest dev builds (from history file)
jq '.[] | select(.channel == "dev") |
    {extension, extension_version, php_version, status}' history-file.json

# Compare dev vs release stability
jq 'group_by(.channel) | map({
  channel: .[0].channel,
  total: length,
  success_rate: ([.[] | select(.status == "success")] | length) / length * 100
})' history-file.json
```

### Multi-Matrix Testing

```bash
# All possible combinations
# - 2 channels (release, dev)
# - 5 PHP versions (8.2, 8.3, 8.4, 8.5, next)
# - 2 platforms (alpine, debian)
# - Multiple platform versions
# - 4 architectures (amd64, arm64, arm32v6, arm32v7)
# Current PHP/OS/architecture matrix: 125 combinations per extension ref
# Channels are separate builds; Debian excludes arm32v6

# Example: Find best configuration for production (from history file)
jq '[.[] | select(.status == "success" and .channel == "release")] |
    group_by(.php_version) | map({
      php: .[0].php_version,
      success_count: length,
      platforms: [.[] | .platform] | unique
    })' history-file.json
```

## License

This project is licensed under the [MIT License](LICENSE).
