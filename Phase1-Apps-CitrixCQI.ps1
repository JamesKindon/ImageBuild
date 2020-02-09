#Downloads Latest Citrix CQI from https://support.citrix.com/article/CTX220774
#Can be used as part of a pipeline or MDT task sequence.
#Ryan Butler TechDrabble.com @ryan_c_butler 07/19/2019
#Updated by James Kindon

# Download URL for the appropriate Package
$Application = "CitrixCQI"
$DLURL = "https://phoenix.citrix.com/supportkc/filedownload?uri=/filedownload/CTX220774/CitrixCQI.zip"
$DownloadFolder = "C:\Apps"
$InstallArgs = 'OPTIONS="DISABLE_CEIP=1" /q'
$InstallerType = "msi" #MSI or EXE
$InstallerName = "CitrixCQI.msi"

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
    $start = Invoke-WebRequest "https://identity.citrix.com/Utility/STS/Sign-In" -SessionVariable websession -Verbose -UseBasicParsing

    #Set Form
    $form = @{
        "persistent" = "1"
        "userName"   = $CitrixUserName
        "loginbtn"   = ""
        "password"   = $CitrixPassword
        "returnURL"  = "https://www.citrix.com/login/bridge?url=https%3A%2F%2Fsupport.citrix.com%2Farticle%2FCTX224676%3Fdownload"
        "errorURL"   = 'https://www.citrix.com/login?url=https%3A%2F%2Fsupport.citrix.com%2Farticle%2FCTX224676%3Fdownload&err=y'
    }

    #Authenticate
    Invoke-WebRequest -Uri ("https://identity.citrix.com/Utility/STS/Sign-In") -WebSession $websession -Method POST -Body $form -ContentType "application/x-www-form-urlencoded" -Verbose -UseBasicParsing

    #Download File
    Invoke-WebRequest -WebSession $websession -Uri $DLURL -OutFile $Outfile -Verbose -UseBasicParsing
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



