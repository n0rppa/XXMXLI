# MAC & IP Address Changer for Windows
# PowerShell Script for Network Identity Management
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

param(
    [string]$Action = "menu",
    [string]$Interface = "",
    [string]$NewMAC = "",
    [string]$NewIP = "",
    [string]$SubnetMask = "255.255.255.0",
    [string]$Gateway = ""
)

# Colors for output
$Color = @{
    Green = "Green"
    Red = "Red"
    Yellow = "Yellow"
    Cyan = "Cyan"
    White = "White"
}

function Write-Banner {
    Write-Host "
 ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
 ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
 ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
                                                  
    MAC & IP Address Changer for Windows
    Educational and Authorized Use Only
" -ForegroundColor $Color.Cyan
}

function Test-AdminRights {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-NetworkAdapters {
    Write-Host "📡 Available Network Adapters:" -ForegroundColor $Color.Green
    Write-Host "================================" -ForegroundColor $Color.Green
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -or $_.Status -eq "Disconnected" }
    
    $i = 1
    foreach ($adapter in $adapters) {
        $config = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        $ipAddress = if ($config.IPv4Address) { $config.IPv4Address.IPAddress } else { "No IP" }
        
        Write-Host "[$i] Name: $($adapter.Name)" -ForegroundColor $Color.White
        Write-Host "    Interface: $($adapter.InterfaceDescription)" -ForegroundColor $Color.Yellow
        Write-Host "    MAC: $($adapter.MacAddress)" -ForegroundColor $Color.Cyan
        Write-Host "    IP: $ipAddress" -ForegroundColor $Color.Cyan
        Write-Host "    Status: $($adapter.Status)" -ForegroundColor $Color.Yellow
        Write-Host ""
        $i++
    }
    
    return $adapters
}

function Generate-RandomMAC {
    $mac = @()
    # First octet should be even for unicast (02, 06, 0A, 0E, etc.)
    $mac += "{0:X2}" -f (Get-Random -Minimum 2 -Maximum 254 | ForEach-Object { $_ -band 0xFE -bor 0x02 })
    
    # Generate remaining 5 octets
    for ($i = 1; $i -lt 6; $i++) {
        $mac += "{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255)
    }
    
    return $mac -join "-"
}

function Generate-RandomIP {
    # Generate random private IP addresses
    $ranges = @(
        @{ Network = "192.168"; Start = 1; End = 254 },
        @{ Network = "10.0"; Start = 1; End = 254 },
        @{ Network = "172.16"; Start = 1; End = 254 }
    )
    
    $range = $ranges | Get-Random
    $third = Get-Random -Minimum 1 -Maximum 254
    $fourth = Get-Random -Minimum $range.Start -Maximum $range.End
    
    return "$($range.Network).$third.$fourth"
}

