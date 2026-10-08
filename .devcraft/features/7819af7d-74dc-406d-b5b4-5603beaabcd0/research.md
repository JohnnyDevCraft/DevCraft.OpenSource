# Research: 001-InstallerFile

- Feature State: Research
- Date: 2026-10-08
- Inputs: `spec.md` (Clarifications #1–#6), repository inspection, profile `~/.DevCraft/` inspection, web sources listed below.

## 1. Repository Evidence

### 1.1 Repository content vs. profile catalog

All checks were read-only, comparing this repository with `~/.DevCraft/` byte for byte (`cmp`).

| Repository file | Profile slug | Profile file |
|---|---|---|
| `architectures/Angular-FrontEnd.md` | `angular-frontend` | identical |
| `architectures/Electron-Wrapped-Angular.md` | `electron-wrapped-angular` | identical |
| `architectures/Ionic-Angular.md` | `ionic-angular` | identical |
| `architectures/Nx-Workspace.md` | `nx-workspace` | identical |
| `architectures/PHP-Laravel-Modular-Monolith.md` | `php-laravel-modular-monolith` | identical |
| `architectures/Playwrite-Tesing.md` | `playwright-testing` | identical |
| `architectures/SwiftUI-App.md` | `swiftui-app` | identical |
| `standards/GoLANG.md` | `go-standards` | identical |
| `standards/Javascript.md` | `javascript-standards` | identical |
| `standards/Laravel.md` | `laravel-standards` | identical |
| `standards/PHP.md` | `php-standards` | identical |
| `standards/Python.md` | `python-standards` | identical |
| `standards/Typescript.md` | `typescript-standards` | identical |
| `project-types/php-laravel-breeze-mysql-modular-monolith.md` | **none** | **absent** |

Findings:

- 13 of the 14 files already exist in the profile with identical content. Their catalog entries should reuse the existing profile slugs so the "repo wins" upsert (Clarification #3) updates entries instead of duplicating them.
- One entry is new. Profile project-type slugs follow `project-type-<kebab-title>`, so the proposed slug is `project-type-php-laravel-breeze-mysql-modular-monolith`.
- The new project type's opening line ("Use this template to define a type of project…") is leftover template boilerplate, and some existing profile entries carry the same placeholder description. The catalog should take its description from the file's `## Description` section instead.
- File names keep their existing spelling (`Playwrite-Tesing.md`) because profile paths already reference them. Renaming is out of scope.
- The profile contains paths with spaces (`standards/ASP.Net Core.md`), so the scripts must quote every path even though none of this repository's current files has a space.
- The repository has `.DS_Store` files in `architectures/` and `standards/`. The scripts copy only catalog paths, so these are ignored, but a `.gitignore` entry is advisable.

### 1.2 DevCraft profile and binary

- The profile root is `~/.DevCraft` (mixed case). The binary is `~/.DevCraft/devcraft` (Mach-O arm64, 1.0.0-alpha.6) and is on `PATH`.
- `configure.json` is written with .NET-style escaping (`'`, ```, `+`). This confirms the binary is the natural writer of that file (Clarification #5).
- Windows profile location: `$HOME\.DevCraft` (`%USERPROFILE%\.DevCraft`), binary `devcraft.exe`. Confirmed by the operator (Clarification #9).

### 1.3 Repository hosting

- This working folder is **not a git repository** and has no remote. The raw-content URL and archive URL (`<owner>/<repo>`, default branch) are therefore undetermined. This blocks the final one-liner text, but not the script design.

## 2. External Findings

### 2.1 Remote-install entry points

- Homebrew documents `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` [S2]. The `$(...)` form captures the whole script before bash runs it, which reduces the partial-download risk of `curl | bash`. Piped bash can start executing before the download finishes [S3].
- Defensive practice (general shell behavior, not sourced): put all logic in functions and call `main "$@"` on the last line, so a truncated download defines functions but runs nothing.
- PowerShell equivalent: `irm <url>/install.ps1 | iex`.

### 2.2 Downloading the repository content

- GitHub serves archives at `https://github.com/OWNER/REPO/archive/refs/heads/BRANCH.tar.gz` (or `.zip`), `.../archive/refs/tags/TAG.zip`, and `.../archive/<sha>.zip` [S1].
- Branch and tag archives can change between downloads; only commit-SHA archives have stable content. Archive checksums are not stable because the compression settings may change [S1].
- An archive extracts to a single top-level folder (`REPO-BRANCH/`), so the scripts must resolve the catalog path inside it.
- Recommended tools: `install.sh` uses `curl` + `tar` (both present on macOS and mainstream Linux); `install.ps1` uses `Invoke-WebRequest` for the `.zip` + `Expand-Archive`.

### 2.3 Windows PowerShell 5.1 pitfalls

- PowerShell 5.1 may default to older TLS versions, and GitHub requires TLS 1.2. Set `[Net.ServicePointManager]::SecurityProtocol` to include `Tls12` before any request [S4].
- The progress bar slows `Invoke-WebRequest` dramatically on 5.1. Set `$ProgressPreference = 'SilentlyContinue'` around downloads [S5].
- The December 2025 Windows update adds a security prompt to `Invoke-WebRequest` on 5.1 unless `-UseBasicParsing` is passed [S6]. An interactive prompt would break the unattended install, so pass `-UseBasicParsing` on every `Invoke-WebRequest` call. Whether `irm` is affected was not confirmed.
- PowerShell 7 (`pwsh`) has none of these issues, but the script must run on stock Windows PowerShell 5.1.

## 3. Script Design Implications

| Concern | `install.sh` | `install.ps1` |
|---|---|---|
| Strict mode | `set -euo pipefail`; `main "$@"` on the last line | `$ErrorActionPreference = 'Stop'`; `Set-StrictMode -Version Latest`; logic in a function invoked at the end |
| Prerequisite check (R8) | `~/.DevCraft/configure.json` exists; `command -v devcraft`, falling back to `~/.DevCraft/devcraft` | `Test-Path "$HOME\.DevCraft\configure.json"`; `Get-Command devcraft`, falling back to `$HOME\.DevCraft\devcraft.exe` |
| Download (R2) | `curl -fsSL` the archive into `mktemp -d`; `tar -xzf` | `Invoke-WebRequest -UseBasicParsing -OutFile`; `Expand-Archive` into a temp folder |
| Select files (8A) | `find <lib-folders> -name '*.md'` | `Get-ChildItem -Recurse -Filter *.md` |
| Copy + backup (R3, R10) | Per path: if the target exists and differs, copy it to `<target>.<timestamp>.bak`, then `mkdir -p` and copy | Same, with `Copy-Item` and `New-Item -ItemType Directory -Force` |
| Merge (R4, R12) | `devcraft merge "$catalog"`; exit with its status | `& devcraft merge $catalog`; propagate `$LASTEXITCODE` |
| Cleanup | `trap` removes the temp folder | `try/finally` removes the temp folder |

## 4. Gaps and Risks

- **G1 — The bash script must read catalog paths (needs operator decision).** R3 says to copy "each catalog entry's file", so the script has to read `Path` values from JSON. Clarification #5 removed `jq` because the scripts no longer write JSON, but reading still needs a parser. Options:
  - Copy the known library folders (`architectures/`, `standards/`, `project-types/`, and later `skills/`, `templates/`) wholesale, without reading the catalog. This needs no JSON parsing, and AC7 (catalog and repository match) keeps them consistent.
  - Use `jq` for reading only (present on macOS 15+, optional on Linux).
  - Have DevCraft also list the paths (`devcraft merge` remains merge-only per #5, so this would be a new ask).

  Recommendation: copy the library folders wholesale, filtered to `*.md`.

  **Resolved 2026-10-08 (Clarification #8): option A.** Folders are copied wholesale, `*.md` only, and no JSON is parsed in either script.
- **R-1 — Windows profile location unverified.** If DevCraft on Windows uses a different root (for example `%APPDATA%`), the copy target is wrong. **Resolved (Clarification #9):** the operator confirmed `%USERPROFILE%\.DevCraft`.
- **R-2 — Hosting: GitHub (Clarification #10).** The owner, repo name, and branch are still unknown, because this folder has no git remote. Ref pinning (branch vs. tag) affects reproducibility [S1].
- **R-3 — Remote execution trust.** `curl`/`irm` → execute is an accepted industry pattern [S2], but it runs whatever the URL serves. Mitigations: HTTPS only, hosting on GitHub, and documenting a "download, inspect, run" alternative in the README.
- **R-4 — Partial install.** Copying succeeds, then the merge fails, leaving files on disk without catalog entries. Rerunning fixes it (idempotent, repo wins). Accepted per Clarification #5.
- **R-5 — No shell/PowerShell standard.** Proposed validation in place of one: `shellcheck` clean for `install.sh`, `PSScriptAnalyzer` clean for `install.ps1`. Optionally create a standard through `create-standard`.

## 5. Testing Approach

- Override seams (recommended): `DEVCRAFT_HOME` (default `~/.DevCraft`) and `DEVCRAFT_SOURCE` (an archive URL or a local folder path). Tests can then run against a sandbox profile and a local checkout without GitHub.
- Cases:
  - Fresh install.
  - Rerun (idempotency).
  - Overwrite with backup.
  - Missing `configure.json`.
  - Missing `devcraft`.
  - Copy failure (read-only target).
  - `devcraft merge` failure (stub binary that exits `1`).
  - Path with a space.
- Static checks: `shellcheck install.sh`; `Invoke-ScriptAnalyzer install.ps1`.
- End-to-end: the remote one-liner against the real hosted URL on macOS and on Windows PowerShell 5.1, once a DevCraft build includes `merge`.

## 6. Recommended Direction

1. Add `catalog.json` at the repository root.
   - Sections: `Architectures`, `Standards`, `ProjectTypes` (with `Skills`/`Templates` reserved for later).
   - Reuse the 13 existing profile slugs; add `project-type-php-laravel-breeze-mysql-modular-monolith`.
2. `install.sh` and `install.ps1`, in this order:
   1. Verify DevCraft is installed.
   2. Download the archive into a temp folder.
   3. Copy the library Markdown, backing up any file that differs.
   4. Run `devcraft merge <temp>/catalog.json`.
   5. Clean up and exit with the merge's status.
3. G1 and R-1 are resolved. R-2 still needs the GitHub owner/repo, which only fills in the URL constant and does not block Planning.

## Sources

- [S1] GitHub Docs — Downloading source code archives: https://docs.github.com/en/repositories/working-with-files/using-files/downloading-source-code-archives
- [S2] Nightwatch Cybersecurity — Security of Homebrew Bootstrap Process: https://wwws.nightwatchcybersecurity.com/2021/04/30/security-of-homebrew-bootstrap-process/
- [S3] Why `curl | bash` is a dangerous bad habit: https://tferdinand.net/en/why-curl-bash-is-a-dangerous-bad-habit/
- [S4] Automox — Force PowerShell to Use TLS 1.2: https://help.automox.com/hc/en-us/articles/31578579603732-Force-PowerShell-to-Use-TLS-1-2
- [S5] Faster Invoke-WebRequest (ProgressPreference): https://zenn.dev/skmkzyk/articles/faster-invoke-webrequest
- [S6] Microsoft — PowerShell 5.1: Invoke-WebRequest: Preventing script execution from web content (Dec 2025): https://support.microsoft.com/fi-FI/servicing/os/windows/2025/12/powershell-5-1-invoke-webrequest-preventing-script-execution-from-web-content
