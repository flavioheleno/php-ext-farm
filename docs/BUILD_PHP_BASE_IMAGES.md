# Build PHP Base Images (`build-php-base-images.yml`)

**Workflow file:** [`.github/workflows/build-php-base-images.yml`](../.github/workflows/build-php-base-images.yml)

## Purpose
Build PHP from source on the farm's OS images and publish the build environments used by extension builds.

Published to GHCR as `ghcr.io/<repo>/php:<tag>` with:
- per-arch images: `:<tag>-<arch>`
- multi-arch manifest: `:<tag>`

Where `<tag>` is:
- Alpine: `<php_version>-alpine<alpine_version>`
- Debian: `<php_version>-<debian_codename>`

For example, `php:8.3-alpine3.23-amd64` is an architecture tag and `php:8.3-bookworm` is a manifest tag. Tags identify the PHP target/minor version, not the actual PHP patch version or source commit.

## PHP compilation

Non-null `tag` entries in `php-versions.json` download the official `.tar.xz` source and verify its configured SHA256. A null tag clones the configured branch; `next` currently uses `master`.

The Dockerfiles install PHP under `/usr/local`, enable CLI, and configure `/usr/local/etc/php/conf.d` as the INI scan directory. They build NTS PHP (no ZTS flag), disable CGI, FPM, phpdbg, and phar, and enable common features including mbstring, mysqlnd, opcache, pcntl, sockets, curl, OpenSSL, readline, sodium, and zlib. These images retain the OS build tools for compiling extensions.

## Triggers
- `schedule` (weekly Saturday 03:00 UTC)
- `workflow_dispatch`
- `workflow_call`
- `push` on changes to `docker/base/php/**` or `php-versions.json` (no explicit branch filter)

## Inputs
Manual dispatch and reusable calls expose the same inputs:

| Input | Default | Meaning |
|-------|---------|---------|
| `php_version` | `all` | One configured PHP key, including `next`, or `all`; not a CSV |
| `platform` | `all` | One platform (`alpine` or `debian`) or `all`; not a CSV |
| `architectures` | `all` | Canonical architecture names as CSV without spaces, or `all` |
| `force_rebuild` | `false` | Rebuild even if the architecture-specific tag exists |

There is no OS-version or runner input. Selecting Debian includes every configured Debian codename.

## Permissions
The workflow defaults to `contents: read`. Matrix builds additionally grant `packages: write`; manifest jobs grant `packages: write`. Preparation and manifest jobs run on `ubuntu-slim`; Docker builds use `ubuntu-24.04` for amd64 and `ubuntu-24.04-arm` for ARM.

## Concurrency
- `group: build-php-base-images-${{ inputs.php_version || 'all' }}-${{ inputs.platform || 'all' }}-${{ inputs.architectures || 'all' }}`
- `cancel-in-progress: false`

## Jobs
### 1) `prepare`
- Generates a build matrix across:
  - `php-versions.json` (tag/branch/sha256 per PHP version)
  - `os-versions.json` (platform versions)
  - `extensions.json` (architectures)
- Applies platform excludes from `os-versions.json` (exact match)
- Also generates a `manifest_matrix` with valid architectures per tag

The current full matrix has 125 architecture builds and 35 manifest entries. All configured Debian versions exclude `arm32v6`. PHP builds require the corresponding OS image/architecture to be available first.

### 2) `build` (matrix)
For each php/platform/os/arch:
- sets up QEMU only for arm32v6/arm32v7; arm64 builds natively
- sets up buildx
- logs in to GHCR
- checks the **architecture-specific** tag, skipping an existing tag unless `force_rebuild=true`
- builds and pushes an arch-specific image:
  - `ghcr.io/<repo>/php:<tag>-<arch>`
- uses GHA layer caching and disables provenance generation

Build args include:
- `BASE_IMAGE_REGISTRY=ghcr.io/<repo>` (OS image namespace)
- `ALPINE_VERSION` or `DEBIAN_VERSION`
- `PHP_VERSION_TAG`, `PHP_VERSION_BRANCH`, `PHP_VERSION_SHA256`, `PHP_VERSION`

### 3) `create-manifest` (matrix)
For each php/platform/os tag:
- logs in to GHCR
- requires every selected, non-excluded architecture tag to exist
- fails without publishing if any selected tag is missing or none are available
- creates and pushes a manifest:
  - `ghcr.io/<repo>/php:<tag>`

This job is attempted after build failures unless cancelled. Existing architecture tags can satisfy the manifest check even if a forced rebuild failed; the check guarantees tag presence, not source freshness.

## Outputs
- Per-arch PHP images: `php:<tag>-<arch>`
- Multi-arch PHP images: `php:<tag>`

## How to run manually
```bash
# rebuild PHP 8.4 images only
gh workflow run build-php-base-images.yml -f php_version=8.4 -f force_rebuild=true

# Build all configured Debian codenames across all PHP versions
gh workflow run build-php-base-images.yml -f platform=debian

# Build the development PHP snapshot for arm64
gh workflow run build-php-base-images.yml \
  -f php_version=next -f architectures=arm64 -f force_rebuild=true
```

## Operational limits

- Exclusions use exact version/architecture comparisons from `os-versions.json`, not `scripts/exclusions.jq` wildcard rules or extension-level exclusions.
- Scheduled and path-triggered runs skip existing tags by default. A changed PHP patch/checksum, Dockerfile, OS image, or master HEAD does not by itself refresh an existing PHP image.
- `check-php-releases.yml` currently dispatches without `force_rebuild=true`; existing minor-version image tags can retain the previous patch. Force rebuilding explicitly when freshness is required.
- Architecture-filtered runs publish a manifest for the selected subset. Changes to `extensions.json` alone do not trigger this workflow.
- The Saturday 03:00 schedule does not wait for the independent 02:00 OS build. For a complete refresh, finish [OS base images](BUILD_OS_BASE_IMAGES.md), then force PHP images, then rebuild extension releases.

Inspect the actual compiled version when diagnosing stale images:

```bash
docker run --rm --platform linux/amd64 \
  ghcr.io/flavioheleno/php-ext-farm/php:8.3-alpine3.23-amd64 php --version
```

The [local PHP helper](LOCAL_TESTING.md) loads images into Docker and does not push them or create registry manifests.