# Check PHP Releases (`check-php-releases.yml`)

**Workflow file:** [`.github/workflows/check-php-releases.yml`](../.github/workflows/check-php-releases.yml)

## Purpose
Detect upstream PHP patch-tag changes using php.net active releases, update `php-versions.json`, and dispatch PHP base-image builds. Dispatch does not necessarily rebuild an existing image tag.

## Triggers
- `schedule` (daily 04:00 UTC)
- `workflow_dispatch`

There are no inputs. The single job runs on `ubuntu-slim`. Concurrency group `check-php-releases` has `cancel-in-progress: false`.

## Permissions
The workflow defaults to `contents: read`. The job grants `contents: write` to commit/push configuration and `actions: write` to dispatch PHP base-image builds.

## Jobs
### 1) `check-php-releases`
- Fetches `https://www.php.net/releases/active.php`
- Iterates keys of `php-versions.json`
  - skips `next` and entries without a configured branch
- For each version:
  - extracts latest patch version
  - builds tag `php-<version>`
  - extracts SHA256 for `.tar.xz`
- If tag changed:
  - updates `php-versions.json` tag and sha256
  - commits and pushes
  - dispatches `build-php-base-images.yml -f php_version=<target>`

Entries absent from php.net's active-release response, or lacking a usable version/checksum, are logged and skipped. A checksum change without a tag change does not trigger an update. The workflow updates existing entries only; it does not add new PHP minor versions or remove end-of-life ones.

## How to run manually
```bash
gh workflow run check-php-releases.yml
```

## Notes
- Only updates versions present in `php-versions.json`.
- Uses the `.tar.xz` SHA256 from `active.php` because the base images consume that artifact.
- `next` is refreshed only by a base-image build, not this release detector.
- Updates are committed directly, not proposed as a PR. Scheduled runs use the default branch.

## Existing-image limitation

The dispatch does **not** set `force_rebuild=true`. PHP image tags contain the target minor version (`8.3-alpine3.23`, for example), so the base-image workflow skips an already-existing architecture tag even after `php-versions.json` moves to a new patch.

To apply an updated PHP source selection to existing images:

```bash
gh workflow run build-php-base-images.yml \
  -f php_version=8.3 \
  -f force_rebuild=true
```

Wait for completion before rebuilding extension releases. See [Build PHP Base Images](BUILD_PHP_BASE_IMAGES.md) for source verification, runner selection, manifest checks, and OS-image prerequisites.