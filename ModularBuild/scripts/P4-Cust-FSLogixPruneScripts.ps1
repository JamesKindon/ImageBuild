Write-Host "===== Downloading FSLogix Pruning Scripts and Templates" -ForegroundColor "Green"

$MaintenancePath = "C:\Tools\FSLogixMaintenance"
if (!(Test-Path -Path $MaintenancePath)) {
    New-Item -Path $MaintenancePath -ItemType "Directory" -Force | Out-Null
}

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/aaronparker/fslogix/main/Profile-Cleanup/Remove-ProfileData.ps1" -OutFile "$MaintenancePath\Remove-ProfileData.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JonathanPitre/Apps/master/Microsoft/FSLogix%20Apps/Profile%20Cleanup/targets.xml" -OutFile "$MaintenancePath\targets.xml"

