Write-Host "===== Downloading and Executing Citrix Optimizer" -ForegroundColor "Green"

$TempAppInstallDir = "C:\Apps\Temp"

if (!(Test-Path -Path $TempAppInstallDir)) {
    New-Item -Path $TempAppInstallDir -ItemType Directory -Force | Out-Null
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Write-Host "Downloading Citrix Optimizer Software" -ForegroundColor Cyan
#Invoke-WebRequest -Uri "https://github.com/JamesKindon/ImageBuild/blob/master/CitrixOptimizer.zip" -OutFile "$TempAppInstallDir\CitrixOptimizer.Zip" -UseBasicParsing

#If (!(Test-Path -Path "c:\Tools")) {
#    New-Item -Path "C:\Tools" -ItemType Directory -Force | Out-Null
#}
#Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JamesKindon/ImageBuild/master/CitrixOptimizer.zip" -OutFile "C:\Tools\CitrixOptimizer.Zip" -UseBasicParsing
#Expand-Archive -Path ($TempAppInstallDir + "\CitrixOptimizer.Zip") -DestinationPath "C:\Tools\CitrixOptimizer"

Set-ExecutionPolicy Bypass -Force
& "C:\Tools\CitrixOptimizer\CtxOptimizerEngine.ps1" -mode Execute
#Use 3rd Party Optimizations
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/j81blog/Citrix_Optimizer_Community_Template_Marketplace/master/templates/John%20Billekens/JohnBillekens_3rd_Party_Components.xml" -UseBasicParsing -OutFile "C:\Tools\CitrixOptimizer\Templates\3rd_Party_Components.xml"
& "C:\Tools\CitrixOptimizer\CtxOptimizerEngine.ps1" -Template "C:\Tools\CitrixOptimizer\Templates\3rd_Party_Components.xml" -mode Execute


#Switch -Regex ((Get-WmiObject Win32_OperatingSystem).Caption) {
#    "Microsoft Windows Server*" {
#    }
#    "Microsoft Windows 10 Enterprise for Virtual Desktops" {
#    }
#    "Microsoft Windows 10*" {
#        Write-Host "====== Remove Modern Apps\"
#        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/JamesKindon/Citrix/master/Windows%2010%20Optimisation/Invoke-RemoveBuiltinApps.ps1" -UseBasicParsing -OutFile "c:\Tools\Invoke-RemoveBuiltinApps.ps1"
#        & "C:\Tools\Invoke-RemoveBuiltinApps.ps1"
#    }
#}

#---------Autoruns