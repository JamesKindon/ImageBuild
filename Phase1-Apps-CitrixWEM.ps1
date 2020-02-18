#Downloads Citrix WEM (not Cloud Service)
#Can be used as part of a pipeline or MDT task sequence.


# Download URL for the appropriate Package
$Application = "Citrix Workspace Environment Management"
$DLURL = "https://secureportal.citrix.com/Licensing/Downloads/UnrestrictedDL.aspx?DLID=16911&URL=https://downloads.citrix.com/16911/Workspace-Environment-Management-v-1912-01-00-01.zip"
$DownloadFolder = "C:\Apps"
$InstallArgs = "/install /quiet Cloud=0"
$InstallerType = "exe" #MSI or EXE
$InstallerName = "Citrix Workspace Environment Management Agent Setup.exe"

function CheckandDownload {
    if (Test-Path $Outfile) {
        Write-Host "$Outfile exists, proceeding with install"
        Install
    }
    else {
        Download
        Install
    }
}

function Download {
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

function Install {
    $File = $DLURL | Split-Path -Leaf
    if ($File -like "*.zip") {
        Write-Host "Extracting Archive to $DownloadFolder\$Application" -ForegroundColor Cyan
        New-Item -Path "$DownloadFolder\$Application" -ItemType Directory -Force | Out-Null
        Expand-Archive -Path $Outfile -DestinationPath $DownloadFolder\$Application -Force -Verbose
        $OutFile = $DownloadFolder + "\" + $Application + "\" + $InstallerName
    }
    if ($InstallerType -eq "exe") {
        Write-host "Installing $Application" -ForegroundColor Cyan
        Start-Process $Outfile -ArgumentList $InstallArgs -wait -PassThru
    }
    if ($InstallerType -eq "msi") {
        Write-host "Installing $Application" -ForegroundColor Cyan
        Start-Process "msiexec" -ArgumentList "/i $Outfile $InstallArgs" -Wait -PassThru
    }
}

$Outfile = $DownloadFolder + "\" + ($DLURL | Split-Path -Leaf)

#Execute
CheckandDownload