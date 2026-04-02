# Integration checks for Wisdom git hooks. Run from repo root:
#   powershell -NoProfile -File scripts/git-hooks/MainProtectionHooks.test.ps1
#   pwsh -NoProfile -File scripts/git-hooks/MainProtectionHooks.test.ps1
# Requires: git on PATH, run from Wisdom root or any cwd (script locates hooks dir).

$ErrorActionPreference = "Stop"

function Invoke-Git {
    # Native git writes hook messages to stderr; avoid Stop treating them as terminating errors.
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    $old = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    try {
        & git @GitArgs 2>&1 | Out-Null
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
}

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$hooksDir = $PSScriptRoot
$gitExe = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExe) { throw "git not on PATH" }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("wisdom-hook-test-" + [Guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Push-Location $tmp
    Invoke-Git init -b main | Out-Null
    git config core.hooksPath $hooksDir

    # First commit on main (empty repo) must succeed
    "init" | Out-File -FilePath "README.md" -Encoding utf8
    git add README.md
    $code = Invoke-Git commit -m "init"
    Assert-True ($code -eq 0) "First commit on main should succeed"

    "more" | Add-Content README.md
    git add README.md
    $code = Invoke-Git commit -m "second on main"
    Assert-True ($code -ne 0) "Second commit on main should be blocked"

    Invoke-Git checkout -b feature | Out-Null
    "feat" | Add-Content README.md
    git add README.md
    $code = Invoke-Git commit -m "on feature"
    Assert-True ($code -eq 0) "Commit on feature branch should succeed"

    # pre-push: block updating remote main after fast-forward merge (main still at first commit)
    $bare = Join-Path $tmp "origin.git"
    Invoke-Git init --bare $bare | Out-Null
    git remote add origin $bare
    Invoke-Git checkout main | Out-Null
    $code = Invoke-Git push -u origin main
    Assert-True ($code -eq 0) "First push of main should succeed (empty remote)"
    $code = Invoke-Git merge --ff-only feature
    Assert-True ($code -eq 0) "Fast-forward merge into main should succeed locally"
    $code = Invoke-Git push origin main
    Assert-True ($code -ne 0) "Push updating remote main should be blocked"

    $env:GIT_MAIN_PROTECTION = "0"
    try {
        Invoke-Git checkout main | Out-Null
        "bypass" | Add-Content README.md
        git add README.md
        $code = Invoke-Git commit -m "bypass"
        Assert-True ($code -eq 0) "Commit on main should succeed when GIT_MAIN_PROTECTION=0"
    }
    finally {
        Remove-Item Env:\GIT_MAIN_PROTECTION -ErrorAction SilentlyContinue
    }

    Write-Host "MainProtectionHooks.test.ps1: OK"
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}
