#Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/ElitebookSOE/Install_Apps.ps1'))

Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install chocolatey-core.extension -Y
choco install 7zip -y
choco install adobereader -y
choco install adobereader-update -y
choco install firefox -Y
choco install GoogleChrome -y
choco install microsoft-edge -Y
choco install brave -Y
choco install keepass -y
choco install notepadplusplus.install -Y
choco install pstools -y
choco install sysinternals -y
choco install vlc -Y
choco install winscp -y
choco install visualstudiocode -y
choco install vscode-powershell -y
choco install lastpass -y --ignore-checksums
choco install teamviewer -y
choco install slack -y
choco install microsoft-teams -y
choco install anydesk -y
choco install git.install -Y
choco install github-desktop -Y
choco install rdmfree -Y
choco install gimp -y
choco install microsoft-windows-terminal -Y
choco install bis-f -Y
choco install fslogix-rule -Y
choco install fslogix-java -Y
choco install whatsapp -Y 
choco install vnc-viewer -Y
choco install windirstat -Y
choco install citrix-workspace -Y
choco install zoom-client -Y
choco install microsoft-teams -Y

Write-Host "====== Install Microsoft OneDrive\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/ElitebookSOE/MicrosoftOneDrive.ps1'))

Write-Host "====== Install Microsoft Office\"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/ElitebookSOE/MicrosofOffice.ps1'))

Write-Host "====== Configure Default File Assocs\"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/ElitebookSOE/DefaultFileAssocs.ps1'))

Write-Host "====== Configuring Start Layouts\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (!(Test-Path -Path "C:\Tools")) {
	New-Item -Path "C:\Tools" -ItemType Directory | Out-Null
}
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/ElitebookSOE/KindonStartLayout.xml' -outfile 'c:\Tools\KindonStartLayout.xml'
Import-StartLayout -LayoutPath 'c:\Tools\CustomLayout-201KindonStartLayout.xml' -MountPath 'c:\' -Verbose
