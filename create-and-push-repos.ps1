# Create GitHub repos and push local content.
# Prerequisite: Run once: & "$env:ProgramFiles\GitHub CLI\gh.exe" auth login
# Then run: .\create-and-push-repos.ps1

$ErrorActionPreference = "Stop"
$gh = Join-Path $env:ProgramFiles "GitHub CLI\gh.exe"
$base = (Get-Item $PSScriptRoot).Parent.FullName   # Wisdom folder (parent of scripts/)
$org = "Wisdom-PA"

& $gh auth status

$repos = @(
    @{ Name = "cube"; Description = "Listener: on-device assistant (Java)" },
    @{ Name = "app"; Description = "Listener: mobile companion (React Native + TypeScript)" },
    @{ Name = "contracts"; Description = "Listener: API shapes (cube <-> app)" },
    @{ Name = "backend"; Description = "Listener: optional backend (Java)" },
    @{ Name = "listener"; Description = "Listener: product docs, plan, tickets" },
    @{ Name = "scripts"; Description = "Listener: shared hooks, CI helpers, installers" }
)

foreach ($r in $repos) {
    Write-Host "--- Creating $org/$($r.Name) and pushing ---"
    & $gh repo create "${org}/$($r.Name)" --public --source (Join-Path $base $r.Name) --remote origin --push --description $r.Description
}

Write-Host "Done. All repos in this list were created and pushed."
