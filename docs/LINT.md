# Lint (`lint.yml`)

**Workflow file:** [`.github/workflows/lint.yml`](../.github/workflows/lint.yml)

## Purpose
Run repository quality checks:
- ShellCheck on scripts
- Hadolint on Dockerfiles
- JSON syntax/structure validation
- README sync check for extension count

## Triggers
- `push` to `main` (limited paths)
- `pull_request` targeting `main` (limited paths)

Both events watch `scripts/**`, `docker/**`, root `*.json`, and `.github/workflows/lint.yml`. Markdown-only changes and changes to other workflow files do not trigger it. There is no manual-dispatch trigger. Every job uses `ubuntu-24.04`.

## Permissions
- `contents: read`

## Jobs
### 1) `shellcheck`
- Uses `ludeeus/action-shellcheck`
- Scans `./scripts`
- Severity: `warning`
- `SHELLCHECK_OPTS`: excludes `SC1091` and `SC2002`

### 2) `hadolint`
- Matrix over Dockerfiles:
  - `docker/Dockerfile.alpine`
  - `docker/Dockerfile.debian`
  - `docker/base/os/Dockerfile.*`
  - `docker/base/php/Dockerfile.*`
- Uses `hadolint/hadolint-action`
- Failure threshold: `warning`

### 3) `json-validate`
- Validates JSON syntax for `extensions.json`, `php-versions.json`, `os-versions.json`
- Performs basic schema checks via `jq`
- Runs `./scripts/validate-config.sh`

The structure checks require the extension file's top-level registry/architecture/extension keys, extension `pecl_name`/`track_url`/`type`/`dependencies`, a `branch` field for every PHP entry, and both OS version arrays. These are basic `jq` checks, not a formal JSON Schema or verification of upstream refs, SHA256 values, package availability, or successful builds.

The configuration script checks extension/OS JSON and exclusion fields. It does not independently validate PHP configuration; the preceding CI syntax/structure steps cover that file.

### 4) `readme-sync`
- Compares:
  - actual extension count (`jq '.extensions | keys | length'`)
  - README count from `## 📦 Supported Extensions (<N>)`
- Emits a warning if out of sync

This is a count-only, non-failing warning. It does not compare table entries or repository URLs and does not run for a README-only change because of the path filter.

## How to run locally
There is no single local wrapper. With the relevant tools installed, run from the repository root:
```bash
shellcheck --severity=warning --exclude=SC1091,SC2002 scripts/*.sh
hadolint --failure-threshold warning \
  docker/Dockerfile.* docker/base/os/Dockerfile.* docker/base/php/Dockerfile.*
jq empty extensions.json php-versions.json os-versions.json
./scripts/validate-config.sh
```

For a local README-count assertion equivalent to the CI comparison:

```bash
test "$(jq '.extensions | length' extensions.json)" = \
  "$(grep -oP '## 📦 Supported Extensions \(\K[0-9]+' README.md)"
```

That command requires GNU grep's `-P` support, as used by CI. Keep the heading format intact and update the table and count when adding/removing extensions. Shell regression commands are documented in [Tests](TESTS.md).