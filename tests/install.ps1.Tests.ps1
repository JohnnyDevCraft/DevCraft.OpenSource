# install.ps1 tests (TEST-3.1 – TEST-3.11), Pester 5.
# Run under both Windows PowerShell 5.1 and PowerShell 7:
#   powershell -NoProfile -Command "Invoke-Pester ./tests/install.ps1.Tests.ps1"
#   pwsh       -NoProfile -Command "Invoke-Pester ./tests/install.ps1.Tests.ps1"
# The installer runs in a child process of the same PowerShell edition as the test host.

BeforeAll {
    $script:Root = Split-Path -Parent $PSScriptRoot
    $script:Installer = Join-Path $Root 'install.ps1'
    $script:HostExe = (Get-Process -Id $PID).Path
    $script:OnWindows = $env:OS -eq 'Windows_NT'

    function New-Sandbox {
        $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ("devcraft-tests-" + [guid]::NewGuid().ToString('N'))
        $profileRoot = Join-Path $sandbox 'profile'
        $stubDir = Join-Path $sandbox 'bin'
        New-Item -ItemType Directory -Path $profileRoot, $stubDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $profileRoot 'configure.json') -Value '{}'

        if ($OnWindows) {
            Set-Content -LiteralPath (Join-Path $stubDir 'devcraft.cmd') -Value @(
                '@echo off'
                'echo %*>>"%STUB_LOG%"'
                'if defined STUB_OUTPUT echo %STUB_OUTPUT%'
                'if not defined STUB_EXIT set STUB_EXIT=0'
                'exit /b %STUB_EXIT%'
            )
        }
        else {
            $stub = Join-Path $stubDir 'devcraft'
            Set-Content -LiteralPath $stub -Value @(
                '#!/bin/sh'
                'echo "$@" >> "$STUB_LOG"'
                '[ -n "$STUB_OUTPUT" ] && echo "$STUB_OUTPUT"'
                'exit "${STUB_EXIT:-0}"'
            )
            chmod +x $stub
        }

        [pscustomobject]@{ Dir = $sandbox; Profile = $profileRoot; Stub = $stubDir; Log = (Join-Path $sandbox 'merge.log') }
    }

    function Remove-Sandbox($Sandbox) {
        Get-ChildItem -LiteralPath $Sandbox.Dir -Recurse -Force -ErrorAction SilentlyContinue |
            ForEach-Object { if (-not $_.PSIsContainer) { $_.IsReadOnly = $false } }
        Remove-Item -LiteralPath $Sandbox.Dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    # Runs the installer in a child process. -Mode File runs it as a script file; -Mode Iex pipes it to Invoke-Expression.
    function Invoke-Installer {
        param($Sandbox, [string] $Source, [hashtable] $ExtraEnv = @{}, [ValidateSet('File', 'Iex')] [string] $Mode = 'File')

        $systemPath = if ($OnWindows) { "$env:SystemRoot\System32;$env:SystemRoot" } else { '/usr/bin:/bin' }
        $vars = @{
            DEVCRAFT_HOME   = $Sandbox.Profile
            DEVCRAFT_SOURCE = $Source
            STUB_LOG        = $Sandbox.Log
            STUB_EXIT       = $null
            STUB_OUTPUT     = $null
            PATH            = "$($Sandbox.Stub)$([System.IO.Path]::PathSeparator)$systemPath"
        }
        foreach ($key in $ExtraEnv.Keys) { $vars[$key] = $ExtraEnv[$key] }

        $saved = @{}
        foreach ($key in $vars.Keys) {
            $saved[$key] = [Environment]::GetEnvironmentVariable($key)
            [Environment]::SetEnvironmentVariable($key, $vars[$key])
        }
        try {
            if ($Mode -eq 'File') {
                $output = & $HostExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Installer *>&1 | Out-String
                $code = $LASTEXITCODE
            }
            else {
                $command = "Get-Content -Raw -LiteralPath '$Installer' | Invoke-Expression; Write-Output ('AFTER:' + `$LASTEXITCODE)"
                $output = & $HostExe -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command $command *>&1 | Out-String
                $code = $LASTEXITCODE
            }
        }
        finally {
            foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
        }
        [pscustomobject]@{ Code = $code; Output = $output }
    }

    function Get-LibraryFiles($Base) {
        foreach ($folder in 'architectures', 'standards', 'project-types', 'skills', 'templates') {
            $path = Join-Path $Base $folder
            if (Test-Path -LiteralPath $path) {
                Get-ChildItem -LiteralPath $path -Recurse -File -Filter '*.md' |
                    ForEach-Object { $_.FullName.Substring($Base.TrimEnd('\', '/').Length + 1).Replace('\', '/') }
            }
        }
    }

    function New-Fixture($Sandbox) {
        $fixture = Join-Path $Sandbox.Dir 'fixture'
        New-Item -ItemType Directory -Path (Join-Path $fixture 'standards') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture 'catalog.json') -Value '{"Standards":[]}'
        Set-Content -LiteralPath (Join-Path $fixture 'standards/Fixture.md') -Value '# Fixture'
        $fixture
    }
}

Describe 'install.ps1' {
    BeforeEach { $script:Box = New-Sandbox }
    AfterEach { Remove-Sandbox $Box }

    It 'TEST-3.1 ps_scriptanalyzer_clean' {
        if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
            Set-ItResult -Skipped -Because 'PSScriptAnalyzer is not installed'
            return
        }
        $findings = Invoke-ScriptAnalyzer -Path $Installer -Severity Warning, Error -ExcludeRule PSAvoidUsingWriteHost
        $findings | Should -BeNullOrEmpty
    }

    It 'TEST-3.2 ps_fresh_install_copies_and_merges' {
        $result = Invoke-Installer $Box $Root
        $result.Code | Should -Be 0 -Because $result.Output
        (Get-LibraryFiles $Box.Profile | Sort-Object) -join "`n" | Should -Be ((Get-LibraryFiles $Root | Sort-Object) -join "`n")
        (Get-Content -LiteralPath $Box.Log -Raw).Trim() | Should -Be "merge $(Join-Path $Root 'catalog.json')"
    }

    It 'TEST-3.3 ps_rerun_is_idempotent' {
        (Invoke-Installer $Box $Root).Code | Should -Be 0
        $first = Get-ChildItem -LiteralPath $Box.Profile -Recurse -File | Get-FileHash | ForEach-Object Hash | Sort-Object
        (Invoke-Installer $Box $Root).Code | Should -Be 0
        $second = Get-ChildItem -LiteralPath $Box.Profile -Recurse -File | Get-FileHash | ForEach-Object Hash | Sort-Object
        Join-Path $Box.Profile 'backups' | Should -Not -Exist
        ($second -join ',') | Should -Be ($first -join ',')
    }

    It 'TEST-3.4 ps_changed_file_is_backed_up' {
        New-Item -ItemType Directory -Path (Join-Path $Box.Profile 'standards') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $Box.Profile 'standards/Python.md') -Value 'local edit'
        (Invoke-Installer $Box $Root).Code | Should -Be 0
        $backup = Get-ChildItem -LiteralPath (Join-Path $Box.Profile 'backups') -Recurse -File -Filter 'Python.md' | Select-Object -First 1
        $backup | Should -Not -BeNullOrEmpty
        (Get-Content -LiteralPath $backup.FullName -Raw).Trim() | Should -Be 'local edit'
        (Get-FileHash (Join-Path $Box.Profile 'standards/Python.md')).Hash | Should -Be (Get-FileHash (Join-Path $Root 'standards/Python.md')).Hash
    }

    It 'TEST-3.5 ps_missing_configure_json_fails_early' {
        Remove-Item -LiteralPath (Join-Path $Box.Profile 'configure.json')
        $result = Invoke-Installer $Box $Root
        $result.Code | Should -Not -Be 0
        Get-LibraryFiles $Box.Profile | Should -BeNullOrEmpty
        $Box.Log | Should -Not -Exist
    }

    It 'TEST-3.6 ps_missing_devcraft_fails_early' {
        Get-ChildItem -LiteralPath $Box.Stub | Remove-Item -Force
        $result = Invoke-Installer $Box $Root
        $result.Code | Should -Not -Be 0
        Get-LibraryFiles $Box.Profile | Should -BeNullOrEmpty
    }

    It 'TEST-3.7 ps_copy_failure_skips_merge' {
        # A file where the standards folder should be makes directory creation fail on every platform.
        Set-Content -LiteralPath (Join-Path $Box.Profile 'standards') -Value 'blocker'
        $result = Invoke-Installer $Box $Root
        $result.Code | Should -Not -Be 0
        $Box.Log | Should -Not -Exist
    }

    It 'TEST-3.8 ps_merge_failure_propagates' {
        $result = Invoke-Installer $Box $Root -ExtraEnv @{ STUB_EXIT = '3'; STUB_OUTPUT = 'boom' }
        $result.Code | Should -Be 3
        $result.Output | Should -Match 'boom'
    }

    It 'TEST-3.9 ps_path_with_space' {
        $fixture = New-Fixture $Box
        Set-Content -LiteralPath (Join-Path $fixture 'standards/With Space.md') -Value '# Space'
        (Invoke-Installer $Box $fixture).Code | Should -Be 0
        Join-Path $Box.Profile 'standards/With Space.md' | Should -Exist
    }

    It 'TEST-3.10 ps_zip_source' {
        $fixture = New-Fixture $Box
        $staging = Join-Path $Box.Dir 'archive/repo-main'
        New-Item -ItemType Directory -Path (Split-Path -Parent $staging) -Force | Out-Null
        Copy-Item -LiteralPath $fixture -Destination $staging -Recurse
        $zip = Join-Path $Box.Dir 'main.zip'
        Compress-Archive -Path $staging -DestinationPath $zip
        $result = Invoke-Installer $Box $zip
        $result.Code | Should -Be 0 -Because $result.Output
        Join-Path $Box.Profile 'standards/Fixture.md' | Should -Exist
        Get-Content -LiteralPath $Box.Log -Raw | Should -Match 'repo-main[\\/]catalog\.json'
    }

    It 'TEST-3.11 ps_no_interactive_prompt_on_51 (and iex mode keeps the session alive)' {
        # -NonInteractive makes any prompt an error instead of a hang; iex mode must not call exit.
        $result = Invoke-Installer $Box $Root -Mode Iex
        $result.Output | Should -Match 'AFTER:0'
        $Box.Log | Should -Exist
    }

    It 'ps_iex_mode_reports_failure_via_lastexitcode' {
        $result = Invoke-Installer $Box $Root -Mode Iex -ExtraEnv @{ STUB_EXIT = '3' }
        $result.Output | Should -Match 'AFTER:3'
    }
}
