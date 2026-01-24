# Cleanup GHCR (`cleanup-ghcr.yml`)

**Workflow file:** `.github/workflows/cleanup-ghcr.yml`

## Purpose
Clean up GHCR packages by deleting:
- ghost images
- partial images

Targets three package namespaces: `alpine`, `debian`, `php`.

## Triggers
- `schedule` (weekly Sunday 06:00 UTC)
- `workflow_dispatch`

## Permissions
- `packages: write`

## Jobs
### `cleanup` (matrix)
Matrix over `package: [alpine, debian, php]`.

Uses `dataaxiom/ghcr-cleanup-action` with:
- `delete-ghost-images: true`
- `delete-partial-images: true`

## How to run manually
```bash
gh workflow run cleanup-ghcr.yml
```

## Notes
- This workflow affects container registry storage only; it does not touch git branches or releases.