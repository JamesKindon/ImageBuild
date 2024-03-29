<#
.SYNOPSIS
    Downloads and Install Citrix CVAD VDA
.DESCRIPTION
	Can be used as part of a pipeline or MDT task sequence.
	https://github.com/ryancbutler/Citrix/blob/master/XenDesktop/AutoDownload/Helpers/Downloads.csv
	Ryan Butler TechDrabble.com @ryan_c_butler 07/19/2019
	Updated by James Kindon
	https://github.com/JamesKindon/Citrix/blob/master/Downloads.csv
	https://github.com/ryancbutler/Citrix_DL_Scrapper/blob/main/ctx_dls.csv
.EXAMPLE
	.\P3-App-Local-CitrixVDA-DL.ps1 -CredentialPrompt -UseScriptVariables
	Will prompt for credentials and use hardcoded download details in script

	.\P3-App-Local-CitrixVDA-DL.ps1
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
$Application = "Citrix Virtual Delivery Agent"
##//LTSR Release Data
$DLNumber_Server_LTSR_HC        = "16837"                        #Only used when UseScriptVariables Switch is present, else pipeline
$DLEXE_Server_LTSR_HC           = "VDAServerSetup_1912.exe"      #Only used when UseScriptVariables Switch is present, else pipeline
$DLNumber_Workstation_LTSR_HC   = "16838"                        #Only used when UseScriptVariables Switch is present, else pipeline
$DLEXE_Workstation_LTSR_HC      = "VDAWorkstationSetup_1912.exe" #Only used when UseScriptVariables Switch is present, else pipeline
##//Current Release Data
$DLNumber_Server_CR_HC          = "20429"                        #Only used when UseScriptVariables Switch is present, else pipeline
$DLEXE_Server_CR_HC             = "VDAServerSetup_2203.exe"      #Only used when UseScriptVariables Switch is present, else pipeline
$DLNumber_Workstation_CR_HC     = "20430"                        #Only used when UseScriptVariables Switch is present, else pipeline
$DLEXE_Workstation_CR_HC        = "VDAWorkstationSetup_2203.exe" #Only used when UseScriptVariables Switch is present, else pipeline
##//Arguments
$Arguments_Server               = "/noreboot /noresume /quiet /enable_remote_assistance /disableexperiencemetrics /enable_ss_ports /virtualmachine /enable_real_time_transport /enable_hdx_ports /enable_hdx_udp_ports /includeadditional ""Citrix MCS IODriver"" /exclude ""Workspace Environment Management"",""User Personalization layer"",""Citrix Files for Outlook"",""Citrix Files for Windows"",""Citrix Supportability Tools"",""Citrix Telemetry Service"" /components vda,plugins /masterimage" 
$Arguments_Workstation          = "/noreboot /noresume /quiet /enable_remote_assistance /disableexperiencemetrics /enable_ss_ports /virtualmachine /enable_real_time_transport /enable_hdx_ports /enable_hdx_udp_ports /includeadditional ""Citrix MCS IODriver"" /exclude ""Workspace Environment Management"",""User Personalization layer"",""Citrix Files for Outlook"",""Citrix Files for Windows"",""Citrix Supportability Tools"",""Citrix Telemetry Service"" /components vda,plugins /masterimage"
$DownloadFolder                 = "C:\Apps\Temp\"
#//Pipeline Variables
$DLNumber_Server_LTSR           = $env:cvad_vda_server_dl_num_ltsr
$DLEXE_Server_LTSR              = $env:cvad_vda_server_dl_name_ltsr
$DLNumber_Workstation_LTSR      = $env:cvad_vda_workstation_dl_num_ltsr
$DLEXE_Workstation_LTSR         = $env:cvad_vda_workstation_dl_name_ltsr
$DLNumber_Server_CR             = $env:cvad_vda_server_dl_num_cr
$DLEXE_Server_CR                = $env:cvad_vda_server_dl_name_cr
$DLNumber_Workstation_CR        = $env:cvad_vda_workstation_dl_num_cr
$DLEXE_Workstation_CR           = $env:cvad_vda_workstation_dl_name_cr
$ReleaseVersion                 = $env:ReleaseVersion
$CitrixUserName                 = $env:CitrixUserName
$CitrixPassword                 = $env:CitrixPassword
#endregion

#region Functions
# ============================================================================
# Functions
# ============================================================================
function CheckandDownloadVDA {
	if (Test-Path $Outfile) {
		Write-Host "$Outfile exists, proceeding with install"
		InstallVDA
	}
 else {
		Write-Host "Downloading Install File $($DLEXE), Please Wait...."
		Get-CTXBinary -DLNUMBER $DLNumber -DLEXE $DLEXE -CitrixUserName $CitrixUserName -CitrixPassword $CitrixPassword -DLPATH $DownloadFolder
		InstallVDA
	}
}

