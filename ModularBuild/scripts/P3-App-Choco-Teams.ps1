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