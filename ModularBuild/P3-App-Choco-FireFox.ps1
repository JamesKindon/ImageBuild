Write-Host "===== Install FireFox" -ForegroundColor "Green"
choco install firefox -Y --params "/l:en-US /NoTaskbarShortcut /NoDesktopShortcut /NoAutoUpdate" --limit-output