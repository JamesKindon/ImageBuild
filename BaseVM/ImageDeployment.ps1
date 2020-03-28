
<#

.SYNOPSIS
Builds an image based on Github Image Build Scripts

.DESCRIPTION
Design to run on top of a deployed VM with nothing else on it

.PARAMETER CitrixVDA
Triggers the download of the latest release VDA (Currently 1912)

.PARAMETER CitrixWEM
Triggers the download of the latest release WEM Agent (Currently 1912)

.PARAMETER ControlFileLocation
Default Control File Location is C:\temp\ImageBuild. Writes Control Files for tracking

.PARAMETER MicrosoftOffice
Triggers the download of the Microsoft Office ProPlus Suites based on the XML files stored in Github

.PARAMETER GeneralBuild
Triggers the General Build Components of the image - Features and Roles

.PARAMETER GeneralApps
Triggers the download and installations of basic applications

.PARAMETER AdminApps
Triggers the download and installations of Admin applications for an Admin Image

.PARAMETER ConfigureAndOptimise
Triggers the download and execution of the configuration and optimization components

.PARAMETER ClearVariable
Triggers the clearing of variables associated with downloads

.PARAMETER CleanupAfterBuild
Triggers the removed of all apps and temp data

.PARAMETER ResetPhases
Triggers the removal of the specified phase control file

.EXAMPLE 
The below will execute the image build with all apps, Microsoft Office, Citrix VDA and CQI, Citrix WEM, a Start Menu Layout, Default file assocs for Edge Chromium and Citrix Optimizer configurations. All temporary data will be removed
This will require multiple runs due to reboot requirements which are tracked via Control Files
.\DeployImage.ps1 -GeneralBuild -GeneralApps -MicrosoftOffice -CitrixVDA -CitrixWEM -ConfigureAndOptimise -CleanupAfterBuild

.EXAMPLE
The below will reset the control files for the Build and WEM phases allowing them to run again
 .\DeployImage.ps1 -ResetPhases Phase0-Control-Build,Phase1-Apps-CitrixWEM


.NOTES


.LINK

#>

# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [switch]$CitrixVDA,

    [Parameter(Mandatory = $false)]
    [switch]$CitrixWEM,

    [Parameter(Mandatory = $false)]
    [string]$ControlFileLocation = "C:\temp\ImageBuild",

    [Parameter(Mandatory = $false)]
    [switch]$MicrosoftOffice,

    [Parameter(Mandatory = $false)]
    [switch]$GeneralBuild,

    [Parameter(Mandatory = $false)]
    [switch]$GeneralApps,

    [Parameter(Mandatory = $false)]
    [switch]$AdminApps,

    [Parameter(Mandatory = $false)]
    [switch]$ConfigureAndOptimise,

    [Parameter(Mandatory = $false)]
    [switch]$ClearVariable,

    [Parameter(Mandatory = $false)]
    [switch]$CleanupAfterBuild,

    [Parameter(Mandatory=$False,ValueFromPipeline=$true)] [ValidateSet('Phase0-Control-Build',
    'Phase1-Control-Apps-General',
    'Phase1-Control-Apps-Admin',
    'Phase1-Control-Apps-MicrosoftOffice365',
    'Phase1-Apps-CitrixVDA-FirstPass',
    'Phase1-Apps-CitrixVDA-SecondPass',
    'Phase1-Apps-CitrixCQI',
    'Phase1-Apps-CitrixWEM',
    'Phase2-Control-Configure',
    'Phase3-Control-Optimize')] [Array] $ResetPhases
)

#region functions
# ============================================================================
# Functions
# ============================================================================

function WriteControlFile {
    param (
        $PhaseName
    )
    New-Item -ItemType File -Path "$ControlFileLocation\$PhaseName.txt" | Out-Null
}

