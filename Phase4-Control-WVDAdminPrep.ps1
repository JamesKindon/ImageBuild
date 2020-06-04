

#Downloads WVD Admin Components to custom image ready for provisioning with WVDAdmin either initially or in the future

function DownloadComponent {
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)] 
        [string]$URL
    )
    $Outfile = $DownloadFolder + "\" + ($URL | Split-Path -Leaf)
    Write-Host "Downloading $OutFile...Please Wait...." -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing -Uri $URL -OutFile $Outfile | Out-Null
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"

$DownloadFolder = "C:\ITPC-WVD-PostCustomizing"

if (!(Test-Path $DownloadFolder)) {
    try {
        New-Item -Path $DownloadFolder -ItemType Directory -ErrorAction Stop | Out-Null
        Write-Host "Created download directory $DownloadFolder"
    }
    catch {
        Write-Warning "Failed to create download directory $DownloadFolder"
    }
}

DownloadComponent -URL "https://saaewvdgeneral.blob.core.windows.net/wvd/Microsoft.RDInfra.RDAgent.msi"
DownloadComponent -URL "https://saaewvdgeneral.blob.core.windows.net/wvd/Microsoft.RDInfra.RDAgentBootLoader.msi"
DownloadComponent -URL "https://saaewvdgeneral.blob.core.windows.net/wvd/ITPC-WVD-Image-Processing.ps1"

Write-Host "Downloading Sepago Azure Monitor for WVD, RDS and Citrix"
DownloadComponent -URL "http://loganalytics.sepago.com/downloads/ITPC-LogAnalyticsAgent.zip"