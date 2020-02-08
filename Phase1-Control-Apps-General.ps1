#Phase 1 - Apps
Write-Host "====== Install 7zip\"
choco install 7zip.install -Y

Write-Host "====== Install Notepad ++\"
choco install notepadplusplus -Y

Write-Host "====== Install VLC\"
choco install vlc -Y

Write-Host "====== Install FSLogix Components\"
choco install fslogix -Y
choco install fslogix-rule -Y

Write-Host "====== Install BIS-F\"
choco install bis-f -Y

Write-Host "====== Install Microsoft Edge\"
choco install microsoft-edge -Y
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Edge%20(Chromium)/master_preferences' -OutFile "${Env:ProgramFiles(x86)}\Microsoft\Edge\Application\Master_preferences" -UseBasicParsing

Write-Host "====== Install Google Chrome Enterprise\"
choco install googlechrome -Y

Write-Host "====== Install Adobe Reader DC\"
choco install adobereader -Y

Write-Host "====== Install Microsoft Teams\"
choco install microsoft-teams.install -Y

Write-Host "====== Install Microsoft Office 365 ProPlus\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-MicrosofOffice.ps1'))

Write-Host "====== Install Microsoft OneDrive\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-MicrosoftOneDrive.ps1'))

Switch -Regex ((Get-WmiObject Win32_OperatingSystem).Caption) {
    "Microsoft Windows Server*" {
    }
    "Microsoft Windows 10 Enterprise for Virtual Desktops" {
    }
    "Microsoft Windows 10*" {
        #---------OldCalc
        #Start-Process -FilePath "\\\Citrix\oldcalcwin10\Old Calculator for Windows 10.exe" -Wait -PassThru
    }
}

