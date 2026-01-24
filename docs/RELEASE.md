# Release (`release.yml`)

**Workflow file:** `.github/workflows/release.yml`

## Purpose
Create (or rebuild) a GitHub Release for a specific extension+version.

High level:
1. Resolve the target version
2. Check whether the GitHub Release already exists
3. If needed, call `build.yml` to build artifacts
4. Publish a GitHub Release with all `.tar.gz` assets

## Triggers
- `workflow_dispatch`
- `workflow_call` (used by `build-all.yml`)

## Inputs
- `extension` (required)
- `extension_version` (optional): empty resolves to `.extensions[extension].latest_version` or `dev`
- `rebuild` (optional boolean): force rebuild/release even if it exists
- `runner` (optional)

## Permissions
- `contents: write` (needed for release create/delete and tag deletion)

## Concurrency
- `group: release-${{ inputs.extension }}-${{ inputs.extension_version || 'latest' }}`

## Jobs
### 1) `check-release`
- resolves the effective `extension_version` (same logic as `build.yml`)
- normalizes version for tag naming via `scripts/normalize-version.sh`
- computes release tag: `${extension}-${normalized_version}`
- checks GitHub Releases via `gh release view`
- outputs:
  - `should_build` (`true`/`false`)
  - `release_tag`
  - `clean_version` (normalized)
  - `extension_version` (resolved input)

### 2) `build` (reusable workflow)
- calls `./.github/workflows/build.yml` when `should_build == true`

### 3) `release`
- downloads the combined artifact `${extension}-${clean_version}-all-builds`
- generates `release_notes.md` summarizing supported configurations
- when `rebuild=true`:
  - deletes existing GitHub release
  - deletes the git tag on origin
- creates a new GitHub Release with all `release/*.tar.gz` assets

## Outputs
- GitHub Release tag: `${extension}-${normalized_version}`
- Release assets: one `.tar.gz` per PHP/platform/arch combination

## How to run manually
```bash
gh workflow run release.yml \
  -f extension=redis \
  -f extension_version=6.3.0

# force rebuild
gh workflow run release.yml \
  -f extension=redis \
  -f extension_version=6.3.0 \
  -f rebuild=true
```

## Notes
- The release tag is based on the **normalized** version, not the raw `extension_version` input.
- If the build produced no artifacts for a subset of the matrix, they will simply be absent from the release assets.