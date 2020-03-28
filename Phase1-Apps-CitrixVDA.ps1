
#Downloads and Install Citrix CVAD VDA
#Can be used as part of a pipeline or MDT task sequence.
#Ryan Butler TechDrabble.com @ryan_c_butler 07/19/2019
#Updated by James Kindon

# Download URL for the appropriate VDA
#LTSR 1912
$ServerVDAURL_LTSR = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=16837&URL=https://downloads.citrix.com/16837/VDAServerSetup_1912.exe"
$DesktopVDAURL_LTSR = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=16838&URL=https://downloads.citrix.com/16838/VDAWorkstationSetup_1912.exe"
#Current Release
$ServerVDAURL_CR = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=17569&URL=https://downloads.citrix.com/17569/VDAServerSetup_2003.exe"
$DesktopVDAURL_CR = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=17570&URL=https://downloads.citrix.com/17570/VDAWorkstationSetup_2003.exe"

$DownloadFolder = "C:\Apps"


function CheckandDownloadVDA {
	if (Test-Path $Outfile) {
		Write-Host "$Outfile exists, proceeding with install"
		InstallVDA
	}
 else {
		DownloadVDA
		InstallVDA
	}
}

function InstallVDA {
	Set-MpPreference -DisableRealtimeMonitoring $True -ErrorAction SilentlyContinue
	$LogsDir = "C:\Windows\Temp\VDA"
	if (!(Test-Path $LogsDir )) {
		New-Item -Path $LogsDir -ItemType Directory -Force | Out-Null
	}
	$UnattendedArgs = "/quiet /components vda,plugins /enable_remote_assistance /enable_hdx_ports /enable_real_time_transport /virtualmachine /noreboot /noresume /logpath $LogsDir /masterimage /install_mcsio_driver"
	(Start-Process ($Outfile) $UnattendedArgs -Wait -Verbose -Passthru).ExitCode
}

function DownloadVDA {
	#Uncomment to use plain text or env variables
	$CitrixUserName = $env:citrixusername
	$CitrixPassword = $env:citrixpassword

	#Uncomment to use credential object
	#$creds = get-credential
	#$CitrixUserName = $creds.UserName
	#$CitrixPassword = $creds.GetNetworkCredential().Password

	if (!(Get-ChildItem Env:citrixusername -ErrorAction SilentlyContinue)) {
		Write-Warning "Environment Variable for Citrix Username is missing. Exit Script"
		Exit
	}
	if (!(Get-ChildItem Env:citrixpassword -ErrorAction SilentlyContinue)) {
		Write-Warning "Environment Variable for Citrix Password is missing. Exit Script"
		Exit
	}
	if (!(Get-ChildItem Env:ReleaseVersion -ErrorAction SilentlyContinue)) {
		Write-Warning "Environment Variable for Citrix Release Version (LTSR or CR) is missing. Exit Script"
		Exit
	}

	Write-Host "Citrix Username is: $CitrixUserName" -ForegroundColor Cyan
	Write-Host "Citrix Release Version is: $ReleaseVersion" -ForegroundColor Cyan


	if (!(Test-Path -Path $DownloadFolder)) {
		New-Item -Path $DownloadFolder -ItemType Directory | Out-Null
	}


	Write-Host "Download location is $Outfile" -ForegroundColor Cyan

	$code = @"
	public class SSLHandler
	{
    public static System.Net.Security.RemoteCertificateValidationCallback GetSSLHandler()
    {
        return new System.Net.Security.RemoteCertificateValidationCallback((sender, certificate, chain, policyErrors) => { return true; });
    }
	}
"@
	#compile the class
	try {
		if ([SSLHandler]) {
			Write-Verbose "SSLHandler already loaded"
		}
	}
	catch {
		Write-Verbose "SSLHandler loading"
		Add-Type -TypeDefinition $code
	}

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = [SSLHandler]::GetSSLHandler()

	#Initialize Session
	Invoke-WebRequest "https://identity.citrix.com/Utility/STS/Sign-In?ReturnUrl=%2fUtility%2fSTS%2fsaml20%2fpost-binding-response" -SessionVariable websession -Verbose -UseBasicParsing | Out-Null

	#Set Form
	$form = @{
		"persistent" = "on"
		"userName"   = $CitrixUserName
		"password"   = $CitrixPassword
	}

	#Authenticate
	Invoke-WebRequest -Uri ("https://identity.citrix.com/Utility/STS/Sign-In?ReturnUrl=%2fUtility%2fSTS%2fsaml20%2fpost-binding-response") -WebSession $websession -Method POST -Body $form -ContentType "application/x-www-form-urlencoded" -Verbose -UseBasicParsing | Out-Null

	$download = Invoke-WebRequest -Uri ($DLURL) -WebSession $websession -MaximumRedirection 100 -Verbose -Method GET -UseBasicParsing
	$webform = @{
		"chkAccept"         = "on"
		"__EVENTTARGET"     = "clbAccept_0"
		"__EVENTARGUMENT"   = "clbAccept_0_Click"
		"__VIEWSTATE"       = ($download.InputFields | Where-Object { $_.id -eq "__VIEWSTATE" }).value
		"__EVENTVALIDATION" = ($download.InputFields | Where-Object { $_.id -eq "__EVENTVALIDATION" }).value
	}

	#Download
	Write-Host "Downloading VDA...Please Wait...." -ForegroundColor Cyan
	$ProgressPreference = "SilentlyContinue"
	Invoke-WebRequest -Uri ($DLURL) -WebSession $websession -Method POST -Body $webform -ContentType "application/x-www-form-urlencoded" -OutFile $Outfile -Verbose -UseBasicParsing
}

# Check for Version and Set URL
$ReleaseVersion = $env:ReleaseVersion
if ($ReleaseVersion -eq "LTSR") {
	$ServerVDAURL = $ServerVDAURL_LTSR
	$DesktopVDAURL = $DesktopVDAURL_LTSR
}
if ($ReleaseVersion -eq "CR") {
	$ServerVDAURL = $ServerVDAURL_CR
	$DesktopVDAURL = $DesktopVDAURL_CR
}

# Desktop or Server Switch
Switch -Regex ((Get-WmiObject Win32_OperatingSystem).Caption) {
	"Microsoft Windows Server*" {
		Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
		$DLURL = $ServerVDAURL
	}
	"Microsoft Windows 10 Enterprise for Virtual Desktops" {
		Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
		$DLURL = $ServerVDAURL
	}
	"Microsoft Windows 10*" {
		Write-Host "Setting Single-session OS Virtual Delivery Agent" -ForegroundColor Cyan
		$DLURL = $DesktopVDAURL
	}
}

$Outfile = $DownloadFolder + "\" + ($DLURL | Split-Path -Leaf)

#Execute

CheckandDownloadVDA



