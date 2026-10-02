# Release (`release.yml`)

**Workflow file:** [`.github/workflows/release.yml`](../.github/workflows/release.yml)

## Purpose

Resolve an extension version, skip an existing release unless forced, call [Build Extension](BUILD.md), and publish its successful `.tar.gz` archives as a GitHub Release.

## Triggers and inputs

The workflow supports `workflow_dispatch` and `workflow_call`. `build-all.yml`, `check-releases.yml`, and `scripts/release-all.sh` all start it as separate dispatched runs (`gh workflow run`), not reusable calls. Both triggers expose the same inputs:

| Input | Type | Default | Meaning |
|-------|------|---------|---------|
| `extension` | String | Required | Key in `extensions.json` |
| `extension_version` | String | `""` | Raw upstream ref, `dev`, or `dev-<sha>`; empty resolves from configuration |
| `rebuild` | Boolean | `false` | Rebuild and replace an existing release |

There are no PHP/platform/architecture filters or runner input. The reusable build uses all configured targets.

Version resolution uses `latest_version`, then `dev` if `last_checked` exists without a cached release; otherwise it fails. The raw ref is passed to the build, while `normalize-version.sh` produces the release tag and asset filename version.

## Jobs

### `check-release`

Runs on `ubuntu-slim`, computes `<extension>-<normalized_version>`, and checks it with `gh release view`. `rebuild=true` bypasses the existence check. Outputs are `should_build`, `release_tag`, `clean_version`, and the resolved raw `extension_version`.

An existing release is skipped as a whole; the workflow does not inspect it for missing assets or compare its binaries against newer base images.

### `build`

Calls `build.yml` only when `should_build` is true. That workflow uploads one archive artifact per successful target and records reports in the dataset.

### `release`

Runs on `ubuntu-24.04` (large extensions exceed `ubuntu-slim`'s 15-minute job limit) after the reusable build, including when some builds failed, provided the run was not cancelled. It downloads the per-target artifacts matching `<extension>-<clean_version>-php*` into `release/` and generates `release_notes.md` from the template in this workflow.

Release notes list **configured build targets**, not a promise that every target succeeded. They describe exact archive naming, the installer, metadata, runtime packages, bundled libraries, and the Zend-extension directive. Actual availability is determined by attached assets and build reports.

The publication step fails if no `release/*.tar.gz` archive was downloaded. Otherwise, when rebuilding, it deletes the existing GitHub Release and matching git tag, then creates the replacement with the collected archives. Because the archive check comes first, a rebuild in which every target failed leaves the existing release in place.

## Outputs and partial failures

Release tag:

```text
<extension>-<normalized_version>
```

Asset filenames:

```text
<extension>-<normalized_version>-php<php_version>-<platform>-<platform_version>-<arch>.tar.gz
```

A partial matrix can still be published: the release job is not restricted to an overall successful build result. If every target failed, the release job fails without publishing. Consult the [dataset](../README.md#-build-reports--dataset), not just the presence of a release.

There is no dev-channel prohibition or automatic prerelease flag. Calling this workflow with `dev`/`dev-<sha>` can publish that version, and the no-cached-release fallback can create `<extension>-dev`.

## Permissions and concurrency

The workflow defaults to `contents: read`. The reusable `build` job and publication job elevate to `contents: write` for dataset updates and release/tag operations.

Concurrency group `release-${{ inputs.extension }}-${{ inputs.extension_version || 'latest' }}` uses the supplied version or `latest`, with `cancel-in-progress: false`. Docker runner selection is controlled by `build.yml`.

## Running manually

```bash
gh workflow run release.yml \
  -f extension=redis \
  -f extension_version=6.3.0

gh workflow run release.yml \
  -f extension=redis \
  -f extension_version=6.3.0 \
  -f rebuild=true
```

**Rebuild warning:** Replacement is not atomic and has no rollback. The old release/tag are deleted before creation of the new release, and binaries at the same download URLs may change. Force base-image rebuilds separately if that is the reason for rebuilding extensions.

`./scripts/release-all.sh` dispatches `release.yml` with `rebuild=true` for every configured extension, using cached version resolution and a one-second delay between dispatches. It requires authenticated `gh` access, replaces existing releases, and does not wait for completion.