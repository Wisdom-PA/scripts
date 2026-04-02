# Run: powershell -NoProfile -File scripts/install-main-branch-hooks.test.ps1
$ErrorActionPreference = "Stop"
$installer = Join-Path $PSScriptRoot "install-main-branch-hooks.ps1"

function New-TempRepo {
    $d = Join-Path ([IO.Path]::GetTempPath()) ("wisdom-inst-" + [guid]::NewGuid().ToString("n"))
    New-Item -ItemType Directory -Path $d | Out-Null
    return $d
}

# Submodule layout: -OnlyCurrentRepo sets hooksPath
$tmp = New-TempRepo
try {
    Push-Location $tmp
    git init -b main 2>&1 | Out-Null
    git config user.email "test@test"
    git config user.name "test"
    New-Item -ItemType Directory -Path "wisdom-scripts/git-hooks" -Force | Out-Null
    & $installer -Mode Submodule -OnlyCurrentRepo
    $p = git config core.hooksPath
    if ($p -ne "wisdom-scripts/git-hooks") {
        throw "Expected core.hooksPath wisdom-scripts/git-hooks, got '$p'"
    }
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

# Submodule copy without -OnlyCurrentRepo must fail
$tmp2 = New-TempRepo
$ws = Join-Path $tmp2 "wisdom-scripts"
New-Item -ItemType Directory -Path $ws | Out-Null
Copy-Item $installer (Join-Path $ws "install-main-branch-hooks.ps1")
try {
    Push-Location $tmp2
    & (Join-Path $ws "install-main-branch-hooks.ps1") -ErrorAction Stop 2>&1 | Out-Null
    throw "Expected installer in wisdom-scripts/ to fail without -OnlyCurrentRepo"
}
catch {
    if ($_.Exception.Message -like "*Expected installer*") { throw }
}
finally {
    Pop-Location
    Remove-Item -Recurse -Force $tmp2 -ErrorAction SilentlyContinue
}

Write-Host "install-main-branch-hooks.test.ps1: OK"
