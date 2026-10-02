# Build All Extensions (`build-all.yml`)

**Workflow file:** [`.github/workflows/build-all.yml`](../.github/workflows/build-all.yml)

## Purpose

Reconcile releases for every enabled extension in `extensions.json` and optionally build GitHub-hosted extensions from default-branch HEADs. Despite the weekly rebuild terminology, existing releases are skipped unless a forced rebuild is requested.

## Triggers and inputs

The workflow runs Sundays at 02:00 UTC or by `workflow_dispatch`. It is not a reusable workflow.

| Manual input | Type | Default | Meaning |
|--------------|------|---------|---------|
| `force_rebuild` | Boolean | `false` | Pass `rebuild=true` to each dispatched release run |
| `build_dev` | Boolean | `true` | Discover GitHub HEADs and dispatch dev builds |

There are no extension, PHP, platform, architecture, or runner filters; each dispatched workflow uses its configured full target matrix.

**Scheduled dev limitation:** Both dev preparation and the dev dispatch step use `inputs.build_dev != false`. Scheduled events have no dispatch inputs; a missing property evaluates to an empty string, which GitHub's loose equality treats as equal to `false`. Consequently, current scheduled runs skip dev builds. The `true` default applies to manual dispatches. See GitHub's [contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) and [expression comparison rules](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions).

## Jobs

### `prepare`

Runs on `ubuntu-slim` and outputs:
- `extensions`: extension keys without a `disabled` field (currently 99 of 106)
- `dev_builds`: discovered `{extension, version}` entries for enabled extensions when dev preparation is enabled

For each dev candidate, the workflow checks that `track_url` is hosted on GitHub, queries its default branch and HEAD SHA, and uses `dev-<first-seven-sha-characters>`. Non-GitHub repositories and unsuccessful HEAD lookups are logged and skipped; GitLab and Bitbucket dev discovery is not implemented here.

### `dispatch`

Runs on `ubuntu-slim` with `actions: write` and uses `gh workflow run` to start **separate workflow runs**:
- one [Release](RELEASE.md) run per enabled extension, with `rebuild` set from `force_rebuild` and `extension_version` omitted so it resolves from cached configuration
- when enabled and discovery produced entries, one [Build Extension](BUILD.md) run per `dev-<sha>` version; this path creates build artifacts and dataset entries, not GitHub Releases

Workflows are dispatched rather than called as reusable workflows because a single run holding every extension produced thousands of artifacts, and `actions/download-artifact` lists only the first 1000; later extensions never found their builds. `build-all` therefore finishes within seconds of dispatching. Track progress, failures, and parallelism in the individual `Release` and `Build Extension` runs; there is no build-all-level matrix limit or aggregate result.

An extension with no cached release but with `last_checked` falls back to `dev`. The release workflow can therefore create `<extension>-dev`; a dispatched release does not guarantee a tagged upstream release.

The build script extracts the dev SHA and both Dockerfiles perform a checkout after a shallow default-branch clone. A commit that has moved behind HEAD may be unavailable by the time the matrix builds begin.

## Permissions and concurrency

The workflow defaults to `contents: read`; `prepare` and `dispatch` grant `actions: write`. Dispatched runs use their own workflow permissions and runners.

Concurrency group `build-all` has `cancel-in-progress: false`, but it only serializes the short dispatch runs, not the dispatched builds. Release and dev runs can execute alongside each other; `latest.json` keeps whichever channel's entry was last published, without comparing run times or versions.

## Running manually

```bash
# Manual defaults: reconcile releases and also discover/build GitHub dev HEADs
gh workflow run build-all.yml

# Release reconciliation only; existing releases are not rebuilt
gh workflow run build-all.yml -f build_dev=false

# Replace existing releases, without the additional dev matrix
gh workflow run build-all.yml -f force_rebuild=true -f build_dev=false
```

Forced rebuilding replaces existing releases and tags; review [Release](RELEASE.md) first. To dispatch forced releases from a local checkout, `./scripts/release-all.sh` iterates **every** configured extension (it does not skip `disabled` entries) with a one-second delay, but does not wait for each run to complete or build the dev matrix.