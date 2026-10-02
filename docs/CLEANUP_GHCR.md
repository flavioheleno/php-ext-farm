# Cleanup GHCR (`cleanup-ghcr.yml`)

**Workflow file:** [`.github/workflows/cleanup-ghcr.yml`](../.github/workflows/cleanup-ghcr.yml)

## Purpose
Clean up GHCR packages by deleting:
- ghost images
- partial images

Targets three packages under the repository owner. In this repository, the action's package names are `php-ext-farm/alpine`, `php-ext-farm/debian`, and `php-ext-farm/php`, corresponding to images under `ghcr.io/flavioheleno/php-ext-farm/`.

## Triggers
- `schedule` (weekly Sunday 06:00 UTC)
- `workflow_dispatch`

There are no inputs or explicit concurrency group; overlapping cleanup runs are not serialized by this workflow.

## Permissions
The `cleanup` job grants `packages: write` and uses `GITHUB_TOKEN`. It runs on `ubuntu-slim`; there is no repository checkout or runner selector.

## Jobs
### `cleanup` (matrix)
Matrix over `package: [alpine, debian, php]`.
`fail-fast` is disabled so one cleanup target cannot cancel the others.

Uses `dataaxiom/ghcr-cleanup-action` with `package` set to
`${{ github.event.repository.name }}/${{ matrix.package }}` and:
- `delete-ghost-images: true`
- `delete-partial-images: true`

## How to run manually
```bash
gh workflow run cleanup-ghcr.yml
```

## Notes
- This workflow affects container registry storage only; it does not touch git branches or releases.
- The workflow configures ghost/partial-image cleanup, not an explicit age-based retention or extension-artifact pruning policy.
- Per-architecture image tags and manifest availability should be diagnosed in the base-image workflows, not inferred from cleanup success.
