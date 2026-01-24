# AGENTS.md

This document provides comprehensive guidance for AI agents and LLMs working with the PHP Extension Farm codebase.

## Project Overview

**PHP Extension Farm** is an automated build system that compiles PHP extensions from source for multiple PHP versions, operating systems, and CPU architectures. The project produces pre-built `.so` files published as GitHub Releases, enabling users to install PHP extensions without compiling them locally.

### Key Capabilities

- Builds **106+ PHP extensions** across multiple PHP versions (8.2, 8.3, 8.4, 8.5, next)
- Supports **Alpine Linux** (3.19-3.23) and **Debian** (bullseye, bookworm, trixie)
- Builds for **4 architectures**: amd64, arm64, arm32v7, arm32v6
- Handles **external library dependencies** for extensions that need them
- Tracks extension releases automatically from GitHub, GitLab, and Bitbucket

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
│   ├── check-releases.sh    # Checks for new extension releases
│   ├── normalize-version.sh # Normalizes version strings
│   ├── validate-config.sh   # Validates JSON config files
│   └── local-test.sh        # Orchestrates local testing
├── .github/workflows/
│   ├── build.yml            # Single extension build workflow
│   ├── build-all.yml        # Weekly batch build of all extensions
│   ├── release.yml          # Creates GitHub releases
│   ├── lint.yml             # ShellCheck, Hadolint, JSON validation
│   └── tests.yml            # Unit and integration tests
└── docs/
    ├── CODE_STYLE.md        # Shell script style guide
    └── LOCAL_TESTING.md     # Local development guide
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
      "type": "git",
      "dependencies": {
        "alpine": { "build": ["..."], "runtime": ["..."] },
        "debian": { "build": ["..."], "runtime": ["..."] }
      },
      "configure_options": ["--enable-redis-igbinary"],
      "zend_extension": false,
      "build_path": "ext/",
      "external_libs": [...],
      "exclude": [
        {"os": "alpine", "version": "3.19", "arch": "arm32*"}
      ],
      "latest_version": "6.0.2",
      "last_checked": "2026-01-14T04:40:43Z"
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
- `configure_options`: Extra flags for `./configure`.
- `zend_extension`: Set to `true` for Zend extensions (e.g. xdebug) so runtime config uses `zend_extension=` instead of `extension=`.
- `build_path`: Subdirectory containing `config.m4` if not at root.
- `external_libs`: Libraries that must be built from source.
- `exclude`: Build combinations to skip. Wildcards are supported by `scripts/check-exclusion.sh`; GitHub Actions matrix generation currently filters **only exact-match platform exclusions**.

**Gotchas:**
- `normalize-version.sh` is used for **artifact/report naming**; the build itself uses the original `extension_version` as a git ref.
- `base_image_registry` in `extensions.json` points to the PHP base-image repository (e.g. `.../php`) but is not currently consumed by `scripts/build.sh`; extension Dockerfiles use a `BASE_IMAGE_REGISTRY` build-arg that expects the registry namespace **without** the trailing `/php` (it appends `/php` in `FROM`).

### php-versions.json

Defines supported PHP versions:

```json
{
  "8.3": {
    "tag": "php-8.3.30",
    "branch": "PHP-8.3",
    "sha256": "67f084d..."
  },
  "next": {
    "tag": null,
    "branch": "master"
  }
}
```

- Versions with `tag` download official tarballs (faster)
- Versions with `tag: null` build from git (development versions)

### os-versions.json

Defines supported OS versions and platform-level exclusions:

```json
{
  "alpine": {
    "versions": ["3.19", "3.20", "3.21", "3.22", "3.23"],
    "exclude": []
  },
  "debian": {
    "versions": ["bullseye", "bookworm", "trixie"],
    "exclude": [
      {"version": "trixie", "arch": "arm32v6"}
    ]
  }
}
```

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
- `check-exclusion.sh`, `check-releases.sh`
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
   - Copies `.so` file to output directory

### Key Scripts

#### build.sh

Main build orchestrator. Arguments:
```bash
./build.sh <extension> <version> <php_version> <platform> <platform_version> [arch] [channel] [--local]
```

Features:
- Validates inputs against config files
- Checks exclusion rules (via `scripts/check-exclusion.sh`)
- Builds with Docker buildx for cross-platform
- Generates `metadata.json` and per-arch build reports
- Supports `--local` flag for local base images

