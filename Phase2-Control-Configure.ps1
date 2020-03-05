#Phase 2 - Configure

Write-Host "====== Configuring Start Layouts\"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (!(Test-Path -Path "C:\Tools")) {
	New-Item -Path "C:\Tools" -ItemType Directory | Out-Null
}
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/CreateShortcuts.ps1'))
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/CustomLayout-2019-Basic-Office-x64.xml' -outfile 'c:\Tools\CustomLayout-2019-Basic-Office-x64.xml'
Import-StartLayout -LayoutPath 'c:\Tools\CustomLayout-2019-Basic-Office-x64.xml' -MountPath 'c:\' -Verbose

Write-Host "====== Downloading AppMasking Files\"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JamesKindon/Citrix/master/FSLogix/AppMasking/Start%20Menu.fxr' -Outfile 'C:\Program Files\FSLogix\Apps\Rules\Start Menu.fxr'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/JamesKindon/Citrix/master/FSLogix/AppMasking/Start%20Menu.fxa' -Outfile 'C:\Program Files\FSLogix\Apps\Rules\Start Menu.fxa'

Write-Host "====== Configuring Default File Assocs\"
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Phase2-DefaultFileAssocs.ps1'))

Write-Host "====== Restoring PhotoViewer\"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/Restore_Windows_Photo_Viewer.reg" -UseBasicParsing -OutFile "C:\Tools\Restore_Windows_Photo_Viewer.reg"
Start-process -FilePath regsvr32.exe -ArgumentList '"C:\Program Files (x86)\Windows Photo Viewer\PhotoViewer.dll" /s' -PassThru
Invoke-Command {reg import "C:\Tools\Restore_Windows_Photo_Viewer.reg"}

Write-Host "====== Deleting Public Desktop Shortcuts\"
Remove-Item -Path "$Env:SystemDrive\Users\Public\Desktop\*" -Force
