# Build Extension (`build.yml`)

**Workflow file:** `.github/workflows/build.yml`

## Purpose
Build a single PHP extension across a matrix of PHP versions, platforms, and architectures, then:
- package per-matrix outputs as `.tar.gz` artifacts
- upload per-matrix build reports
- aggregate reports into the `dataset` branch (`latest.json`, `reports/...`, `history/...`)

## Triggers
- `workflow_dispatch`
- `workflow_call` (used by `release.yml` and `build-all.yml`)

## Inputs
### workflow_dispatch
- `extension` (required): extension key in `extensions.json` (e.g. `redis`)
- `extension_version` (optional): git ref/tag; empty resolves to `.extensions[extension].latest_version` or `dev` if tracked but no releases
- `php_versions` (optional): comma-separated list or `all`
- `platforms` (optional): comma-separated list (`alpine,debian`) or `all`
- `architectures` (optional): comma-separated list or `all`
- `runner` (optional): `ubuntu-latest` or `self-hosted`

### workflow_call
- `extension` (required)
- `extension_version` (required)
- `architectures` (optional): string, default `all`
- `runner` (optional)

## Permissions
- `contents: write` (used to push aggregated JSON into `dataset` branch)

## Concurrency
Prevents concurrent builds of the *same extension+version*:
- `group: build-${{ inputs.extension }}-${{ inputs.extension_version }}`

## Jobs
### 1) `prepare`
- Resolves `extension_version` if not provided (uses `extensions.json`)
- Generates the full build matrix using `jq` from:
  - `php-versions.json`
  - `os-versions.json`
  - `extensions.json`
- Filters **platform-level excludes only** (exact `version` + exact `arch` matches from `os-versions.json`)

Outputs:
- `matrix`: JSON matrix used by the `build` job
- `extension_version`: resolved version/ref

### 2) `build`
For each matrix entry:
- sets up QEMU for non-`amd64`
- runs `scripts/build.sh` with:
  - `channel` inferred from version format (`dev-*` => `dev`, else `release`)
- packages results into `EXT-VERSION-phpX-PLATFORM-OS-ARCH.tar.gz`
  - includes `*.so`, `metadata.json`, and optional `libs/`
- uploads:
  - build artifact (`actions/upload-artifact`)
  - build report (`reports/` folder) as a separate artifact

Notes:
- `extension_version` is treated as a **git ref** inside the build container.
- The special literal version `dev` means “clone default branch”.

### 3) `collect-artifacts`
- downloads all build artifacts and report artifacts
- uploads a combined artifact named `${extension}-${normalized_version}-all-builds`
- aggregates reports into:
  - `dataset/history/YYYY/MM/DD/<extension>-<version>-<run_id>.json` (merged array)
  - `dataset/reports/<extension>/<version>.json` (index pointing to history files)
  - `dataset/latest.json` (per-extension pointer + pass/fail/total)
- pushes updates to the `dataset` branch via a temporary git worktree

## Outputs / Artifacts
- Per-matrix `.tar.gz` build artifact (90 days)
- Per-matrix report artifact (90 days)
- Combined “all builds” artifact (90 days)
- Persistent dataset JSON in the `dataset` branch

## How to run manually
```bash
gh workflow run build.yml \
  -f extension=redis \
  -f extension_version=6.0.2 \
  -f php_versions=8.3,8.4 \
  -f platforms=alpine \
  -f architectures=amd64
```

## Common pitfalls
- Matrix exclude filtering only considers platform-level excludes from `os-versions.json` and only exact matches; extension-level excludes are enforced later by `scripts/check-exclusion.sh` during the build.
- `dev-<sha>` versions are treated as git refs; they will fail unless the upstream repo actually has that ref (tag/branch).