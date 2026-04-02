# Add wisdom-scripts submodule to each Wisdom sibling consumer repo.
# Run once after the scripts repository exists on GitHub (or pass -ScriptsRepoUrl for another remote).
#
# Usage (from anywhere):
#   .\scripts\bootstrap-wisdom-submodules.ps1
#   .\scripts\bootstrap-wisdom-submodules.ps1 -ScriptsRepoUrl https://github.com/your-org/scripts.git

param(
    [string]$ScriptsRepoUrl = "https://github.com/Wisdom-PA/scripts.git"
)

$ErrorActionPreference = "Stop"
$wisdomRoot = Split-Path -Parent $PSScriptRoot
$consumers = @("app", "backend", "contracts", "cube", "listener")

foreach ($name in $consumers) {
    $repoPath = Join-Path $wisdomRoot $name
    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Warning "Skipping $($name) (no .git)"
        continue
    }
    Push-Location $repoPath
    try {
        if (Test-Path "wisdom-scripts") {
            Write-Host ($name + ': wisdom-scripts already exists — skip')
            continue
        }
        # Windows Git often blocks file:// submodules unless allowed (local ../scripts).
        git -c protocol.file.allow=always submodule add -b main $ScriptsRepoUrl wisdom-scripts
        git submodule update --init --depth 1 wisdom-scripts
        Write-Host ($name + ': submodule wisdom-scripts added')
    }
    finally {
        Pop-Location
    }
}

Write-Host 'Done. Commit .gitmodules and submodule pointer on a feature branch in each repo (not on main).'
