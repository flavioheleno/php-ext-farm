# Build All Extensions (`build-all.yml`)

**Workflow file:** `.github/workflows/build-all.yml`

## Purpose
Weekly batch run that:
- builds/releases all extensions (release channel)
- optionally builds all extensions in a dev channel (HEAD-derived version)

## Triggers
- `schedule` (weekly Sunday 02:00 UTC)
- `workflow_dispatch`

## Inputs (workflow_dispatch)
- `force_rebuild` (boolean): force rebuilding releases even if they exist
- `runner`: `ubuntu-latest` or `self-hosted`
- `build_dev` (boolean): also run dev builds

## Permissions
- `actions: write` (to trigger workflows)
- `contents: write`

## Concurrency
- `group: build-all`

## Jobs
### 1) `prepare`
- loads the full extension list from `extensions.json`
- (optional) prepares dev versions for each extension:
  - determines upstream default branch via GitHub API (`gh api repos/<path>`)
  - takes HEAD SHA and uses `dev-<7charsha>`

Outputs:
- `extensions`: JSON array of extension keys
- `dev_builds`: JSON array of `{extension, version}`

### 2) `build-release` (matrix)
- for each extension, calls reusable workflow `release.yml`

### 3) `build-dev` (matrix, optional)
- for each entry in `dev_builds`, calls reusable workflow `build.yml`

## Outputs
- Release channel: GitHub Releases per extension/version
- Dev channel: build artifacts + dataset entries (no GitHub Releases)

## How to run manually
```bash
# trigger a full run
gh workflow run build-all.yml

# release-only
gh workflow run build-all.yml -f build_dev=false

# force rebuild releases
gh workflow run build-all.yml -f force_rebuild=true
```

## Caveats
- Dev version strings (`dev-<sha>`) are passed through as `extension_version` and treated as a **git ref** by the build container; this only works if the upstream repository has a matching tag/branch. If it doesn’t, dev builds will fail unless the build logic is extended to explicitly `git checkout <sha>`.
- Dev SHA discovery uses GitHub APIs (and a partial Bitbucket URL normalization); extensions tracked on GitLab may be skipped/fail for dev build preparation.