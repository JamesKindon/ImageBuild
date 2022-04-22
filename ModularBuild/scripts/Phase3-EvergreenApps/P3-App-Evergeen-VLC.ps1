<#
.SYNOPSIS
    Downloads and Installs VLC Player via Evergreen
.DESCRIPTION
    Uses the Evergreen module by Aaron Parker
    https://stealthpuppy.com/evergreen/
.EXAMPLE
	.\P3-App-Evergeen-VLC.ps1
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

$Application        = "VideoLanVlcPlayer"
$DownloadFolder     = "C:\Apps\Temp\"
$URI                = (Get-EvergreenApp -Name "VideoLanVlcPlayer" | Where-Object {$_.Architecture -eq "x64" -and $_.Type -eq "EXE"}).uri
$AppInstallSource   = $URI | Split-Path -Leaf 
$InstallExe         = $AppInstallSource
$Arguments          = "/S"
$Modules            = @("Evergreen")
#endregion

#region Functions
# ============================================================================
# Functions
# ============================================================================

function CheckForModules {
    <#
    .SYNOPSIS
        Installs modules
#>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    Param (
        [Parameter()]
        [System.String[]] $Modules = $Modules
    )

    #region Trust the PSGallery and install modules
    $Repository = "PSGallery"
    If (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
        try {
            Write-Host " Trusting the repository: $Repository."
            Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force
            Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
        }
        catch {
            Throw $_
            Break
        }
    }

    ForEach ($module in $Modules) {
        try {
            Write-Host " Checking module: $module."
            $installedModule = Get-Module -Name $module -ListAvailable | `
                Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
                Select-Object -First 1
            $publishedModule = Find-Module -Name $module -ErrorAction "SilentlyContinue"
            If (($Null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
                Write-Host " Installing module: $module"
                $params = @{
                    Name               = $module
                    SkipPublisherCheck = $true
                    Force              = $true
                    ErrorAction        = "Stop"
                }
                Install-Module @params
            }
        }
        catch {
            Throw $_
            Break
        }
    }
    #endregion
}

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================

# Checking Modules
CheckForModules

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

Write-Host "===== Install $($Application)"
$InstallParams = @{
    FilePath     = $DownloadFolder + $InstallExe
    ArgumentList = $Arguments
    Wait         = $true
    PassThru     = $True
}
Start-Process @InstallParams

#endregion

