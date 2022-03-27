
##---------------------------------------------------
# Variables per application
##---------------------------------------------------
$Application = "Bloomberg"
$DownloadFolder = "C:\Apps\Temp\"
$AppInstallSource = "Bloomberg.zip"
##---------------------------------------------------
# Variables from vault (leave these alone)
##---------------------------------------------------
$Base = $env:sabaseappsdir
$Key = $env:sasaskey
$URI = $Base + $AppInstallSource + $Key
##---------------------------------------------------

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (!(Test-Path -Path $DownloadFolder)) {
    New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

Write-Host "============================================================"
Write-Host "===== Downloading $($Application)"
Write-Host "============================================================"

$dlparams = @{
    uri             = $URI
    UseBasicParsing = $True
    ErrorAction     = "Stop"
    OutFile         = ($DownloadFolder + $AppInstallSource)
}
Invoke-WebRequest @dlparams

Write-Host "Extracting Archive to $($DownloadFolder + $Application)" -ForegroundColor Cyan
Expand-Archive -Path ($DownloadFolder + $AppInstallSource) -DestinationPath $DownloadFolder -Force

Write-Host "===== Install $($Application)"
$params = @{
    FilePath     = ($DownloadFolder + $Application + "\" + "Deploy-Application.exe")
    ArgumentList = "-DeployMode Silent"
    Wait         = $true
    PassThru     = $True
}
Start-Process @params