function ExecutePhase {
    param (
        $PhaseName
    )
    if (Test-Path "$ControlFileLocation\$PhaseName.txt") {
        Write-Host "$PhaseName Control File Exists. Phase: $PhaseName already complete. Moving on" -ForegroundColor Cyan
    }
    else {
        Write-Host "Starting Image Build Phase: $PhaseName" -ForegroundColor Cyan
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($Script))
        WriteControlFile -PhaseName $PhaseName
    }
}

function ClearVariable {
    param (
        $Variable
    )
    Get-ChildItem Env:$Variable -ErrorAction SilentlyContinue | Remove-Item
}

function RestartComputer {
    # Add a check to cater for VDA first pass (Control file exists before reboot is called)
    #if (Test-Path "$ControlFileLocation\$PhaseName.txt") {
    #    Write-Host "$PhaseName Control File Exists. Phase: $PhaseName already complete. No Reboot Required" -ForegroundColor Cyan
    #}
    else {
        Write-Host "You must restart this computer and run the script again to Continue" -ForegroundColor Yellow
        $Restart = Read-Host "Restart Computer Y/N?"
        if ($Restart -eq "Y") {
            Write-Host "Restarting Computer" -ForegroundColor Yellow
            restart-computer -Force 
        }
        elseif ($Restart -ne "Y") {
            Write-Warning "You must restart this computer manually before proceeding"
            Break
        }    
    }
}

function ResetPhaseControlFile {
    param (
        $PhaseName
    )
    if (Test-Path -Path "$ControlFileLocation\$PhaseName.txt") {
        Write-Host "PhaseName: $PhaseName Control File exists, Deleting"
        Remove-Item -Path "$ControlFileLocation\$PhaseName.txt" -Force | Out-Null
    }
    else {
        Write-Host "PhaseName: $PhaseName Control File does not exist"
    }
}

function ResetPhase {
    foreach ($PhaseName in ($ResetPhases | Sort-Object -Unique)) {
        switch ($PhaseName) {
            'Phase0-Control-Build' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Control-Apps-General' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Control-Apps-Admin' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Control-Apps-MicrosoftOffice365' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Apps-CitrixVDA-FirstPass' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Apps-CitrixVDA-SecondPass' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Apps-CitrixCQI' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase1-Apps-CitrixWEM' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase2-Control-Configure' {
                ResetPhaseControlFile -PhaseName $PhaseName
            } 'Phase3-Control-Optimize' {
                ResetPhaseControlFile -PhaseName $PhaseName
            }
        }
    }
}
#endregion

# ============================================================================
# Execute the Script
# ============================================================================

if (!(Test-Path -Path $ControlFileLocation)) {
    Write-Host "Creating Control File Path: $ControlFileLocation" -ForegroundColor Cyan
    New-Item -Type Directory -Path $ControlFileLocation | Out-Null
}

if ($ClearVariable.IsPresent) {
    Write-Host "Removing Variables" -ForegroundColor Cyan
    ClearVariable -Variable citrixusername
    ClearVariable -Variable citrixpassword
    ClearVariable -Variable CitrixReleaseVersion
}

if ($GeneralBuild.IsPresent) {
    $PhaseName = "Phase0-Control-Build"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase0-Control-Build-OnPrem.ps1"
    ExecutePhase -PhaseName $PhaseName
    RestartComputer
}

if ($GeneralApps.IsPresent) {
    $PhaseName = "Phase1-Control-Apps-General"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Control-Apps-General.ps1"
    ExecutePhase -PhaseName $PhaseName
}

if ($AdminApps.IsPresent) {
    $PhaseName = "Phase1-Control-Apps-Admin"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Control-Apps-Admin.ps1"
    ExecutePhase -PhaseName $PhaseName
}

if ($MicrosoftOffice.IsPresent) {
    $PhaseName = "Phase1-Control-Apps-MicrosoftOffice365"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Control-Apps-MicrosoftOffice365.ps1"
    ExecutePhase -PhaseName $PhaseName
}

