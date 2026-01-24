# Build PHP Base Images (`build-php-base-images.yml`)

**Workflow file:** `.github/workflows/build-php-base-images.yml`

## Purpose
Build and publish *PHP base images* (PHP built from source) used by extension builds.

Published to GHCR as `ghcr.io/<repo>/php:<tag>` with:
- per-arch images: `:<tag>-<arch>`
- multi-arch manifest: `:<tag>`

Where `<tag>` is:
- Alpine: `<php_version>-alpine<alpine_version>`
- Debian: `<php_version>-<debian_codename>`

## Triggers
- `schedule` (weekly Saturday 03:00 UTC)
- `workflow_dispatch`
- `workflow_call`
- `push` on changes to `docker/base/php/**` or `php-versions.json`

## Inputs
- `php_version` (string): a single version (e.g. `8.3`) or `all`
- `platform` (string): `alpine`, `debian`, or `all`
- `architectures` (string): comma-separated list or `all`
- `force_rebuild` (boolean)
- `runner`

## Permissions
- `contents: read`
- `packages: write`

## Concurrency
- `group: build-php-base-images-${{ inputs.php_version || 'all' }}-${{ inputs.platform || 'all' }}-${{ inputs.architectures || 'all' }}`

## Jobs
### 1) `prepare`
- Generates a build matrix across:
  - `php-versions.json` (tag/branch/sha256 per PHP version)
  - `os-versions.json` (platform versions)
  - `extensions.json` (architectures)
- Applies platform excludes from `os-versions.json` (exact match)
- Also generates a `manifest_matrix` with valid architectures per tag

### 2) `build` (matrix)
For each php/platform/os/arch:
- sets up QEMU (non-amd64)
- sets up buildx
- logs in to GHCR
- checks if the manifest tag exists (skips build if it does and `force_rebuild != true`)
- builds and pushes an arch-specific image:
  - `ghcr.io/<repo>/php:<tag>-<arch>`

Build args include:
- `BASE_IMAGE_REGISTRY=ghcr.io/<repo>` (OS image namespace)
- `ALPINE_VERSION` or `DEBIAN_VERSION`
- `PHP_VERSION_TAG`, `PHP_VERSION_BRANCH`, `PHP_VERSION_SHA256`, `PHP_VERSION`

### 3) `create-manifest` (matrix)
For each php/platform/os tag:
- logs in to GHCR
- creates and pushes a manifest:
  - `ghcr.io/<repo>/php:<tag>`

## Outputs
- Per-arch PHP images: `php:<tag>-<arch>`
- Multi-arch PHP images: `php:<tag>`

## How to run manually
```bash
# rebuild PHP 8.4 images only
gh workflow run build-php-base-images.yml -f php_version=8.4 -f force_rebuild=true

# build only debian bookworm across all PHP versions
gh workflow run build-php-base-images.yml -f platform=debian
```

## Notes
- `next` (if present in `php-versions.json`) typically uses `tag: null` and builds from the configured branch.
- Excludes are based only on `os-versions.json` and require exact version+arch matches.