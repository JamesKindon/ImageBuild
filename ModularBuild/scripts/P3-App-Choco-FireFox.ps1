Write-Host "============================================================"
Write-Host "===== Install FireFox" -ForegroundColor "Green"
Write-Host "============================================================"

choco install firefox -Y --params "/l:en-US /NoTaskbarShortcut /NoDesktopShortcut /NoAutoUpdate" --limit-output