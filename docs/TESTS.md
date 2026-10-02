# Tests (`tests.yml`)

**Workflow file:** [`.github/workflows/tests.yml`](../.github/workflows/tests.yml)

## Purpose
Validate scripts and config behavior via unit and integration tests.

## Triggers
- `push` to `main` (limited paths)
- `pull_request` targeting `main` (limited paths)

Both events watch `scripts/**`, root `*.json`, and `.github/workflows/tests.yml`. There is no `workflow_dispatch`. Dockerfile-only changes do not trigger this workflow, despite its Dockerfile ordering job; they do trigger [Lint](LINT.md). Markdown-only changes also do not trigger it.

## Permissions
- `contents: read`

All four jobs run on `ubuntu-24.04`.

## Jobs
### 1) `unit-tests`
Runs:
- `./scripts/test-check-exclusion.sh`
- `./scripts/test-normalize-version.sh`
- `./scripts/test-version-tracking.sh`

These cover exclusion matching/exit codes, normalization (including `tags/` and dev versions), and configuration/version-tracking invariants. Some version-tracking conditions, such as stale checks or a small number of missing cached versions, are warnings rather than failures.

### 2) `integration-tests`
- Verifies `scripts/build.sh` shows usage on missing args
- Verifies `scripts/build.sh` rejects invalid extension
- Verifies `scripts/build.sh` reports an unsupported PHP version (the script writes a skipped report and exits zero)
- Verifies `scripts/install.sh` shows usage on missing args
- Runs `scripts/check-releases.sh` against live upstream APIs with `GITHUB_TOKEN` and `CHECK_RELEASES_DELAY=0`, then checks for a valid JSON `checked_at` field

The release check is network-dependent; this is not an entirely offline suite. It checks report shape, not whether every upstream version lookup succeeded.

### 3) `matrix-generation-tests`
- Calls the same `build_matrix` function in `scripts/exclusions.jq` as `build.yml`
- Selects PHP 8.3/8.4, Alpine, and amd64
- Requires at least eight entries; the current four Alpine versions produce exactly eight

### 4) `dockerfile-syntax-tests`
- Ensures `ARG BASE_IMAGE_REGISTRY` appears before the first `FROM` in:
  - `docker/Dockerfile.alpine`
  - `docker/Dockerfile.debian`

This is an ordering assertion, not a full Docker syntax check or container build. Hadolint coverage lives in `lint.yml`.

## How to run locally
```bash
./scripts/test-check-exclusion.sh
./scripts/test-normalize-version.sh
./scripts/test-version-tracking.sh
./scripts/test-build-smoke.sh
./scripts/validate-config.sh
```

`test-build-smoke.sh` is an additional Docker-free regression script for exclusion call-site handling under `set -e`, dev SHA extraction/version handling, and installer URL normalization. It exists in the repository but is **not currently invoked by `tests.yml`**.

To inspect the same selected matrix locally:

```bash
jq -n -L scripts \
  --slurpfile php_versions php-versions.json \
  --slurpfile os_versions os-versions.json \
  --slurpfile extensions extensions.json \
  'include "exclusions";
   build_matrix($php_versions[0]; $os_versions[0]; $extensions[0];
                "redis"; "8.3,8.4"; "alpine"; "amd64")
   | .include | length'
```

None of these jobs compile PHP/extensions in Docker or run upstream extension test suites. A real build/load test requires the [Local Testing](LOCAL_TESTING.md) flow or [Build Extension](BUILD.md).