#Phase 1 - Apps

$SfrHook = "HKLM:\SOFTWARE\Citrix\CtxHook\AppInit_DLLs\SfrHook\"
$WarningFile = "C:\Apps\WarningFile.txt"


function SetSfrHook {
    param (
        $ProcessName
    )
    if (Test-Path -Path $SfrHook) {
        New-Item -Path $SfrHook -Name $ProcessName -Force -ErrorAction SilentlyContinue | Out-Null
    }
    else {
        if (!(Test-path -Path $WarningFIle)) {
            New-Item -Path $WarningFile -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Write-Output "Citrix VDA does not appear to be installed, SfrHook for $ProcessName must be set post VDA install" | Out-File -Append $WarningFile
    }
}

#Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))


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
choco install microsoft-teams.install --params "'/AllUsers /AllUser /NoAutoStart'" -Y

Write-Host "====== Install Microsoft Autoruns\"
choco install autoruns -Y

#Write-Host "====== Install Microsoft Office 365 ProPlus\"
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-MicrosofOffice.ps1'))

Write-Host "====== Install Microsoft OneDrive\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-MicrosoftOneDrive.ps1'))

Switch -Regex ((Get-WmiObject Win32_OperatingSystem).Caption) {
    "Microsoft Windows Server*" {
        Write-Host "====== Install Microsoft Autologon\"
        choco install autologon -Y

        # Set Reg Key to bypass ICA Hooks https://support.citrix.com/article/CTX265011
        #SetSfrHook -ProcessName "msedge.exe"

    }
    "Microsoft Windows 10 Enterprise for Virtual Desktops" {
    }
    "Microsoft Windows 10*" {
        Write-Host "====== Install OldCalc\"
        choco install oldcalc -Y
    }
}

