# System Hardening Tool - Windows PowerShell Version
# Windows Security Hardening and Configuration
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

param(
    [switch]$Help,
    [switch]$Status,
    [switch]$Backup,
    [switch]$FullHarden
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Configuration
$ConfigDir = "$env:USERPROFILE\.system_hardening"
$BackupDir = "$ConfigDir\backups"
$LogFile = "$ConfigDir\hardening.log"

# Create directories
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

# Logging function
function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logEntry
}

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host " ██╗  ██╗ █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗" -ForegroundColor Cyan
    Write-Host " ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║" -ForegroundColor Cyan
    Write-Host " ███████║███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║" -ForegroundColor Cyan
    Write-Host " ██╔══██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║" -ForegroundColor Cyan
    Write-Host " ██║  ██║██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗" -ForegroundColor Cyan
    Write-Host " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║" -ForegroundColor Cyan
    Write-Host "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║" -ForegroundColor Cyan
    Write-Host " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    System Hardening Tool - Windows PowerShell" -ForegroundColor Green
    Write-Host "    Windows Security Hardening and Configuration" -ForegroundColor Green
    Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
    Write-Host ""
}

# Create backup
function New-SystemBackup {
    Write-Log "Creating system configuration backup..." "Yellow"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$BackupDir\system_backup_$timestamp"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    try {
        # Backup registry keys
        Write-Log "Backing up registry settings..." "Cyan"
        
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System",
            "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        )
        
        foreach ($path in $registryPaths) {
            if (Test-Path $path) {
                $fileName = ($path -replace "HKLM:\\", "" -replace "\\", "_") + ".reg"
                reg export $path "$backupPath\$fileName" /y | Out-Null
            }
        }
        
        # Backup Windows Firewall settings
        netsh advfirewall export "$backupPath\firewall_settings.wfw" | Out-Null
        
        # Backup services
        Get-Service | Export-Csv "$backupPath\services.csv" -NoTypeInformation
        
        # Backup audit policies
        auditpol /backup /file:"$backupPath\audit_policy.csv" | Out-Null
        
        # Create backup info
        @{
            Timestamp = Get-Date
            ComputerName = $env:COMPUTERNAME
            WindowsVersion = [System.Environment]::OSVersion.VersionString
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        } | ConvertTo-Json | Out-File "$backupPath\backup_info.json"
        
        Write-Log "Backup created: $backupPath" "Green"
        return $backupPath
    }
    catch {
        Write-Log "Failed to create backup: $($_.Exception.Message)" "Red"
        return $null
    }
}

# Harden Windows Firewall
function Set-WindowsFirewallHardening {
    Write-Log "Hardening Windows Firewall..." "Yellow"
    
    try {
        # Enable firewall for all profiles
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Write-Log "Firewall enabled for all profiles" "Green"
        
        # Set default actions
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
        Write-Log "Default firewall actions configured" "Green"
        
        # Enable logging
        Set-NetFirewallProfile -Profile Domain,Public,Private -LogAllowed True -LogBlocked True
        Write-Log "Firewall logging enabled" "Green"
        
        # Block common attack ports
        $dangerousPorts = @(135, 137, 138, 139, 445, 1433, 1434, 3389)
        foreach ($port in $dangerousPorts) {
            New-NetFirewallRule -DisplayName "Block_Port_$port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction SilentlyContinue
        }
        Write-Log "Dangerous ports blocked" "Green"
        
    }
    catch {
        Write-Log "Failed to configure firewall: $($_.Exception.Message)" "Red"
    }
}

# Disable unnecessary services
function Disable-UnnecessaryServices {
    Write-Log "Disabling unnecessary services..." "Yellow"
    
    $servicesToDisable = @(
        "Telnet",
        "RemoteRegistry",
        "RemoteAccess",
        "Routing",
        "IISAdmin",
        "MSFTPSVC",
        "W3SVC",
        "SMTPSVC",
        "SNMP",
        "Browser",
        "Messenger",
        "NetDDE",
        "NetDDEdsdm",
        "NtLmSsp",
        "RasAuto",
        "RasMan",
        "seclogon",
        "TlntSvr",
        "UPS"
    )
    
    foreach ($service in $servicesToDisable) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq "Running") {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Log "Disabled service: $service" "Green"
            }
        }
        catch {
            # Service doesn't exist, continue
        }
    }
}

