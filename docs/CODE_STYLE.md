# Code Style Guide

## Shell Scripts

### Script Types

We maintain two types of shell scripts with different portability requirements:

#### POSIX Shell Scripts (`#!/bin/sh`)

**Used for:** Scripts that run on end-user systems (Alpine, Debian, Ubuntu, etc.)

**Scripts:**
- `install.sh` - Installation script for pre-built extensions
- `normalize-version.sh` - Version normalization utility

**Style:**
- Use `[ ]` for conditionals (POSIX compatible)
- Use `set -eu` (no pipefail, not POSIX)
- Avoid bash-specific features
- Use `$(command)` instead of backticks
- Always use `${VAR}` braces for variable expansion

**Example:**
```sh
#!/bin/sh
set -eu

if [ -z "${VAR}" ]; then
    echo "Error"
    exit 1
fi
```

#### Bash Scripts (`#!/bin/bash`)

**Used for:** Build scripts, CI/CD automation, development tools

**Scripts:**
- `build.sh`
- `build-base-image.sh`
- `check-exclusion.sh`
- `check-releases.sh`
- `local-test.sh`
- `test-check-exclusion.sh`
- `validate-config.sh`

**Style:**
- Use `[[ ]]` for conditionals (bash extended test)
- Use `set -euo pipefail` for strict error handling
- Bash features allowed (arrays, `${VAR,,}`, etc.)
- Always use `${VAR}` braces for variable expansion
- Quote variable expansions unless word splitting intended

**Example:**
```bash
#!/bin/bash
set -euo pipefail

if [[ -z "${VAR}" ]]; then
    echo "Error"
    exit 1
fi
```

## GitHub Actions Workflows

### Variable References

- Use spaces after `{{` and before `}}`: `${{ inputs.var }}`
- Quote expressions in shell contexts: `"${{ inputs.var }}"`
- Use proper yaml indentation (2 spaces)

### Runner Options

Standard runner choices:
- `ubuntu-latest` - GitHub-hosted runner (default)
- `ubuntu-slim` - Slim runner for lightweight tasks
- `self-hosted` - Self-hosted runner

### Naming Conventions

- Jobs: `kebab-case` (e.g., `build-os`, `create-manifest`)
- Workflows: `Sentence Case` (e.g., `Build OS Base Images`)
- Variables: `UPPER_SNAKE_CASE` for environment, `lower` for inputs

## JSON Configuration

- Use 2-space indentation
- No trailing commas
- Alphabetically sort keys where logical (e.g., extensions, versions)
- Keep `exclude` arrays compact on single line when short

## General Principles

1. **Consistency over perfection** - Follow existing patterns
2. **Portability matters** - Choose sh vs bash appropriately
3. **Fail fast** - Use strict error handling
4. **Always use braces** - Use `${VAR}` not `$VAR` for clarity
5. **Quote variables** - Prevent word splitting issues
6. **Document exceptions** - Add comments when deviating