function InstallVDA {
	Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue
	$LogsDir = "C:\Windows\Temp\VDA"
	if (!(Test-Path $LogsDir )) {
		New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
	}
	Write-Host "===== Installing $($Application)" -ForegroundColor "Green"
	$UnattendedArgs = $Arguments
	(Start-Process ($Outfile) $UnattendedArgs -Wait -Verbose -Passthru).ExitCode
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

Write-Host "============================================================"
Write-Host "====== Install Citrix VDA\" -ForegroundColor "Green"
Write-Host "============================================================"

if ($CredentialPrompt.IsPresent) {
	Write-Host "CredentialPrompt present - using credential prompt"
	$creds = get-credential
	$CitrixUserName = $creds.UserName
	$CitrixPassword = $creds.GetNetworkCredential().Password
}

if ($UseScriptVariables.IsPresent) {
	Write-Host "UseScriptVariables present - using hardcoded script values"
	$DLNumber_Server_LTSR       = $DLNumber_Server_LTSR_HC
    $DLEXE_Server_LTSR          = $DLEXE_Server_LTSR_HC
    $DLNumber_Workstation_LTSR  = $DLNumber_Workstation_LTSR_HC
    $DLEXE_Workstation_LTSR     = $DLEXE_Workstation_LTSR_HC

    $DLNumber_Server_CR         = $DLNumber_Server_CR_HC
    $DLEXE_Server_CR            = $DLEXE_Server_CR_HC
    $DLNumber_Workstation_CR    = $DLNumber_Workstation_CR_HC
    $DLEXE_Workstation_CR       = $DLEXE_Workstation_CR_HC
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

if (!(Get-ChildItem Env:ReleaseVersion -ErrorAction SilentlyContinue)) {
	Write-Warning "Environment Variable for Citrix Release Version (LTSR or CR) is missing. Defaulting to: CR"
	$ReleaseVersion = "CR"
}

Write-Host "Citrix Username is: $CitrixUserName" -ForegroundColor Cyan
Write-Host "Citrix Release Version is: $ReleaseVersion" -ForegroundColor Cyan

if (!(Test-Path -Path $DownloadFolder)) {
	New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
}

# Desktop or Server Switch
Switch -Regex ((Get-CimInstance -ClassName "CIM_OperatingSystem").Caption) {
    "^Microsoft Windows Server 2022.*$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Server_LTSR
            $DLEXE = $DLEXE_Server_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Server_CR
            $DLEXE = $DLEXE_Server_CR
        }
        $Arguments = $Arguments_Server; Break
    }
    "^Microsoft Windows Server 2019.*$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Server_LTSR
            $DLEXE = $DLEXE_Server_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Server_CR
            $DLEXE = $DLEXE_Server_CR
        }
        $Arguments = $Arguments_Server; Break
    }
    "^Microsoft Windows Server 2016.*$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Server_LTSR
            $DLEXE = $DLEXE_Server_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Server_CR
            $DLEXE = $DLEXE_Server_CR
        }
        $Arguments = $Arguments_Server; Break
    }
    "^Microsoft Windows 11 Enterprise for Virtual Desktops$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Server_LTSR
            $DLEXE = $DLEXE_Server_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Server_CR
            $DLEXE = $DLEXE_Server_CR
        }
        $Arguments = $Arguments_Server; Break
    }
    "^Microsoft Windows 10 Enterprise for Virtual Desktops$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Server_LTSR
            $DLEXE = $DLEXE_Server_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Server_CR
            $DLEXE = $DLEXE_Server_CR
        }
        $Arguments = $Arguments_Server; Break
    }
    "^Microsoft Windows 11.*$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Single-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Workstation_LTSR
            $DLEXE = $DLEXE_Workstation_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Workstation_CR
            $DLEXE = $DLEXE_Workstation_CR
        }
        $Arguments = $Arguments_Workstation; Break
    }
    "^Microsoft Windows 10.*$" {
        Write-Host "OS Version is: $((Get-WmiObject Win32_OperatingSystem).Caption)"
        Write-Host "Setting Single-session OS Virtual Delivery Agent" -ForegroundColor Cyan
        if ($ReleaseVersion -eq "LTSR") {
            $DLNumber = $DLNumber_Workstation_LTSR
            $DLEXE = $DLEXE_Workstation_LTSR
        }
        if ($ReleaseVersion -eq "CR") {
            $DLNumber = $DLNumber_Workstation_CR
            $DLEXE = $DLEXE_Workstation_CR
        }
        $Arguments = $Arguments_Workstation; Break
    }
}

$Outfile = $DownloadFolder + $DLEXE

#Execute
CheckandDownloadVDA
#endregion



