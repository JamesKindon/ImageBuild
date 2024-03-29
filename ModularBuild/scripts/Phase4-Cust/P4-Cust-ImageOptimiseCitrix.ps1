Write-Host "=====  Executing Citrix Optimizer" -ForegroundColor "Green"

Set-ExecutionPolicy Bypass -Force
#//  Remove execution if using BIS-F
#& "C:\Tools\CitrixOptimizer\CtxOptimizerEngine.ps1" -mode Execute
#Use 3rd Party Optimizations
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/j81blog/Citrix_Optimizer_Community_Template_Marketplace/master/templates/John%20Billekens/JohnBillekens_3rd_Party_Components.xml" -UseBasicParsing -OutFile "C:\Tools\CitrixOptimizer\Templates\JohnBillekens_3rd_Party_Components.xml"
#//  Remove execution if using BIS-F
#& "C:\Tools\CitrixOptimizer\CtxOptimizerEngine.ps1" -Template "C:\Tools\CitrixOptimizer\Templates\JohnBillekens_3rd_Party_Components.xml" -mode Execute 