# Configure registry security settings
function Set-RegistryHardening {
    Write-Log "Configuring registry security settings..." "Yellow"
    
    try {
        # Disable SMBv1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "SMBv1 disabled" "Green"
        
        # Enable DEP
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoDataExecutionPrevention" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "Data Execution Prevention enabled" "Green"
        
        # Disable AutoRun
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "AutoRun disabled" "Green"
        
        # Enable UAC
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "UAC configured" "Green"
        
        # Disable Remote Desktop
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "Remote Desktop disabled" "Green"
        
        # Configure password policy
        net accounts /minpwlen:12 /maxpwage:90 /minpwage:1 /uniquepw:5 | Out-Null
        Write-Log "Password policy configured" "Green"
        
    }
    catch {
        Write-Log "Failed to configure registry settings: $($_.Exception.Message)" "Red"
    }
}

# Configure Windows Updates
function Set-WindowsUpdateHardening {
    Write-Log "Configuring Windows Update settings..." "Yellow"
    
    try {
        # Enable automatic updates
        $updatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (!(Test-Path $updatePath)) {
            New-Item -Path $updatePath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $updatePath -Name "NoAutoUpdate" -Value 0 -Type DWord
        Set-ItemProperty -Path $updatePath -Name "AUOptions" -Value 4 -Type DWord
        Set-ItemProperty -Path $updatePath -Name "ScheduledInstallDay" -Value 0 -Type DWord
        Set-ItemProperty -Path $updatePath -Name "ScheduledInstallTime" -Value 3 -Type DWord
        
        Write-Log "Windows Updates configured for automatic installation" "Green"
    }
    catch {
        Write-Log "Failed to configure Windows Updates: $($_.Exception.Message)" "Red"
    }
}

# Enable audit policies
function Set-AuditPolicies {
    Write-Log "Configuring audit policies..." "Yellow"
    
    try {
        # Enable audit policies
        auditpol /set /category:"Account Logon" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Account Management" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Object Access" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Policy Change" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"Privilege Use" /success:enable /failure:enable | Out-Null
        auditpol /set /category:"System" /success:enable /failure:enable | Out-Null
        
        Write-Log "Audit policies configured" "Green"
    }
    catch {
        Write-Log "Failed to configure audit policies: $($_.Exception.Message)" "Red"
    }
}

# Configure network security
function Set-NetworkHardening {
    Write-Log "Configuring network security settings..." "Yellow"
    
    try {
        # Disable NetBIOS over TCP/IP
        $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($adapter in $adapters) {
            $adapter.SetTcpipNetbios(2) | Out-Null
        }
        Write-Log "NetBIOS over TCP/IP disabled" "Green"
        
        # Disable LLMNR
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "LLMNR disabled" "Green"
        
        # Configure TCP/IP security
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "SynAttackProtect" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "EnableICMPRedirect" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        Write-Log "TCP/IP security configured" "Green"
        
    }
    catch {
        Write-Log "Failed to configure network security: $($_.Exception.Message)" "Red"
    }
}

# Show security status
function Show-SecurityStatus {
    Write-Host "Windows Security Status:" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    
    # Firewall status
    Write-Host "`nFirewall Status:" -ForegroundColor Yellow
    $firewallProfiles = Get-NetFirewallProfile
    foreach ($profile in $firewallProfiles) {
        $status = if ($profile.Enabled) { "ENABLED" } else { "DISABLED" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "  $($profile.Name): $status" -ForegroundColor $color
    }
    
    # Windows Updates
    Write-Host "`nWindows Updates:" -ForegroundColor Yellow
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $updates = $updateSearcher.Search("IsInstalled=0")
        Write-Host "  Pending Updates: $($updates.Updates.Count)" -ForegroundColor White
    }
    catch {
        Write-Host "  Status: Unable to check" -ForegroundColor Gray
    }
    
    # UAC Status
    Write-Host "`nUser Account Control:" -ForegroundColor Yellow
    $uacEnabled = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue).EnableLUA
    $uacStatus = if ($uacEnabled -eq 1) { "ENABLED" } else { "DISABLED" }
    $uacColor = if ($uacEnabled -eq 1) { "Green" } else { "Red" }
    Write-Host "  UAC: $uacStatus" -ForegroundColor $uacColor
    
    # Remote Desktop
    Write-Host "`nRemote Desktop:" -ForegroundColor Yellow
    $rdpDisabled = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -ErrorAction SilentlyContinue).fDenyTSConnections
    $rdpStatus = if ($rdpDisabled -eq 1) { "DISABLED" } else { "ENABLED" }
    $rdpColor = if ($rdpDisabled -eq 1) { "Green" } else { "Yellow" }
    Write-Host "  RDP: $rdpStatus" -ForegroundColor $rdpColor
    
    # Services status
    Write-Host "`nCritical Services:" -ForegroundColor Yellow
    $criticalServices = @("Windows Defender Antivirus Service", "Windows Security Service", "Windows Update")
    foreach ($serviceName in $criticalServices) {
        $service = Get-Service -DisplayName "*$serviceName*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($service) {
            $color = if ($service.Status -eq "Running") { "Green" } else { "Red" }
            Write-Host "  $($service.DisplayName): $($service.Status)" -ForegroundColor $color
        }
    }
}

