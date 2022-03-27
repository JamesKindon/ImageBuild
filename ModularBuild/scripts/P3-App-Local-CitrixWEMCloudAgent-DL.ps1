#Downloads and Install Citrix WEM
#Can be used as part of a pipeline or MDT task sequence.
# https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Helpers/Downloads.csv


#//Release Data
$Application = "Citrix Workspace Environment Management"
$InstallerName = "Citrix Workspace Environment Management Agent.exe"

##// can set manually if not using variables
#$DLNumber 	= "20209"
#$DLEXE 		= "Workspace-Environment-Management-v-2112-01-00-01.zip"

$DLNumber 	= $env:cvad_wem_dl_num
$DLEXE 		= $env:cvad_wem_dl_name

$Arguments = "/quiet Cloud=1"
$DownloadFolder = "C:\Apps\Temp\"

$CitrixUserName = $env:CitrixUserName
$CitrixPassword = $env:CitrixPassword

#Uncomment to use credential object
#$creds = get-credential
#$CitrixUserName = $creds.UserName
#$CitrixPassword = $creds.GetNetworkCredential().Password

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
		Expand-Archive -Path "$($DownloadFolder + $DLEXE)" -DestinationPath $DownloadFolder -Force
    }

    #if ($InstallerType -eq "exe") {
        Write-Host "===== Installing $($Application)" -ForegroundColor "Green"
        Start-Process "$Outfile" -ArgumentList $Arguments -wait -PassThru
    #}
    #if ($InstallerType -eq "msi") {
        #Write-host "Installing $Application" -ForegroundColor Cyan
        #Start-Process "msiexec" -ArgumentList "/i $Outfile $InstallArgs" -Wait -PassThru
    #}
}

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
Write-Host "============================================================"
Write-Host "====== Install Citrix WEM Cloud Agent\" -ForegroundColor "Green"
Write-Host "============================================================"

if (!(Get-ChildItem Env:CitrixUserName -ErrorAction SilentlyContinue)) {
	Write-Warning "Environment Variable for Citrix Username is missing. Assuming speficic credential set"
	if ($null -eq $CitrixUserName) {
		Write-Warning "Citrix Username is missing. Exit Script"
		Exit
	}
}
if (!(Get-ChildItem Env:CitrixPassword -ErrorAction SilentlyContinue)) {
	Write-Warning "Environment Variable for Citrix Password is missing. Assuming speficic credential set"
	if ($null -eq $CitrixPassword) {
		Write-Warning "Citrix Password is missing. Exit Script"
		Exit
	}
}
#if (!(Get-ChildItem Env:ReleaseVersion -ErrorAction SilentlyContinue)) {
#	Write-Warning "Environment Variable for Citrix Release Version (LTSR or CR) is missing. Defaulting to: CR"
#	$ReleaseVersion = "CR"
#}

Write-Host "Citrix Username is: $CitrixUserName" -ForegroundColor Cyan
#Write-Host "Citrix Release Version is: $ReleaseVersion" -ForegroundColor Cyan

if (!(Test-Path -Path $DownloadFolder)) {
	New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

$OutFile = $DownloadFolder + ($DLEXE -replace ".zip","") + "\" + $InstallerName

#Execute
CheckandDownload
#endregion