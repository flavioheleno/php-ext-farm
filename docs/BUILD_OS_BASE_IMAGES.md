# Build OS Base Images (`build-os-base-images.yml`)

**Workflow file:** [`.github/workflows/build-os-base-images.yml`](../.github/workflows/build-os-base-images.yml)

## Purpose
Build and publish the OS build environments used as the foundation for PHP base images:
- Alpine base image: `ghcr.io/<repo>/alpine:<version>`
- Debian base image: `ghcr.io/<repo>/debian:<version>`

Images install system upgrades, common compilers/PHP build dependencies, git, curl, and jq. They are build environments, not minimal application runtime images. Images are built per architecture and then combined into a manifest for the selected architectures.

## Triggers
- `schedule` (weekly Saturday 02:00 UTC)
- `workflow_dispatch`
- `workflow_call`
- `push` on changes to `docker/base/os/**` or `os-versions.json` (no explicit branch filter)

## Inputs
Manual dispatch and reusable calls expose the same inputs:

| Input | Default | Meaning |
|-------|---------|---------|
| `platform` | `all` | One platform (`alpine` or `debian`) or `all`; not a CSV |
| `architectures` | `all` | Canonical architecture names as CSV without spaces, or `all` |
| `force_rebuild` | `false` | Rebuild even if the architecture-specific tag exists |

There is no OS-version or runner input. A selected platform builds all its configured versions.

## Permissions
The workflow defaults to `contents: read`. Matrix builds additionally grant `packages: write`; manifest jobs grant `packages: write` for GHCR publication. `prepare` and manifest jobs use `ubuntu-slim`. Docker builds use `ubuntu-24.04` for amd64 or `ubuntu-24.04-arm` for ARM.

## Concurrency
- `group: build-os-base-images-${{ inputs.platform || 'all' }}-${{ inputs.architectures || 'all' }}`
- `cancel-in-progress: false`

## Jobs
### 1) `prepare`
- Generates a build matrix from `os-versions.json` and `extensions.json` (architectures list)
- Skips excluded platform/version/arch combinations using `os-versions.json` excludes (exact match)
- Generates a separate `manifest_matrix` (one entry per platform+version, with a CSV list of valid architectures)

Current configuration produces 25 architecture builds and 7 manifest entries: four Alpine versions with four architectures and three Debian versions with three architectures. All Debian `arm32v6` combinations are excluded.

### 2) `build` (matrix)
For each platform/version/arch:
- sets up QEMU only for arm32v6/arm32v7; arm64 uses the native ARM runner
- sets up buildx
- logs in to GHCR
- checks the **architecture-specific** tag with `docker manifest inspect` and skips an existing tag unless `force_rebuild=true`
- builds and pushes an arch-specific image tag:
  - `ghcr.io/<repo>/<platform>:<version>-<arch>`
- uses GHA layer caching and disables provenance generation

### 3) `create-manifest` (matrix)
For each platform/version:
- logs in to GHCR
- verifies that every selected, non-excluded architecture tag exists
- fails without publishing if any selected tag is missing or none are available
- creates and pushes a manifest:
  - `ghcr.io/<repo>/<platform>:<version>`

Manifest jobs are attempted after build failures unless cancelled. An old existing architecture tag can satisfy the check; it does not prove that architecture was rebuilt successfully in this run.

## Outputs
- Per-arch OS images: `<platform>:<version>-<arch>`
- Multi-arch manifests: `<platform>:<version>`

## How to run manually
```bash
# rebuild alpine images only
gh workflow run build-os-base-images.yml -f platform=alpine -f force_rebuild=true

# Build only amd64; the published manifest will select that subset
gh workflow run build-os-base-images.yml -f architectures=amd64
```

## Operational limits

- Excludes come from `os-versions.json` only and use exact version/architecture matching. These workflows do not use the wildcard matcher in `scripts/exclusions.jq`.
- Scheduled and path-triggered runs do not force rebuild existing tags, even after Dockerfile/package changes. Use `force_rebuild=true` for a refresh.
- Architecture-filtered runs publish the manifest for the selected subset; they do not guarantee a manifest containing every configured architecture.
- Changing the architecture list in `extensions.json` alone does not match this workflow's push filter. Dispatch both OS and PHP base-image workflows when adding architectures.
- PHP base-image builds run on an independent schedule. Wait for the OS build/manifests to finish before explicitly forcing [PHP base images](BUILD_PHP_BASE_IMAGES.md).

For local OS-image bootstrapping and image-store requirements, see [Local Testing](LOCAL_TESTING.md).