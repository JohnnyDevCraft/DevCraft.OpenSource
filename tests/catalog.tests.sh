#!/usr/bin/env bash
# Catalog consistency checks (TEST-1.1 – TEST-1.5). Development-time only; requires jq.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CATALOG="$ROOT/catalog.json"
LIBRARY_FOLDERS=(architectures standards project-types skills templates)
SECTIONS='["Skills","Standards","Architectures","Templates","ProjectTypes"]'

failures=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

command -v jq >/dev/null 2>&1 || { echo "jq is required to run catalog tests." >&2; exit 2; }

catalog_is_valid_json() {
  if jq empty "$CATALOG" 2>/dev/null; then pass "${FUNCNAME[0]}"; else fail "${FUNCNAME[0]}" "catalog.json is not valid JSON"; fi
}

entries() {
  jq -c --argjson s "$SECTIONS" 'to_entries[] | select(.key as $k | $s | index($k)) | .value[]' "$CATALOG"
}

catalog_every_path_exists() {
  local missing=0 path
  while IFS= read -r path; do
    [[ -f "$ROOT/$path" ]] || { fail "${FUNCNAME[0]}" "missing file: $path"; missing=1; }
  done < <(entries | jq -r '.Path')
  [[ $missing -eq 0 ]] && pass "${FUNCNAME[0]}"
  return 0
}

catalog_every_library_file_has_entry() {
  local bad=0 file count folder
  for folder in "${LIBRARY_FOLDERS[@]}"; do
    [[ -d "$ROOT/$folder" ]] || continue
    while IFS= read -r file; do
      count=$(entries | jq -r --arg p "$file" 'select(.Path == $p) | .Slug' | wc -l | tr -d ' ')
      [[ "$count" == "1" ]] || { fail "${FUNCNAME[0]}" "$file has $count entries"; bad=1; }
    done < <(cd "$ROOT" && find "$folder" -type f -name '*.md' | sort)
  done
  [[ $bad -eq 0 ]] && pass "${FUNCNAME[0]}"
  return 0
}

catalog_slugs_unique_and_kebab() {
  local dupes invalid
  dupes=$(entries | jq -r '.Slug' | sort | uniq -d)
  invalid=$(entries | jq -r '.Slug' | grep -Ev '^[a-z0-9]+(-[a-z0-9]+)*$' || true)
  if [[ -z "$dupes" && -z "$invalid" ]]; then
    pass "${FUNCNAME[0]}"
  else
    [[ -n "$dupes" ]] && fail "${FUNCNAME[0]}" "duplicate slugs: $dupes"
    [[ -n "$invalid" ]] && fail "${FUNCNAME[0]}" "non-kebab slugs: $invalid"
  fi
  return 0
}

catalog_entries_complete() {
  local bad
  bad=$(entries | jq -r 'select(
      ([.Slug, .Name, .Description, .Path] | map(type == "string" and length > 0) | all | not)
      or (.Description | tostring | test("Use this template"))
    ) | .Slug // "<no slug>"')
  if [[ -z "$bad" ]]; then pass "${FUNCNAME[0]}"; else fail "${FUNCNAME[0]}" "incomplete entries: $bad"; fi
}

main() {
  echo "Catalog tests: $CATALOG"
  catalog_is_valid_json
  [[ $failures -eq 0 ]] || exit 1
  catalog_every_path_exists
  catalog_every_library_file_has_entry
  catalog_slugs_unique_and_kebab
  catalog_entries_complete
  if [[ $failures -eq 0 ]]; then echo "All catalog tests passed."; else echo "$failures catalog test(s) failed."; exit 1; fi
}

main "$@"
