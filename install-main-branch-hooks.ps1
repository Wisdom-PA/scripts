# Point each repo at shared hook scripts under git-hooks/.
#
# Two layouts:
#   Workspace  — local Wisdom folder: siblings app/, cube/, … next to scripts/.
#                Consumers use core.hooksPath ../scripts/git-hooks; scripts repo uses git-hooks.
#   Submodule  — each consumer repo vendors the scripts repo as a git submodule at wisdom-scripts/.
#                Consumers use core.hooksPath wisdom-scripts/git-hooks; canonical scripts repo uses git-hooks.
#
# Usage:
#   .\scripts\install-main-branch-hooks.ps1                          # Workspace (default)
#   .\scripts\install-main-branch-hooks.ps1 -Mode Submodule          # under Wisdom root, after submodules inited
#   .\scripts\install-main-branch-hooks.ps1 -Mode Submodule -OnlyCurrentRepo   # run inside one cloned consumer (cwd = repo root)
#
# Bypass (rare): $env:GIT_MAIN_PROTECTION='0'  or  git ... --no-verify

param(
    [ValidateSet('Workspace', 'Submodule')]
    [string]$Mode = 'Workspace',
    [switch]$OnlyCurrentRepo
)

$ErrorActionPreference = "Stop"

if ((Split-Path -Leaf $PSScriptRoot) -eq "wisdom-scripts" -and -not $OnlyCurrentRepo) {
    throw "This copy lives inside submodule wisdom-scripts/. Run from the consumer repo root with -OnlyCurrentRepo, or use scripts/install-main-branch-hooks.ps1 from a Wisdom workspace clone for batch install."
}

function Set-HooksPathInRepo {
    param(
        [string]$RepoPath,
        [string]$HooksPathRel,
        [string]$Label
    )
    Push-Location $RepoPath
    try {
        git config core.hooksPath $HooksPathRel
        Write-Host "core.hooksPath set for $Label -> $HooksPathRel"
    }
    finally {
        Pop-Location
    }
}

if ($OnlyCurrentRepo) {
    $here = (Get-Location).Path
    if (-not (Test-Path (Join-Path $here ".git"))) {
        throw "Run from a git repository root (missing .git in $here)."
    }
    if ($Mode -ne 'Submodule') {
        throw "-OnlyCurrentRepo is only supported with -Mode Submodule (vendored wisdom-scripts/)."
    }
    $subHooks = Join-Path $here "wisdom-scripts/git-hooks"
    if (-not (Test-Path $subHooks)) {
        throw "Missing wisdom-scripts/git-hooks. Add the scripts repo: git submodule add <scripts-repo-url> wisdom-scripts && git submodule update --init"
    }
    Set-HooksPathInRepo -RepoPath $here -HooksPathRel "wisdom-scripts/git-hooks" -Label (Split-Path -Leaf $here)
    Write-Host "Done."
    exit 0
}

$wisdomRoot = Split-Path -Parent $PSScriptRoot
$repos = @("app", "backend", "contracts", "cube", "listener", "scripts")

foreach ($name in $repos) {
    $repoPath = Join-Path $wisdomRoot $name
    if (-not (Test-Path (Join-Path $repoPath ".git"))) {
        Write-Warning "Skipping $name (no .git at $repoPath)"
        continue
    }

    if ($name -eq "scripts") {
        $hooksPathRel = "git-hooks"
    }
    elseif ($Mode -eq 'Submodule') {
        $subHooks = Join-Path $repoPath "wisdom-scripts/git-hooks"
        if (-not (Test-Path $subHooks)) {
            Write-Warning "Skipping ${name}: no wisdom-scripts/git-hooks. Add: git submodule add <scripts-url> wisdom-scripts (from ${name} repo root)"
            continue
        }
        $hooksPathRel = "wisdom-scripts/git-hooks"
    }
    else {
        $hooksPathRel = "../scripts/git-hooks"
    }

    Set-HooksPathInRepo -RepoPath $repoPath -HooksPathRel $hooksPathRel -Label $name
}

Write-Host "Done. Hooks: pre-commit, pre-merge-commit, pre-push (see git-hooks/). Mode=$Mode"
