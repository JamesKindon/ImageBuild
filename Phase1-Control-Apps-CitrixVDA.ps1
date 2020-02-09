
#Downloads and Install Citrix CVAD VDA
#Can be used as part of a pipeline or MDT task sequence.
#Ryan Butler TechDrabble.com @ryan_c_butler 07/19/2019
#Updated by James Kindon

# Download URL for the appropriate VDA
$ServerVDAURL = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=16837&URL=https://downloads.citrix.com/16837/VDAServerSetup_1912.exe"
$DesktopVDAURL = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=16838&URL=https://downloads.citrix.com/16838/VDAWorkstationSetup_1912.exe"
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
	$LogsDir = "C:\Windows\Temp\VDA"
	if (!(Test-Path $LogsDir )) {
		New-Item -Path $LogsDir -Force | Out-Null
	}
	$UnattendedArgs = '/quiet /components vda,plugin /enable_remote_assistance /enable_hdx_ports /enable_real_time_transport /virtualmachine /noreboot /noresume /logpath $LogsDir /masterimage /install_mcsio_driver /exclude "Personal vDisk","Citrix Files for Windows","Citrix Files for Outlook"'
	$exit = (Start-Process ($Outfile) $UnattendedArgs -Wait -Verbose -Passthru).ExitCode

	if ($exit -eq 0) {
		Write-Host "VDA INSTALL COMPLETED!"
	}
	elseif ($exit -eq 3) {
		Write-Host "REBOOT NEEDED!"
	}
	elseif ($exit -eq 1) {
		#dump log
		Get-Content "$LogsDir\XenDesktop Installation.log"
		throw "Install FAILED! Check Log"
	}

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

	Write-Host "Citrix Username is: $CitrixUserName" -ForegroundColor Cyan

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

	$download = Invoke-WebRequest -Uri ($vdaurl) -WebSession $websession -MaximumRedirection 100 -Verbose -Method GET -UseBasicParsing
	$webform = @{
		"chkAccept"         = "on"
		"__EVENTTARGET"     = "clbAccept_0"
		"__EVENTARGUMENT"   = "clbAccept_0_Click"
		"__VIEWSTATE"       = ($download.InputFields | Where-Object { $_.id -eq "__VIEWSTATE" }).value
		"__EVENTVALIDATION" = ($download.InputFields | Where-Object { $_.id -eq "__EVENTVALIDATION" }).value
	}

	#Download
	Write-Host "Downloading VDA...Please Wait...." -ForegroundColor Cyan
	Invoke-WebRequest -Uri ($vdaurl) -WebSession $websession -Method POST -Body $webform -ContentType "application/x-www-form-urlencoded" -OutFile $Outfile -Verbose -UseBasicParsing
}

# Desktop or Server Switch
Switch -Regex ((Get-WmiObject Win32_OperatingSystem).Caption) {
	"Microsoft Windows Server*" {
		Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
		$vdaurl = $ServerVDAURL
	}
	"Microsoft Windows 10 Enterprise for Virtual Desktops" {
		Write-Host "Setting Multi-session OS Virtual Delivery Agent" -ForegroundColor Cyan
		$vdaurl = $ServerVDAURL
	}
	"Microsoft Windows 10*" {
		Write-Host "Setting Single-session OS Virtual Delivery Agent" -ForegroundColor Cyan
		$vdaurl = $DesktopVDAURL
	}
}

$Outfile = $DownloadFolder + "\" + ($vdaurl | Split-Path -Leaf)

#Execute
CheckandDownloadVDA



