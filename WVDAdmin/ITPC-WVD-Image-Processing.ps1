# This powershell script is part of WVD Admin - see https://blog.itprocloud.de/Windows-Virtual-Desktop-Admin/ for more information
# Current Version of this script: 2.5

param(

	[string] $Secret='',

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[ValidateSet('Generalize','JoinDomain')]
	[string] $Mode,
	[string] $LocalAdminName='localAdmin',
	[string] $LocalAdminPassword='',
	[string] $DomainJoinUserName='',
	[string] $DomainJoinUserPassword='',
	[string] $DomainJoinOU='',
	[string] $DomainFqdn='',
	[string] $WvdRegistrationKey='',
	[string] $LogDir="$env:windir\system32\logfiles"
)

function LogWriter($message)
{
    $message="$(Get-Date ([datetime]::UtcNow) -Format "o") $message"
	write-host($message)
	if ([System.IO.Directory]::Exists($LogDir)) {write-output($message) | Out-File $LogFile -Append}
}

# Define static variables
$LocalConfig="C:\ITPC-WVD-PostCustomizing"

# Define logfile
$LogFile=$LogDir+"\WVD.Customizing.log"

# Main
LogWriter("Starting ITPC-WVD-Image-Processing in mode ${Mode}")


# check for the existend of the helper scripts
if ((Test-Path ($LocalConfig+"\ITPC-WVD-Image-Processing.ps1")) -eq $false) {
	# Create local directory for script(s) and copy files (including the RD agent and boot loader - rename it to the specified name)
	LogWriter("Copy files to local session host or downloading files from Microsoft")
	new-item $LocalConfig -ItemType Directory -ErrorAction Ignore
	try {(Get-Item $LocalConfig -ErrorAction Ignore).attributes="Hidden"} catch {}

	if ((Test-Path ("${PSScriptRoot}\ITPC-WVD-Image-Processing.ps1")) -eq $false) {
		LogWriter("Creating ITPC-WVD-Image-Processing.ps1")
		Copy-Item "$($MyInvocation.InvocationName)" -Destination ($LocalConfig+"\ITPC-WVD-Image-Processing.ps1")
	} else {Copy-Item "${PSScriptRoot}\ITPC-WVD-Image-Processing.ps1" -Destination ($LocalConfig+"\")}


	if ((Test-Path ($ScriptRoot+"\Microsoft.RDInfra.RDAgent.msi")) -eq $false) {
		LogWriter("Downloading RDAgent")
		Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv" -OutFile ($LocalConfig+"\Microsoft.RDInfra.RDAgent.msi")
	} else {Copy-Item "${PSScriptRoot}\Microsoft.RDInfra.RDAgent.msi" -Destination ($LocalConfig+"\")}
	if ((Test-Path ($ScriptRoot+"\Microsoft.RDInfra.RDAgentBootLoader.msi ")) -eq $false) {
		LogWriter("Downloading RDBootloader")
		Invoke-WebRequest -Uri "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH" -OutFile ($LocalConfig+"\Microsoft.RDInfra.RDAgentBootLoader.msi")
	} else {Copy-Item "${PSScriptRoot}\Microsoft.RDInfra.RDAgentBootLoader.msi" -Destination ($LocalConfig+"\")}
}

if ($mode -eq "Generalize") {
	LogWriter("Removing existing Remote Desktop Agent Boot Loader")
	$app=Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Remote Desktop Agent Boot Loader"}
	if ($app -ne $null) {$app.uninstall()}
	LogWriter("Removing existing Remote Desktop Services Infrastructure Agent")
	$app=Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Remote Desktop Services Infrastructure Agent"}
	if ($app -ne $null) {$app.uninstall()}
	Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\RDMonitoringAgent" -Force -ErrorAction Ignore

	LogWriter("Disabling ITPC-LogAnalyticAgent and MySmartScale if exist") 
	Disable-ScheduledTask  -TaskName "ITPC-LogAnalyticAgent for RDS and Citrix" -ErrorAction Ignore
	Disable-ScheduledTask  -TaskName "ITPC-MySmartScaleAgent" -ErrorAction Ignore
	
	LogWriter("Cleaning up reliability messages")
	$key="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reliability"
	Remove-ItemProperty -Path $key -Name "DirtyShutdown" -ErrorAction Ignore
	Remove-ItemProperty -Path $key -Name "DirtyShutdownTime" -ErrorAction Ignore
	Remove-ItemProperty -Path $key -Name "LastAliveStamp" -ErrorAction Ignore
	Remove-ItemProperty -Path $key -Name "TimeStampInterval" -ErrorAction Ignore

	LogWriter("Modifying sysprep to avoid issues with AppXPackages - Start")
	$sysPrepActionPath="$env:windir\System32\Sysprep\ActionFiles"
	$sysPrepActionFile="Generalize.xml"
	$sysPrepActionPathItem = Get-Item $sysPrepActionPath.Replace("C:\","\\localhost\\c$\") -ErrorAction Ignore
	$acl = $sysPrepActionPathItem.GetAccessControl()
	$acl.SetOwner((New-Object System.Security.Principal.NTAccount("SYSTEM")))
	$sysPrepActionPathItem.SetAccessControl($acl)
	$aclSystemFull = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","Allow")
	$acl.AddAccessRule($aclSystemFull)
	$sysPrepActionPathItem.SetAccessControl($acl)
	[xml]$xml = Get-Content -Path "$sysPrepActionPath\$sysPrepActionFile"
	$xmlNode=$xml.sysprepInformation.imaging | where {$_.sysprepModule.moduleName -match "AppxSysprep.dll"}
	if ($xmlNode -ne $null) {
		$xmlNode.ParentNode.RemoveChild($xmlNode)
		$xml.sysprepInformation.imaging.Count
		$xml.Save("$sysPrepActionPath\$sysPrepActionFile.new")
		Remove-Item "$sysPrepActionPath\$sysPrepActionFile.old" -Force -ErrorAction Ignore
		Move-Item "$sysPrepActionPath\$sysPrepActionFile" "$sysPrepActionPath\$sysPrepActionFile.old"
		Move-Item "$sysPrepActionPath\$sysPrepActionFile.new" "$sysPrepActionPath\$sysPrepActionFile"
		LogWriter("Modifying sysprep to avoid issues with AppXPackages - Done")
	}

	LogWriter("Removing an older Sysprep state")
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\Sysprep" -Name "SysprepCorrupt" -ErrorAction Ignore
	New-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -Name "State" -Value 2 -force
	New-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -Name "GeneralizationState" -Value 7 -force

	LogWriter("Saving time zone info for re-deploy")
	$timeZone=(Get-TimeZone).Id
	LogWriter("Current time zone is: "+$timeZone)
	New-Item -Path "HKLM:\SOFTWARE" -Name "ITProCloud" -ErrorAction Ignore
	New-Item -Path "HKLM:\SOFTWARE\ITProCloud" -Name "WVD.Runtime" -ErrorAction Ignore
	New-ItemProperty -Path "HKLM:\SOFTWARE\ITProCloud\WVD.Runtime" -Name "TimeZone.Origin" -Value $timeZone -force
	
	LogWriter("Removing existing Azure Monitoring Certificates")
	Get-ChildItem "Cert:\LocalMachine\Microsoft Monitoring Agent" -ErrorAction Ignore | Remove-Item

	if ([System.IO.File]::Exists("C:\ProgramData\Optimize\Win10_VirtualDesktop_Optimize.ps1")) {
		LogWriter("Running VDI Optimization script")
		Start-Process -wait -FilePath PowerShell.exe -WorkingDirectory "C:\ProgramData\Optimize" -ArgumentList '-ExecutionPolicy Bypass -File "C:\ProgramData\Optimize\Win10_VirtualDesktop_Optimize.ps1" -WindowsVersion 2004 -Verbose -WindowsMediaPlayer -AppxPackages -DefaultUserSettings -Autologgers -ScheduledTasks -Services -NetworkOptimizations -LGPO' -RedirectStandardOutput "$($LogDir)\VirtualDesktop_Optimize.Stage1.Out.txt" -RedirectStandardError "$($LogDir)\VirtualDesktop_Optimize.Stage1.Warning.txt"
	}

	LogWriter("Starting sysprep to generalize session host")
	if ([System.Environment]::OSVersion.Version.Major -le 6) {
		#Windows 7
		LogWriter("Enabling RDP8 on Windows 7")
		New-Item -Path "HKLM:\SOFTWARE" -Name "Policies" -ErrorAction Ignore
		New-Item -Path "HKLM:\SOFTWARE\Policies" -Name "Microsoft" -ErrorAction Ignore
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Windows NT" -ErrorAction Ignore
		New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT" -Name "Terminal Services" -ErrorAction Ignore
		New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fServerEnableRDP8" -Value 1 -force
		Start-Process -FilePath "$env:windir\System32\Sysprep\sysprep" -ArgumentList "/generalize /oobe /shutdown"
	} else {
		Start-Process -FilePath "$env:windir\System32\Sysprep\sysprep" -ArgumentList "/generalize /oobe /shutdown /mode:vm"
	}

} elseif ($mode -eq "JoinDomain")
{
	# Checking for a saved time zone information
	if (Test-Path -Path "HKLM:\SOFTWARE\ITProCloud\WVD.Runtime") {
		$timeZone=(Get-ItemProperty -Path "HKLM:\SOFTWARE\ITProCloud\WVD.Runtime" -ErrorAction Ignore)."TimeZone.Origin"
		if ($timeZone -ne "" -and $timeZone -ne $null) {
			LogWriter("Setting time zone to: "+$timeZone)
			Set-TimeZone -Id $timeZone
		}
	}
		
	LogWriter("Joining domain")
	$psc = New-Object System.Management.Automation.PSCredential($DomainJoinUserName, (ConvertTo-SecureString $DomainJoinUserPassword -AsPlainText -Force))
	if ($DomainJoinOU -eq "")
	{
		Add-Computer -DomainName $DomainFqdn -Credential $psc -Force
	} 
	else
	{
		Add-Computer -DomainName $DomainFqdn -OUPath $DomainJoinOU -Credential $psc -Force
	}


	if ([System.Environment]::OSVersion.Version.Major -gt 6) {
		LogWriter("Installing WVD boot loader - current path is ${PSScriptRoot}")
		Start-Process -wait -FilePath "${PSScriptRoot}\Microsoft.RDInfra.RDAgentBootLoader.msi" -ArgumentList "/q"
		LogWriter("Installing WVD agent")
		Start-Process -wait -FilePath "${PSScriptRoot}\Microsoft.RDInfra.RDAgent.msi" -ArgumentList "/q RegistrationToken=${WvdRegistrationKey}"
	} else {
        if ((Test-Path "${PSScriptRoot}\Microsoft.RDInfra.WVDAgent.msi") -eq $false) {
            LogWriter("Downloading Microsoft.RDInfra.WVDAgent.msi")
            Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE3JZCm' -OutFile "${PSScriptRoot}\Microsoft.RDInfra.WVDAgent.msi"
        }
        if ((Test-Path "${PSScriptRoot}\Microsoft.RDInfra.WVDAgentManager.msi") -eq $false) {
            LogWriter("Downloading Microsoft.RDInfra.WVDAgentManager.msi")
            Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE3K2e3' -OutFile "${PSScriptRoot}\Microsoft.RDInfra.WVDAgentManager.msi"
        }
		LogWriter("Installing WVDAgent")
        Start-Process -wait -FilePath "${PSScriptRoot}\Microsoft.RDInfra.WVDAgent.msi" -ArgumentList "/q RegistrationToken=${WvdRegistrationKey}"
        LogWriter("Installing WVDAgentManager")
		Start-Process -wait -FilePath "${PSScriptRoot}\Microsoft.RDInfra.WVDAgentManager.msi" -ArgumentList '/q'
	}


	LogWriter("Enabling ITPC-LogAnalyticAgent and MySmartScale if exist") 
	Enable-ScheduledTask  -TaskName "ITPC-LogAnalyticAgent for RDS and Citrix" -ErrorAction Ignore
	Enable-ScheduledTask  -TaskName "ITPC-MySmartScaleAgent" -ErrorAction Ignore

	if ([System.IO.File]::Exists("C:\ProgramData\Optimize\Win10_VirtualDesktop_Optimize.ps1")) {
		LogWriter("Running VDI Optimization script")
		Start-Process -wait -FilePath PowerShell.exe -WorkingDirectory "C:\ProgramData\Optimize" -ArgumentList '-ExecutionPolicy Bypass -File "C:\ProgramData\Optimize\Win10_VirtualDesktop_Optimize.ps1" -WindowsVersion 2004 -Verbose -WindowsMediaPlayer -AppxPackages -DefaultUserSettings -Autologgers -ScheduledTasks -Services -NetworkOptimizations -LGPO' -RedirectStandardOutput "$($LogDir)\VirtualDesktop_Optimize.Stage2.Out.txt" -RedirectStandardError "$($LogDir)\VirtualDesktop_Optimize.Stage2.Warning.txt"
	}


	LogWriter("Finally restarting session host")

	# final reboot
	Restart-Computer -Force
}

# SIG # Begin signature block
# MIIZZAYJKoZIhvcNAQcCoIIZVTCCGVECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULrbH6xFyypMJLprb06RbLXSh
# LzagghSCMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBRMwggP7
# oAMCAQICEALOSlLbW5psqB5bksPrt4UwDQYJKoZIhvcNAQELBQAwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTAeFw0yMDEyMDQwMDAwMDBaFw0yNDAxMTgyMzU5NTlaMFAxCzAJ
# BgNVBAYTAkRFMREwDwYDVQQHEwhPZGVudGhhbDEWMBQGA1UEChMNTWFyY2VsIE1l
# dXJlcjEWMBQGA1UEAxMNTWFyY2VsIE1ldXJlcjCCASIwDQYJKoZIhvcNAQEBBQAD
# ggEPADCCAQoCggEBANgyb1YA1wESEMVcrhrxWQ4FrBJxG2BXA8DqwT3ce743bss1
# tmBzIeQJXptNlTk+3p8f6Y80uE+fcRsgyFW/DX2quB90UaW/zOoCFzUeNKw19IM8
# fWSlwf9jPWwONKf8OQdh1SXlhKFPf9QLiTjz2M5Yzu3wYQtp8P1mqsF/44W8ql8u
# usZRa7IxndTwS57MkmkkPrl5xGECS4PBVZ7/9LHAxRrdhKfXFhkBdZDj6Ed1ZVmv
# eYmg5F+oGGa7+TBKg3SxaFtFgZmkeUKmtErIXkSJ7HIo+yY0rVfLTr9+Uggd7Bh+
# 19Qwzd5xV+G2t4QGfrVuNaZkyF+GZhwwX8EUje0CAwEAAaOCAcUwggHBMB8GA1Ud
# IwQYMBaAFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBShTLm22BZdBQEj
# gb5inoC9qcK6PzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMw
# dwYDVR0fBHAwbjA1oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTIt
# YXNzdXJlZC1jcy1nMS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNv
# bS9zaGEyLWFzc3VyZWQtY3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMB
# MCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYG
# Z4EMAQQBMIGEBggrBgEFBQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3Nw
# LmRpZ2ljZXJ0LmNvbTBOBggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwG
# A1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggEBACFBFC1FgkKrx4YnCx7DzNeg
# kW4Vo9knajjDx45Dg2PzCyA1dYLmTvtO9ToLk/eAxZZnTiNzGCBCBFv+/V03/dAl
# 5hF5YLJyp0pL9xYHAmbigBhR4IPL0qfnVpTLYSOF0uJENSNNooBGJ804n9x80n3z
# g8+sYt0Mxg7KUoETOLRFXo+8S8isrP6/02YIF43OkRWX66KtA/HO5VHfnMD7h6Oe
# 2FV2SlktrCWmbmtOQtjZjufuFqzI23pbQa4YfFXbMeNARoohP1uf0lkshSCvg8PW
# /cyHg2YEufLiZhdQuV68Av11/aQgc/dQ28/gn5Ezwb9098AbJ5KCXzQkgdlh4Pcw
# ggUwMIIEGKADAgECAhAECRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9v
# dCBDQTAeFw0xMzEwMjIxMjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNp
# Z25pbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4R
# r2d3B9MLMUkZz9D7RZmxOttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrw
# nIal2CWsDnkoOn7p0WfTxvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnC
# wlLyFGeKiUXULaGj6YgsIJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8
# y5Kh5TsxHM/q8grkV7tKtel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM
# 0SAlI+sIZD5SlsHyDxL0xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6f
# pjOp/RnfJZPRAgMBAAGjggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1Ud
# DwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGsw
# JAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcw
# AoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElE
# Um9vdENBLmNydDCBgQYDVR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNl
# cnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDov
# L2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBP
# BgNVHSAESDBGMDgGCmCGSAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93
# d3cuZGlnaWNlcnQuY29tL0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoK
# o6XqcQPAYPkt9mV1DlgwHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8w
# DQYJKoZIhvcNAQELBQADggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+
# C2D9wz0PxK+L/e8q3yBVN7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119E
# efM2FAaK95xGTlz/kLEbBw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR
# 4pwUR6F6aGivm6dcIFzZcbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4v
# cn4c10lFluhZHen6dGRrsutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwH
# gfqL2vmCSfdibqFT+hKUGIUukpHqaGxEMrJmoecYpJpkUe8wggUxMIIEGaADAgEC
# AhAKoSXW1jIbfkHkBdo2l8IVMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xNjAx
# MDcxMjAwMDBaFw0zMTAxMDcxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC90DLuS82Pf92puoKZxTlUKFe2
# I0rEDgdFM1EQfdD5fU1ofue2oPSNs4jkl79jIZCYvxO8V9PD4X4I1moUADj3Lh47
# 7sym9jJZ/l9lP+Cb6+NGRwYaVX4LJ37AovWg4N4iPw7/fpX786O6Ij4YrBHk8JkD
# bTuFfAnT7l3ImgtU46gJcWvgzyIQD3XPcXJOCq3fQDpct1HhoXkUxk0kIzBdvOw8
# YGqsLwfM/fDqR9mIUF79Zm5WYScpiYRR5oLnRlD9lCosp+R1PrqYD4R/nzEU1q3V
# 8mTLex4F0IQZchfxFwbvPc3WTe8GQv2iUypPhR3EHTyvz9qsEPXdrKzpVv+TAgMB
# AAGjggHOMIIByjAdBgNVHQ4EFgQU9LbhIB3+Ka7S5GGlsqIlssgXNW4wHwYDVR0j
# BBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wEgYDVR0TAQH/BAgwBgEB/wIBADAO
# BgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwgweQYIKwYBBQUHAQEE
# bTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYB
# BQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3Vy
# ZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cmwwUAYDVR0gBEkwRzA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBz
# Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCwYJYIZIAYb9bAcBMA0GCSqGSIb3DQEB
# CwUAA4IBAQBxlRLpUYdWac3v3dp8qmN6s3jPBjdAhO9LhL/KzwMC/cWnww4gQiyv
# d/MrHwwhWiq3BTQdaq6Z+CeiZr8JqmDfdqQ6kw/4stHYfBli6F6CJR7Euhx7LCHi
# 1lssFDVDBGiy23UC4HLHmNY8ZOUfSBAYX4k4YU1iRiSHY4yRUiyvKYnleB/WCxSl
# gNcSR3CzddWThZN+tpJn+1Nhiaj1a5bA9FhpDXzIAbG5KHW3mWOFIoxhynmUfln8
# jA/jb7UBJrZspe6HUSHkWGCbugwtK22ixH67xCUrRwIIfEmuE7bhfEJCKMYYVs9B
# NLZmXbZ0e/VWMyIvIjayS6JKldj1po5SMYIETDCCBEgCAQEwgYYwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQQIQAs5KUttbmmyoHluSw+u3hTAJBgUrDgMCGgUAoHgwGAYKKwYB
# BAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAc
# BgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUZj7O
# TfHumVZ6QGsJixlV4eDkI70wDQYJKoZIhvcNAQEBBQAEggEAilG6+UjCpM6N9CiB
# VHzx/MY/4yxdAqaKqV0DabxO01sODvA5DbqpfrWfrDSgj3UZy9H+eJpUe5FGFar0
# 8VheGT0+tyEXh7pmQ2g/mGUctudUJMz6+fuEsARIekBq8+WmQSYI+l5W2xrvi8X8
# u+Kv7g7jEiNwZ2y65wks3xILgXnvDaY6hkPjsmPQhZmjqFAUyFeV3z2xoJegnu8L
# KOPG2Mepr20f9l7cxRqTjPjLpBgHZi8one/oE1XwmvQ/lxSLcl38gcITBAa9l1vu
# huymhmCbMiD2Uw4TYKbmRF7mnxL+jtsVLzkHXcfwpTj6s2BlQn4cABk8TE7g1LmJ
# jARgGKGCAiAwggIcBgkqhkiG9w0BCQYxggINMIICCQIBATCBhjByMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0
# YW1waW5nIENBAhANQkrgvjqI/2BAIc4UAPDdMAkGBSsOAwIaBQCgXTAYBgkqhkiG
# 9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMTAyMTcxMzU0MDBa
# MCMGCSqGSIb3DQEJBDEWBBTk/gxmI+T8DwyqAcWGvC4YBYz0BDANBgkqhkiG9w0B
# AQEFAASCAQAZYAhuoQlM+RF2FRo4Ty0KE+fppbQYvwUlLT0Ivzo6qUjlgf8JHgpF
# IOqPGLoLp1QeIukKlsAqyElkbySTweHOPqcGmWupuAYPINKh5PFhI9MJWShowGMz
# 2DAZ2IynIp+TGsmE3DAme32QtrQyVjdtr/3MJT4RSfWcYHFO72UIfCtySbUSPFiA
# fAfzctGsWOoPwo7gpHf7aXnDSaUqwu9lGFh4SG9zLK+i5Pm/vpcesUO02WlD2PmI
# M3dxEsADLZGMSu46HJukG+/vqXrg16CqHZWcEiloeYhFt1Rd28MVx7/doU8FZtqO
# XRDDTFtpP8cDBlTyAoU6WgGyvqD0aQ5h
# SIG # End signature block