# DevCraft.OpenSource

Reusable [DevCraft](https://github.com/JohnnyDevCraft/DevCraft) guidance for open source development: architectures, coding standards, and project types.

One command installs everything into your DevCraft profile and registers it in your DevCraft catalog.

## Install

Paste the line for your platform into a terminal.

### macOS / Linux

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JohnnyDevCraft/DevCraft.OpenSource/main/install.sh)"
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/JohnnyDevCraft/DevCraft.OpenSource/main/install.ps1 | iex
```

Works in Windows PowerShell 5.1 and PowerShell 7. You don't need to change the execution policy.

When it finishes you'll see something like:

```text
Downloading https://github.com/JohnnyDevCraft/DevCraft.OpenSource/archive/refs/heads/main.tar.gz
Library files: 14 copied, 0 unchanged, 0 backed up.
Merging catalog with: devcraft merge
DevCraft.OpenSource installed into /Users/you/.DevCraft.
```

## Requirements

- DevCraft must already be installed:
  - The profile file `~/.DevCraft/configure.json` exists (Windows: `%USERPROFILE%\.DevCraft\configure.json`).
  - The `devcraft` command is on your `PATH`, or the binary is in the profile folder.
- Your DevCraft version must support `devcraft merge`.
- macOS/Linux: `curl` and `tar`. Both are present by default.

## What the installer does

1. **Checks** that DevCraft is installed. If it isn't, the installer stops before changing anything.
2. **Downloads** this repository from GitHub into a temporary folder. The folder is deleted afterwards.
3. **Copies** the Markdown files from `architectures/`, `standards/`, `project-types/`, `skills/`, and `templates/` into your profile at the same paths, for example `~/.DevCraft/standards/Python.md`.
   - Files that are already identical are skipped.
   - Files that differ are **backed up**, then replaced.
4. **Merges** this repository's `catalog.json` into your profile catalog by running `devcraft merge`. New entries are added and existing entries with the same slug are updated.

The installer exits non-zero if any step fails. If a copy fails, the merge is not run.

Running the installer again is safe, and it's also how you update.

## Backups

Before overwriting a file, the installer saves the previous version to:

```text
~/.DevCraft/backups/install-<yyyyMMdd-HHmmss>/<original path>
```

On Windows this is `%USERPROFILE%\.DevCraft\backups\...`. To undo an update, copy the file back. `devcraft merge` handles backing up `configure.json` itself.

## Inspect before running

If you'd rather read the script before running it:

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/JohnnyDevCraft/DevCraft.OpenSource/main/install.sh
less install.sh
/bin/bash install.sh
```

```powershell
irm https://raw.githubusercontent.com/JohnnyDevCraft/DevCraft.OpenSource/main/install.ps1 -OutFile install.ps1
notepad install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## Options

Set these environment variables before running the installer to change its behavior:

| Variable | Default | Purpose |
|---|---|---|
| `DEVCRAFT_HOME` | `~/.DevCraft` (`%USERPROFILE%\.DevCraft`) | The profile to install into. |
| `DEVCRAFT_SOURCE` | `https://github.com/JohnnyDevCraft/DevCraft.OpenSource/archive/refs/heads/main` | Where to install from. Accepts an archive URL, a local archive (`.tar.gz` for bash, `.zip` for PowerShell), or a local folder such as a clone or fork. |

Example: install from a local clone.

```bash
DEVCRAFT_SOURCE="$PWD" ./install.sh
```

```powershell
$env:DEVCRAFT_SOURCE = (Get-Location).Path; .\install.ps1
```

## Troubleshooting

| Message | Fix |
|---|---|
| `DevCraft is not installed: …configure.json was not found.` | Install DevCraft first, or set `DEVCRAFT_HOME` to your profile folder. |
| `DevCraft is not installed: the devcraft binary was not found…` | Add the DevCraft binary to your `PATH`, or place it in the profile folder. |
| `devcraft merge failed (exit N).` | Your DevCraft version may not support `devcraft merge`; update DevCraft and run the installer again. The files are already copied, so a rerun completes the install. |
| `could not download or extract …` | Check your network connection and that GitHub is reachable. |

## What's included

| Type | Slug | Description |
|---|---|---|
| Architecture | `angular-frontend` | Default architecture guidance for Angular frontend applications. |
| Architecture | `electron-wrapped-angular` | Default architecture guidance for an Angular application packaged with Electron. |
| Architecture | `ionic-angular` | Default architecture guidance for Ionic Angular applications. |
| Architecture | `nx-workspace` | Default architecture guidance for an Nx workspace. |
| Architecture | `php-laravel-modular-monolith` | Default architecture guidance for a Laravel modular monolith. |
| Architecture | `playwright-testing` | Default architecture guidance for Playwright end-to-end and workflow-focused UI tests. |
| Architecture | `swiftui-app` | Default architecture guidance for SwiftUI applications. |
| Standard | `go-standards` | Coding standards for Go services, CLIs, libraries, and tests. |
| Standard | `javascript-standards` | Coding standards for JavaScript in browser, server, scripting, and test environments. |
| Standard | `laravel-standards` | Laravel-specific standards built on the shared PHP standards. |
| Standard | `php-standards` | Coding standards for PHP applications, libraries, CLI commands, jobs, and tests. |
| Standard | `python-standards` | Coding standards for Python applications, services, scripts, automation, and tests. |
| Standard | `typescript-standards` | Coding standards for TypeScript applications, libraries, frontend, backend, and tests. |
| Project type | `project-type-php-laravel-breeze-mysql-modular-monolith` | Laravel modular monolith with Breeze (Blade) authentication, MySQL via Sail, and PHPUnit. |

## Contributing

1. Add or edit Markdown in `architectures/`, `standards/`, `project-types/`, `skills/`, or `templates/`.
2. Add or update the file's entry in `catalog.json`.
   - Each entry has `Slug`, `Name`, `Description`, and `Path`.
   - Slugs are lowercase kebab-case, and `Path` is relative to the repository root.
   - Every Markdown file in those folders needs exactly one entry.
3. Run the tests:

```bash
tests/catalog.tests.sh        # catalog consistency (requires jq)
tests/install.sh.tests.sh     # install.sh in a sandbox (shellcheck optional)
```

```powershell
Invoke-Pester ./tests/install.ps1.Tests.ps1   # run under Windows PowerShell 5.1 and pwsh 7 (Pester 5)
```
