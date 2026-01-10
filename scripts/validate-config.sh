#!/bin/bash
# Validate extensions.json schema and exclusion rules
# Usage: ./validate-config.sh [config_file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
CONFIG_FILE="${1:-${ROOT_DIR}/extensions.json}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "Error: Config file not found: ${CONFIG_FILE}" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

echo "Validating ${CONFIG_FILE}..."
echo

ERRORS=0
WARNINGS=0

# Validate JSON syntax
if ! jq empty "${CONFIG_FILE}" 2>/dev/null; then
    echo "✗ Invalid JSON syntax"
    exit 1
fi
echo "✓ Valid JSON syntax"

# Check platform excludes don't have 'os' field
platforms=$(jq -r '.platforms | keys[]' "${CONFIG_FILE}")
for platform in $platforms; do
    excludes=$(jq -r --arg p "$platform" '.platforms[$p].exclude // []' "${CONFIG_FILE}")
    
    if [[ "$excludes" != "[]" ]]; then
        num_rules=$(echo "$excludes" | jq 'length')
        for ((i=0; i<num_rules; i++)); do
            rule=$(echo "$excludes" | jq ".[$i]")
            has_os=$(echo "$rule" | jq 'has("os")')
            
            if [[ "$has_os" == "true" ]]; then
                echo "✗ Platform '$platform' exclude rule $i has 'os' field (should be implicit)"
                ERRORS=$((ERRORS + 1))
            fi
            
            # Check required fields
            has_version=$(echo "$rule" | jq 'has("version")')
            has_arch=$(echo "$rule" | jq 'has("arch")')
            
            if [[ "$has_version" != "true" ]]; then
                echo "✗ Platform '$platform' exclude rule $i missing 'version' field"
                ERRORS=$((ERRORS + 1))
            fi
            
            if [[ "$has_arch" != "true" ]]; then
                echo "✗ Platform '$platform' exclude rule $i missing 'arch' field"
                ERRORS=$((ERRORS + 1))
            fi
        done
    fi
done

if [[ ${ERRORS} -eq 0 ]]; then
    echo "✓ Platform excludes are valid (no 'os' field)"
fi

# Check extension excludes have 'os' field
extensions=$(jq -r '.extensions | keys[]' "${CONFIG_FILE}")
for extension in $extensions; do
    excludes=$(jq -r --arg e "$extension" '.extensions[$e].exclude // []' "${CONFIG_FILE}")
    
    if [[ "$excludes" != "[]" ]]; then
        num_rules=$(echo "$excludes" | jq 'length')
        for ((i=0; i<num_rules; i++)); do
            rule=$(echo "$excludes" | jq ".[$i]")
            has_os=$(echo "$rule" | jq 'has("os")')
            
            if [[ "$has_os" != "true" ]]; then
                echo "✗ Extension '$extension' exclude rule $i missing 'os' field (required)"
                ERRORS=$((ERRORS + 1))
            fi
            
            # Check required fields
            has_version=$(echo "$rule" | jq 'has("version")')
            has_arch=$(echo "$rule" | jq 'has("arch")')
            
            if [[ "$has_version" != "true" ]]; then
                echo "✗ Extension '$extension' exclude rule $i missing 'version' field"
                ERRORS=$((ERRORS + 1))
            fi
            
            if [[ "$has_arch" != "true" ]]; then
                echo "✗ Extension '$extension' exclude rule $i missing 'arch' field"
                ERRORS=$((ERRORS + 1))
            fi
        done
    fi
done

if [[ ${ERRORS} -eq 0 ]]; then
    echo "✓ Extension excludes are valid (have 'os' field)"
fi

# Check for platform version references that don't exist
for platform in $platforms; do
    platform_versions=$(jq -r --arg p "$platform" '.platforms[$p].versions[]' "${CONFIG_FILE}")
    excludes=$(jq -r --arg p "$platform" '.platforms[$p].exclude // []' "${CONFIG_FILE}")
    
    if [[ "$excludes" != "[]" ]]; then
        num_rules=$(echo "$excludes" | jq 'length')
        for ((i=0; i<num_rules; i++)); do
            rule=$(echo "$excludes" | jq ".[$i]")
            version_pattern=$(echo "$rule" | jq -r '.version')
            
            # Skip wildcard patterns
            if [[ "$version_pattern" == *"*"* ]]; then
                continue
            fi
            
            # Check if version exists
            version_found=false
            for v in $platform_versions; do
                if [[ "$v" == "$version_pattern" ]]; then
                    version_found=true
                    break
                fi
            done
            
            if [[ "$version_found" == "false" ]]; then
                echo "⚠ Platform '$platform' exclude rule $i references non-existent version '$version_pattern'"
                WARNINGS=$((WARNINGS + 1))
            fi
        done
    fi
done

# Check for architecture references that don't exist
all_archs=$(jq -r '.architectures[]' "${CONFIG_FILE}")
for platform in $platforms; do
    excludes=$(jq -r --arg p "$platform" '.platforms[$p].exclude // []' "${CONFIG_FILE}")
    
    if [[ "$excludes" != "[]" ]]; then
        num_rules=$(echo "$excludes" | jq 'length')
        for ((i=0; i<num_rules; i++)); do
            rule=$(echo "$excludes" | jq ".[$i]")
            arch_pattern=$(echo "$rule" | jq -r '.arch')
            
            # Skip wildcard patterns
            if [[ "$arch_pattern" == *"*"* ]]; then
                continue
            fi
            
            # Check if arch exists
            arch_found=false
            for a in $all_archs; do
                if [[ "$a" == "$arch_pattern" ]]; then
                    arch_found=true
                    break
                fi
            done
            
            if [[ "$arch_found" == "false" ]]; then
                echo "⚠ Platform '$platform' exclude rule $i references non-existent architecture '$arch_pattern'"
                WARNINGS=$((WARNINGS + 1))
            fi
        done
    fi
done

for extension in $extensions; do
    excludes=$(jq -r --arg e "$extension" '.extensions[$e].exclude // []' "${CONFIG_FILE}")
    
    if [[ "$excludes" != "[]" ]]; then
        num_rules=$(echo "$excludes" | jq 'length')
        for ((i=0; i<num_rules; i++)); do
            rule=$(echo "$excludes" | jq ".[$i]")
            arch_pattern=$(echo "$rule" | jq -r '.arch')
            
            # Skip wildcard patterns
            if [[ "$arch_pattern" == *"*"* ]]; then
                continue
            fi
            
            # Check if arch exists
            arch_found=false
            for a in $all_archs; do
                if [[ "$a" == "$arch_pattern" ]]; then
                    arch_found=true
                    break
                fi
            done
            
            if [[ "$arch_found" == "false" ]]; then
                echo "⚠ Extension '$extension' exclude rule $i references non-existent architecture '$arch_pattern'"
                WARNINGS=$((WARNINGS + 1))
            fi
        done
    fi
done

# Summary
echo
echo "================================"
echo "Validation complete"
echo "Errors: ${ERRORS}"
echo "Warnings: ${WARNINGS}"
echo "================================"

if [[ ${ERRORS} -gt 0 ]]; then
    echo "Validation failed with ${ERRORS} error(s)"
    exit 1
elif [[ ${WARNINGS} -gt 0 ]]; then
    echo "Validation passed with ${WARNINGS} warning(s)"
    exit 0
else
    echo "✓ All checks passed"
    exit 0
fi
