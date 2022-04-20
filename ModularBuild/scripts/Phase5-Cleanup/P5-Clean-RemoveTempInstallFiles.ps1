Write-Host "===== Clean Temp Install Files" -ForegroundColor "Green"

$PathToClean = "C:\Apps\Temp"

if (Test-Path -Path $PathToClean) {
    Remove-Item -path $PathToClean -force -Recurse
}
