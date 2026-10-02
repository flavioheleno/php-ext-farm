# AGENTS.md

This document provides comprehensive guidance for AI agents and LLMs working with the PHP Extension Farm codebase.

## Project Overview

**PHP Extension Farm** is an automated build system that compiles PHP extensions from source for multiple PHP versions, operating systems, and CPU architectures. The project packages `.so` binaries, metadata, and optional libraries as `.tar.gz` assets in GitHub Releases, enabling users to install extensions without compiling them locally.

### Key Capabilities

- Configures **106 PHP extensions** across PHP targets 8.2, 8.3, 8.4, 8.5, and next
- Supports **Alpine Linux** (3.21, 3.22, 3.23, 3.24) and **Debian** (bullseye, bookworm, trixie)
- Builds for **4 architectures**: amd64, arm64, arm32v7, arm32v6
- Handles **external library dependencies** for extensions that need them
- Tracks extension releases automatically from GitHub, GitLab, and Bitbucket

All Debian versions exclude arm32v6. The current unfiltered extension matrix has 125 combinations before extension-specific exclusions. Configuration is not proof that every build succeeds; consult release assets and reports. PHP base images compile NTS PHP; the installer does not validate every ABI variant.

Use the JSON files, scripts, Dockerfiles, and workflow definitions as the source of truth. This guide and [README.md](README.md) summarize them; the [documentation index](README.md#-documentation) links the detailed operational guides.

## Repository Structure

```
php-ext-farm/
├── extensions.json          # Extension definitions, dependencies, and version tracking
├── php-versions.json        # Supported PHP versions with tarballs and branches
├── os-versions.json         # Supported OS versions and architecture exclusions
├── docker/
│   ├── Dockerfile.alpine    # Main extension build Dockerfile for Alpine
│   ├── Dockerfile.debian    # Main extension build Dockerfile for Debian
│   └── base/
│       ├── os/              # Base OS images with build tools
│       └── php/             # PHP base images (built from source)
├── scripts/
│   ├── build.sh             # Main extension build script
│   ├── build-base-image.sh  # Builds PHP base images locally
│   ├── install.sh           # End-user installation script
│   ├── check-exclusion.sh   # Checks if build combo is excluded
│   ├── exclusions.jq        # Shared exclusion rules + matrix generation
│   ├── check-releases.sh    # Checks for new extension releases
│   ├── normalize-version.sh # Normalizes version strings
│   ├── release-all.sh       # Dispatches forced releases for every extension
│   ├── validate-config.sh   # Validates JSON config files
│   ├── local-test.sh        # Orchestrates local image/extension builds
│   └── test-*.sh            # Docker-free checks, including test-build-smoke.sh
├── .github/workflows/
│   ├── build.yml            # Single extension build workflow
│   ├── build-all.yml        # Weekly per-extension release/dev dispatches
│   ├── release.yml          # Creates GitHub releases
│   ├── build-os-base-images.yml  # OS images and selected-architecture manifests
│   ├── build-php-base-images.yml # PHP images compiled from source
│   ├── check-releases.yml   # Batched extension updates and release dispatches
│   ├── check-php-releases.yml # PHP patch-tag/checksum updates
│   ├── check-os-releases.yml # PRs for new OS versions
│   ├── cleanup-ghcr.yml     # Ghost/partial image cleanup
│   ├── lint.yml             # ShellCheck, Hadolint, JSON validation
│   └── tests.yml            # Unit and integration tests
├── .github/dependabot.yml   # Grouped GitHub Actions and Docker updates
└── docs/
    ├── CODE_STYLE.md        # Shell, workflow, JSON, and Docker conventions
    ├── LOCAL_TESTING.md     # Local development guide
    └── *.md                # One guide for each workflow
```

## Configuration Files

### extensions.json

Central configuration for all extensions. Structure:

```json
{
  "base_image_registry": "ghcr.io/flavioheleno/php-ext-farm/php",
  "architectures": ["amd64", "arm64", "arm32v6", "arm32v7"],
  "extensions": {
    "redis": {
      "pecl_name": "redis",
      "track_url": "https://github.com/phpredis/phpredis",
      "type": "pecl",
      "dependencies": {
        "alpine": {
          "build": ["lz4-dev", "zstd-dev"],
          "runtime": ["lz4-libs", "zstd-libs"]
        },
        "debian": {
          "build": ["liblz4-dev", "libzstd-dev"],
          "runtime": ["liblz4-1", "libzstd1"]
        }
      },
      "configure_options": [
        "--enable-redis-lzf",
        "--enable-redis-zstd",
        "--with-libzstd",
        "--enable-redis-lz4",
        "--with-liblz4"
      ],
      "zend_extension": false,
      "latest_version": "6.3.0"
    }
  }
}
```

**Key fields:**
- `pecl_name`: The actual extension name used for the `.so` file.
- `track_url`: Repository URL for version tracking and builds.
- `type`: `git` or `pecl` (primarily informational/for tracking); the current build path in `docker/Dockerfile.*` is **git clone + phpize** for both.
- `latest_version`: Cached upstream tag/ref used by workflows when no version is provided. **This should be a valid git ref** (tag/branch) for `track_url`.
- `dependencies`: Platform-specific build and runtime dependencies.
- `dependencies.<platform>.version_overrides`: Per-OS-version replacements for `build` and/or `runtime` lists. Each field falls back independently; a supplied array replaces rather than appends. `zip` on Debian trixie currently overrides runtime `libzip4` with `libzip5`.
- `configure_options`: Extra flags for `./configure`.
- `zend_extension`: Set to `true` for Zend extensions (e.g. xdebug) so runtime config uses `zend_extension=` instead of `extension=`.
- `pin_version`: Set to `true` so `check-releases.yml` leaves `latest_version` alone (newest upstream tag isn't buildable).
- `disabled`: Reason string; skips the extension in `build-all.yml` and `check-releases.yml` (manual runs still work).
- `build_path`: Subdirectory containing `config.m4` if not at root.
- `external_libs`: Libraries that must be built from source.
- `last_checked`: Lookup timestamp, not proof that an upstream lookup succeeded. Enables the `dev` fallback when no `latest_version` is cached.
- `notes`: Informational contributor notes, not build instructions.
- `exclude`: Build combinations to skip. Wildcards (`arm32*`, `*`) are supported. Matching rules live in `scripts/exclusions.jq` and are shared by `scripts/check-exclusion.sh` and the workflow matrix generation, so platform- and extension-level excludes are filtered out of the matrix before any build is queued.

**Gotchas:**
- `normalize-version.sh` is used for **artifact/report naming**; the build itself uses the original `extension_version` as a git ref.
- `dev` clones the default branch. `dev-<sha>` passes the suffix as `COMMIT_SHA`, then checks out that commit in both Dockerfiles. The shallow clone may not contain a commit that has moved behind HEAD.
- `base_image_registry` in `extensions.json` points to the PHP base-image repository (e.g. `.../php`) but is not currently consumed by `scripts/build.sh`; extension Dockerfiles use a `BASE_IMAGE_REGISTRY` build-arg that expects the registry namespace **without** the trailing `/php` (it appends `/php` in `FROM`).

### php-versions.json

Defines supported PHP versions:

```json
{
  "8.3": {
    "tag": "php-8.3.35",
    "branch": "PHP-8.3",
    "sha256": "ff4630fbbbd94359134b7d3c223db59329905bdc4f5a9ef93d257b48e358619a"
  },
  "next": {
    "tag": null,
    "branch": "master"
  }
}
```

- Versions with `tag` download official tarballs (faster)
- Versions with `tag: null` build from git (development versions)
- Existing image tags are skipped by default even after a PHP source update. `check-php-releases.yml` dispatches without forcing a rebuild; use `force_rebuild=true` when updating an existing image's PHP patch.

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

Extension matrices/local checks apply wildcard exclusions through `scripts/exclusions.jq`. The OS/PHP base-image workflows currently use separate exact-match platform filters; do not assume wildcard behavior is identical.

Adding an architecture also requires updating the hardcoded Docker/uname mappings in build/base-image/installer scripts and base-image workflows, plus runner/emulation routing. A JSON-list change alone does not implement support.

## Code Style Guidelines

### Shell Script Types

The project uses **two types of shell scripts** with different portability requirements:

#### POSIX Shell (`#!/bin/sh`)

Used for scripts that run on end-user systems:
- `install.sh`
- `normalize-version.sh`

Rules:
- Use `[ ]` for conditionals (not `[[ ]]`)
- Use `set -eu` (no `pipefail`, not POSIX)
- Avoid bash-specific features
- Use `$(command)` syntax

#### Bash Scripts (`#!/bin/bash`)

Used for build scripts and CI automation:
- `build.sh`, `build-base-image.sh`, `local-test.sh`
- `check-exclusion.sh`, `check-releases.sh`, `release-all.sh`
- `validate-config.sh`, test scripts

Rules:
- Use `[[ ]]` for conditionals
- Use `set -euo pipefail`
- Bash features allowed (arrays, `${VAR,,}`, etc.)
- Always use `${VAR}` braces for variables
- Quote variable expansions

### JSON Style

- 2-space indentation
- No trailing commas
- Alphabetically sort keys where logical

### Dockerfiles

- Follow Hadolint recommendations
- Use `hadolint ignore=DL####` comments when necessary
- Set `SHELL` for proper pipefail handling

Full conventions and current runner routing are in [Code Style](docs/CODE_STYLE.md).

## Build System Architecture

### Build Flow

1. **Base OS Image** (`docker/base/os/Dockerfile.*`)
   - Starts from official Alpine/Debian
   - Installs build tools (gcc, make, autoconf, etc.)

2. **PHP Base Image** (`docker/base/php/Dockerfile.*`)
   - Builds on top of OS base image
   - Compiles PHP from source with extension build capabilities

3. **Extension Build** (`docker/Dockerfile.*`)
   - Uses PHP base image
   - Installs extension-specific dependencies
   - Clones extension source
   - Runs `phpize`, `configure`, `make`, `make install`
   - Copies the `.so` from `php-config --extension-dir` to the output directory and strips it (`strip --strip-unneeded`)
   - Verifies module loading with `php -m`; does not run upstream extension test suites

External libraries are built before the extension. Builds can export regular shared-library files from `/usr/local/lib` into `libs/`; metadata records runtime packages and extracted filenames.

### Key Scripts

#### build.sh

Main build orchestrator. Arguments:
```text
./scripts/build.sh <extension> <version> <php_version> <platform> <platform_version> [arch] [channel] [--local]
```

Features:
- Checks the extension key, PHP/platform support, architecture aliases, and exclusions; choose OS versions from `os-versions.json`
- Checks exclusion rules (via `scripts/check-exclusion.sh`)
- Builds with Docker buildx for cross-platform
- Generates `metadata.json` and per-arch build reports
- Supports `--local` flag for local base images

Notes:
- Ordinary `extension_version` values are git tags/branches; `dev` and `dev-<sha>` use the default-branch checkout path described above.
- The local channel argument defaults to `release`; pass `dev` explicitly for dev report labels. `build.yml` infers both `dev` and `dev-*`.
- Unsupported PHP/platform/architecture and excluded targets write `status: "skipped"` reports and exit zero. Build failures exit nonzero; unknown extensions/missing arguments fail without a build report.
- Output paths omit the extension version and can contain older files from a prior local build. Inspect the new report, not just file existence.
- Local output is unpackaged; only CI creates archives and pushes dataset entries.

#### build-base-image.sh and local-test.sh

- `build-base-image.sh` loads architecture-suffixed PHP images and an unsuffixed local alias. It does not push images; the alias represents the last architecture built, not a multi-arch manifest.
- `--local` changes the PHP image tag namespace, not the PHP Dockerfiles' GHCR OS-image dependency.
- `local-test.sh` checks only that the unsuffixed base tag exists, then builds and displays output. It does not check architecture/freshness, run an additional load test, or run a test suite; its channel is always `release`.
- Use a Buildx builder that can resolve locally loaded images. See [Local Testing](docs/LOCAL_TESTING.md) for engine-backed builder selection and explicit container checks.

#### install.sh

End-user installation script:
- Detects numeric PHP major/minor, OS, and architecture; does not select `phpnext` assets
- Downloads correct binary from GitHub Releases
- Installs runtime dependencies
- Copies extension and enables it
- Uses `zend_extension=` from metadata for Zend modules and keeps an existing `50-<pecl_name>.ini`
- Can warn without failing for missing runtime packages or an unloaded module; verify loading separately
- Maps Ubuntu to Debian assets on a best-effort basis, not a separately supported build matrix

A standalone installer uses the extension key as `pecl_name` without local configuration and only normalizes versions if `normalize-version.sh` is beside it. Full compatibility/permission requirements are in the [installation guide](README.md#-installation).

#### check-exclusion.sh

Determines if a build combination should be skipped:
- Platform-level exclusions (from os-versions.json)
- Extension-level exclusions (from extensions.json)
- Supports wildcards (`arm32*`, `*`)

Matching is implemented in `scripts/exclusions.jq`, which the build and tests
workflows also include to generate the build matrix. Change the rules there,
not in a workflow.

Exit codes are intentionally `0` for excluded and `1` for allowed; unexpected statuses are errors. Call it in an `if` block under `set -e`, not as a bare command.

## GitHub Actions Workflows

| Workflow | Trigger/role | Guide |
|----------|--------------|-------|
| `build.yml` | Dispatch/reusable; build one extension and publish reports | [Build](docs/BUILD.md) |
| `release.yml` | Dispatch/reusable; skip or replace a release | [Release](docs/RELEASE.md) |
| `build-all.yml` | Sunday 02:00 UTC/dispatch; dispatch per-extension release runs, optional manual dev builds | [Build All](docs/BUILD_ALL.md) |
| `build-os-base-images.yml` | Saturday 02:00 UTC, paths, dispatch/reusable; OS images | [OS Images](docs/BUILD_OS_BASE_IMAGES.md) |
| `build-php-base-images.yml` | Saturday 03:00 UTC, paths, dispatch/reusable; PHP images | [PHP Images](docs/BUILD_PHP_BASE_IMAGES.md) |
| `check-releases.yml` | Monday hourly/dispatch; up to 20 eligible extension checks | [Extension Tracking](docs/CHECK_RELEASES.md) |
| `check-php-releases.yml` | Daily 04:00 UTC/dispatch; existing PHP patch updates | [PHP Tracking](docs/CHECK_PHP_RELEASES.md) |
| `check-os-releases.yml` | Sunday 05:00 UTC/dispatch; OS-version PRs | [OS Tracking](docs/CHECK_OS_RELEASES.md) |
| `cleanup-ghcr.yml` | Sunday 06:00 UTC/dispatch; ghost/partial images | [Cleanup](docs/CLEANUP_GHCR.md) |
| `lint.yml` | Matching main pushes/PRs; ShellCheck, Hadolint, basic JSON/README checks | [Lint](docs/LINT.md) |
| `tests.yml` | Matching main pushes/PRs; Docker-free regressions and a live API check | [Tests](docs/TESTS.md) |

Docker builds use `ubuntu-24.04` for amd64 and `ubuntu-24.04-arm` for ARM; QEMU is enabled only for 32-bit ARM. Lightweight jobs use `ubuntu-slim`; release publication uses `ubuntu-24.04`, and matrix builds time out after 60 minutes. Build/release workflows expose no `runner` input; reusable `build.yml` also does not expose the dispatch-only PHP/platform filters.

Scheduled events do not receive dispatch defaults. `build-all.yml` currently skips scheduled dev builds through its `inputs.build_dev != false` gate; manual dispatch defaults to dev enabled. Dev discovery is GitHub-only. Scheduled base-image/release runs skip existing tags/releases unless explicitly forced; OS and PHP schedules are independent, not chained.

`release.yml` can publish successful partial matrices and does not prohibit dev/prerelease versions. Forced releases delete the existing release/tag before replacement. Base-image manifests instead require every selected architecture tag to exist, though existing tags may be stale.

`check-releases.yml` mutates cached extension data directly. The local `check-releases.sh` is a different, read-only JSON report and does not dispatch builds. `check-php-releases.yml` updates existing keys, not new PHP minors; OS version PRs still require review of package names and architecture support.

## Common Tasks

### Adding a New Extension

1. Add entry to `extensions.json`:
```json
"newext": {
  "pecl_name": "newext",
  "track_url": "https://github.com/org/newext",
  "type": "git",
  "dependencies": {
    "alpine": { "build": [], "runtime": [] },
    "debian": { "build": [], "runtime": [] }
  }
}
```

2. Run validation: `./scripts/validate-config.sh`
3. Set a valid upstream `latest_version` or supply an explicit ref, then test locally: `./scripts/local-test.sh newext v1.0.0 8.3 alpine 3.23`
4. Update the README extension table/count. The extension is picked up dynamically by `build-all.yml` unless `disabled` is set; success across the matrix is not automatic.

### Adding Build Exclusions

**Platform-level** (applies to all extensions) in `os-versions.json`:
```json
"exclude": [{"version": "3.23", "arch": "arm32v6"}]
```

**Extension-level** in `extensions.json`:
```json
"exclude": [{"os": "alpine", "version": "*", "arch": "arm32*"}]
```

### Testing Locally

```bash
# Local build orchestrator (builds a PHP base image if the alias is missing)
./scripts/local-test.sh redis 6.3.0 8.3 alpine 3.23

# Manual steps
./scripts/build-base-image.sh 8.3 alpine 3.23 amd64 --local
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 amd64 release --local
```

### Running Tests

```bash
# Run local Docker-free checks
./scripts/test-check-exclusion.sh
./scripts/test-normalize-version.sh
./scripts/test-version-tracking.sh
./scripts/test-build-smoke.sh

# Validate configuration
jq empty extensions.json php-versions.json os-versions.json
./scripts/validate-config.sh
```

`test-build-smoke.sh` is not currently wired into `tests.yml`. The config validator checks extension/OS exclusion structure, not a complete schema, PHP checksums, package availability, or every upstream ref.

## Important Conventions

### Version Normalization

Extension versions are normalized by `normalize-version.sh` (used for artifact/report naming):
- Strips extension name prefix: `yar-2.3.3` → `2.3.3`
- Strips `tags/`: `tags/VLD_0_11_0` → `VLD.0.11.0`
- Strips `v` prefix: `v6.3.0` → `6.3.0`
- Strips `release-` / `release_` prefixes
- Converts underscores to dots

Prefixes are stripped once in that order, not repeatedly until a semantic version remains. Preserve raw refs for checkout and normalize only naming surfaces.

### Build Reports

Builds generate JSON reports stored in the `dataset` branch:
- `history/{year}/{month}/{day}/{extension}-{version}-{run_id}.json`
- `reports/{extension}/{version}.json`
- `latest.json`

History files are arrays of collected reports. Version indexes keep one pointer per UTC day; `latest.json` keeps the last published entry across channels without ordering comparisons. Pre-filtered exclusions normally have no CI report. Local report directories retain raw version names, while normal success/failure report versions are normalized.

Archive metadata retains the raw ref, represents `runtime_deps` as a space-separated string, and uses `external_lib_files: null` when no bundled files were extracted. Refer to the [README schemas](README.md#-build-reports--dataset) rather than inventing new field meanings.

### External Libraries

Some extensions require libraries not in package managers. Define in `external_libs`:
```json
"external_libs": [{
  "name": "libsomelib",
  "type": "cmake",
  "repo_url": "https://github.com/org/libsomelib",
  "version": "v1.0.0",
  "build_commands": [
    "cmake -S . -B build -DCMAKE_BUILD_TYPE=Release",
    "cmake --build build",
    "cmake --install build"
  ]
}]
```

Each command runs in a separate `sh -c` process in the library checkout; `cd`/`export` does not persist between entries. `type` is informational and does not install a toolchain. Add required tools to platform build dependencies and use an upstream tag/branch in `version` when reproducibility matters.

## Troubleshooting

### Common Build Failures

1. **Missing dependencies**: Add to `dependencies.{platform}.build`
2. **Configure errors**: Check `configure_options` and dependency packages
3. **Excluded combination**: Check `os-versions.json` and extension `exclude`

### Debugging Locally

```bash
# Build with verbose output
BUILDKIT_PROGRESS=plain ./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 amd64 release --local

# Enter build container
docker run --rm -it --platform linux/amd64 php-ext-redis:8.3-alpine3.23-amd64 /bin/ash
```

## Security Considerations

- Never commit secrets to source code
- GitHub Actions uses pinned action versions with SHA hashes
- Keep GITHUB_TOKEN permissions job-scoped; build reports/releases, registry publication, and workflow dispatch need different write permissions
- Validate and quote inputs when changing scripts/workflows; do not assume existing checks validate every value or ABI
- Treat extension configuration and external-library build commands as trusted executable build inputs

## Performance Notes

- Base images are cached in GitHub Actions (GHA cache)
- PHP tarballs are downloaded (faster than git clone)
- Matrix builds run in parallel
- `--local` selects local PHP images and disables explicit cache import/export; it does not make source/package downloads offline or change the GHCR OS-image namespace
- Rebuild existing image tags explicitly when PHP sources, Dockerfiles, or OS packages change; tag-existence checks do not prove freshness
