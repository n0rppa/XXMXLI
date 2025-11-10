# XXMXLI MAC and IP Address Changer - PowerShell
# This script provides advanced MAC address and IP configuration options

#Requires -Version 5.1

param(
    [switch]$Help,
    [switch]$Status,
    [ValidateSet("1", "2", "3", "4", "5", "6", "7")]
    [string]$Action
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "network_changes.log"

# Ensure we're running from the script directory
Set-Location $ScriptDir

# Help function
function Show-Help {
    [CmdletBinding()]
    param()
    
    Write-Host @"
XXMXLI MAC and IP Address Changer - PowerShell

SYNOPSIS
    Advanced MAC address and IP configuration tool

DESCRIPTION
    This script provides comprehensive network adapter configuration options
    including MAC address changes, IP configuration, and network management.

PARAMETERS
    -Help       Show this help message
    -Status     Show current network configuration
    -Action     Perform specific action (1-7):
                1 = View current network configuration
                2 = Show network adapters
                3 = Generate and apply random MAC address
                4 = Configure static IP address
                5 = Reset to DHCP
                6 = Enable/Disable network adapter
                7 = Clear DNS cache

EXAMPLES
    .\mac_ip_changer.ps1
    .\mac_ip_changer.ps1 -Status
    .\mac_ip_changer.ps1 -Action 3

REQUIREMENTS
    - Windows 10/11
    - Administrator privileges
    - PowerShell 5.0 or later

WARNING
    Changing MAC addresses may violate network policies
    Use only on networks you own or have permission to modify

"@
}

# Check if running as administrator
function Test-Administrator {
    [CmdletBinding()]
    param()
    
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Host "Failed to check administrator privileges: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
}

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI MAC and IP Address Changer - PowerShell" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Working directory: $ScriptDir" -ForegroundColor Yellow
Write-Host ""

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Running with administrator privileges" -ForegroundColor Green
Write-Host ""

function Show-Menu {
    [CmdletBinding()]
    param()
    
    Write-Host "MAC/IP Configuration Options:" -ForegroundColor Cyan
    Write-Host "  1. View current network configuration"
    Write-Host "  2. Show network adapters"
    Write-Host "  3. Generate and apply random MAC address"
    Write-Host "  4. Configure static IP address"
    Write-Host "  5. Reset to DHCP"
    Write-Host "  6. Enable/Disable network adapter"
    Write-Host "  7. Clear DNS cache"
    Write-Host "  8. Exit"
    Write-Host ""
}

function Get-NetworkConfiguration {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Current Network Configuration:" -ForegroundColor Cyan
        Write-Host "==============================" -ForegroundColor Cyan
        Get-NetIPConfiguration | Format-Table -AutoSize
        Write-Host ""
        Get-NetAdapter | Select-Object Name, InterfaceDescription, LinkSpeed, Status | Format-Table -AutoSize
    }
    catch {
        Write-Host "Failed to get network configuration: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-NetworkAdapters {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Network Adapters:" -ForegroundColor Cyan
        Write-Host "=================" -ForegroundColor Cyan
        $adapters = Get-NetAdapter | Select-Object Name, InterfaceIndex, MacAddress, Status, LinkSpeed
        $adapters | Format-Table -AutoSize
        return $adapters
    }
    catch {
        Write-Host "Failed to show network adapters: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Generate-RandomMAC {
    [CmdletBinding()]
    param()
    
    try {
        # Generate a random MAC address with valid first octet
        $mac = "02-{0:X2}-{1:X2}-{2:X2}-{3:X2}-{4:X2}" -f (Get-Random -Maximum 256), (Get-Random -Maximum 256), (Get-Random -Maximum 256), (Get-Random -Maximum 256), (Get-Random -Maximum 256)
        return $mac
    }
    catch {
        Write-Host "Failed to generate random MAC: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Set-RandomMAC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$AdapterName
    )
    
    try {
        $adapters = Show-NetworkAdapters
        
        if (-not $AdapterName) {
            $AdapterName = Read-Host "Enter adapter name"
        }
        
        if (-not $AdapterName) {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
        
        $adapter = $adapters | Where-Object { $_.Name -eq $AdapterName }
        if (-not $adapter) {
            Write-Host "Adapter not found" -ForegroundColor Red
            return
        }
        
        $newMAC = Generate-RandomMAC
        if (-not $newMAC) {
            Write-Host "Failed to generate MAC address" -ForegroundColor Red
            return
        }
        
        Write-Host "Generated MAC: $newMAC" -ForegroundColor Green
        
        $confirm = Read-Host "Apply this MAC address? (y/N)"
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            # Disable adapter
            Write-Host "Disabling adapter..." -ForegroundColor Yellow
            Disable-NetAdapter -Name $AdapterName -Confirm:$false
            
            # Change MAC address in registry
            $macClean = $newMAC -replace '-', ''
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
            $adapters = Get-ChildItem $regPath
            
            foreach ($adapterPath in $adapters) {
                $desc = Get-ItemProperty -Path $adapterPath.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue
                if ($desc -and $desc.DriverDesc -eq $adapter.InterfaceDescription) {
                    Set-ItemProperty -Path $adapterPath.PSPath -Name "NetworkAddress" -Value $macClean
                    Write-Host "MAC address updated in registry" -ForegroundColor Green
                    break
                }
            }
            
            # Re-enable adapter
            Write-Host "Re-enabling adapter..." -ForegroundColor Yellow
            Enable-NetAdapter -Name $AdapterName
            
            Write-Host "✓ MAC address changed successfully" -ForegroundColor Green
            Write-Host "New MAC: $newMAC" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "✗ Error changing MAC address: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-StaticIP {
    $adapters = Show-NetworkAdapters
    $adapterName = Read-Host "Enter adapter name"
    
    if (-not $adapterName) {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        return
    }
    
    $ip = Read-Host "Enter IP address (e.g., 192.168.1.100)"
    $prefix = Read-Host "Enter prefix length (e.g., 24 for /24)"
    $gateway = Read-Host "Enter gateway (e.g., 192.168.1.1)"
    $dns = Read-Host "Enter DNS server (e.g., 8.8.8.8)"
    
    try {
        Remove-NetIPAddress -InterfaceAlias $adapterName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $adapterName -Confirm:$false -ErrorAction SilentlyContinue
        
        New-NetIPAddress -InterfaceAlias $adapterName -IPAddress $ip -PrefixLength $prefix -DefaultGateway $gateway
        Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses $dns
        
        Write-Host "✓ Static IP configured successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error configuring static IP: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Reset-ToDHCP {
    $adapters = Show-NetworkAdapters
    $adapterName = Read-Host "Enter adapter name"
    
    if (-not $adapterName) {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        return
    }
    
    try {
        Remove-NetIPAddress -InterfaceAlias $adapterName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $adapterName -Confirm:$false -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses
        
        Write-Host "✓ DHCP configuration restored" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error resetting to DHCP: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Toggle-NetworkAdapter {
    $adapters = Show-NetworkAdapters
    $adapterName = Read-Host "Enter adapter name"
    
    if (-not $adapterName) {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        return
    }
    
    $adapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-Host "Adapter not found" -ForegroundColor Red
        return
    }
    
    if ($adapter.Status -eq "Up") {
        Disable-NetAdapter -Name $adapterName -Confirm:$false
        Write-Host "✓ Adapter disabled" -ForegroundColor Yellow
    } else {
        Enable-NetAdapter -Name $adapterName -Confirm:$false
        Write-Host "✓ Adapter enabled" -ForegroundColor Green
    }
}

function Clear-DNSCache {
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Clearing DNS cache..." -ForegroundColor Yellow
        Clear-DnsClientCache
        Write-Host "✓ DNS cache cleared" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to clear DNS cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI MAC and IP Address Changer - PowerShell" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Working directory: $ScriptDir" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Running with administrator privileges" -ForegroundColor Green
Write-Host ""

if ($Status) {
    Get-NetworkConfiguration
    exit 0
}

if ($Action) {
    try {
        switch ($Action) {
            "1" { Get-NetworkConfiguration }
            "2" { Show-NetworkAdapters }
            "3" { Set-RandomMAC }
            "4" { Set-StaticIP }
            "5" { Reset-ToDHCP }
            "6" { Toggle-NetworkAdapter }
            "7" { Clear-DNSCache }
        }
    }
    catch {
        Write-Host "Error executing action: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    
    # Log the action
    $LogEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Action = "Automated Action $Action"
        User = $env:USERNAME
        Computer = $env:COMPUTERNAME
    }
    
    $LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile -Encoding UTF8
    exit 0
}

# Interactive mode
do {
    Show-Menu
    $choice = Read-Host "Select option (1-8)"
    
    switch ($choice) {
        "1" { Get-NetworkConfiguration }
        "2" { Show-NetworkAdapters }
        "3" { Set-RandomMAC }
        "4" { Set-StaticIP }
        "5" { Reset-ToDHCP }
        "6" { Toggle-NetworkAdapter }
        "7" { Clear-DNSCache }
        "8" { 
            Write-Host "Thank you for using XXMXLI MAC/IP Changer" -ForegroundColor Blue
            break 
        }
        default { 
            Write-Host "Invalid choice. Please select 1-8." -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "8") {
        Write-Host ""
        Read-Host "Press Enter to continue"
        Clear-Host
    }
    
} while ($choice -ne "8")

# Log the session
$LogEntry = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Action = "MAC/IP Configuration Session"
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
}

$LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile -Encoding UTF8