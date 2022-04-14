Write-Host "============================================================"
Write-Host "====== Install JRE8" -ForegroundColor "Green"
Write-Host "============================================================"

choco install server-jre8 -Y --limit-output

## The below is designed to allow pipeline continuation on failure - used for testing phases. Variable typically set in DevOps
if ($LASTEXITCODE -ne "0" -and $Env:FailureOverrideCode -eq "0") {
    write-Warning "Package Failed to Install. Continuing with false return code: 0"
    Exit 0
}