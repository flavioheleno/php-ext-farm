# Check PHP Releases (`check-php-releases.yml`)

**Workflow file:** `.github/workflows/check-php-releases.yml`

## Purpose
Detect new upstream PHP patch releases using `php.net` active releases, update `php-versions.json`, and trigger rebuilding PHP base images.

## Triggers
- `schedule` (daily 04:00 UTC)
- `workflow_dispatch`

## Permissions
- `contents: write` (commit updates to `php-versions.json`)
- `actions: write` (trigger PHP base image builds)

## Jobs
### 1) `check-php-releases`
- Fetches `https://www.php.net/releases/active.php`
- Iterates keys of `php-versions.json`
  - skips `next`
- For each version:
  - extracts latest patch version
  - builds tag `php-<version>`
  - extracts SHA256 for `.tar.xz`
- If tag changed:
  - updates `php-versions.json` tag and sha256
  - commits and pushes
  - triggers `build-php-base-images.yml` for the updated version

## How to run manually
```bash
gh workflow run check-php-releases.yml
```

## Notes
- Only updates versions present in `php-versions.json`.
- Uses the `.tar.xz` SHA256 from `active.php` because the base images consume that artifact.