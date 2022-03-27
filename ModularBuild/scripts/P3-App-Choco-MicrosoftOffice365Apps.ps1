Write-Host "============================================================"
Write-Host "====== Install Microsoft Office 365 Apps\" -ForegroundColor "Green"
Write-Host "============================================================"

choco install microsoft-office-deployment --params "'/XMLfile:c:\tools\OfficeConfig_Win10.xml'" -Y --limit-output 