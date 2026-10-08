#!/usr/bin/env bash
# install.sh tests (TEST-2.1 – TEST-2.12). Runs the installer under /bin/bash
# against a sandboxed DEVCRAFT_HOME with a stub devcraft binary.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT/install.sh"
BASE_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

failures=0
skipped=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }
skip() { printf '  SKIP  %s: %s\n' "$1" "$2"; skipped=$((skipped + 1)); }

# --- sandbox helpers ---------------------------------------------------------

new_sandbox() {
  SANDBOX="$(mktemp -d)"
  HOME_DIR="$SANDBOX/profile"
  STUB_DIR="$SANDBOX/bin"
  mkdir -p "$HOME_DIR" "$STUB_DIR"
  echo '{}' > "$HOME_DIR/configure.json"
  cat > "$STUB_DIR/devcraft" <<'STUB'
#!/bin/bash
echo "$@" >> "$STUB_LOG"
[ -n "${STUB_OUTPUT:-}" ] && echo "$STUB_OUTPUT"
exit "${STUB_EXIT:-0}"
STUB
  chmod +x "$STUB_DIR/devcraft"
}

drop_sandbox() {
  chmod -R u+w "$SANDBOX" 2>/dev/null || true
  rm -rf "$SANDBOX"
}

# run_installer <source> [extra env assignments...]
run_installer() {
  local source="$1"
  shift
  OUTPUT="$(env -i HOME="$SANDBOX" PATH="$STUB_DIR:$BASE_PATH" \
    DEVCRAFT_HOME="$HOME_DIR" DEVCRAFT_SOURCE="$source" STUB_LOG="$SANDBOX/merge.log" \
    "$@" /bin/bash "$INSTALLER" 2>&1)"
  STATUS=$?
}

library_files() {
  (cd "$1" && find architectures standards project-types skills templates -type f -name '*.md' 2>/dev/null | sort)
}

merge_called() { [ -s "$SANDBOX/merge.log" ]; }

make_fixture() {
  FIXTURE="$SANDBOX/fixture"
  mkdir -p "$FIXTURE/standards"
  echo '{"Standards":[]}' > "$FIXTURE/catalog.json"
  echo '# Fixture' > "$FIXTURE/standards/Fixture.md"
}

# --- tests -------------------------------------------------------------------

sh_shellcheck_clean() {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "${FUNCNAME[0]}" "shellcheck is not installed"
    return
  fi
  if out="$(shellcheck "$INSTALLER" 2>&1)"; then pass "${FUNCNAME[0]}"; else fail "${FUNCNAME[0]}" "$out"; fi
}

