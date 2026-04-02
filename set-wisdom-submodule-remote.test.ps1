# Run: powershell -NoProfile -File scripts/set-wisdom-submodule-remote.test.ps1
$ErrorActionPreference = "Stop"
$script = Join-Path $PSScriptRoot "set-wisdom-submodule-remote.ps1"
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$errors)
if ($errors.Count -gt 0) {
    throw "Parse errors: $errors"
}
Write-Host "set-wisdom-submodule-remote.test.ps1: OK"
