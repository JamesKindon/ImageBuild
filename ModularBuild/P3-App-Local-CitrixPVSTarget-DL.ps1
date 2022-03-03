
#Downloads and Install Citrix PVS Target Device
#Can be used as part of a pipeline or MDT task sequence.
#Ryan Butler TechDrabble.com @ryan_c_butler 07/19/2019
#Updated by James Kindon
# https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Helpers/Downloads.csv
# https://github.com/JamesKindon/Citrix/blob/master/Downloads.csv
# https://github.com/ryancbutler/Citrix_DL_Scrapper/blob/main/ctx_dls.csv

$Application = "Citrix PVS Target Device"
##//LTSR Release Data
$DLNumber_LTSR = "19999"
$DLEXE_LTSR = "Citrix_Provisioning_1912_19.iso" #Citrix_Provisioning_1912_19.iso

##//Current Release Data
$DLNumber_CR = "20119"
$DLEXE_CR = "Citrix_Provisioning_2112.iso" #Citrix_Provisioning_2112.iso

$InstallExe = "PVS_Device_x64.exe"

##// Arguments
$Arguments = "/s /v`"/qn /norestart`""

$DownloadFolder = "C:\Apps\Temp\"

$ReleaseVersion = $env:ReleaseVersion
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
function CheckandDownloadPVSTarget {
	if (Test-Path $Outfile) {
		Write-Host "$Outfile exists, proceeding with install"
		InstallPVSTarget
	}
 else {
		Write-Host "Downloading Install File $($DLEXE), Please Wait...."
		Get-CTXBinary -DLNUMBER $DLNumber -DLEXE $DLEXE -CitrixUserName $CitrixUserName -CitrixPassword $CitrixPassword -DLPATH $DownloadFolder
		InstallPVSTarget
	}
}

function InstallPVSTarget {
    ##// Mount ISO
    Write-Host "Mounting ISO"
    $MountISO = Mount-DiskImage $Outfile -PassThru
    Start-Sleep -Seconds 10
    $DriveLetter = ($MountISO | Get-Volume).DriveLetter
    Push-Location ($DriveLetter + ":" + "\Device")

    Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue

    $LogsDir = "C:\Windows\Temp\PVS"
    if (!(Test-Path $LogsDir )) {
        New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
    }
    Write-Host "===== Installing $($Application)" -ForegroundColor "Green"
    $UnattendedArgs = $Arguments
    (Start-Process ($InstallExe) $UnattendedArgs -Wait -Verbose -Passthru).ExitCode

    ##// Dismount ISO
    Write-Host "Dismounting ISO"
    Pop-Location
    Dismount-DiskImage -ImagePath $Outfile | Out-Null
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
if (!(Get-ChildItem Env:ReleaseVersion -ErrorAction SilentlyContinue)) {
	Write-Warning "Environment Variable for Citrix Release Version (LTSR or CR) is missing. Defaulting to: CR"
	$ReleaseVersion = "CR"
}

Write-Host "Citrix Username is: $CitrixUserName" -ForegroundColor Cyan
Write-Host "Citrix Release Version is: $ReleaseVersion" -ForegroundColor Cyan

if (!(Test-Path -Path $DownloadFolder)) {
	New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

if ($ReleaseVersion -eq "LTSR") {
    $DLNumber = $DLNumber_LTSR
    $DLEXE = $DLEXE_LTSR
}
if ($ReleaseVersion -eq "CR") {
    $DLNumber = $DLNumber_CR
    $DLEXE = $DLEXE_CR
}

$Outfile = $DownloadFolder + $DLEXE

#Execute
CheckandDownloadPVSTarget
#endregion