# Show menu
function Show-Menu {
    Write-Host "`nSystem Hardening Menu:" -ForegroundColor Green
    Write-Host "======================" -ForegroundColor Green
    Write-Host "[1] Show security status" -ForegroundColor White
    Write-Host "[2] Full system hardening" -ForegroundColor White
    Write-Host "[3] Harden Windows Firewall" -ForegroundColor White
    Write-Host "[4] Configure registry security" -ForegroundColor White
    Write-Host "[5] Disable unnecessary services" -ForegroundColor White
    Write-Host "[6] Configure audit policies" -ForegroundColor White
    Write-Host "[7] Configure network security" -ForegroundColor White
    Write-Host "[8] Create system backup" -ForegroundColor White
    Write-Host "[0] Exit" -ForegroundColor White
    Write-Host ""
}

# Full hardening
function Start-FullHardening {
    Write-Log "Starting full system hardening..." "Yellow"
    Write-Host "WARNING: This will modify many system settings!" -ForegroundColor Red
    $confirm = Read-Host "Continue? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        $backupPath = New-SystemBackup
        if ($backupPath) {
            Set-WindowsFirewallHardening
            Set-RegistryHardening
            Disable-UnnecessaryServices
            Set-WindowsUpdateHardening
            Set-AuditPolicies
            Set-NetworkHardening
            
            Write-Log "Full system hardening completed!" "Green"
            Write-Log "Backup created at: $backupPath" "Cyan"
            Write-Log "Reboot recommended to apply all changes" "Yellow"
        }
    }
}

# Help function
function Show-Help {
    Write-Host @"
System Hardening Tool - Windows PowerShell

SYNOPSIS
    Windows security hardening and configuration tool

DESCRIPTION
    This tool helps harden Windows systems by configuring:
    - Windows Firewall settings
    - Registry security settings
    - Service configurations
    - Audit policies
    - Network security settings

PARAMETERS
    -Help         Show this help message
    -Status       Show current security status
    -Backup       Create backup of current settings
    -FullHarden   Perform complete system hardening

EXAMPLES
    .\system_hardening.ps1
    .\system_hardening.ps1 -Status
    .\system_hardening.ps1 -FullHarden

REQUIREMENTS
    - Windows 10/11 or Windows Server
    - Administrator privileges
    - PowerShell 5.0 or later

SECURITY FEATURES
    - Windows Firewall hardening
    - Registry security configuration
    - Unnecessary service disabling
    - Audit policy configuration
    - Network security hardening
    - Automatic backup creation

NOTES
    - Creates automatic backups before changes
    - Supports Windows 10/11 and Server versions
    - Use only for legitimate purposes
    - Test in non-production environment first

"@
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Show-Banner

if ($Status) {
    Show-SecurityStatus
    exit 0
}

if ($Backup) {
    New-SystemBackup
    exit 0
}

if ($FullHarden) {
    Start-FullHardening
    exit 0
}

# Main interactive loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (0-8)"
    
    switch ($choice) {
        "1" {
            Show-SecurityStatus
            Read-Host "Press Enter to continue"
        }
        "2" {
            Start-FullHardening
            Read-Host "Press Enter to continue"
        }
        "3" {
            $confirm = Read-Host "Harden Windows Firewall? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                New-SystemBackup
                Set-WindowsFirewallHardening
            }
            Read-Host "Press Enter to continue"
        }
        "4" {
            $confirm = Read-Host "Configure registry security? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                New-SystemBackup
                Set-RegistryHardening
            }
            Read-Host "Press Enter to continue"
        }
        "5" {
            $confirm = Read-Host "Disable unnecessary services? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                New-SystemBackup
                Disable-UnnecessaryServices
            }
            Read-Host "Press Enter to continue"
        }
        "6" {
            $confirm = Read-Host "Configure audit policies? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Set-AuditPolicies
            }
            Read-Host "Press Enter to continue"
        }
        "7" {
            $confirm = Read-Host "Configure network security? (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                New-SystemBackup
                Set-NetworkHardening
            }
            Read-Host "Press Enter to continue"
        }
        "8" {
            New-SystemBackup
            Read-Host "Press Enter to continue"
        }
        "0" {
            Write-Log "Goodbye!" "Green"
            exit 0
        }
        default {
            Write-Log "Invalid choice!" "Red"
            Read-Host "Press Enter to continue"
        }
    }
}