sh_fresh_install_copies_and_merges() {
  new_sandbox
  run_installer "$ROOT"
  if [ $STATUS -ne 0 ]; then
    fail "${FUNCNAME[0]}" "exit $STATUS: $OUTPUT"
  elif [ "$(library_files "$ROOT")" != "$(library_files "$HOME_DIR")" ]; then
    fail "${FUNCNAME[0]}" "installed files differ from source"
  elif [ "$(cat "$SANDBOX/merge.log")" != "merge $ROOT/catalog.json" ]; then
    fail "${FUNCNAME[0]}" "unexpected merge call: $(cat "$SANDBOX/merge.log" 2>/dev/null)"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_rerun_is_idempotent() {
  new_sandbox
  run_installer "$ROOT"
  local first
  first="$(cd "$HOME_DIR" && find . -type f -exec cksum {} + | sort)"
  run_installer "$ROOT"
  local second
  second="$(cd "$HOME_DIR" && find . -type f -exec cksum {} + | sort)"
  if [ $STATUS -ne 0 ]; then
    fail "${FUNCNAME[0]}" "second run exit $STATUS"
  elif [ -d "$HOME_DIR/backups" ]; then
    fail "${FUNCNAME[0]}" "rerun created a backups folder"
  elif [ "$first" != "$second" ]; then
    fail "${FUNCNAME[0]}" "profile changed on rerun"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_changed_file_is_backed_up() {
  new_sandbox
  mkdir -p "$HOME_DIR/standards"
  echo 'local edit' > "$HOME_DIR/standards/Python.md"
  run_installer "$ROOT"
  local backup
  backup="$(find "$HOME_DIR/backups" -path '*/standards/Python.md' 2>/dev/null | head -1)"
  if [ $STATUS -ne 0 ]; then
    fail "${FUNCNAME[0]}" "exit $STATUS: $OUTPUT"
  elif [ -z "$backup" ] || [ "$(cat "$backup")" != "local edit" ]; then
    fail "${FUNCNAME[0]}" "backup missing or wrong"
  elif ! cmp -s "$ROOT/standards/Python.md" "$HOME_DIR/standards/Python.md"; then
    fail "${FUNCNAME[0]}" "target was not replaced"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_missing_configure_json_fails_early() {
  new_sandbox
  rm "$HOME_DIR/configure.json"
  run_installer "$ROOT"
  if [ $STATUS -eq 0 ]; then
    fail "${FUNCNAME[0]}" "expected non-zero exit"
  elif [ -n "$(library_files "$HOME_DIR")" ] || merge_called; then
    fail "${FUNCNAME[0]}" "files copied or merge called"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_missing_devcraft_fails_early() {
  new_sandbox
  rm "$STUB_DIR/devcraft"
  run_installer "$ROOT"
  if [ $STATUS -eq 0 ]; then
    fail "${FUNCNAME[0]}" "expected non-zero exit"
  elif [ -n "$(library_files "$HOME_DIR")" ]; then
    fail "${FUNCNAME[0]}" "files were copied"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_devcraft_found_in_profile() {
  new_sandbox
  mv "$STUB_DIR/devcraft" "$HOME_DIR/devcraft"
  run_installer "$ROOT"
  if [ $STATUS -eq 0 ] && merge_called; then pass "${FUNCNAME[0]}"; else fail "${FUNCNAME[0]}" "exit $STATUS: $OUTPUT"; fi
  drop_sandbox
}

sh_copy_failure_skips_merge() {
  if [ "$(id -u)" = "0" ]; then
    skip "${FUNCNAME[0]}" "read-only folders are writable as root"
    return
  fi
  new_sandbox
  mkdir -p "$HOME_DIR/standards"
  chmod 555 "$HOME_DIR/standards"
  run_installer "$ROOT"
  if [ $STATUS -eq 0 ]; then
    fail "${FUNCNAME[0]}" "expected non-zero exit"
  elif merge_called; then
    fail "${FUNCNAME[0]}" "merge was called after a copy failure"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_merge_failure_propagates() {
  new_sandbox
  run_installer "$ROOT" STUB_EXIT=3 STUB_OUTPUT=boom
  if [ $STATUS -ne 3 ]; then
    fail "${FUNCNAME[0]}" "expected exit 3, got $STATUS"
  elif ! printf '%s' "$OUTPUT" | grep -q boom; then
    fail "${FUNCNAME[0]}" "merge output not shown"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_path_with_space() {
  new_sandbox
  make_fixture
  echo '# Space' > "$FIXTURE/standards/With Space.md"
  run_installer "$FIXTURE"
  if [ $STATUS -eq 0 ] && cmp -s "$FIXTURE/standards/With Space.md" "$HOME_DIR/standards/With Space.md"; then
    pass "${FUNCNAME[0]}"
  else
    fail "${FUNCNAME[0]}" "exit $STATUS: $OUTPUT"
  fi
  drop_sandbox
}

sh_non_markdown_ignored() {
  new_sandbox
  make_fixture
  echo junk > "$FIXTURE/standards/.DS_Store"
  echo junk > "$FIXTURE/standards/notes.txt"
  run_installer "$FIXTURE"
  if [ $STATUS -ne 0 ]; then
    fail "${FUNCNAME[0]}" "exit $STATUS: $OUTPUT"
  elif [ -e "$HOME_DIR/standards/.DS_Store" ] || [ -e "$HOME_DIR/standards/notes.txt" ]; then
    fail "${FUNCNAME[0]}" "non-Markdown file was copied"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_archive_source() {
  new_sandbox
  make_fixture
  mkdir -p "$SANDBOX/archive"
  cp -R "$FIXTURE" "$SANDBOX/archive/repo-main"
  tar -czf "$SANDBOX/main.tar.gz" -C "$SANDBOX/archive" repo-main
  run_installer "file://$SANDBOX/main"
  if [ $STATUS -ne 0 ]; then
    fail "${FUNCNAME[0]}" "exit $STATUS: $OUTPUT"
  elif ! cmp -s "$FIXTURE/standards/Fixture.md" "$HOME_DIR/standards/Fixture.md"; then
    fail "${FUNCNAME[0]}" "archive content not installed"
  elif ! grep -q 'repo-main/catalog.json' "$SANDBOX/merge.log"; then
    fail "${FUNCNAME[0]}" "merge not called with the extracted catalog"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_default_source_is_github() {
  new_sandbox
  # Stub curl records the URL and fails, so no network access happens.
  printf '#!/bin/bash\necho "$@" > "%s/curl.log"\nexit 22\n' "$SANDBOX" > "$STUB_DIR/curl"
  chmod +x "$STUB_DIR/curl"
  OUTPUT="$(env -i HOME="$SANDBOX" PATH="$STUB_DIR:$BASE_PATH" DEVCRAFT_HOME="$HOME_DIR" \
    STUB_LOG="$SANDBOX/merge.log" /bin/bash "$INSTALLER" 2>&1)"
  STATUS=$?
  if [ $STATUS -eq 0 ] || merge_called; then
    fail "${FUNCNAME[0]}" "expected a failed download and no merge"
  elif ! grep -q 'https://github.com/JohnnyDevCraft/DevCraft.OpenSource/archive/refs/heads/main.tar.gz' "$SANDBOX/curl.log" 2>/dev/null; then
    fail "${FUNCNAME[0]}" "unexpected download: $(cat "$SANDBOX/curl.log" 2>/dev/null)"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

sh_truncated_script_does_nothing() {
  new_sandbox
  local size
  size=$(wc -c < "$INSTALLER" | tr -d ' ')
  head -c $((size / 2)) "$INSTALLER" > "$SANDBOX/truncated.sh"
  env -i HOME="$SANDBOX" PATH="$STUB_DIR:$BASE_PATH" DEVCRAFT_HOME="$HOME_DIR" \
    DEVCRAFT_SOURCE="$ROOT" STUB_LOG="$SANDBOX/merge.log" /bin/bash "$SANDBOX/truncated.sh" >/dev/null 2>&1
  if [ -n "$(library_files "$HOME_DIR")" ] || merge_called; then
    fail "${FUNCNAME[0]}" "truncated script had side effects"
  else
    pass "${FUNCNAME[0]}"
  fi
  drop_sandbox
}

main() {
  echo "install.sh tests: $INSTALLER"
  sh_shellcheck_clean
  sh_fresh_install_copies_and_merges
  sh_rerun_is_idempotent
  sh_changed_file_is_backed_up
  sh_missing_configure_json_fails_early
  sh_missing_devcraft_fails_early
  sh_devcraft_found_in_profile
  sh_copy_failure_skips_merge
  sh_merge_failure_propagates
  sh_path_with_space
  sh_non_markdown_ignored
  sh_archive_source
  sh_default_source_is_github
  sh_truncated_script_does_nothing
  echo "$failures failed, $skipped skipped."
  [ $failures -eq 0 ]
}

main "$@"
