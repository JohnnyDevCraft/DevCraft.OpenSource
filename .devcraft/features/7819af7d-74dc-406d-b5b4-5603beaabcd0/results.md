# Results: 001-InstallerFile

- Feature State: Implementation
- Implementation authorized: 2026-10-08. The operator said: "Skip analysis. You are clear to implement the plan." The operator chose to skip the Analysis state, so there is no `analysis.md`.

## Phase 1 — Catalog (2026-10-08)

### Changes

| File | Change | Why |
|---|---|---|
| `catalog.json` | New. 7 Architectures and 6 Standards copied verbatim from `~/.DevCraft/configure.json`, plus 1 new ProjectType, `project-type-php-laravel-breeze-mysql-modular-monolith`. Its description comes from the file's `## Description` section. Entries are sorted by slug. | R1, T1.1 |
| `.gitignore` | New. Excludes `.DS_Store`. | T1.2 |
| `tests/catalog.tests.sh` | New. Runs TEST-1.1–1.5 with `jq`, which is a development-only dependency. | T1.3, PD4 |

### Validation

- `tests/catalog.tests.sh`: 5/5 pass.
- Negative check: against a fixture with an orphan `.md`, a `Bad_Slug`, and a "Use this template" description, the expected 3 tests fail and the script exits `1`.
- TEST-1.6 (manual): all 13 existing paths map to identical slugs in the current profile catalog.

## Phase 2 — `install.sh` (2026-10-08)

### Changes

| File | Change | Why |
|---|---|---|
| `install.sh` | New. Strict mode; all logic in functions with `main "$@"` as the last line. Steps: prerequisite check → fetch (local folder, or `curl \| tar` of the `.tar.gz`) → copy `*.md` from the library folders with PD1 backups → `devcraft merge` → exit with the merge's status. The default source is a placeholder that fails with a clear message until T4.1. | R2–R4, R6, R8, R10, R12–R14 |
| `tests/install.sh.tests.sh` | New. A dependency-free runner that uses a sandboxed `DEVCRAFT_HOME`, a stub `devcraft`, and `env -i`, and runs the installer under `/bin/bash`. | PD4 |

### Notes

- The script targets **bash 3.2** (stock macOS `/bin/bash`, which is what the one-liner uses), so it avoids `mapfile`, associative arrays, and other bash 4 features.
- **Defect found and fixed during implementation:** `install_file` is called from an `|| fail` list, and bash suspends `set -e` inside such calls. A failed `cp` would therefore have been ignored and the merge would still have run, violating R3a/AC4. Fixed with explicit `|| return 1` on every step. A mutation test (removing the guards) makes `sh_copy_failure_skips_merge` fail, which confirms the test covers it.
- Added tests beyond the plan:
  - `sh_devcraft_found_in_profile`: the fallback to `$DEVCRAFT_HOME/devcraft`.
  - `sh_unconfigured_source_fails`: the placeholder guard.

### Validation

- `tests/install.sh.tests.sh`: 13 pass, 0 fail, 1 skipped.
- **TEST-2.1 (shellcheck) was skipped** because `shellcheck` is not installed on this machine.

## Phase 3 — `install.ps1` (2026-10-08)

### Changes

| File | Change | Why |
|---|---|---|
| `install.ps1` | New. All logic in functions. Strict mode, `$ErrorActionPreference = 'Stop'`, `$ProgressPreference = 'SilentlyContinue'`, and TLS 1.2 are set inside the entry function. Download uses `Invoke-WebRequest -UseBasicParsing` for the `.zip`, then `Expand-Archive`; a local `.zip` or folder can also be used. Copying uses `Get-FileHash` to detect changes, with PD1 backups. Then `& devcraft merge`, propagating `$LASTEXITCODE`. | R2–R4, R6, R8, R10, R12–R14, research.md §2.3 |
| `tests/install.ps1.Tests.ps1` | New. Pester 5 suite covering TEST-3.1–3.11 plus 2 extra tests. Each test runs the installer in a child process of the host edition, using a platform-specific stub (`devcraft.cmd` on Windows, a shell script elsewhere). | PD4 |

### Deviation from plan

- **No `exit` under `irm | iex`.** Planned as `exit $LASTEXITCODE` (T3.7). With `irm | iex` the script runs in the caller's session, so `exit` would close the user's PowerShell window. The script now calls `exit <code>` only when run as a file (`$PSCommandPath` is set); under `iex` it sets `$global:LASTEXITCODE`. R12 still holds for file runs. For one-liner runs, the result is available in `$LASTEXITCODE`. Covered by the extra test `ps_iex_mode_reports_failure_via_lastexitcode`.
- Because all logic is inside functions, strict mode and preference changes do not leak into the caller's session. The one exception is the TLS 1.2 flag, which is process-wide by design.
- TEST-3.7 makes the copy fail by placing a file where the `standards` folder should be, because read-only folders are not enforced on Windows.

### Validation

- **Not run.** Neither `pwsh` nor Windows PowerShell is available on this machine. Phase 3 is unverified until the Pester suite runs under both Windows PowerShell 5.1 and pwsh 7.

## Phase 4 — Publish (2026-10-08, partial)

### Changes

| File | Change | Why |
|---|---|---|
| `README.md` | New. Covers purpose, both one-liners, inspect-before-running steps, backups, the `DEVCRAFT_HOME`/`DEVCRAFT_SOURCE` overrides, the catalog rule, and how to run the tests. URLs use `<OWNER>/<REPO>/<BRANCH>` placeholders. | T4.2, research.md R-3 |

### T4.1 and README rewrite (2026-10-08)

The operator asked for a copy-paste README. The GitHub remote turned out to be `JohnnyDevCraft/DevCraft.OpenSource` (public, default branch `main`).

| File | Change | Why |
|---|---|---|
| `install.sh`, `install.ps1` | Default source and header one-liner now use `JohnnyDevCraft/DevCraft.OpenSource`, branch `main`. Removed the `<OWNER>` placeholder guard, which could no longer trigger. | T4.1 |
| `tests/install.sh.tests.sh` | Replaced `sh_unconfigured_source_fails` with `sh_default_source_is_github`, which uses a stub `curl` to assert the default `.tar.gz` URL without network access. | T4.1 |
| `tests/install.ps1.Tests.ps1` | Removed `ps_unconfigured_source_fails`, since the guard no longer exists. | T4.1 |
| `README.md` | Rewritten so the install commands come first and work when pasted: real one-liners for macOS/Linux and Windows, requirements, what the installer does, backups, inspect-first steps, options, troubleshooting, a table of everything included, and contributing steps. | Operator request, T4.2 |

Validation: `install.sh` tests 13 pass, 1 skipped (shellcheck). Catalog tests pass. A sandboxed run produced the README's sample output (`14 copied`).

### Remaining

- **TEST-4.1–4.4** need a DevCraft build with `devcraft merge` and a Windows machine.
