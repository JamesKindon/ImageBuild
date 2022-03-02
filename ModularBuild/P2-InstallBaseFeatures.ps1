Write-Host "===== Configure Roles and Features" -ForegroundColor "Green"

Function Set-Roles {
    Switch -Regex ((Get-WmiObject Win32_OperatingSystem).Caption) {
        "Microsoft Windows Server*" {
            # Add / Remove roles (requires reboot at end of deployment)
            Add-WindowsFeature -Name 'RDS-RD-Server', 'Server-Media-Foundation', 'Search-Service', 'NET-Framework-Core', 'Remote-Assistance'
        }
        "Microsoft Windows 10*" {
        }
        "Microsoft Windows 10 Enterprise for Virtual Desktops" {
        }
    }
}

Set-Roles

Set-Service Audiosrv -StartupType Automatic
Set-Service WSearch -StartupType Automatic