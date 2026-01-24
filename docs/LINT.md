# Lint (`lint.yml`)

**Workflow file:** `.github/workflows/lint.yml`

## Purpose
Run repository quality checks:
- ShellCheck on scripts
- Hadolint on Dockerfiles
- JSON syntax/structure validation
- README sync check for extension count

## Triggers
- `push` to `main` (limited paths)
- `pull_request` targeting `main` (limited paths)

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

### 4) `readme-sync`
- Compares:
  - actual extension count (`jq '.extensions | keys | length'`)
  - README count from `## 📦 Supported Extensions (<N>)`
- Emits a warning if out of sync

## How to run locally
There is no single local wrapper, but you can run the core checks:
```bash
./scripts/validate-config.sh
./scripts/test-check-exclusion.sh
./scripts/test-normalize-version.sh
./scripts/test-version-tracking.sh
```

## Notes
- ShellCheck/Hadolint are only run in CI via GitHub Actions.