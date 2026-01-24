# Check Releases (`check-releases.yml`)

**Workflow file:** `.github/workflows/check-releases.yml`

## Purpose
Incrementally check upstream extension repositories for new releases/tags, update `extensions.json`, and trigger release builds for updated extensions.

This workflow is rate-limited by design: each run checks up to 20 extensions and marks them as checked for the current week.

## Triggers
- `schedule` (hourly on Mondays)
- `workflow_dispatch`

## Permissions
- `contents: write` (updates `extensions.json`)
- `actions: write` (triggers `release.yml`)

## Jobs
### 1) `check-extension-releases`
Steps:
- Computes week start (Monday 00:00 UTC)
- Iterates extensions from `extensions.json`
  - skips those with `last_checked` after week start
  - stops after 20 extensions
- For each extension:
  - fetches latest tag via:
    - GitHub releases API, then tags API
    - GitLab releases/tags API
    - Bitbucket tags API
  - updates `.extensions[ext].last_checked`
  - updates `.extensions[ext].latest_version` when changed

Commit strategy:
- Uses GitHub Contents API to update `extensions.json` atomically (base64 content + existing SHA)

Trigger strategy:
- For each updated extension, triggers:
  - `gh workflow run release.yml -f extension=<ext> -f extension_version=<tag>`

## How to run manually
```bash
gh workflow run check-releases.yml
```

## Notes
- This workflow mutates `extensions.json` directly on the default branch via Contents API; it does not open PRs.
- Version strings are stored as upstream tag names and later normalized only for artifact naming.