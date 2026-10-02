# Local Testing Guide

Build a single PHP/OS/architecture target locally using the same Dockerfiles as CI. Local scripts extract binaries and write reports; they do not publish releases or push the dataset.

## Prerequisites

- A running Docker daemon with Buildx
- jq (JSON processor)
- Bash 4.0+
- Network access to GHCR, PHP sources, upstream repositories, and OS package repositories
- GNU `find` for external-library filename collection (`find -printf` in `build.sh`)

For non-native targets, configure working binfmt/QEMU emulation on the Docker host. Native amd64/arm64 builds do not need QEMU when the host architecture matches.

Choose values from `extensions.json`, `php-versions.json`, and `os-versions.json`. The current Alpine targets are 3.21-3.24; Debian targets are bullseye, bookworm, and trixie, all excluding arm32v6.

## Select a builder for local images

`--local` expects Buildx to resolve PHP images from the local Docker image store. An engine-backed builder using the `docker` driver is the simplest setup; a separate `docker-container` builder does not automatically see images loaded into that store.

```bash
docker buildx ls
# On a typical local Docker setup, "default" uses the docker driver
docker buildx use default
```

Confirm the driver in `docker buildx ls` rather than assuming a previously selected CI/container builder can use local tags.

## Quick start

The easiest way to test locally is using the orchestrator script:

```bash
# Test redis extension with PHP 8.3 on Alpine
./scripts/local-test.sh redis 6.3.0 8.3 alpine 3.23

# Test imagick with PHP 8.4 on Debian
./scripts/local-test.sh imagick 3.8.1 8.4 debian bookworm

# Test with different architecture
./scripts/build-base-image.sh 8.3 alpine 3.23 arm64 --local
./scripts/local-test.sh redis 6.3.0 8.3 alpine 3.23 arm64
```

The `local-test.sh` script automatically:
1. Checks if the required base image exists
2. Builds the base image if needed
3. Builds the extension
4. Displays metadata and lists output files
5. Shows installation pointers

The Dockerfile checks loading during compilation, but `local-test.sh` does not run another load test or upstream test suite. It always passes channel `release`, even for a `dev` version. Use `build.sh` directly to label local dev reports correctly.

The base-image check only inspects the unsuffixed tag; it does not check architecture or PHP-source freshness. Before switching architectures, rebuild the PHP base image for that architecture. The helper retags the unsuffixed image to the last architecture built.

## Manual workflow

### Step 1: Build Base Image

Choose one target example below, then use that same target in Step 2. Do not run every example in sequence when relying on the unsuffixed alias:

```bash
# Build PHP 8.3 base image for Alpine 3.23
./scripts/build-base-image.sh 8.3 alpine 3.23 amd64 --local

# Build PHP 8.4 base image for Debian bookworm
./scripts/build-base-image.sh 8.4 debian bookworm amd64 --local

# Build for different architecture
./scripts/build-base-image.sh 8.3 alpine 3.23 arm64 --local
```

With `--local`, the first amd64 example creates both:

```text
php-ext-farm/php:8.3-alpine3.23-amd64
php-ext-farm/php:8.3-alpine3.23
```

The unsuffixed tag is a convenience alias for one local architecture, not a multi-architecture manifest. Without `--local`, the same two tags use `ghcr.io/flavioheleno/php-ext-farm/php`; the helper still loads them locally and **does not push** them.

The helper checks PHP configuration and exclusions, builds from a GHCR OS image, and verifies `php --version` in the resulting container. It can fall back to `docker build` when Buildx is unavailable, but extension builds require Buildx and cross-platform builds require an appropriate builder/emulation setup.

### Step 2: Build the extension

Build the matching base architecture first; the following commands are independent target examples:

```bash
# Build redis extension
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 amd64 release --local

# Build imagick extension
./scripts/build.sh imagick 3.8.1 8.4 debian bookworm amd64 release --local

# Build for different architecture
./scripts/build.sh redis 6.3.0 8.3 alpine 3.23 arm64 release --local

# Current default branch, with the correct report channel
./scripts/build.sh redis dev 8.3 alpine 3.23 amd64 dev --local
```

`build.sh --local` passes `BASE_IMAGE_REGISTRY=php-ext-farm` to the extension Dockerfile. It disables explicit GHA/filesystem cache import/export options, not BuildKit's own local layer cache.

Ordinary versions are tags/branches. `dev` clones the default branch; `dev-<sha>` checks out the suffix after a shallow default-branch clone and can fail for a commit absent from that clone. See [Build Extension](BUILD.md) for workflow version resolution.

### Step 3: Inspect and verify

For the amd64 Redis release example:

```bash
jq . output/redis/8.3/alpine/3.23/amd64/metadata.json
jq . reports/redis/6.3.0/php8.3/alpine-3.23/amd64.json
docker run --rm --platform linux/amd64 \
  php-ext-redis:8.3-alpine3.23-amd64 php --ri redis
```

The build image already has its runtime dependencies, external libraries, and INI directive. Test inside that image rather than copying the binary to an unrelated host PHP installation.

Output paths do **not** contain the extension version:

```text
output/<extension>/<php_version>/<platform>/<platform_version>/<arch>/
reports/<extension>/<raw_version>/php<php_version>/<platform>-<platform_version>/<arch>.json
```

Retain separate copies when comparing versions and do not treat an old output file as evidence of a successful new build. Unsupported direct-build targets/exclusions can generate a skipped report and exit zero; inspect its `status`.

For Redis, which has no bundled source-built libraries, an optional local archive can be created with:

```bash
tar -C output/redis/8.3/alpine/3.23/amd64 \
  -czf redis-6.3.0-php8.3-alpine-3.23-amd64.tar.gz redis.so metadata.json
```

Include `libs/` as well for builds that produce bundled libraries. Local builds do not create archives automatically.

## Bootstrapping the OS image locally

`--local` does not change the PHP Dockerfiles' OS-image namespace. They still use `ghcr.io/flavioheleno/php-ext-farm/alpine:<version>` or `.../debian:<codename>`, and the helper does not build that layer for you.

If the required GHCR OS image is unavailable, an engine-backed builder can build it locally under the tag those Dockerfiles expect:

```bash
docker buildx build --platform linux/amd64 --load \
  --build-arg ALPINE_VERSION=3.23 \
  -f docker/base/os/Dockerfile.alpine \
  -t ghcr.io/flavioheleno/php-ext-farm/alpine:3.23 .
./scripts/build-base-image.sh 8.3 alpine 3.23 amd64 --local
```

Use the same target architecture throughout. This tag is local; the command does not publish to GHCR. Package installation and source downloads still need network access.

## Troubleshooting and lightweight checks

For a missing base image, inspect the exact target tag and available architectures. For a load failure, check `metadata.json`, the INI directive, and `ldd` inside the target image. Runtime dependencies and `libs/` must also be present when installing elsewhere.

For Docker-free regression/configuration checks, see [Tests](TESTS.md) and [Lint](LINT.md). `test-build-smoke.sh` is a regression script, not a real container build.

## Cleanup

Remove only tags from the example build when no longer needed:
```bash
docker image rm php-ext-redis:8.3-alpine3.23-amd64 \
  php-ext-farm/php:8.3-alpine3.23-amd64 \
  php-ext-farm/php:8.3-alpine3.23
```

Remove only that target's generated output/report:
```bash
rm -r -- output/redis/8.3/alpine/3.23/amd64
rm -f -- reports/redis/6.3.0/php8.3/alpine-3.23/amd64.json
```
