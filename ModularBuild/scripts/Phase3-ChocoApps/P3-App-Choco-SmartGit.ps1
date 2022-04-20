Write-Host "============================================================"
Write-Host "====== Install SmartGit" -ForegroundColor "Green"
Write-Host "============================================================"

if (-not (Test-Path "C:\ProgramData\chocolatey\choco.exe")) {
    Write-Host "Chocolatey not installed, attempting to install"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

choco install smartgit -Y --limit-output --ignore-checksums

## The below is designed to allow pipeline continuation on failure - used for testing phases. Variable typically set in DevOps
if ($LASTEXITCODE -ne "0" -and $Env:FailureOverrideCode -eq "0") {
    write-Warning "Package Failed to Install. Continuing with false return code: 0"
    Exit 0
}