<#
.SYNOPSIS
    Downloads and Installs Bloomberg
.DESCRIPTION
	Can be used as part of a pipeline or MDT task sequence.
.EXAMPLE
	.\P3-App-Local-Bloomberg.ps1 -UseScriptVariables
	Will use hardcoded download details in script

	.\P3-App-Local-CitrixCQI-DL.ps1
	Assumes pipeline environment variables
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
	[Parameter(Mandatory = $false)]
    [switch]$UseScriptVariables # Use script variables for downloads (not using environment variables)

)
#endregion

#region Variables
# ============================================================================
# Variables
# ============================================================================
# Set Variables
#//Release Data
$Application        = "Bloomberg"
$DownloadFolder     = "C:\Apps\Temp\"
$AppInstallSource   = "Bloomberg.zip"
#//Hardcoded Variables
$Base_HC            = "FolderStoringAppsInStorageAccount" #Only used when UseScriptVariables Switch is present, else pipeline
$Key_HC             = "KeytoAccessFolderInStorageAccount" #Only used when UseScriptVariables Switch is present, else pipeline
#//Pipeline Variables
$Base               = $env:sabaseappsdir
$Key                = $env:sasaskey
$URI                = $Base + $AppInstallSource + $Key
#endregion

#region Functions
# ============================================================================
# Functions
# ============================================================================
#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
Write-Host "============================================================"
Write-Host "===== Downloading $($Application)"
Write-Host "============================================================"

$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (!(Test-Path -Path $DownloadFolder)) {
    New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

if ($UseScriptVariables.IsPresent) {
	Write-Host "UseScriptVariables present - using hardcoded script values"
	$Base   = $Base_HC
    $Key    = $Key_HC
}


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

#endregion
