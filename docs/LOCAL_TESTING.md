# Local Testing Guide

This guide explains how to test extension builds locally, replicating the CI workflow.

## Prerequisites

- Docker with buildx support
- jq (JSON processor)
- Bash 4.0+

## Quick Start

The easiest way to test locally is using the orchestrator script:

```bash
# Test redis extension with PHP 8.3 on Alpine
./scripts/local-test.sh redis 6.0.2 8.3 alpine 3.20

# Test imagick with PHP 8.4 on Debian
./scripts/local-test.sh imagick 3.7.0 8.4 debian bookworm

# Test with different architecture
./scripts/local-test.sh redis 6.0.2 8.3 alpine 3.20 arm64
```

The `local-test.sh` script automatically:
1. Checks if the required base image exists
2. Builds the base image if needed
3. Builds the extension
4. Verifies the output
5. Shows installation instructions

## Manual Workflow

### Step 1: Build Base Image

Build the PHP base image for your target configuration:

```bash
# Build PHP 8.3 base image for Alpine 3.20
./scripts/build-base-image.sh 8.3 alpine 3.20 --local

# Build PHP 8.4 base image for Debian bookworm
./scripts/build-base-image.sh 8.4 debian bookworm --local

# Build for different architecture
./scripts/build-base-image.sh 8.3 alpine 3.20 arm64 --local
```

**The `--local` flag is important** - it tags images as `php-ext-farm/php:*` instead of `ghcr.io/flavioheleno/php-ext-farm/php:*`.

### Step 2: Build Extension

Once the base image exists, build your extension:

```bash
# Build redis extension
./scripts/build.sh redis 6.0.2 8.3 alpine 3.20 --local

# Build imagick extension
./scripts/build.sh imagick 3.7.0 8.4 debian bookworm --local

# Build for different architecture
./scripts/build.sh redis 6.0.2 8.3 alpine 3.20 arm64 --local
```

**The `--local` flag tells build.sh to use local base images** instead of pulling from GitHub Container Registry.

## Understanding the Flags

### `--local` Flag Behavior

**For base images** (`build-base-image.sh --local`):
- Tags as: `php-ext-farm/php:8.3-alpine3.20`
- Instead of: `ghcr.io/flavioheleno/php-ext-farm/php:8.3-alpine3.20`

**For extensions** (`build.sh --local`):
- Passes `BASE_IMAGE_REGISTRY=php-ext-farm` as build arg
- Extension Dockerfile uses local base images

## Cleanup

Remove local base images:
```bash
docker images php-ext-farm/php --format "{{.Repository}}:{{.Tag}}" | xargs docker rmi
```

Remove build outputs:
```bash
rm -rf output/
```
