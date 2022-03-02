#Downloads and Install Citrix WEM
#Can be used as part of a pipeline or MDT task sequence.
# https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Helpers/Downloads.csv


#//Release Data
$Application = "CitrixOptimizer"
#$InstallerName = "CitrixCQI.msi"

#$DLNumber = "20209"
$DLEXE = "CitrixOptimizer.zip"
$DLURL = "https://fileservice.citrix.com/download/secured/support/article/CTX224676/downloads/CitrixOptimizer.zip"

#$Arguments = 'OPTIONS="DISABLE_CEIP=1" /q'
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
		#Get-CTXBinary -DLNUMBER $DLNumber -DLEXE $DLEXE -CitrixUserName $CitrixUserName -CitrixPassword $CitrixPassword -DLPATH $DownloadFolder
		Download
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

function Download {
#Initialize Session 
Invoke-WebRequest "https://identity.citrix.com/Utility/STS/Sign-In" -SessionVariable websession -UseBasicParsing | Out-Null

#Set Form
$form = @{
	"persistent" = "1"
	"userName" = $CitrixUserName
	"loginbtn" = ""
	"password" = $CitrixPassword
	"returnURL" = "https://login.citrix.com/bridge?url=https://support.citrix.com/article/CTX224676"
	"errorURL" = "https://login.citrix.com?url=https://support.citrix.com/article/CTX224676&err=y"
}
#Authenticate
Invoke-WebRequest -Uri ("https://identity.citrix.com/Utility/STS/Sign-In") -WebSession $websession -Method POST -Body $form -ContentType "application/x-www-form-urlencoded" -UseBasicParsing | Out-Null

#Download File
Invoke-WebRequest -WebSession $websession -Uri $DLURL -OutFile $OutFile -Verbose -UseBasicParsing

}

function Install {
	Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue
    if ($DLEXE -like "*.zip") {

		If (!(Test-Path -Path "c:\Tools")) {
			New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
		}
		Write-Host "Extracting Archive to $($DownloadFolder + $Application)" -ForegroundColor Cyan

		Expand-Archive -Path ($DownloadFolder + "\CitrixOptimizer.Zip") -DestinationPath "C:\Tools\CitrixOptimizer" -Force
    }

    #if ($InstallerType -eq "exe") {
        #Write-Host "===== Installing $($Application)" -ForegroundColor "Green"
        #Start-Process "$Outfile" -ArgumentList $Arguments -wait -PassThru
		#Start-Process -FilePath "C:\Apps\Temp\Workspace-Environment-Management-v-2112-01-00-01\Citrix Workspace Environment Management Agent.exe" -ArgumentList $Arguments -wait -PassThru
    #}
    #if ($InstallerType -eq "msi") {
        #Write-host "Installing $Application" -ForegroundColor Cyan
        #Start-Process "msiexec" -ArgumentList "/i $Outfile $InstallArgs" -Wait -PassThru
		#Start-Process "msiexec" -ArgumentList "/i ($DownloadFolder + $Application + "\" + $InstallerName) $InstallArgs" -Wait -PassThru
    #}
}

#endregion

#Region Execute
# ============================================================================
# Execute
# ============================================================================
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

$OutFile = $DownloadFolder + $DLEXE

#Execute
CheckandDownload
#endregion