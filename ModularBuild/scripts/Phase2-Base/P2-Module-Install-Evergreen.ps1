<#
    .SYNOPSIS
        Installs modules
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
[CmdletBinding()]
Param (
    [Parameter()]
    [System.String[]] $Modules = @("Evergreen")
)

#region Trust the PSGallery and install modules
$Repository = "PSGallery"
If (Get-PSRepository | Where-Object { $_.Name -eq $Repository -and $_.InstallationPolicy -ne "Trusted" }) {
    try {
        Write-Host " Trusting the repository: $Repository."
        Install-PackageProvider -Name "NuGet" -MinimumVersion "2.8.5.208" -Force
        Set-PSRepository -Name $Repository -InstallationPolicy "Trusted"
    }
    catch {
        Throw $_
        Break
    }
}

ForEach ($module in $Modules) {
    try {
        Write-Host " Checking module: $module."
        $installedModule = Get-Module -Name $module -ListAvailable | `
            Sort-Object -Property @{ Expression = { [System.Version]$_.Version }; Descending = $true } | `
            Select-Object -First 1
        $publishedModule = Find-Module -Name $module -ErrorAction "SilentlyContinue"
        If (($Null -eq $installedModule) -or ([System.Version]$publishedModule.Version -gt [System.Version]$installedModule.Version)) {
            Write-Host " Installing module: $module"
            $params = @{
                Name               = $module
                SkipPublisherCheck = $true
                Force              = $true
                ErrorAction        = "Stop"
            }
            Install-Module @params
        }
    }
    catch {
        Throw $_
        Break
    }
}
#endregion