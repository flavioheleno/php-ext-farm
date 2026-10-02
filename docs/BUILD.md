# Build Extension (`build.yml`)

**Workflow file:** [`.github/workflows/build.yml`](../.github/workflows/build.yml)

## Purpose

Build one configured PHP extension across selected PHP/platform/architecture targets, package successful binaries, upload reports, and persist collected results to the `dataset` branch. This workflow does not create GitHub Releases; [Release](RELEASE.md) wraps it for publication.

## Triggers and inputs

`workflow_dispatch` supports manual builds and is also how `build-all.yml` starts dev builds (one dispatched run per extension). `workflow_call` is used by `release.yml`.

| Input | Manual dispatch | Reusable call | Meaning |
|-------|-----------------|---------------|---------|
| `extension` | Required | Required | Key in `extensions.json` |
| `extension_version` | Default `""` | Required | Upstream ref, `dev`, or `dev-<sha>` |
| `php_versions` | Default `all` | Not exposed | Comma-separated PHP targets |
| `platforms` | Default `all` | Not exposed | `alpine`, `debian`, or both as CSV |
| `architectures` | Default `all` | Default `all` | Comma-separated configured architecture names |

Use CSV values without spaces and canonical architecture names (`amd64`, `arm64`, `arm32v6`, `arm32v7`). There is no OS-version selector or `runner` input. Reusable callers build all configured PHP/platform targets.

An omitted version resolves to `.extensions[extension].latest_version`. If that is absent but `last_checked` exists, it becomes `dev`; otherwise preparation fails and an explicit version is required.

## Source and channel selection

Ordinary versions are shallow-cloned using `--branch <ref>`. Both `pecl` and `git` extension types use this git build path, not PECL downloads.

`dev` clones the default branch. For `dev-<sha>`, `build.sh` passes the suffix as `COMMIT_SHA`, and the Dockerfile checks it out after cloning the default branch. A shallow clone may not contain an older commit, including a HEAD that moved between discovery and checkout.

The workflow infers channel `dev` for both `dev` and `dev-*`, and `release` otherwise. The channel labels reports; it does not guarantee that an upstream tag is stable. Normalization affects artifact/report version names, not the source ref.

## Jobs

### `prepare`

Runs on `ubuntu-slim`, resolves the version, and calls `build_matrix` from [`scripts/exclusions.jq`](../scripts/exclusions.jq) with:
- PHP keys from `php-versions.json`
- OS version lists from `os-versions.json`
- architecture names and extension rules from `extensions.json`

Platform- and extension-level exclusions are both applied with wildcard matching **before** scheduling. With the current configuration, an unfiltered extension with no extension-specific exclusions has 125 entries; all Debian `arm32v6` combinations are excluded.

Job outputs are `matrix` and the resolved `extension_version`; these are internal job outputs, not declared reusable-workflow outputs.

### `build`

Each matrix entry runs on `ubuntu-24.04` for amd64 or `ubuntu-24.04-arm` for ARM, with a 60-minute job timeout. QEMU is configured only for the two 32-bit ARM targets; arm64 runs natively. The matrix has `fail-fast: false` and `max-parallel: 60`.

The job runs `scripts/build.sh`, which resolves version-specific dependency overrides and compiles using the configured PHP base image. The Dockerfile verifies module loading with `php -m`, locates the module via `php-config --extension-dir`, and runs `strip --strip-unneeded` on the copied `.so`; it does not run upstream extension test suites.

Successful output is packaged as:

```text
<extension>-<normalized_version>-php<php_version>-<platform>-<platform_version>-<arch>.tar.gz
```

Archives contain `<pecl_name>.so`, `metadata.json`, and optional `libs/`. Each archive is uploaded as its own artifact named after the archive (without `.tar.gz`); [Release](RELEASE.md) downloads them by pattern. The report upload is attempted with `always()`, including for failed builds, but early failures may produce no report.

### `collect-artifacts`

Runs on `ubuntu-slim` with `always()`, so it attempts collection after failed matrix jobs as well. It downloads only the `report-<extension>-*` artifacts; it does not combine or re-upload archives.

Collected reports are merged into a JSON array and pushed via a temporary worktree:

```text
history/YYYY/MM/DD/<extension>-<normalized_version>-<run_id>.json
reports/<extension>/<normalized_version>.json
latest.json
```

The history path is per run, the version index has one pointer per UTC day, and `latest.json` has one entry per extension across channels. Multiple runs in one day replace the daily pointer; same-day retries with the same run ID can replace the history file. See the [dataset reference](../README.md#-build-reports--dataset) for schemas and query examples.

## Permissions, concurrency, and retention

The workflow defaults to `contents: read`; only `collect-artifacts` elevates to `contents: write` for dataset updates. Its concurrency group is `build-${{ inputs.extension }}-${{ inputs.extension_version }}`, using the supplied input rather than the resolved version, with `cancel-in-progress: false`.

Per-target archives and report artifacts request 90-day retention. Dataset JSON persists in git. Successful partial output can exist even when the overall build workflow fails.

## Running manually

```bash
gh workflow run build.yml \
  -f extension=redis \
  -f extension_version=6.3.0 \
  -f php_versions=8.3,8.4 \
  -f platforms=alpine \
  -f architectures=amd64

gh workflow run build.yml \
  -f extension=redis \
  -f extension_version=dev \
  -f php_versions=next \
  -f architectures=arm64
```

The first command includes all configured Alpine versions, not just one OS version. For a single local PHP/OS/architecture target, see [Local Testing](LOCAL_TESTING.md).

## Reading outcomes

Inspect the report `status`, not just the process exit code. A direct `build.sh` invocation writes a skipped report and exits zero for unsupported PHP/platform/architecture or an exclusion; a build failure exits nonzero. Matrix-filtered exclusions normally produce neither a CI job nor a report. A failure report's `asset_name` is the intended name, not evidence that the archive exists.