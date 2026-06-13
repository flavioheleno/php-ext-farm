# Cleanup GHCR (`cleanup-ghcr.yml`)

**Workflow file:** `.github/workflows/cleanup-ghcr.yml`

## Purpose
Clean up GHCR packages by deleting:
- ghost images
- partial images

Targets three nested GHCR package namespaces:
- `<repo>/alpine`
- `<repo>/debian`
- `<repo>/php`

## Triggers
- `schedule` (weekly Sunday 06:00 UTC)
- `workflow_dispatch`

## Permissions
- `packages: write`

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
