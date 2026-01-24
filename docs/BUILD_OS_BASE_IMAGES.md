# Build OS Base Images (`build-os-base-images.yml`)

**Workflow file:** `.github/workflows/build-os-base-images.yml`

## Purpose
Build and publish the *OS base images* used as the foundation for PHP base images:
- Alpine base image: `ghcr.io/<repo>/alpine:<version>`
- Debian base image: `ghcr.io/<repo>/debian:<version>`

Images are built per-architecture and then combined into a multi-arch manifest.

## Triggers
- `schedule` (weekly Saturday 02:00 UTC)
- `workflow_dispatch`
- `workflow_call`
- `push` on changes to `docker/base/os/**` or `os-versions.json`

## Inputs
- `platform` (string): `alpine`, `debian`, or `all`
- `architectures` (string): comma-separated list or `all`
- `force_rebuild` (boolean)
- `runner`

## Permissions
- `contents: read`
- `packages: write` (push images to GHCR)

## Concurrency
- `group: build-os-base-images-${{ inputs.platform || 'all' }}-${{ inputs.architectures || 'all' }}`

## Jobs
### 1) `prepare`
- Generates a build matrix from `os-versions.json` and `extensions.json` (architectures list)
- Skips excluded platform/version/arch combinations using `os-versions.json` excludes (exact match)
- Generates a separate `manifest_matrix` (one entry per platform+version, with a CSV list of valid architectures)

### 2) `build` (matrix)
For each platform/version/arch:
- sets up QEMU (non-amd64)
- sets up buildx
- logs in to GHCR
- optionally checks if the manifest tag exists (skips build if it does and `force_rebuild != true`)
- builds and pushes an arch-specific image tag:
  - `ghcr.io/<repo>/<platform>:<version>-<arch>`

### 3) `create-manifest` (matrix)
For each platform/version:
- logs in to GHCR
- discovers which arch images exist
- creates and pushes a manifest:
  - `ghcr.io/<repo>/<platform>:<version>`

## Outputs
- Per-arch OS images: `<platform>:<version>-<arch>`
- Multi-arch manifests: `<platform>:<version>`

## How to run manually
```bash
# rebuild alpine images only
gh workflow run build-os-base-images.yml -f platform=alpine -f force_rebuild=true

# build only amd64
gh workflow run build-os-base-images.yml -f architectures=amd64
```

## Notes
- Excludes are applied from `os-versions.json` only and require exact version+arch matches.