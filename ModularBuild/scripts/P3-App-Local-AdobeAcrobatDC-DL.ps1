<#
.SYNOPSIS
    Downloads and Installs Adobe Acrobat DC
.DESCRIPTION
	Can be used as part of a pipeline or MDT task sequence.
    https://helpx.adobe.com/au/acrobat/kb/acrobat-dc-downloads.html
.EXAMPLE
	.\P3-App-Local-AdobeAcrobatDC-DL.ps1
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
#endregion

#region Variables
# ============================================================================
# Variables
# ============================================================================
# Set Variables
#//Release Data

$Application        = "AdobeAcrobatDC"
$DownloadFolder     = "C:\Apps\Temp\"
$URI                = "https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/win32/Acrobat_DC_Web_WWMUI.zip"
$AppInstallSource   = $URI | Split-Path -Leaf 
$ExtractedName      = "Adobe Acrobat"
$InstallExe         = "Setup.exe"
$Arguments          = "/sAll /rs /msi EULA_ACCEPT=YES"

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

$dlparams = @{
    uri             = $URI
    UseBasicParsing = $True
    ErrorAction     = "Stop"
    OutFile         = ($DownloadFolder + $AppInstallSource)
}
Invoke-WebRequest @dlparams

Write-Host "===== Extracting Archive to $($DownloadFolder + $Application)" -ForegroundColor Cyan
Expand-Archive -Path ($DownloadFolder + $AppInstallSource) -DestinationPath $DownloadFolder -Force

Write-Host "===== Install $($Application)"
$InstallParams = @{
    FilePath     = $DownloadFolder + $ExtractedName + "\" + $InstallExe
    ArgumentList = $Arguments
    Wait         = $true
    PassThru     = $True
}
Start-Process @InstallParams

Write-Host "===== Setting Registry Values for Licencing"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Adobe\Licensing\UserSpecificLicensing" -Name "Enabled" -Value "1"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Adobe\Identity\UserSpecificIdentity" -Name "Enabled" -Value "1"

#endregion

