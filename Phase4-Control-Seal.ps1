#Phase 4 - Seal 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Get-InstalledSoftware.ps1'))

# Re-enable Defender
Write-Output "====== Enable Windows Defender real time scan"
Set-MpPreference -DisableRealtimeMonitoring $false
#Write-Output "====== Enable Windows Store updates"
#reg delete HKLM\Software\Policies\Microsoft\Windows\CloudContent /v DisableWindowsConsumerFeatures /f
#reg delete HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /f

# Sysprep
Write-Output "====== Run Sysprep"

#region Prepare
If (Get-Service -Name "RdAgent" -ErrorAction "SilentlyContinue") { Set-Service -Name "RdAgent" -StartupType "Disabled" }
If (Get-Service -Name "WindowsAzureTelemetryService" -ErrorAction "SilentlyContinue") { Set-Service -Name "WindowsAzureTelemetryService" -StartupType "Disabled" }
If (Get-Service -Name "WindowsAzureGuestAgent" -ErrorAction "SilentlyContinue") { Set-Service -Name "WindowsAzureGuestAgent" -StartupType "Disabled" }
Remove-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\SysPrepExternal\\Generalize' -Name '*'
#endregion

#region Sysprep
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State"
& $env:SystemRoot\System32\Sysprep\Sysprep.exe /oobe /generalize /quiet /quit
While ($True) {
    $imageState = Get-ItemProperty $RegPath | Select-Object ImageState
    If ($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') {
        Write-Output $imageState.ImageState
        Start-Sleep -s 10 
    }
    Else {
        Break
    }
}
$imageState = Get-ItemProperty $RegPath | Select-Object ImageState
Write-Output $imageState.ImageState
#endregion
Write-Host "================ Complete: Sysprep."