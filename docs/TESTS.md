# Tests (`tests.yml`)

**Workflow file:** `.github/workflows/tests.yml`

## Purpose
Validate scripts and config behavior via unit and integration tests.

## Triggers
- `push` to `main` (limited paths)
- `pull_request` targeting `main` (limited paths)

## Permissions
- `contents: read`

## Jobs
### 1) `unit-tests`
Runs:
- `./scripts/test-check-exclusion.sh`
- `./scripts/test-normalize-version.sh`
- `./scripts/test-version-tracking.sh`

### 2) `integration-tests`
- Verifies `scripts/build.sh` shows usage on missing args
- Verifies `scripts/build.sh` rejects invalid extension
- Verifies `scripts/build.sh` rejects unsupported PHP version
- Verifies `scripts/install.sh` shows usage on missing args
- Runs `scripts/check-releases.sh` and verifies it outputs valid JSON (via `jq`)

### 3) `matrix-generation-tests`
- Reproduces the matrix generation `jq` logic from `build.yml`
- Performs a sanity check on the entry count

### 4) `dockerfile-syntax-tests`
- Ensures `ARG BASE_IMAGE_REGISTRY` appears before the first `FROM` in:
  - `docker/Dockerfile.alpine`
  - `docker/Dockerfile.debian`

## How to run locally
```bash
./scripts/test-check-exclusion.sh
./scripts/test-normalize-version.sh
./scripts/test-version-tracking.sh
```

## Notes
- Integration tests are intentionally lightweight and do not build Docker images.