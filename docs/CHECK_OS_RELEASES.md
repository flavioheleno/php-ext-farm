# Check OS Releases (`check-os-releases.yml`)

**Workflow file:** `.github/workflows/check-os-releases.yml`

## Purpose
Detect new OS versions (Alpine stable and Debian stable codename), and open a PR updating `os-versions.json`.

## Triggers
- `schedule` (weekly Sunday 05:00 UTC)
- `workflow_dispatch`

## Inputs
- `runner` (optional): `ubuntu-latest`, `ubuntu-slim`, or `self-hosted`

## Permissions
- `contents: write`
- `pull-requests: write`

## Concurrency
- `group: check-os-releases`

## Jobs
### 1) `check-alpine-releases`
- Fetches Alpine `latest-releases.yaml`
- Extracts latest stable major.minor
- If not present in `os-versions.json`, outputs an update entry

### 2) `check-debian-releases`
- Scrapes Debian stable releases page for current stable codename
- If not present in `os-versions.json`, outputs an update entry

### 3) `create-pr`
Runs only if there are updates:
- Creates a branch `bot/update-os-versions-YYYYMMDD`
- Updates `os-versions.json`:
  - Alpine: appends and sorts
  - Debian: appends (no sort)
- Commits and pushes
- Opens a PR labeled `dependencies` and `automated`

## How to run manually
```bash
gh workflow run check-os-releases.yml
```

## Notes
- This workflow updates only `os-versions.json` (not `extensions.json`).
- The PR body includes a reminder to update other config if needed.