# Rewrite wisdom-scripts submodule URL in .gitmodules to the canonical GitHub URL.
# Run from Wisdom root after scripts exists on GitHub (or before push so clones work).
#
# Usage:
#   .\scripts\set-wisdom-submodule-remote.ps1
#   .\scripts\set-wisdom-submodule-remote.ps1 -ScriptsRepoUrl https://github.com/your-org/scripts.git

param(
    [string]$ScriptsRepoUrl = "https://github.com/Wisdom-PA/scripts.git"
)

$ErrorActionPreference = "Stop"
$wisdomRoot = Split-Path -Parent $PSScriptRoot
$consumers = @("app", "backend", "contracts", "cube", "listener")

foreach ($name in $consumers) {
    $repoPath = Join-Path $wisdomRoot $name
    $gm = Join-Path $repoPath ".gitmodules"
    if (-not (Test-Path $gm)) {
        Write-Warning "Skipping $name (no .gitmodules)"
        continue
    }
    Push-Location $repoPath
    try {
        git config -f .gitmodules submodule.wisdom-scripts.url $ScriptsRepoUrl
        git add .gitmodules
        if (git diff --cached --quiet) {
            Write-Host "$name : .gitmodules already set"
        }
        else {
            git commit -m "Point wisdom-scripts submodule at GitHub ($ScriptsRepoUrl)"
            Write-Host "$name : updated submodule URL"
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "Done."
