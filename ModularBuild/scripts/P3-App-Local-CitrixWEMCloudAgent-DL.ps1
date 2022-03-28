<#
.SYNOPSIS
    Downloads and Install Citrix WEM Cloud Agent
.DESCRIPTION
	Can be used as part of a pipeline or MDT task sequence.
	https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Helpers/Downloads.csv
	Ryan Butler TechDrabble.com @ryan_c_butler 07/19/2019
	Updated by James Kindon
	https://github.com/JamesKindon/Citrix/blob/master/Downloads.csv
	https://github.com/ryancbutler/Citrix_DL_Scrapper/blob/main/ctx_dls.csv
.EXAMPLE
	.\P3-App-Local-CitrixWEMCloudAgent-DL.ps1 -CredentialPrompt -UseScriptVariables
	Will prompt for credentials and use hardcoded download details in script

	.\P3-App-Local-CitrixWEMCloudAgent-DL.ps1
	Assumes pipeline environment variables
#>

#region Params
# ============================================================================
# Parameters
# ============================================================================
Param(
    [Parameter(Mandatory = $false)]
    [switch]$CredentialPrompt, # Prompt for Credentials (not using environment variables)

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
$Application 	= "Citrix Workspace Environment Management"
$InstallerName 	= "Citrix Workspace Environment Management Agent.exe"
$DLNumber_HC	= "16122" 												#Only used when UseScriptVariables Switch is present, else pipeline
$DLEXE_HC		= "Workspace-Environment-Management-Agent-2201.2.zip" 	#Only used when UseScriptVariables Switch is present, else pipeline
##//Arguments
$Arguments 		= "/quiet Cloud=1"
$DownloadFolder = "C:\Apps\Temp\"
#//Pipeline Variables
$DLNumber 		= $env:cvad_wem_dl_num
$DLEXE 			= $env:cvad_wem_dl_name
$CitrixUserName = $env:CitrixUserName
$CitrixPassword = $env:CitrixPassword

#endregion

#region Functions
# ============================================================================
# Functions
# ============================================================================
function CheckandDownload {
    if (Test-Path $Outfile) {
        Write-Host "$Outfile exists, proceeding with install"
        Install
    }
    else {
		Write-Host "Downloading Install File $($DLEXE), Please Wait...."
		Get-CTXBinary -DLNUMBER $DLNumber -DLEXE $DLEXE -CitrixUserName $CitrixUserName -CitrixPassword $CitrixPassword -DLPATH $DownloadFolder
        Install
    }
}

function get-ctxbinary {
	<#
.SYNOPSIS
  Downloads a Citrix VDA or ISO from Citrix.com utilizing authentication
.DESCRIPTION
  Downloads a Citrix VDA or ISO from Citrix.com utilizing authentication.
  Ryan Butler 2/6/2020
.PARAMETER DLNUMBER
  Number assigned to binary download
.PARAMETER DLEXE
  File to be downloaded
.PARAMETER DLPATH
  Path to store downloaded file. Must contain following slash (c:\temp\)
.PARAMETER CitrixUserName
  Citrix.com username
.PARAMETER CitrixPassword
  Citrix.com password
.EXAMPLE
  Get-CTXBinary -DLNUMBER "16834" -DLEXE "Citrix_Virtual_Apps_and_Desktops_7_1912.iso" -CitrixUserName "mycitrixusername" -CitrixPassword "mycitrixpassword" -DLPATH "C:\temp\"
#>
	Param(
		[Parameter(Mandatory = $true)]$DLNUMBER,
		[Parameter(Mandatory = $true)]$DLEXE,
		[Parameter(Mandatory = $true)]$DLPATH,
		[Parameter(Mandatory = $true)]$CitrixUserName,
		[Parameter(Mandatory = $true)]$CitrixPassword
	)
	
	$ProgressPreference = 'SilentlyContinue'
	#Initialize Session 
	Invoke-WebRequest "https://identity.citrix.com/Utility/STS/Sign-In?ReturnUrl=%2fUtility%2fSTS%2fsaml20%2fpost-binding-response" -SessionVariable websession -UseBasicParsing | Out-Null

	#Set Form
	$form = @{
		"persistent" = "on"
		"userName"   = $CitrixUserName
		"password"   = $CitrixPassword
	}

	#Authenticate
	try {
		Invoke-WebRequest -Uri ("https://identity.citrix.com/Utility/STS/Sign-In?ReturnUrl=%2fUtility%2fSTS%2fsaml20%2fpost-binding-response") -WebSession $websession -Method POST -Body $form -ContentType "application/x-www-form-urlencoded" -UseBasicParsing -ErrorAction Stop | Out-Null
	}
	catch {
		if ($_.Exception.Response.StatusCode.Value__ -eq 500) {
			Write-Verbose "500 returned on auth. Ignoring"
			Write-Verbose $_.Exception.Response
			Write-Verbose $_.Exception.Message
		}
		else {
			throw $_
		}

	}
	$dlurl = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=${DLNUMBER}&URL=https://downloads.citrix.com/${DLNUMBER}/${DLEXE}"
	$download = Invoke-WebRequest -Uri $dlurl -WebSession $websession -UseBasicParsing -Method GET
	$webform = @{ 
		"chkAccept"            = "on"
		"clbAccept"            = "Accept"
		"__VIEWSTATEGENERATOR" = ($download.InputFields | Where-Object { $_.id -eq "__VIEWSTATEGENERATOR" }).value
		"__VIEWSTATE"          = ($download.InputFields | Where-Object { $_.id -eq "__VIEWSTATE" }).value
		"__EVENTVALIDATION"    = ($download.InputFields | Where-Object { $_.id -eq "__EVENTVALIDATION" }).value
	}

	$outfile = ($DLPATH + $DLEXE)
	#Download
	Invoke-WebRequest -Uri $dlurl -WebSession $websession -Method POST -Body $webform -ContentType "application/x-www-form-urlencoded" -UseBasicParsing -OutFile $outfile
	return $outfile
}

function Install {
	Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue
    if ($DLEXE -like "*.zip") {
        Write-Host "Extracting Archive to $($DownloadFolder + $Application)" -ForegroundColor Cyan
		Expand-Archive -Path "$($DownloadFolder + $DLEXE)" -DestinationPath ($DownloadFolder + $Application) -Force
    }
        Write-Host "===== Installing $($Application)" -ForegroundColor "Green"
		$InstallerLocation = $($DownloadFolder + $Application + "\" + $InstallerName)
		Write-Host "Installer Location: $InstallerLocation"
		Start-Process $InstallerLocation -ArgumentList $Arguments -wait -PassThru
}

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
Write-Host "============================================================"
Write-Host "====== Install Citrix WEM Cloud Agent\" -ForegroundColor "Green"
Write-Host "============================================================"

if ($CredentialPrompt.IsPresent) {
	Write-Host "CredentialPrompt present - using credential prompt"
	$creds = get-credential
	$CitrixUserName = $creds.UserName
	$CitrixPassword = $creds.GetNetworkCredential().Password
}

if ($UseScriptVariables.IsPresent) {
	Write-Host "UseScriptVariables present - using hardcoded script values"
	$DLNumber 	= $DLNumber_HC
	$DLEXE 		= $DLEXE_HC
}

if (!(Get-ChildItem Env:CitrixUserName -ErrorAction SilentlyContinue)) {
	Write-Warning "Environment Variable for Citrix Username is missing. Assuming specific credential set"
	if ($null -eq $CitrixUserName) {
		Write-Warning "Citrix Username is missing. Exit Script"
		Exit
	}
}
if (!(Get-ChildItem Env:CitrixPassword -ErrorAction SilentlyContinue)) {
	Write-Warning "Environment Variable for Citrix Password is missing. Assuming specific credential set"
	if ($null -eq $CitrixPassword) {
		Write-Warning "Citrix Password is missing. Exit Script"
		Exit
	}
}

Write-Host "Citrix Username is: $CitrixUserName" -ForegroundColor Cyan

if (!(Test-Path -Path $DownloadFolder)) {
	New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

$OutFile = $DownloadFolder + $DLEXE

#Execute
CheckandDownload
#endregion