function Change-MACAddress {
    param(
        [string]$AdapterName,
        [string]$NewMAC
    )
    
    Write-Host "🔄 Changing MAC address for: $AdapterName" -ForegroundColor $Color.Yellow
    Write-Host "New MAC: $NewMAC" -ForegroundColor $Color.Cyan
    
    try {
        # Get the adapter
        $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction Stop
        
        # Disable the adapter
        Write-Host "📴 Disabling adapter..." -ForegroundColor $Color.Yellow
        Disable-NetAdapter -Name $AdapterName -Confirm:$false
        Start-Sleep -Seconds 2
        
        # Change MAC address in registry
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
        $subKeys = Get-ChildItem $regPath
        
        foreach ($subKey in $subKeys) {
            $driverDesc = Get-ItemProperty -Path $subKey.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue
            if ($driverDesc -and $driverDesc.DriverDesc -eq $adapter.InterfaceDescription) {
                Set-ItemProperty -Path $subKey.PSPath -Name "NetworkAddress" -Value ($NewMAC -replace "-", "")
                break
            }
        }
        
        # Enable the adapter
        Write-Host "📡 Enabling adapter..." -ForegroundColor $Color.Yellow
        Enable-NetAdapter -Name $AdapterName
        Start-Sleep -Seconds 3
        
        # Verify the change
        $updatedAdapter = Get-NetAdapter -Name $AdapterName
        Write-Host "✅ MAC address changed successfully!" -ForegroundColor $Color.Green
        Write-Host "New MAC: $($updatedAdapter.MacAddress)" -ForegroundColor $Color.Cyan
        
    } catch {
        Write-Host "❌ Error changing MAC address: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

function Change-IPAddress {
    param(
        [string]$AdapterName,
        [string]$NewIP,
        [string]$SubnetMask,
        [string]$Gateway
    )
    
    Write-Host "🔄 Changing IP address for: $AdapterName" -ForegroundColor $Color.Yellow
    Write-Host "New IP: $NewIP" -ForegroundColor $Color.Cyan
    Write-Host "Subnet: $SubnetMask" -ForegroundColor $Color.Cyan
    
    try {
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceAlias $AdapterName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $AdapterName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Calculate prefix length from subnet mask
        $prefixLength = switch ($SubnetMask) {
            "255.255.255.0" { 24 }
            "255.255.0.0" { 16 }
            "255.0.0.0" { 8 }
            "255.255.255.128" { 25 }
            "255.255.255.192" { 26 }
            default { 24 }
        }
        
        # Set new IP address
        New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $NewIP -PrefixLength $prefixLength -ErrorAction Stop
        
        # Set gateway if provided
        if ($Gateway) {
            Write-Host "Setting gateway: $Gateway" -ForegroundColor $Color.Cyan
            New-NetRoute -InterfaceAlias $AdapterName -DestinationPrefix "0.0.0.0/0" -NextHop $Gateway -ErrorAction SilentlyContinue
        }
        
        Write-Host "✅ IP address changed successfully!" -ForegroundColor $Color.Green
        
    } catch {
        Write-Host "❌ Error changing IP address: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

function Show-Menu {
    Write-Host "🎯 Select an option:" -ForegroundColor $Color.Green
    Write-Host "===================" -ForegroundColor $Color.Green
    Write-Host "[1] Show network adapters" -ForegroundColor $Color.White
    Write-Host "[2] Change MAC address" -ForegroundColor $Color.White
    Write-Host "[3] Change IP address" -ForegroundColor $Color.White
    Write-Host "[4] Generate random MAC" -ForegroundColor $Color.White
    Write-Host "[5] Generate random IP" -ForegroundColor $Color.White
    Write-Host "[6] Reset adapter to DHCP" -ForegroundColor $Color.White
    Write-Host "[7] Backup current configuration" -ForegroundColor $Color.White
    Write-Host "[8] Restore configuration" -ForegroundColor $Color.White
    Write-Host "[9] Exit" -ForegroundColor $Color.White
    Write-Host ""
}

function Backup-Configuration {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "network_backup_$timestamp.json"
    
    Write-Host "💾 Creating backup..." -ForegroundColor $Color.Yellow
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $backup = @()
    
    foreach ($adapter in $adapters) {
        $config = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        
        $adapterInfo = @{
            Name = $adapter.Name
            InterfaceDescription = $adapter.InterfaceDescription
            MacAddress = $adapter.MacAddress
            IPAddress = if ($config.IPv4Address) { $config.IPv4Address.IPAddress } else { $null }
            SubnetMask = if ($config.IPv4Address) { $config.IPv4Address.PrefixLength } else { $null }
            Gateway = if ($config.IPv4DefaultGateway) { $config.IPv4DefaultGateway.NextHop } else { $null }
            DHCPEnabled = $config.NetProfile.NetworkCategory -eq "DomainAuthenticated"
        }
        
        $backup += $adapterInfo
    }
    
    $backup | ConvertTo-Json -Depth 3 -Compress | Out-File -FilePath $backupFile -Encoding UTF8
    Write-Host "✅ Backup saved to: $backupFile" -ForegroundColor $Color.Green
}

function Reset-AdapterToDHCP {
    param([string]$AdapterName)
    
    Write-Host "🔄 Resetting $AdapterName to DHCP..." -ForegroundColor $Color.Yellow
    
    try {
        # Remove static IP configuration
        Remove-NetIPAddress -InterfaceAlias $AdapterName -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceAlias $AdapterName -Confirm:$false -ErrorAction SilentlyContinue
        
        # Enable DHCP
        Set-NetIPInterface -InterfaceAlias $AdapterName -Dhcp Enabled
        
        # Restart adapter
        Restart-NetAdapter -Name $AdapterName
        
        Write-Host "✅ Adapter reset to DHCP successfully!" -ForegroundColor $Color.Green
        
    } catch {
        Write-Host "❌ Error resetting adapter: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

# Main script execution
Write-Banner

# Check for administrator rights
if (-not (Test-AdminRights)) {
    Write-Host "❌ This script requires administrator privileges!" -ForegroundColor $Color.Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor $Color.Yellow
    exit 1
}

Write-Host "✅ Running with administrator privileges" -ForegroundColor $Color.Green
Write-Host ""

# Handle command line parameters
switch ($Action.ToLower()) {
    "menu" {
        do {
            Show-Menu
            $choice = Read-Host "Enter your choice (1-9)"
            
            switch ($choice) {
                "1" {
                    Get-NetworkAdapters
                    Read-Host "Press Enter to continue"
                }
                "2" {
                    $adapters = Get-NetworkAdapters
                    $adapterChoice = Read-Host "Select adapter number"
                    $selectedAdapter = $adapters[$adapterChoice - 1]
                    
                    if ($selectedAdapter) {
                        $newMAC = Read-Host "Enter new MAC address (XX-XX-XX-XX-XX-XX) or press Enter for random"
                        if (-not $newMAC) {
                            $newMAC = Generate-RandomMAC
                            Write-Host "Generated random MAC: $newMAC" -ForegroundColor $Color.Cyan
                        }
                        Change-MACAddress -AdapterName $selectedAdapter.Name -NewMAC $newMAC
                    }
                    Read-Host "Press Enter to continue"
                }
                "3" {
                    $adapters = Get-NetworkAdapters
                    $adapterChoice = Read-Host "Select adapter number"
                    $selectedAdapter = $adapters[$adapterChoice - 1]
                    
                    if ($selectedAdapter) {
                        $newIP = Read-Host "Enter new IP address or press Enter for random"
                        if (-not $newIP) {
                            $newIP = Generate-RandomIP
                            Write-Host "Generated random IP: $newIP" -ForegroundColor $Color.Cyan
                        }
                        $subnet = Read-Host "Enter subnet mask (default: 255.255.255.0)"
                        if (-not $subnet) { $subnet = "255.255.255.0" }
                        $gateway = Read-Host "Enter gateway (optional)"
                        
                        Change-IPAddress -AdapterName $selectedAdapter.Name -NewIP $newIP -SubnetMask $subnet -Gateway $gateway
                    }
                    Read-Host "Press Enter to continue"
                }
                "4" {
                    $randomMAC = Generate-RandomMAC
                    Write-Host "Random MAC: $randomMAC" -ForegroundColor $Color.Cyan
                    Read-Host "Press Enter to continue"
                }
                "5" {
                    $randomIP = Generate-RandomIP
                    Write-Host "Random IP: $randomIP" -ForegroundColor $Color.Cyan
                    Read-Host "Press Enter to continue"
                }
                "6" {
                    $adapters = Get-NetworkAdapters
                    $adapterChoice = Read-Host "Select adapter number to reset to DHCP"
                    $selectedAdapter = $adapters[$adapterChoice - 1]
                    
                    if ($selectedAdapter) {
                        Reset-AdapterToDHCP -AdapterName $selectedAdapter.Name
                    }
                    Read-Host "Press Enter to continue"
                }
                "7" {
                    Backup-Configuration
                    Read-Host "Press Enter to continue"
                }
                "8" {
                    $backupFile = Read-Host "Enter backup file name"
                    if (Test-Path $backupFile) {
                        Write-Host "🔄 Restoring configuration from $backupFile..." -ForegroundColor $Color.Yellow
                        # Restore logic would go here
                        Write-Host "⚠️ Restore functionality is a placeholder - implement as needed" -ForegroundColor $Color.Yellow
                    } else {
                        Write-Host "❌ Backup file not found!" -ForegroundColor $Color.Red
                    }
                    Read-Host "Press Enter to continue"
                }
                "9" {
                    Write-Host "👋 Goodbye!" -ForegroundColor $Color.Green
                    exit 0
                }
                default {
                    Write-Host "❌ Invalid choice!" -ForegroundColor $Color.Red
                    Read-Host "Press Enter to continue"
                }
            }
        } while ($true)
    }
    "changemac" {
        if ($Interface -and $NewMAC) {
            Change-MACAddress -AdapterName $Interface -NewMAC $NewMAC
        } else {
            Write-Host "❌ Missing parameters for MAC change" -ForegroundColor $Color.Red
            Write-Host "Usage: .\mac_ip_changer.ps1 -Action changemac -Interface 'Ethernet' -NewMAC 'XX-XX-XX-XX-XX-XX'" -ForegroundColor $Color.Yellow
        }
    }
    "changeip" {
        if ($Interface -and $NewIP) {
            Change-IPAddress -AdapterName $Interface -NewIP $NewIP -SubnetMask $SubnetMask -Gateway $Gateway
        } else {
            Write-Host "❌ Missing parameters for IP change" -ForegroundColor $Color.Red
            Write-Host "Usage: .\mac_ip_changer.ps1 -Action changeip -Interface 'Ethernet' -NewIP '192.168.1.100' -SubnetMask '255.255.255.0'" -ForegroundColor $Color.Yellow
        }
    }
    "genmac" {
        $randomMAC = Generate-RandomMAC
        Write-Host "Random MAC: $randomMAC" -ForegroundColor $Color.Cyan
    }
    "genip" {
        $randomIP = Generate-RandomIP
        Write-Host "Random IP: $randomIP" -ForegroundColor $Color.Cyan
    }
    default {
        Write-Host "❌ Invalid action!" -ForegroundColor $Color.Red
        Write-Host "Available actions: menu, changemac, changeip, genmac, genip" -ForegroundColor $Color.Yellow
    }
}

Write-Host ""
Write-Host "📋 Script completed. Remember to use these tools responsibly!" -ForegroundColor $Color.Green
