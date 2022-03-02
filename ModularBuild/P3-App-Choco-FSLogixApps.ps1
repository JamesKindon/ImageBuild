Write-Host "===== Install FSlogix Apps and Rules Editor" -ForegroundColor "Green"
choco install fslogix -Y --limit-output
choco install fslogix-rule -Y --limit-output