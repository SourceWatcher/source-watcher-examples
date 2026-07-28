#!/usr/bin/env bash

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
required_combinations=(
  "extractor -> execution-extractor"
  "extractor -> transformer"
  "extractor -> loader"
  "execution-extractor -> execution-extractor"
  "execution-extractor -> transformer"
  "execution-extractor -> loader"
  "transformer -> execution-extractor"
  "transformer -> transformer"
  "transformer -> loader"
)

declare -A covered_by

for file in "$root"/*.json; do
  while IFS= read -r combination; do
    if [[ -n "${covered_by[$combination]:-}" ]]; then
      covered_by["$combination"]+=", $(basename "$file")"
    else
      covered_by["$combination"]="$(basename "$file")"
    fi
  done < <(
    jq -er '
      if (.steps | type) != "array" or (.steps | length) < 2 then
        error("pipeline must contain at least two steps")
      else
        .steps as $steps
        | range(0; $steps | length - 1)
        | "\($steps[.].type) -> \($steps[. + 1].type)"
      end
    ' "$file"
  )
done

missing=0
for combination in "${required_combinations[@]}"; do
  if [[ -z "${covered_by[$combination]:-}" ]]; then
    printf 'No demo covers %s.\n' "$combination" >&2
    missing=1
  else
    printf '%-44s %s\n' "$combination" "${covered_by[$combination]}"
  fi
done

exit "$missing"
