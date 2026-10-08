# Tasks: 001-InstallerFile

- Feature State: Implementation
- Date: 2026-10-08
- Inputs: [spec.md](spec.md) (R1–R14, AC1–AC7, Clarifications #1–#10), [research.md](research.md)
- Operator Mode: User Operator Mode. Phases are implemented one at a time, and only after the operator approves.

## Planning Decisions

These are planning-level choices that follow from the spec and research. They are open to challenge in Analysis.

- **PD1 — Backup location.** Files the scripts overwrite are backed up to `<DEVCRAFT_HOME>/backups/install-<yyyyMMdd-HHmmss>/<relative path>`, not next to the original. This keeps the library folders free of `.bak` clutter. A backup is taken only when the existing file differs from the incoming one, so an identical rerun creates no backup folder. (R10, R6)
- **PD2 — Override seams.** Both scripts honor `DEVCRAFT_HOME` (default: the profile root from R13) and `DEVCRAFT_SOURCE` (default: the GitHub archive URL; it may also be a local folder or a `file://` archive). These exist for testing and for forks. (research.md §5)
- **PD3 — Library folders.** The set of folders is a single constant in each script: `architectures`, `standards`, `project-types`, `skills`, `templates`. Folders missing from the source are skipped. (R3, Clarification #8)
- **PD4 — Test tooling.**
  - `install.sh`: a dependency-free bash test runner, `tests/install.sh.tests.sh`, with a sandboxed `DEVCRAFT_HOME` and a stub `devcraft` on `PATH`.
  - `install.ps1`: Pester 5.
  - Catalog checks: `jq`. It is a development-time dependency only and is never needed by end users.
- **PD5 — Static analysis in place of a standard.** `shellcheck` and PSScriptAnalyzer must be clean (research.md R-5).
- **PD6 — Default source URL.** Each script holds `https://github.com/<OWNER>/<REPO>/archive/refs/heads/<BRANCH>` as a single constant. Placeholders stay until the operator supplies owner/repo (spec Open Question 1).

## Phase 1 — Catalog

### Implementation

- [x] **T1.1** Create `catalog.json` at the repository root with sections `Architectures`, `Standards`, `ProjectTypes`. (R1)
  - Reuse the 13 existing profile entries verbatim (`Slug`, `Name`, `Description`, `Path`) from `~/.DevCraft/configure.json`, as listed in research.md §1.1.
  - Add `project-type-php-laravel-breeze-mysql-modular-monolith`. Take its `Name` from the file's H1 and its `Description` from the file's `## Description` section, not from the template boilerplate line.
- [x] **T1.2** Add a root `.gitignore` that excludes `.DS_Store`.
- [x] **T1.3** Create `tests/catalog.tests.sh`, which runs every TEST-1.x check and exits non-zero on the first failure.

### Tests

- [x] **TEST-1.1 `catalog_is_valid_json`** — `jq empty catalog.json` succeeds.
- [x] **TEST-1.2 `catalog_every_path_exists`** — every entry's `Path` exists in the repository. (AC7)
- [x] **TEST-1.3 `catalog_every_library_file_has_entry`** — every `*.md` under the PD3 folders has exactly one catalog entry. (AC7)
- [x] **TEST-1.4 `catalog_slugs_unique_and_kebab`** — slugs are unique across all sections and match `^[a-z0-9]+(-[a-z0-9]+)*$`.
- [x] **TEST-1.5 `catalog_entries_complete`** — every entry has non-empty `Slug`, `Name`, `Description`, `Path`, and no `Description` contains "Use this template".
- [x] **TEST-1.6 `catalog_reuses_profile_slugs`** (one-time, manual) — the 13 existing files map to the same slugs as in the current `~/.DevCraft/configure.json`.

## Phase 2 — `install.sh` (macOS / Linux)

### Implementation

- [x] **T2.1** Script skeleton.
  - `#!/usr/bin/env bash` and `set -euo pipefail`.
  - All logic in functions, with `main "$@"` as the final line. (research.md §2.1)
- [x] **T2.2** Configuration: resolve `DEVCRAFT_HOME` and `DEVCRAFT_SOURCE` with their defaults. (PD2, PD6, R13)
- [x] **T2.3** Prerequisite check, before any download or copy. (R8)
  - `"$DEVCRAFT_HOME/configure.json"` must exist.
  - `devcraft` must be found via `command -v`, falling back to `"$DEVCRAFT_HOME/devcraft"`.
  - On failure, print a clear error and exit `1`.
- [x] **T2.4** Fetch source into `mktemp -d`, with a `trap` that cleans up on exit. (R2, R14)
  - URL source: `curl -fsSL "<source>.tar.gz" | tar -xz`.
  - Local folder: use it in place.
  - Resolve the single top-level folder inside the archive, and fail if `catalog.json` is missing from it.
- [x] **T2.5** Copy step. (R3, R3a, R6, R10, PD1, PD3)
  - For each PD3 folder present in the source, select `*.md` with `find`.
  - Compare each file with its target using `cmp -s`. When the target exists and differs, back it up to the PD1 location first.
  - `mkdir -p` the target folder, then `cp`.
  - Quote every path.
  - Any failure exits non-zero before the merge.
- [x] **T2.6** Merge step: run `"$devcraft" merge "$src/catalog.json"`, pass its stdout and stderr through, and exit with its status. (R4, R12)
- [x] **T2.7** Summary output: counts of files copied, unchanged, and backed up; the backup folder path when one was created.

### Tests (`tests/install.sh.tests.sh`)

- [ ] **TEST-2.1 `sh_shellcheck_clean`** *(written; skipped: shellcheck not installed)* — `shellcheck install.sh` reports nothing. (PD5)
- [x] **TEST-2.2 `sh_fresh_install_copies_and_merges`**
  - Setup: empty sandbox containing `configure.json`; stub `devcraft` records its args and exits `0`.
  - Expect: every library `*.md` is present, and the stub was called with `merge <src>/catalog.json`. (AC1)
- [x] **TEST-2.3 `sh_rerun_is_idempotent`** — a second run leaves the same tree and creates no `backups/` folder. (AC6)
- [x] **TEST-2.4 `sh_changed_file_is_backed_up`** — edit one sandbox file, then run. The edited copy appears under `backups/install-*/` and the target matches the source. (AC2)
- [x] **TEST-2.5 `sh_missing_configure_json_fails_early`** — exit is non-zero, nothing is copied, and the stub is not called. (AC3)
- [x] **TEST-2.6 `sh_missing_devcraft_fails_early`** — with no stub on `PATH` or in `DEVCRAFT_HOME`: exit is non-zero and nothing is copied. (AC3)
- [x] **TEST-2.7 `sh_copy_failure_skips_merge`** — make a target folder read-only. Exit is non-zero and the stub is not called. (AC4)
- [x] **TEST-2.8 `sh_merge_failure_propagates`** — stub prints "boom" and exits `3`. The script's exit is non-zero and "boom" is visible. (AC5)
- [x] **TEST-2.9 `sh_path_with_space`** — a source fixture `standards/With Space.md` is copied correctly.
- [x] **TEST-2.10 `sh_non_markdown_ignored`** — `.DS_Store` in the source is not copied.
- [x] **TEST-2.11 `sh_archive_source`** — `DEVCRAFT_SOURCE=file://<fixture>` (a tarball with a top-level `repo-main/` folder) installs correctly.
- [x] **TEST-2.12 `sh_truncated_script_does_nothing`** — run `install.sh` cut in half. No files change and the stub is not called.

## Phase 3 — `install.ps1` (Windows)

### Implementation

- [x] **T3.1** Script skeleton.
  - `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`.
  - All logic in functions, invoked by a single call on the last line.
  - Must run on Windows PowerShell 5.1 and PowerShell 7.
- [x] **T3.2** Session setup. (research.md §2.3)
  - Add `Tls12` to `[Net.ServicePointManager]::SecurityProtocol`.
  - Set `$ProgressPreference = 'SilentlyContinue'`, and restore it in `finally`.
- [x] **T3.3** Configuration: resolve `DEVCRAFT_HOME` (default `$HOME\.DevCraft`) and `DEVCRAFT_SOURCE`. (PD2, PD6, R13)
- [x] **T3.4** Prerequisite check. (R8)
  - `configure.json` must exist.
  - `devcraft` must be found via `Get-Command devcraft`, falling back to `$DEVCRAFT_HOME\devcraft.exe`.
- [x] **T3.5** Fetch source into a temp folder, with cleanup in `try/finally`. (R2, R14)
  - `Invoke-WebRequest -UseBasicParsing -OutFile` the `.zip`, then `Expand-Archive`.
  - Resolve the top-level folder.
- [x] **T3.6** Copy step, at parity with T2.5. (PD1, PD3)
  - `Get-ChildItem -Recurse -Filter *.md`.
  - Detect changes with `Get-FileHash`.
  - `New-Item -ItemType Directory -Force`, then `Copy-Item`.
- [x] **T3.7** Merge step: `& $devcraft merge $catalog`. Show its output and `exit $LASTEXITCODE` when non-zero. (R4, R12)
- [x] **T3.8** Summary output, at parity with T2.7.

### Tests (`tests/install.ps1.Tests.ps1`, Pester 5)

*All Phase 3 tests are written but **not yet run**, because there is no PowerShell on this Mac. See results.md.*

Every test runs on Windows PowerShell 5.1 and on pwsh 7.

- [ ] **TEST-3.1 `ps_scriptanalyzer_clean`** — `Invoke-ScriptAnalyzer install.ps1` reports no warnings or errors. (PD5)
- [ ] **TEST-3.2 `ps_fresh_install_copies_and_merges`** — parity with TEST-2.2. (AC1)
- [ ] **TEST-3.3 `ps_rerun_is_idempotent`** — parity with TEST-2.3. (AC6)
- [ ] **TEST-3.4 `ps_changed_file_is_backed_up`** — parity with TEST-2.4. (AC2)
- [ ] **TEST-3.5 `ps_missing_configure_json_fails_early`** — parity with TEST-2.5. (AC3)
- [ ] **TEST-3.6 `ps_missing_devcraft_fails_early`** — parity with TEST-2.6. (AC3)
- [ ] **TEST-3.7 `ps_copy_failure_skips_merge`** — parity with TEST-2.7. (AC4)
- [ ] **TEST-3.8 `ps_merge_failure_propagates`** — parity with TEST-2.8. (AC5)
- [ ] **TEST-3.9 `ps_path_with_space`** — parity with TEST-2.9.
- [ ] **TEST-3.10 `ps_zip_source`** — `DEVCRAFT_SOURCE` points to a local `.zip` fixture.
- [ ] **TEST-3.11 `ps_no_interactive_prompt_on_51`** — under Windows PowerShell 5.1 with no console input, the install completes without hanging, which confirms `-UseBasicParsing`.

## Phase 4 — Publish and End-to-End

### Implementation

- [x] **T4.1** Replace the PD6 placeholders with the GitHub owner/repo/branch. Done: `JohnnyDevCraft/DevCraft.OpenSource`, branch `main`.
- [x] **T4.2** Root `README.md` covering:
  - Purpose.
  - The two one-liners.
  - A "download, inspect, then run" alternative.
  - Prerequisites: DevCraft installed, a version with `devcraft merge`.
  - `DEVCRAFT_HOME`/`DEVCRAFT_SOURCE`.
  - Where backups go.
  - (research.md R-3)

### Tests

*Blocked on a DevCraft build with `merge` and on T4.1.*

- [ ] **TEST-4.1 `e2e_macos_one_liner`** — on macOS, run the published `/bin/bash -c "$(curl -fsSL …/install.sh)"` against the real profile. Expect:
  - Exit `0`.
  - The library files are present.
  - `project-type-php-laravel-breeze-mysql-modular-monolith` appears in `~/.DevCraft/configure.json`.
  - DevCraft lists it. (AC1)
- [ ] **TEST-4.2 `e2e_windows_ps51_one_liner`** — on stock Windows PowerShell 5.1, run `irm …/install.ps1 | iex`. Same expectations as TEST-4.1. (AC1)
- [ ] **TEST-4.3 `e2e_rerun_no_changes`** — rerun both one-liners. No backups are created and the catalog is unchanged. (AC6)
- [ ] **TEST-4.4 `readme_commands_match_scripts`** — the README one-liners match the published raw URLs exactly.

## Dependencies and Blockers

- `devcraft merge` (DevCraft repository, operator in progress). This blocks only Phase 4 tests. Phases 1–3 test against a stub.
- GitHub owner/repo/branch. This blocks T4.1 and Phase 4 tests.
- A Windows machine or VM with Windows PowerShell 5.1. `pwsh` is not installed on the current Mac, so Phase 3 tests cannot run here.

## Traceability

| Requirement / AC | Tasks | Tests |
|---|---|---|
| R1 | T1.1 | TEST-1.1–1.5 |
| R2, R14 | T2.4, T3.5 | TEST-2.11, 3.10, 4.1, 4.2 |
| R3, R3a | T2.5, T3.6 | TEST-2.2, 2.7, 2.9, 2.10, 3.2, 3.7, 3.9 |
| R4, R12 | T2.6, T3.7 | TEST-2.8, 3.8 |
| R6 | T2.5, T3.6 | TEST-2.3, 3.3, 4.3 |
| R8 | T2.3, T3.4 | TEST-2.5, 2.6, 3.5, 3.6 |
| R9 | Phases 2, 3 | — |
| R10 | T2.5, T3.6 (PD1) | TEST-2.4, 3.4 |
| R13 | T2.2, T3.3 | TEST-3.6, 4.2 |
| AC7 | T1.1, T1.3 | TEST-1.2, 1.3 |
