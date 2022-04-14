Write-Host "============================================================"
Write-Host "====== Install Microsoft Teams\" -ForegroundColor "Green"
Write-Host "============================================================"

$KeyPath = "HKLM:\SOFTWARE\Microsoft\Teams\"
$WVDKey = "IsWVDEnvironment"

if (!(Test-Path $KeyPath)) {
    New-Item -Path $KeyPath -Force
    New-ItemProperty -Path $KeyPath -Name $WVDKey -PropertyType "DWORD" -Value "1" -Force 
}

choco install microsoft-teams.install --params "'/AllUsers /AllUser /NoAutoStart'" -Y --limit-output 

## The below is designed to allow pipeline continuation on failure - used for testing phases. Variable typically set in DevOps
if ($LASTEXITCODE -ne "0" -and $Env:FailureOverrideCode -eq "0") {
    write-Warning "Package Failed to Install. Continuing with false return code: 0"
    Exit 0
}