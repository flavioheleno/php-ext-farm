#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="${SCRIPT_DIR}/../extensions.json"

for extension in $(jq -r '.extensions | keys[]' "${EXTENSIONS_FILE}"); do
  echo "Triggering release for ${extension}..."
  gh workflow run release.yml -f "extension=${extension}" -f rebuild=true
  sleep 1
done

echo "Done. Triggered release for all extensions."
