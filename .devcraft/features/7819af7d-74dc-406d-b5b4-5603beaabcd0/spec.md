# Feature Spec: 001-InstallerFile

## Feature Identity

- Feature Name: 001-InstallerFile
- Feature Slug: 001-installerfile
- Feature Folder: `.devcraft/features/7819af7d-74dc-406d-b5b4-5603beaabcd0/`
- Project: DevCraft.OpenSource (`0dcdbaaf-2105-44e8-8526-aa8f1e97385c`)
- Feature Storage: repo-central
- Feature Type: Pending (Feature | Bug | Enabler | Task)
- Feature State: Implementation
- Operator Mode: User Operator Mode
- Created: 2026-10-08

## Overview

Ship a JSON catalog at the repository root plus a one-line, Homebrew-style install script. Running the script installs this repository's reusable guidance (architectures, standards, project types, and later skills and templates) into the operator's profile `~/.DevCraft/` folder. It also merges the repository catalog's entries into the profile `~/.DevCraft/configure.json`.

## Goals

- A single remote command installs or updates this repository's content into an existing DevCraft profile install.
- A root catalog file is the source of truth for what the repository provides.
- Merging catalog entries into the profile `configure.json` is automatic, repeatable, and safe.

## Non-Goals

- Implementing, validating, or version-checking `devcraft merge`. The operator is building this in the DevCraft repository as separate work, and the scripts treat it as a black box. (Clarification #6)
- Parsing or writing `configure.json` from the scripts.

## Current State

Repository evidence (read-only inspection, 2026-10-08):

- The repository holds reusable DevCraft guidance as Markdown:
  - `architectures/` — Angular-FrontEnd, Electron-Wrapped-Angular, Ionic-Angular, Nx-Workspace, PHP-Laravel-Modular-Monolith, Playwrite-Tesing, SwiftUI-App.
  - `standards/` — GoLANG, Javascript, Laravel, PHP, Python, Typescript.
  - `project-types/` — php-laravel-breeze-mysql-modular-monolith.
- No installer, manifest, or catalog file exists at the repository root.
- The profile catalog (`~/.DevCraft/configure.json`) indexes entries by lowercase kebab-case slug with `Slug`, `Name`, `Description`, and `Path` fields, grouped into `Skills`, `Standards`, `Architectures`, `Templates`, `ProjectTypes`, and `FeatureStorageTypes`.
- The profile `devcraft-import` skill already describes importing documentation from a local repository into the profile folder and updating `configure.json`.
- Repository content and the profile catalog have drifted: `project-types/php-laravel-breeze-mysql-modular-monolith.md` is in this repository but not in the profile catalog.
- The project is in project status `Discovery`, discovery stage `Brainstorming`. The operator explicitly requested this feature, which DevCraft permits ahead of project discovery completion.

## Target State

- The repository root contains a JSON catalog that lists every installable entry with `Slug`, `Name`, `Description`, and `Path`, in the same section shape as the profile `configure.json`.
- The repository root contains an install script that can be invoked remotely, e.g. `/bin/bash -c "$(curl -fsSL <raw-url>/install.sh)"` and `irm <raw-url>/install.ps1 | iex`.
- Running the script does two things, in this order:
  1. It copies the catalog's Markdown files into `~/.DevCraft/` at the same relative paths.
  2. It calls `devcraft merge <catalog.json>`, and the DevCraft binary merges the catalog entries into `~/.DevCraft/configure.json`.
- The scripts never parse or write `configure.json`; the binary is its only writer.

## Requirements (Draft)

- R1. Root catalog file in JSON, mirroring the profile catalog section names (`Skills`, `Standards`, `Architectures`, `Templates`, `ProjectTypes`).
- R2. The install script fetches the repository content when it is run remotely (it must not assume a local clone).
- R3. The scripts copy the library folders (`architectures/`, `standards/`, `project-types/`, and later `skills/`, `templates/`) wholesale from the downloaded archive into `~/.DevCraft/<folder>/`. Only `*.md` files are copied, keeping relative paths. Neither script parses `catalog.json`. (Clarification #5, #8)
- R3a. File copying finishes before the merge runs. If any copy fails, the script stops and does not run the merge. (Clarification #5)
- R4. After all files are copied, the scripts invoke `devcraft merge <downloaded-catalog.json>`. How the merge behaves (matching by `Slug`, protected sections, idempotency, backup of `configure.json`) belongs to the DevCraft binary; see External Dependency. (Clarification #5, #6)
- R6. The file copy is idempotent: running the script twice leaves the same files on disk.
- R8. The scripts fail with a clear message, before copying anything, if `~/.DevCraft/configure.json` does not exist or the `devcraft` binary cannot be found (DevCraft not installed).
- R9. Deliver both `install.sh` (macOS/Linux) and `install.ps1` (Windows; also runs under pwsh). (Clarification #2)
- R10. Conflict policy is "repo wins, with backup": incoming entries replace profile entries with the same `Slug`, and incoming files overwrite existing files. The scripts make a timestamped backup of every file they overwrite; `devcraft merge` makes a timestamped backup of `configure.json`. (Clarification #3, #5)
- ~~R11. `install.sh` requires `jq`.~~ Superseded by Clarification #5: neither script parses JSON, so neither needs `jq` or a JSON library.
- R13. Profile root is `~/.DevCraft` on macOS/Linux and `%USERPROFILE%\.DevCraft` (`$HOME\.DevCraft`) on Windows. The binary is `devcraft` / `devcraft.exe`. (Clarification #9)
- R14. The repository is hosted on GitHub. The scripts download the GitHub source archive (`.tar.gz` for bash, `.zip` for PowerShell) of the default branch. Owner/repo are pending (see Open Questions). (Clarification #10)
- R12. The scripts propagate `devcraft merge`'s exit code and output. A non-zero exit means the install failed.

## External Dependency: `devcraft merge`

The merge is implemented in the DevCraft binary, which is a separate repository. The operator is building it in parallel, and that work owns its behavior. This feature only depends on the invocation `devcraft merge <path-to-catalog.json>` and a non-zero exit code on failure. End-to-end validation needs a DevCraft build that includes the command.

The following is reference only: the contract this feature assumes. It is not a requirement of this feature.

- Invocation: `devcraft merge <path-to-catalog.json>`. It must be non-interactive: no TUI, no startup scan prompts.
- Scope: the command merges only. It does not copy files.
- Input: a catalog containing any of `Skills`, `Standards`, `Architectures`, `Templates`, `ProjectTypes`. Each entry has `Slug`, `Name`, `Description`, `Path`, and `Path` is relative to `~/.DevCraft`.
- Behavior:
  - Upsert entries by `Slug` within each section; incoming entries win.
  - Leave every other section and key untouched.
  - Back up `configure.json` with a timestamp, then write the new file atomically.
  - Running it twice with the same input produces the same result.
- Validation: reject malformed JSON, unknown sections, missing fields, and slugs that are not kebab-case, without modifying anything.
- Output and exit codes: `0` on success, with a summary of added/updated entries. Non-zero on validation or IO failure, with nothing changed.

## Acceptance Criteria (Draft)

- AC1. With DevCraft installed, the remote one-liner on macOS (`install.sh`) and on Windows (`install.ps1`) copies every catalog file into `~/.DevCraft/<Path>`, then runs `devcraft merge`, and exits `0`.
- AC2. Any profile file that gets overwritten is backed up with a timestamp first.
- AC3. If `~/.DevCraft/configure.json` or the `devcraft` binary is missing, the script exits non-zero before copying anything.
- AC4. If a file copy fails, the script exits non-zero and does not run `devcraft merge`.
- AC5. If `devcraft merge` exits non-zero, the script exits non-zero and shows the merge output.
- AC6. Running the one-liner twice leaves the same files on disk.
- AC7. Every file in the repository's `architectures/`, `standards/`, and `project-types/` folders has an entry in the root catalog, and every catalog `Path` exists in the repository.

## Standards Application

- No profile `.DevCraft/standards` entry applies to Markdown or manifest content directly.
- The installer is a script. No profile standard currently covers shell or PowerShell. This standards gap must be acknowledged or filled (e.g. via `create-standard`) before Implementation.
- Catalog entries produced or consumed by the installer must follow the `configure.json` convention: lowercase kebab-case slugs and paths relative to the library root.

## Open Questions

1. What are the GitHub owner and repository name (and is the default branch `main`)? They are needed for the one-liner text and the scripts' default source URL. This does not block Planning.
2. Working assumption, not confirmed: the scripts download from the default branch now and move to release tags later (research.md R-2).

## Research Readiness

Research completed 2026-10-08; findings are in [research.md](research.md). Planning started 2026-10-08; tasks are in [tasks.md](tasks.md). Before the original readiness note:

Ready. Research should cover:
- Homebrew-style remote install patterns for bash and PowerShell.
- How to download the repository archive (tarball or zip, from which branch or tag).
- Cross-platform path handling.
- Script standards to apply, given that no shell or PowerShell standard exists in the profile.

## Clarification Log

| # | Date | Question | Decision | Affected Sections |
|---|------|----------|----------|-------------------|
| 1 | 2026-10-08 | What is the Installer File for, and what form should it take? | Operator direction (closest to 1C): a root JSON catalog plus a Homebrew-style remotely invokable shell and/or PowerShell script that merges the catalog's entries into the profile `~/.DevCraft/configure.json` and installs the files there. | Overview, Goals, Target State, Requirements, Open Questions |
| 2 | 2026-10-08 | Which install scripts should this feature deliver? | 2A: both `install.sh` and `install.ps1`. | Requirements (R9) |
| 3 | 2026-10-08 | How are Slug/file conflicts handled? | 3A: repo wins, with timestamped backups. | Requirements (R10) |
| 4 | 2026-10-08 | How does `install.sh` get a JSON tool? | 4A: require `jq` for bash. PowerShell needs nothing because it has native JSON. Operator proposed moving the merge into the binary as `devcraft merge {path}` (see Clarification #5). | Requirements (R11), Open Questions |
| 5 | 2026-10-08 | Where should the catalog merge logic live? | 5D: the scripts copy the `.md` files into place first, then call DevCraft (`devcraft merge`) to merge the catalog into the profile `configure.json`. R11 (`jq`) is superseded. | Target State, Requirements (R3, R3a, R4, R7, R8, R10, R11, R12), External Dependency. R5 and R7 were later moved to the binary's contract (Clarification #6). |
| 6 | 2026-10-08 | How should the scripts handle missing `Path`s and older DevCraft versions without `merge`? | Operator: the merge command is being built separately, and the scripts need not handle these details. Version checks and merge validation are out of scope; the scripts just invoke `devcraft merge` and pass its result through. | Non-Goals, External Dependency, Acceptance Criteria, Open Questions |
| 8 | 2026-10-08 | How does `install.sh` know which files to copy without parsing JSON? | 8A: copy the library folders wholesale, `*.md` only. AC7 keeps the folders and `catalog.json` in sync. | Requirements (R3) |
| 9 | 2026-10-08 | Where is the DevCraft profile on Windows? | Confirmed: `%USERPROFILE%\.DevCraft`, binary `devcraft.exe`. | Requirements (R13) |
| 10 | 2026-10-08 | Where is this repository hosted? | GitHub. Owner/repo/branch still to be supplied. | Requirements (R14), Open Questions |

## Notes

- No spec template exists in profile `.DevCraft/templates/`; this spec follows the section list required by `DevCraft.md` (Discovery responsibilities) and the GitHub Issue Feature Intake skill.
- Environment note: macOS 15+ ships `/usr/bin/jq` (this machine: jq 1.7.1); most Linux distributions do not install it by default. PowerShell has native JSON support.
- The profile folder is `~/.DevCraft` (mixed case). macOS tolerates `~/.devcraft`, but case-sensitive Linux file systems do not, so the scripts must use the exact casing.
- The DevCraft binary is installed at `~/.DevCraft/devcraft` (1.0.0-alpha.6, Mach-O arm64) and is on `PATH`. Invoking it with `--help` starts the normal startup scan rather than printing usage, so no non-interactive subcommand surface was observed.
- `.devcraft/configure.json` names `FeaturesIndexPath: features.json`, but no `features.json` exists; the feature is currently indexed in the `Features` array of `.devcraft/configure.json`. Left unchanged.
