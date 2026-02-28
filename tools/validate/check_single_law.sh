#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

# “fingerprint” robusto: file che deve esistere in una law valida
PATTERN="registry/primitives.v1.json"

mapfile -t hits < <(cd "$ROOT" && find . -type f -path "*/$PATTERN" -print | sed 's|^\./||')

count="${#hits[@]}"

if [[ "$count" -eq 0 ]]; then
  echo "FATAL: no yai-law found (missing $PATTERN)."
  exit 1
fi

if [[ "$count" -gt 1 ]]; then
  echo "FATAL: multiple yai-law roots detected ($count)."
  echo "Found:"
  for h in "${hits[@]}"; do
    echo " - $h"
  done
  echo ""
  echo "Rule: only ONE yai-law per workspace. Remove nested deps (deps of deps)."
  exit 1
fi

echo "OK: single yai-law detected at: ${hits[0]%/$PATTERN}"