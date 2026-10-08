#!/usr/bin/env bash
#
# DevCraft.OpenSource installer (macOS / Linux).
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JohnnyDevCraft/DevCraft.OpenSource/main/install.sh)"
#
# Copies this repository's library Markdown into the DevCraft profile, then asks
# DevCraft to merge catalog.json into the profile catalog (devcraft merge).
#
# Environment overrides:
#   DEVCRAFT_HOME    Profile root. Default: $HOME/.DevCraft
#   DEVCRAFT_SOURCE  Archive URL (with or without .tar.gz), file:// archive, or local folder.
#
# All logic lives in functions and runs from the last line, so a truncated
# download defines functions but executes nothing.

set -euo pipefail

DEFAULT_SOURCE="https://github.com/JohnnyDevCraft/DevCraft.OpenSource/archive/refs/heads/main"
LIBRARY_FOLDERS="architectures standards project-types skills templates"

info() { printf '%s\n' "$*"; }
fail() { printf 'devcraft-install: %s\n' "$*" >&2; exit 1; }

resolve_config() {
  DEVCRAFT_HOME="${DEVCRAFT_HOME:-$HOME/.DevCraft}"
  DEVCRAFT_SOURCE="${DEVCRAFT_SOURCE:-$DEFAULT_SOURCE}"
}

check_prerequisites() {
  [ -f "$DEVCRAFT_HOME/configure.json" ] ||
    fail "DevCraft is not installed: $DEVCRAFT_HOME/configure.json was not found."

  if command -v devcraft >/dev/null 2>&1; then
    DEVCRAFT_BIN="$(command -v devcraft)"
  elif [ -x "$DEVCRAFT_HOME/devcraft" ]; then
    DEVCRAFT_BIN="$DEVCRAFT_HOME/devcraft"
  else
    fail "DevCraft is not installed: the devcraft binary was not found on PATH or in $DEVCRAFT_HOME."
  fi
}

cleanup() {
  if [ -n "${WORK_DIR:-}" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
}

fetch_source() {
  if [ -d "$DEVCRAFT_SOURCE" ]; then
    SOURCE_ROOT="$DEVCRAFT_SOURCE"
  else
    local url="$DEVCRAFT_SOURCE"
    case "$url" in
      *.tar.gz | *.tgz) ;;
      *) url="$url.tar.gz" ;;
    esac

    WORK_DIR="$(mktemp -d)"
    trap cleanup EXIT
    info "Downloading $url"
    mkdir -p "$WORK_DIR/src"
    curl -fsSL "$url" | tar -xzf - -C "$WORK_DIR/src" ||
      fail "could not download or extract $url"

    SOURCE_ROOT="$WORK_DIR/src"
    if [ ! -f "$SOURCE_ROOT/catalog.json" ]; then
      local entries
      entries="$(find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1)"
      if [ "$(printf '%s\n' "$entries" | wc -l | tr -d ' ')" = "1" ] && [ -d "$entries" ]; then
        SOURCE_ROOT="$entries"
      fi
    fi
  fi

  [ -f "$SOURCE_ROOT/catalog.json" ] || fail "catalog.json was not found in the source."
}

# Called from an `||` list, where `set -e` does not apply, so every step
# returns explicitly on failure.
install_file() {
  local relative="$1"
  local source_file="$SOURCE_ROOT/$relative"
  local target="$DEVCRAFT_HOME/$relative"

  if [ -f "$target" ]; then
    if cmp -s "$source_file" "$target"; then
      UNCHANGED=$((UNCHANGED + 1))
      return 0
    fi
    mkdir -p "$(dirname "$BACKUP_DIR/$relative")" || return 1
    cp -p "$target" "$BACKUP_DIR/$relative" || return 1
    BACKED_UP=$((BACKED_UP + 1))
  fi

  mkdir -p "$(dirname "$target")" || return 1
  cp "$source_file" "$target" || return 1
  COPIED=$((COPIED + 1))
}

copy_library() {
  COPIED=0
  UNCHANGED=0
  BACKED_UP=0
  BACKUP_DIR="$DEVCRAFT_HOME/backups/install-$(date +%Y%m%d-%H%M%S)"

  local folder relative
  for folder in $LIBRARY_FOLDERS; do
    [ -d "$SOURCE_ROOT/$folder" ] || continue
    while IFS= read -r -d '' relative; do
      install_file "$relative" || fail "could not install $relative; catalog merge skipped."
    done < <(cd "$SOURCE_ROOT" && find "$folder" -type f -name '*.md' -print0)
  done

  info "Library files: $COPIED copied, $UNCHANGED unchanged, $BACKED_UP backed up."
  if [ "$BACKED_UP" -gt 0 ]; then
    info "Backups: $BACKUP_DIR"
  fi
}

merge_catalog() {
  info "Merging catalog with: devcraft merge"
  local status=0
  "$DEVCRAFT_BIN" merge "$SOURCE_ROOT/catalog.json" || status=$?
  if [ "$status" -ne 0 ]; then
    printf 'devcraft-install: devcraft merge failed (exit %s).\n' "$status" >&2
    exit "$status"
  fi
  info "DevCraft.OpenSource installed into $DEVCRAFT_HOME."
}

main() {
  resolve_config
  check_prerequisites
  fetch_source
  copy_library
  merge_catalog
}

main "$@"
