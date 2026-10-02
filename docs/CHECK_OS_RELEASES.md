# Check OS Releases (`check-os-releases.yml`)

**Workflow file:** [`.github/workflows/check-os-releases.yml`](../.github/workflows/check-os-releases.yml)

## Purpose
Detect the current Alpine stable major/minor and Debian stable codename, and open a PR adding missing entries to `os-versions.json`. This does not verify every architecture or compile extensions for the new OS.

## Triggers
- `schedule` (weekly Sunday 05:00 UTC)
- `workflow_dispatch`

## Inputs
- None; both detection jobs and the PR job run on `ubuntu-slim`

## Permissions
- Default workflow permission: `contents: read`
- `create-pr` job: `contents: write`, `pull-requests: write`

## Concurrency
- `group: check-os-releases`
- `cancel-in-progress: false`

## Jobs
### 1) `check-alpine-releases`
- Fetches Alpine `latest-stable/releases/x86_64/latest-releases.yaml`
- Uses a jq-style `yq` filter to select the `alpine-standard` entry and extract stable `major.minor`
- If not present in `os-versions.json`, outputs an update entry

### 2) `check-debian-releases`
- Fetches Debian repository metadata from `dists/stable/Release`
- Extracts the current stable codename from the `Codename:` field
- If not present in `os-versions.json`, outputs an update entry

### 3) `create-pr`
Runs only if there are updates:
- Creates a branch `bot/update-os-versions-YYYYMMDD`
- Updates `os-versions.json`:
  - Alpine: appends and sorts
  - Debian: appends (no sort)
- Commits and pushes
- Opens a PR labeled `dependencies` and `automated`

Existing versions are retained; the workflow does not remove older/EOL entries, add architecture exclusions, or update extension dependency overrides. Same-day runs reuse the date-based branch name, so inspect an existing bot branch/PR before repeating a run.

## How to run manually
```bash
gh workflow run check-os-releases.yml
```

## Notes
- This workflow updates only `os-versions.json` (not `extensions.json`).
- OS version lists belong only in `os-versions.json`; there is no `extensions.json` platforms section. The PR reminder asks reviewers to check architecture availability, exclusions, and dependency overrides.
- Review new versions for architecture availability, required exclusions, and platform package-name changes (`dependencies.<platform>.version_overrides`) before merging.
- The Alpine detector checks x86_64 release metadata; it does not establish ARM image availability.
- No image-build workflow is dispatched directly. A matching push/merge to `os-versions.json` can trigger [OS base images](BUILD_OS_BASE_IMAGES.md); existing tags are still skipped unless forced. Build PHP images separately after the OS images are available.
- The runner must provide curl, jq, git, gh, and a compatible jq-style `yq` command for the Alpine check.
