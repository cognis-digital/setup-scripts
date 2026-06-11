#!/usr/bin/env pwsh
# setup.ps1 — launch the Cognis guided setup wizard on Windows / PowerShell.
#
#   .\setup.ps1            # interactive guided wizard (type a number)
#   .\setup.ps1 --dry-run  # preview every command, never run it
#
# Pure stdlib Python — nothing to install first. All extra arguments are
# passed straight through to cognis_setup.py.

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Wizard = Join-Path $ScriptDir 'cognis_setup.py'

if (-not (Test-Path $Wizard)) {
    Write-Error "cannot find cognis_setup.py next to setup.ps1 ($Wizard)"
    exit 1
}

# Find a Python interpreter that actually runs. We probe with --version rather
# than trusting PATH, because the Microsoft Store "python"/"python3" shim sits
# on PATH but only prints an install prompt and exits non-zero.
$Py = $null
foreach ($cand in @('python', 'py', 'python3')) {
    $cmd = Get-Command $cand -ErrorAction SilentlyContinue
    if (-not $cmd) { continue }
    try {
        & $cmd.Source --version *> $null
        if ($LASTEXITCODE -eq 0) { $Py = $cmd.Source; break }
    } catch { }
}

if (-not $Py) {
    Write-Error "no Python interpreter found (need python 3.8+). Install Python, then re-run: .\setup.ps1"
    exit 1
}

& $Py $Wizard @args
exit $LASTEXITCODE
