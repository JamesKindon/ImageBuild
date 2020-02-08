#Phase 1 - Apps - Citrix
Write-Host "====== Install Citrix VDA\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase1-Control-Apps-CitrixVDA.ps1'))
#---------WEM
#Start-Process -FilePath "\\\Citrix\Workspace-Environment-Management-v-1912-01-00-01\Citrix Workspace Environment Management Agent Setup.exe" -ArgumentList "/install /quiet Cloud=0" -wait -PassThru

#---------CQI
#Start-Process -FilePath msiexec.exe -ArgumentList '/i "\\\Citrix\CitrixCQI\CitrixCQI.msi" OPTIONS="DISABLE_CEIP=1" /q' -wait -PassThru