Notes:
- `extension_version` is treated as a **git ref** (tag/branch). The special literal value `dev` builds from the repo default branch; values like `dev-<sha>` only work if such a ref exists (otherwise add explicit checkout logic).

#### install.sh

End-user installation script:
- Auto-detects PHP version, OS, and architecture
- Downloads correct binary from GitHub Releases
- Installs runtime dependencies
- Copies extension and enables it

#### check-exclusion.sh

Determines if a build combination should be skipped:
- Platform-level exclusions (from os-versions.json)
- Extension-level exclusions (from extensions.json)
- Supports wildcards (`arm32*`, `*`)

## GitHub Actions Workflows

### build.yml

Single extension build workflow:
- Generates build matrix from config files
- Runs parallel builds across PHP/OS/arch combinations
- Uploads artifacts and build reports
- Pushes reports to `dataset` branch

### release.yml

Release workflow:
- Checks if release already exists
- Calls build.yml
- Creates GitHub Release with all artifacts

### build-all.yml

Weekly scheduled workflow:
- Builds all extensions (release + dev channels)
- Runs on Sunday 2 AM UTC

### lint.yml

Code quality checks:
- ShellCheck for shell scripts
- Hadolint for Dockerfiles
- JSON syntax and schema validation

### tests.yml

Test suite:
- Unit tests for scripts
- Integration tests for argument validation
- Matrix generation tests

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
3. Test locally: `./scripts/local-test.sh newext v1.0.0 8.3 alpine 3.20`

### Adding Build Exclusions

**Platform-level** (applies to all extensions) in `os-versions.json`:
```json
"exclude": [{"version": "3.19", "arch": "arm32v6"}]
```

**Extension-level** in `extensions.json`:
```json
"exclude": [{"os": "alpine", "version": "*", "arch": "arm32*"}]
```

### Testing Locally

```bash
# Full test workflow (builds base image if needed)
./scripts/local-test.sh redis 6.0.2 8.3 alpine 3.20

# Manual steps
./scripts/build-base-image.sh 8.3 alpine 3.20 --local
./scripts/build.sh redis 6.0.2 8.3 alpine 3.20 --local
```

### Running Tests

```bash
# Run all tests
./scripts/test-check-exclusion.sh
./scripts/test-normalize-version.sh
./scripts/test-version-tracking.sh

# Validate configuration
./scripts/validate-config.sh
```

## Important Conventions

### Version Normalization

Extension versions are normalized by `normalize-version.sh` (used for artifact/report naming):
- Strips `v` prefix: `v6.0.2` → `6.0.2`
- Strips extension name prefix: `yar-2.3.3` → `2.3.3`
- Strips `release-` / `release_` prefixes
- Converts underscores to dots

### Build Reports

Builds generate JSON reports stored in the `dataset` branch:
- `history/{year}/{month}/{day}/{extension}-{version}-{run_id}.json`
- `reports/{extension}/{version}.json`
- `latest.json`

### External Libraries

Some extensions require libraries not in package managers. Define in `external_libs`:
```json
"external_libs": [{
  "name": "libsomelib",
  "type": "cmake",
  "repo_url": "https://github.com/org/libsomelib",
  "version": "v1.0.0",
  "build_commands": [
    "cmake -B build -DCMAKE_BUILD_TYPE=Release",
    "cmake --build build",
    "cmake --install build"
  ]
}]
```

## Troubleshooting

### Common Build Failures

1. **Missing dependencies**: Add to `dependencies.{platform}.build`
2. **Configure errors**: Check `configure_options` and dependency packages
3. **Excluded combination**: Check `os-versions.json` and extension `exclude`

### Debugging Locally

```bash
# Build with verbose output
docker buildx build --progress=plain ...

# Enter build container
docker run -it php-ext-farm/php:8.3-alpine3.20 /bin/ash
```

## Security Considerations

- Never commit secrets to source code
- GitHub Actions uses pinned action versions with SHA hashes
- GITHUB_TOKEN has minimal required permissions
- Scripts validate all inputs before use

## Performance Notes

- Base images are cached in GitHub Actions (GHA cache)
- PHP tarballs are downloaded (faster than git clone)
- Matrix builds run in parallel
- Local builds can use `--local` flag to skip registry pulls
