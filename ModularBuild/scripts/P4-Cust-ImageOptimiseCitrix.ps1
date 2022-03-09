Write-Host "=====  Executing Citrix Optimizer" -ForegroundColor "Green"

$TempAppInstallDir = "C:\Apps\Temp"

if (!(Test-Path -Path $TempAppInstallDir)) {
    New-Item -Path $TempAppInstallDir -ItemType Directory -Force | Out-Null
}

Set-ExecutionPolicy Bypass -Force
& "C:\Tools\CitrixOptimizer\CtxOptimizerEngine.ps1" -mode Execute
#Use 3rd Party Optimizations
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/j81blog/Citrix_Optimizer_Community_Template_Marketplace/master/templates/John%20Billekens/JohnBillekens_3rd_Party_Components.xml" -UseBasicParsing -OutFile "C:\Tools\CitrixOptimizer\Templates\JohnBillekens_3rd_Party_Components.xml"
& "C:\Tools\CitrixOptimizer\CtxOptimizerEngine.ps1" -Template "C:\Tools\CitrixOptimizer\Templates\3rd_Party_Components.xml" -mode Execute
