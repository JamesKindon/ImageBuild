#Phase 0 - Build
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "====== Configure Roles\"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase0-SetRoles.ps1'))

Write-Host "====== Install VCRedists\"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase0-VCRedists.ps1'))

#Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#Write-Host "====== Install Microsoft .NET Framework\"
#choco install dotnetfx -Y
#Restart-Computer -Force