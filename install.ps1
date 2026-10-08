<#
DevCraft.OpenSource installer (Windows PowerShell 5.1 / PowerShell 7).

    irm https://raw.githubusercontent.com/JohnnyDevCraft/DevCraft.OpenSource/main/install.ps1 | iex

Copies this repository's library Markdown into the DevCraft profile, then asks
DevCraft to merge catalog.json into the profile catalog (devcraft merge).

Environment overrides:
    DEVCRAFT_HOME    Profile root. Default: $HOME\.DevCraft
    DEVCRAFT_SOURCE  Archive URL (with or without .zip), local .zip file, or local folder.

Everything runs inside functions invoked from the last line. Under `irm | iex`
this keeps strict mode and preference changes out of the caller's session, and
the script never calls `exit` (which would close the caller's window); it sets
$LASTEXITCODE instead. Run as a file, it exits with the result code.
#>

function Get-DevCraftInstallConfig {
    $defaultSource = 'https://github.com/JohnnyDevCraft/DevCraft.OpenSource/archive/refs/heads/main'

    $home_ = $env:DEVCRAFT_HOME
    if ([string]::IsNullOrEmpty($home_)) { $home_ = Join-Path $HOME '.DevCraft' }

    $source = $env:DEVCRAFT_SOURCE
    if ([string]::IsNullOrEmpty($source)) { $source = $defaultSource }

    [pscustomobject]@{ Home = $home_; Source = $source }
}

function Resolve-DevCraftBinary {
    param([string] $ProfileRoot)

    if (-not (Test-Path -LiteralPath (Join-Path $ProfileRoot 'configure.json') -PathType Leaf)) {
        throw "DevCraft is not installed: $(Join-Path $ProfileRoot 'configure.json') was not found."
    }

    $command = Get-Command devcraft -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }

    $binaryName = 'devcraft'
    if ($env:OS -eq 'Windows_NT') { $binaryName = 'devcraft.exe' }
    $candidate = Join-Path $ProfileRoot $binaryName
    if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }

    throw "DevCraft is not installed: the devcraft binary was not found on PATH or in $ProfileRoot."
}

function Get-DevCraftSource {
    param([string] $Source, [string] $WorkDir)

    if (Test-Path -LiteralPath $Source -PathType Container) {
        $root = $Source
    }
    else {
        if (Test-Path -LiteralPath $Source -PathType Leaf) {
            $zip = $Source
        }
        else {
            $url = $Source
            if (-not $url.EndsWith('.zip')) { $url = "$url.zip" }
            $zip = Join-Path $WorkDir 'source.zip'
            Write-Host "Downloading $url"
            Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        }

        $root = Join-Path $WorkDir 'src'
        Expand-Archive -LiteralPath $zip -DestinationPath $root -Force

        if (-not (Test-Path -LiteralPath (Join-Path $root 'catalog.json'))) {
            $entries = @(Get-ChildItem -LiteralPath $root -Force)
            if ($entries.Count -eq 1 -and $entries[0].PSIsContainer) { $root = $entries[0].FullName }
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $root 'catalog.json') -PathType Leaf)) {
        throw 'catalog.json was not found in the source.'
    }
    (Resolve-Path -LiteralPath $root).ProviderPath
}

function Copy-DevCraftLibrary {
    param([string] $SourceRoot, [string] $ProfileRoot)

    $libraryFolders = @('architectures', 'standards', 'project-types', 'skills', 'templates')
    $backupDir = Join-Path (Join-Path $ProfileRoot 'backups') ("install-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $copied = 0; $unchanged = 0; $backedUp = 0

    foreach ($folder in $libraryFolders) {
        $folderPath = Join-Path $SourceRoot $folder
        if (-not (Test-Path -LiteralPath $folderPath -PathType Container)) { continue }

        foreach ($file in Get-ChildItem -LiteralPath $folderPath -Recurse -File -Filter '*.md') {
            $relative = $file.FullName.Substring($SourceRoot.TrimEnd('\', '/').Length + 1)
            $target = Join-Path $ProfileRoot $relative

            try {
                if (Test-Path -LiteralPath $target -PathType Leaf) {
                    if ((Get-FileHash -LiteralPath $target).Hash -eq (Get-FileHash -LiteralPath $file.FullName).Hash) {
                        $unchanged++
                        continue
                    }
                    $backup = Join-Path $backupDir $relative
                    New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
                    Copy-Item -LiteralPath $target -Destination $backup
                    $backedUp++
                }

                New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
                Copy-Item -LiteralPath $file.FullName -Destination $target -Force
                $copied++
            }
            catch {
                throw "Could not install ${relative}; catalog merge skipped. $($_.Exception.Message)"
            }
        }
    }

    Write-Host "Library files: $copied copied, $unchanged unchanged, $backedUp backed up."
    if ($backedUp -gt 0) { Write-Host "Backups: $backupDir" }
}

function Invoke-DevCraftOpenSourceInstall {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ("devcraft-install-" + [guid]::NewGuid().ToString('N'))
    try {
        $config = Get-DevCraftInstallConfig
        $devcraft = Resolve-DevCraftBinary -ProfileRoot $config.Home
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
        $sourceRoot = Get-DevCraftSource -Source $config.Source -WorkDir $workDir

        Copy-DevCraftLibrary -SourceRoot $sourceRoot -ProfileRoot $config.Home

        Write-Host 'Merging catalog with: devcraft merge'
        & $devcraft merge (Join-Path $sourceRoot 'catalog.json') | Out-Host
        $mergeExit = $LASTEXITCODE
        if ($mergeExit -ne 0) {
            Write-Host "devcraft-install: devcraft merge failed (exit $mergeExit)." -ForegroundColor Red
            return $mergeExit
        }

        Write-Host "DevCraft.OpenSource installed into $($config.Home)."
        return 0
    }
    catch {
        Write-Host "devcraft-install: $($_.Exception.Message)" -ForegroundColor Red
        return 1
    }
    finally {
        if (Test-Path -LiteralPath $workDir) { Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

function Complete-DevCraftOpenSourceInstall {
    param([int] $Code)

    # $PSCommandPath is set only when this script runs from a file; under `irm | iex` it is empty.
    if ($PSCommandPath) { exit $Code }
    $global:LASTEXITCODE = $Code
}

Complete-DevCraftOpenSourceInstall -Code (Invoke-DevCraftOpenSourceInstall)
