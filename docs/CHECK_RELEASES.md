# Check Releases (`check-releases.yml`)

**Workflow file:** [`.github/workflows/check-releases.yml`](../.github/workflows/check-releases.yml)

## Purpose
Incrementally check upstream extension repositories for new releases/tags, update `extensions.json`, and trigger release builds for updated extensions.

Each run processes up to 20 eligible supported-host candidates. Disabled and pinned extensions are never eligible, so their `last_checked` and `latest_version` stay unchanged. Eligibility depends on `last_checked`, not whether the previous lookup succeeded.

## Triggers
- `schedule` (hourly on Mondays)
- `workflow_dispatch`

There are no inputs. The job runs on `ubuntu-slim`; concurrency group `check-releases` has `cancel-in-progress: false`.

## Permissions
The workflow defaults to `contents: read`. The `check-extension-releases` job elevates to `contents: write` to update `extensions.json` and `actions: write` to dispatch `release.yml`.

## Jobs
### 1) `check-extension-releases`
Steps:
- Computes a cutoff with `date -u -d "last monday"` at 00:00 UTC, with a BSD-date fallback
- Iterates extensions from `extensions.json`
  - skips those with `disabled` set or `pin_version: true` (their `latest_version` is maintained by hand)
  - skips those with `last_checked` strictly after that cutoff
  - stops after 20 extensions
- For each extension:
  - fetches latest tag via:
    - GitHub latest-release API, then the first tag from `/tags?per_page=1`
    - GitLab releases/tags API
    - Bitbucket tags API
  - updates `.extensions[ext].last_checked`
  - updates `.extensions[ext].latest_version` when changed

Commit strategy:
- Uses the GitHub Contents API to replace `extensions.json` on the default branch (base64 content plus the current file SHA)
- Retries up to three times, refreshing the remote SHA between attempts

Trigger strategy:
- For each updated extension, triggers:
  - `gh workflow run release.yml -f extension=<ext> -f extension_version=<tag>`

No release is dispatched for timestamp-only changes or unsuccessful version lookups. The Contents API retry refreshes the SHA, not the payload from other writers; it does not merge simultaneous configuration edits.

## How to run manually
```bash
gh workflow run check-releases.yml
```

## Notes
- This workflow writes directly to the default branch; it does not open PRs.
- `last_checked` is updated even when no version can be obtained. A recent timestamp is not proof of a successful upstream lookup.
- The literal `last monday` cutoff is not an explicit calendar-week calculation; on GNU date, Monday runs use the previous Monday. Do not assume every extension is rechecked once per calendar week.
- The first GitHub tag is not selected by semantic version or by resolving every tag's commit date. Fallbacks can select prerelease/non-version tags; `latest_version` is an upstream ref, not a stability guarantee.
- Version strings remain unmodified for checkout; `normalize-version.sh` is used later for artifact, report, and release names.

## Local report script

[`scripts/check-releases.sh`](../scripts/check-releases.sh) is a **separate, read-only implementation**, not the script invoked by this workflow:

```bash
./scripts/check-releases.sh > release-check.json
jq '.extensions.redis' release-check.json
```

It requires Bash, curl, jq, and standard Unix tools; it scans all configured extensions, prints a JSON object with `checked_at` and per-extension `{latest_version, track_url}`, and uses `"unknown"` when no version is found. It does not update cached fields or dispatch releases.

For GitHub it tries the latest release, then paginates tags and chooses by commit date. GitLab uses the first tag; Bitbucket requests tags ordered by target date. This differs from the workflow's GitHub/GitLab fallback logic.

The script accepts optional `GITHUB_TOKEN` authentication and defines `CHECK_RELEASES_DELAY` (default `1`). Its request counter is updated inside command-substitution subshells, so the printed global counter and periodic rate-limit check are not a reliable request count or throttle. Authenticated access is important for large tag scans; CI's integration check runs this network-dependent script with the delay setting `0`.