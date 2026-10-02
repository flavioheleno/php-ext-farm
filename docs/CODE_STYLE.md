# Code Style Guide

## Shell Scripts

### Script Types

We maintain two types of shell scripts with different portability requirements:

#### POSIX Shell Scripts (`#!/bin/sh`)

**Used for:** Scripts that run on end-user systems (Alpine, Debian, Ubuntu, etc.)

**Scripts:**
- `install.sh` - Installation script for pre-built extensions
- `normalize-version.sh` - Version normalization utility

**Style:**
- Use `[ ]` for conditionals (POSIX compatible)
- Use `set -eu` (no pipefail, not POSIX)
- Avoid bash-specific features
- Use `$(command)` instead of backticks
- Always use `${VAR}` braces for variable expansion

**Example:**
```sh
#!/bin/sh
set -eu

if [ -z "${VAR:-}" ]; then
    echo "Error: VAR is required." >&2
    exit 1
fi
```

#### Bash Scripts (`#!/bin/bash`)

**Used for:** Build scripts, CI/CD automation, development tools

**Scripts:**
- `build.sh`
- `build-base-image.sh`
- `check-exclusion.sh`
- `check-releases.sh`
- `local-test.sh`
- `release-all.sh`
- `test-*.sh`
- `validate-config.sh`

**Style:**
- Use `[[ ]]` for conditionals (bash extended test)
- Use `set -euo pipefail` for strict error handling
- Bash features allowed (arrays, `${VAR,,}`, etc.)
- Always use `${VAR}` braces for variable expansion
- Quote variable expansions unless word splitting intended

**Example:**
```bash
#!/bin/bash
set -euo pipefail

if [[ -z "${VAR:-}" ]]; then
    echo "Error: VAR is required." >&2
    exit 1
fi
```

### Exclusions and JSON

`check-exclusion.sh` intentionally returns `0` for **excluded**, `1` for **allowed**, and other nonzero statuses for errors. Call it in an `if`/`else` block under `set -e`, handle `1` as allowed, and surface unexpected errors. Do not use a bare call or suppress every nonzero result.

Extension matrix generation and local exclusion checks share `scripts/exclusions.jq`; change matching rules there rather than duplicating them in `build.yml` or `tests.yml`. The base-image workflows currently have separate exact-match platform filters.

Use `jq` for JSON that requires escaping or structured updates. Distinguish raw source refs from normalized artifact versions, and preserve the metadata types (`runtime_deps` is a string, `zend_extension` a boolean).

## GitHub Actions Workflows

### Variable References

- Use spaces after `{{` and before `}}`: `${{ inputs.var }}`
- Pass untrusted workflow values through environment variables where possible and quote their shell expansions; do not introduce shell code assembled from user input.
- Use proper yaml indentation (2 spaces)
- Pin external actions to full commit SHAs, retaining the human-readable version comment.
- Keep write permissions on the jobs that require them, following existing `contents`/`packages`/`actions` permission overrides.

### Runner Options

Current workflows use fixed runners, not a `runner` input:
- `ubuntu-24.04` for amd64 Docker builds, lint, and tests
- `ubuntu-24.04-arm` for ARM Docker builds (arm64 natively; QEMU only for 32-bit ARM)
- `ubuntu-slim` for lightweight preparation, dispatch, report, detection, manifest, and cleanup jobs (it has a 15-minute job limit; the release publication job uses `ubuntu-24.04` for that reason)

Preserve architecture-aware routing when changing matrix jobs. Avoid adding a runner selector unless the workflows actually implement it.

### Naming Conventions

- Jobs: `kebab-case` (e.g., `build-os`, `create-manifest`)
- Workflows: `Sentence Case` (e.g., `Build OS Base Images`)
- Variables: `UPPER_SNAKE_CASE` for environment, `lower` for inputs

Keep dispatch/reusable input differences explicit in workflow documentation. Comma-separated filters are not whitespace-trimmed by the matrix helper. Scheduled events do not receive dispatch defaults; account for that when comparing optional boolean inputs.

## JSON Configuration

- Use 2-space indentation
- No trailing commas
- Alphabetically sort keys where logical (e.g., extensions, versions)
- Keep `exclude` arrays compact on single line when short
- Keep PHP sources in `php-versions.json`, OS versions/exclusions in `os-versions.json`, and extension/architecture definitions in `extensions.json`.
- Dependency `version_overrides` replace one package-list field at a time; they do not append to the default list.

## Dockerfiles

Declare any `ARG` used in `FROM` before that instruction and redeclare it afterward if the build stage needs its value. `BASE_IMAGE_REGISTRY` is a namespace without `/php`, not the full PHP image repository.

Keep the platform's `SHELL`/pipefail settings and document necessary Hadolint exceptions with a focused `hadolint ignore=DL####` comment. Do not change build behavior merely to reformat a Dockerfile.

External-library command entries run separately via `sh -c`; directory/environment changes do not persist between entries. Use explicit paths/build-directory options rather than relying on a prior entry's `cd`.

## General Principles

1. **Consistency over perfection** - Follow existing patterns
2. **Portability matters** - Choose sh vs bash appropriately
3. **Fail fast** - Use strict error handling
4. **Always use braces** - Use `${VAR}` not `$VAR` for clarity
5. **Quote variables** - Prevent word splitting issues
6. **Document exceptions** - Add comments when deviating
7. **Keep docs grounded** - Update related guides/help/templates when behavior changes; configured targets are not proof of successful binaries.