if ($CitrixVDA.IsPresent) {
    $PhaseName = "Phase1-Apps-CitrixVDA-FirstPass"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Apps-CitrixVDA.ps1"
    
    if (!(Test-Path "$ControlFileLocation\$PhaseName.txt")) {
        Write-Host "Setting Variables" -ForegroundColor Cyan
        if (!(Test-Path -Path env:citrixusername)) {
            Write-Warning -Message "Citrix Username and Password details are not set for downloading the required media"
            $env:citrixusername = Read-Host "Please enter your Citrix Username"
            $env:citrixpassword = Read-Host "Please enter your Citrix password"
            #$env:citrixpassword = Read-Host "Please enter your Citrix password" -AsSecureString     
        }
        else {
            Write-Host "Citrix Username is $env:citrixusername" -ForegroundColor Cyan
            Write-Host "Citrix Password has been set" -ForegroundColor Cyan
        }
        if (!(Test-Path env:CitrixReleaseVersion)) {
            $env:CitrixReleaseVersion = Read-Host "Please Select Citrix Release Version: CR or LTSR"
            Write-Host "Citrix Release Version has been set to $env:CitrixReleaseVersion" -ForegroundColor Cyan
        }
        else {
            Write-Host "Citrix Release Version has been set to $env:CitrixReleaseVersion" -ForegroundColor Cyan
        }
        ExecutePhase -PhaseName $PhaseName
        RestartComputer
    }

    if (Test-Path -Path "$ControlFileLocation\Phase1-Apps-CitrixVDA-FirstPass.txt") {
        $PhaseName = "Phase1-Apps-CitrixVDA-SecondPass"
        $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Apps-CitrixVDA.ps1"
        ExecutePhase -PhaseName $PhaseName

        $PhaseName = "Phase1-Apps-CitrixCQI"
        $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Apps-CitrixCQI.ps1"
        ExecutePhase -PhaseName $PhaseName
        Write-Host "Removing Variables" -ForegroundColor Cyan
        ClearVariable -Variable citrixusername
        ClearVariable -Variable citrixpassword
        ClearVariable -Variable CitrixReleaseVersion   
    }

    if (Test-Path -Path "$ControlFileLocation\Phase1-Apps-CitrixVDA-SecondPass.txt") {
        Write-Host "Phase1-Apps-CitrixVDA-SecondPass Control File Exists. Phase: Phase1-Apps-CitrixVDA-SecondPass already complete. Moving on" -ForegroundColor Cyan
    }
}

if ($CitrixWEM.IsPresent) {
    Write-Host "Setting Variables" -ForegroundColor Cyan
    if (!(Test-Path -Path env:citrixusername)) {
        Write-Warning -Message "Citrix Username and Password details are not set for downloading the required media"
        $env:citrixusername = Read-Host "Please enter your Citrix Username" 
        $env:citrixpassword = Read-Host "Please enter your Citrix password"   
    }
    else {
        Write-Host "Citrix Username is $env:citrixusername" -ForegroundColor Cyan
        Write-Host "Citrix Password has been set" -ForegroundColor Cyan
    }
    $PhaseName = "Phase1-Apps-CitrixWEM"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Apps-CitrixWEM.ps1"
    ExecutePhase -PhaseName $PhaseName
    Write-Host "Removing Variables" -ForegroundColor Cyan
    ClearVariable -Variable citrixusername
    ClearVariable -Variable citrixpassword   
}

if ($ConfigureAndOptimise.IsPresent) {
    $PhaseName = "Phase2-Control-Configure"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase2-Control-Configure.ps1"
    ExecutePhase -PhaseName $PhaseName

    $PhaseName = "Phase3-Control-Optimize"
    $Script = "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase3-Control-Optimize.ps1"
    ExecutePhase -PhaseName $PhaseName
}

if ($CleanupAfterBuild.IsPresent) {
    Write-Host "Cleaning all Software and Control Files" -ForegroundColor Cyan
    Remove-Item -Path $ControlFileLocation -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path "C:\Apps" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    ClearVariable
}

# Reset phases as specified
ResetPhase
