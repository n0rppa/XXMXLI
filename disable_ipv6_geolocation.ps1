# IPv6 & Geolocation Disable Script for Windows
# PowerShell Script for Privacy and Network Configuration
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

param(
    [string]$Action = "menu",
    [switch]$IPv6Only = $false,
    [switch]$GeolocationOnly = $false,
    [switch]$EnableAll = $false,
    [switch]$Restore = $false
)

# Colors for output
$Color = @{
    Green = "Green"
    Red = "Red"
    Yellow = "Yellow"
    Cyan = "Cyan"
    White = "White"
    Magenta = "Magenta"
}

function Write-Banner {
    Write-Host "
 ██╗██████╗ ██╗   ██╗ ██████╗      ██████╗ ███████╗ ██████╗ 
 ██║██╔══██╗██║   ██║██╔════╝     ██╔════╝ ██╔════╝██╔═══██╗
 ██║██████╔╝██║   ██║███████╗     ██║  ███╗█████╗  ██║   ██║
 ██║██╔═══╝ ╚██╗ ██╔╝██╔═══██╗    ██║   ██║██╔══╝  ██║   ██║
 ██║██║      ╚████╔╝ ╚██████╔╝    ╚██████╔╝███████╗╚██████╔╝
 ╚═╝╚═╝       ╚═══╝   ╚═════╝      ╚═════╝ ╚══════╝ ╚═════╝ 
                                                            
    IPv6 & Geolocation Disable Tool for Windows
    Privacy Protection and Network Configuration
    Educational and Authorized Use Only
" -ForegroundColor $Color.Cyan
}

function Test-AdminRights {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Backup-CurrentSettings {
    Write-Host "💾 Creating backup of current settings..." -ForegroundColor $Color.Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = "network_privacy_backup_$timestamp.json"
    
    try {
        # Get current IPv6 status
        $ipv6Status = @{}
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $adapters) {
            $ipv6Binding = Get-NetAdapterBinding -Name $adapter.Name -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
            if ($ipv6Binding) {
                $ipv6Status[$adapter.Name] = $ipv6Binding.Enabled
            }
        }
        
        # Get current location service status
        $locationService = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        $locationServiceStatus = if ($locationService) { $locationService.Status } else { "NotFound" }
        
        # Get registry settings
        $registrySettings = @{
            DisabledComponents = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -ErrorAction SilentlyContinue).DisabledComponents
            LocationConsent = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -ErrorAction SilentlyContinue).Value
            SensorPermissionState = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -ErrorAction SilentlyContinue).SensorPermissionState
        }
        
        $backup = @{
            Timestamp = Get-Date
            IPv6Status = $ipv6Status
            LocationServiceStatus = $locationServiceStatus
            RegistrySettings = $registrySettings
        }
        
        $backup | ConvertTo-Json -Depth 3 | Out-File -FilePath $backupFile -Encoding UTF8
        Write-Host "✅ Backup saved to: $backupFile" -ForegroundColor $Color.Green
        return $backupFile
        
    } catch {
        Write-Host "❌ Error creating backup: $($_.Exception.Message)" -ForegroundColor $Color.Red
        return $null
    }
}

function Disable-IPv6 {
    Write-Host "🔄 Disabling IPv6..." -ForegroundColor $Color.Yellow
    
    try {
        # Method 1: Registry modification (most effective)
        Write-Host "📝 Updating registry to disable IPv6..." -ForegroundColor $Color.Cyan
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xffffffff -Type DWord -Force
        
        # Method 2: Disable IPv6 on all network adapters
        Write-Host "🔧 Disabling IPv6 on network adapters..." -ForegroundColor $Color.Cyan
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $adapters) {
            try {
                Disable-NetAdapterBinding -Name $adapter.Name -ComponentID "ms_tcpip6" -Confirm:$false
                Write-Host "  ✓ Disabled IPv6 on: $($adapter.Name)" -ForegroundColor $Color.Green
            } catch {
                Write-Host "  ⚠️ Could not disable IPv6 on: $($adapter.Name)" -ForegroundColor $Color.Yellow
            }
        }
        
        # Method 3: Disable IPv6 transition technologies
        Write-Host "🚫 Disabling IPv6 transition technologies..." -ForegroundColor $Color.Cyan
        netsh interface teredo set state disabled 2>$null
        netsh interface 6to4 set state disabled 2>$null
        netsh interface isatap set state disabled 2>$null
        
        Write-Host "✅ IPv6 disabled successfully!" -ForegroundColor $Color.Green
        Write-Host "⚠️  A system restart is recommended for full effect." -ForegroundColor $Color.Yellow
        
    } catch {
        Write-Host "❌ Error disabling IPv6: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

function Enable-IPv6 {
    Write-Host "🔄 Enabling IPv6..." -ForegroundColor $Color.Yellow
    
    try {
        # Restore registry setting
        Write-Host "📝 Updating registry to enable IPv6..." -ForegroundColor $Color.Cyan
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0x0 -Type DWord -Force
        
        # Enable IPv6 on all network adapters
        Write-Host "🔧 Enabling IPv6 on network adapters..." -ForegroundColor $Color.Cyan
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $adapters) {
            try {
                Enable-NetAdapterBinding -Name $adapter.Name -ComponentID "ms_tcpip6" -Confirm:$false
                Write-Host "  ✓ Enabled IPv6 on: $($adapter.Name)" -ForegroundColor $Color.Green
            } catch {
                Write-Host "  ⚠️ Could not enable IPv6 on: $($adapter.Name)" -ForegroundColor $Color.Yellow
            }
        }
        
        # Enable IPv6 transition technologies
        Write-Host "✅ Enabling IPv6 transition technologies..." -ForegroundColor $Color.Cyan
        netsh interface teredo set state default 2>$null
        netsh interface 6to4 set state default 2>$null
        netsh interface isatap set state default 2>$null
        
        Write-Host "✅ IPv6 enabled successfully!" -ForegroundColor $Color.Green
        Write-Host "⚠️  A system restart is recommended for full effect." -ForegroundColor $Color.Yellow
        
    } catch {
        Write-Host "❌ Error enabling IPv6: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

function Disable-GeolocationService {
    Write-Host "🔄 Disabling Windows Geolocation Service..." -ForegroundColor $Color.Yellow
    
    try {
        # Stop and disable the geolocation service
        Write-Host "🛑 Stopping Geolocation Service..." -ForegroundColor $Color.Cyan
        $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Stop-Service -Name "lfsvc" -Force
                Write-Host "  ✓ Geolocation service stopped" -ForegroundColor $Color.Green
            }
            Set-Service -Name "lfsvc" -StartupType Disabled
            Write-Host "  ✓ Geolocation service disabled" -ForegroundColor $Color.Green
        } else {
            Write-Host "  ⚠️ Geolocation service not found" -ForegroundColor $Color.Yellow
        }
        
        # Disable location access in registry
        Write-Host "📝 Disabling location access in registry..." -ForegroundColor $Color.Cyan
        
        # Disable location consent
        $locationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        if (Test-Path $locationPath) {
            Set-ItemProperty -Path $locationPath -Name "Value" -Value "Deny" -Force
            Write-Host "  ✓ Location consent disabled" -ForegroundColor $Color.Green
        }
        
        # Disable location sensors
        $sensorPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
        if (!(Test-Path $sensorPath)) {
            New-Item -Path $sensorPath -Force | Out-Null
        }
        Set-ItemProperty -Path $sensorPath -Name "SensorPermissionState" -Value 0 -Type DWord -Force
        Write-Host "  ✓ Location sensors disabled" -ForegroundColor $Color.Green
        
        # Disable location scripting
        $scriptingPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location\Microsoft.Win32WebViewHost_cw5n1h2txyewy"
        if (Test-Path $scriptingPath) {
            Set-ItemProperty -Path $scriptingPath -Name "Value" -Value "Deny" -Force
            Write-Host "  ✓ Location scripting disabled" -ForegroundColor $Color.Green
        }
        
        Write-Host "✅ Windows Geolocation Service disabled successfully!" -ForegroundColor $Color.Green
        
    } catch {
        Write-Host "❌ Error disabling geolocation: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

function Enable-GeolocationService {
    Write-Host "🔄 Enabling Windows Geolocation Service..." -ForegroundColor $Color.Yellow
    
    try {
        # Enable and start the geolocation service
        Write-Host "▶️ Enabling Geolocation Service..." -ForegroundColor $Color.Cyan
        $service = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
        if ($service) {
            Set-Service -Name "lfsvc" -StartupType Manual
            Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
            Write-Host "  ✓ Geolocation service enabled and started" -ForegroundColor $Color.Green
        }
        
        # Enable location access in registry
        Write-Host "📝 Enabling location access in registry..." -ForegroundColor $Color.Cyan
        
        # Enable location consent
        $locationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
        if (Test-Path $locationPath) {
            Set-ItemProperty -Path $locationPath -Name "Value" -Value "Allow" -Force
            Write-Host "  ✓ Location consent enabled" -ForegroundColor $Color.Green
        }
        
        # Enable location sensors
        $sensorPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
        if (Test-Path $sensorPath) {
            Set-ItemProperty -Path $sensorPath -Name "SensorPermissionState" -Value 1 -Type DWord -Force
            Write-Host "  ✓ Location sensors enabled" -ForegroundColor $Color.Green
        }
        
        Write-Host "✅ Windows Geolocation Service enabled successfully!" -ForegroundColor $Color.Green
        
    } catch {
        Write-Host "❌ Error enabling geolocation: $($_.Exception.Message)" -ForegroundColor $Color.Red
    }
}

function Show-CurrentStatus {
    Write-Host "📊 Current Privacy Settings Status:" -ForegroundColor $Color.Green
    Write-Host "===================================" -ForegroundColor $Color.Green
    
    # IPv6 Status
    Write-Host "🌐 IPv6 Status:" -ForegroundColor $Color.Cyan
    $disabledComponents = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -ErrorAction SilentlyContinue).DisabledComponents
    if ($disabledComponents -eq 0xffffffff) {
        Write-Host "  Status: DISABLED (Registry)" -ForegroundColor $Color.Red
    } elseif ($disabledComponents -eq 0x0 -or $disabledComponents -eq $null) {
        Write-Host "  Status: ENABLED" -ForegroundColor $Color.Green
    } else {
        Write-Host "  Status: PARTIALLY DISABLED (Value: $disabledComponents)" -ForegroundColor $Color.Yellow
    }
    
    # Check adapter bindings
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        $ipv6Binding = Get-NetAdapterBinding -Name $adapter.Name -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
        if ($ipv6Binding) {
            $status = if ($ipv6Binding.Enabled) { "ENABLED" } else { "DISABLED" }
            $color = if ($ipv6Binding.Enabled) { $Color.Green } else { $Color.Red }
            Write-Host "  $($adapter.Name): $status" -ForegroundColor $color
        }
    }
    
    Write-Host ""
    
    # Geolocation Status
    Write-Host "📍 Geolocation Service Status:" -ForegroundColor $Color.Cyan
    $locationService = Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue
    if ($locationService) {
        $status = $locationService.Status
        $startType = $locationService.StartType
        $color = switch ($status) {
            "Running" { $Color.Green }
            "Stopped" { $Color.Red }
            default { $Color.Yellow }
        }
        Write-Host "  Service Status: $status ($startType)" -ForegroundColor $color
    } else {
        Write-Host "  Service Status: NOT FOUND" -ForegroundColor $Color.Yellow
    }
    
    # Location consent
    $locationConsent = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -ErrorAction SilentlyContinue).Value
    $consentColor = if ($locationConsent -eq "Deny") { $Color.Red } else { $Color.Green }
    Write-Host "  Location Consent: $locationConsent" -ForegroundColor $consentColor
    
    Write-Host ""
}

function Show-Menu {
    Write-Host "🎯 Select an option:" -ForegroundColor $Color.Green
    Write-Host "===================" -ForegroundColor $Color.Green
    Write-Host "[1] Show current status" -ForegroundColor $Color.White
    Write-Host "[2] Disable IPv6 only" -ForegroundColor $Color.White
    Write-Host "[3] Disable Geolocation only" -ForegroundColor $Color.White
    Write-Host "[4] Disable both IPv6 & Geolocation" -ForegroundColor $Color.White
    Write-Host "[5] Enable IPv6 only" -ForegroundColor $Color.White
    Write-Host "[6] Enable Geolocation only" -ForegroundColor $Color.White
    Write-Host "[7] Enable both IPv6 & Geolocation" -ForegroundColor $Color.White
    Write-Host "[8] Create backup of current settings" -ForegroundColor $Color.White
    Write-Host "[9] Restore from backup" -ForegroundColor $Color.White
    Write-Host "[0] Exit" -ForegroundColor $Color.White
    Write-Host ""
}

# Main script execution
Write-Banner

# Check for administrator rights
if (-not (Test-AdminRights)) {
    Write-Host "❌ This script requires administrator privileges!" -ForegroundColor $Color.Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor $Color.Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Running with administrator privileges" -ForegroundColor $Color.Green
Write-Host ""

# Handle command line parameters
switch ($Action.ToLower()) {
    "menu" {
        do {
            Show-Menu
            $choice = Read-Host "Enter your choice (0-9)"
            
            switch ($choice) {
                "1" {
                    Show-CurrentStatus
                    Read-Host "Press Enter to continue"
                }
                "2" {
                    Backup-CurrentSettings | Out-Null
                    Disable-IPv6
                    Read-Host "Press Enter to continue"
                }
                "3" {
                    Backup-CurrentSettings | Out-Null
                    Disable-GeolocationService
                    Read-Host "Press Enter to continue"
                }
                "4" {
                    Backup-CurrentSettings | Out-Null
                    Write-Host "🔄 Disabling both IPv6 and Geolocation..." -ForegroundColor $Color.Yellow
                    Disable-IPv6
                    Write-Host ""
                    Disable-GeolocationService
                    Write-Host ""
                    Write-Host "✅ Both IPv6 and Geolocation disabled!" -ForegroundColor $Color.Green
                    Read-Host "Press Enter to continue"
                }
                "5" {
                    Enable-IPv6
                    Read-Host "Press Enter to continue"
                }
                "6" {
                    Enable-GeolocationService
                    Read-Host "Press Enter to continue"
                }
                "7" {
                    Write-Host "🔄 Enabling both IPv6 and Geolocation..." -ForegroundColor $Color.Yellow
                    Enable-IPv6
                    Write-Host ""
                    Enable-GeolocationService
                    Write-Host ""
                    Write-Host "✅ Both IPv6 and Geolocation enabled!" -ForegroundColor $Color.Green
                    Read-Host "Press Enter to continue"
                }
                "8" {
                    Backup-CurrentSettings
                    Read-Host "Press Enter to continue"
                }
                "9" {
                    $backupFile = Read-Host "Enter backup file name"
                    if (Test-Path $backupFile) {
                        Write-Host "🔄 Restoring configuration from $backupFile..." -ForegroundColor $Color.Yellow
                        Write-Host "⚠️ Restore functionality is a placeholder - implement as needed" -ForegroundColor $Color.Yellow
                    } else {
                        Write-Host "❌ Backup file not found!" -ForegroundColor $Color.Red
                    }
                    Read-Host "Press Enter to continue"
                }
                "0" {
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
    "disable" {
        Backup-CurrentSettings | Out-Null
        if ($IPv6Only) {
            Disable-IPv6
        } elseif ($GeolocationOnly) {
            Disable-GeolocationService
        } else {
            Disable-IPv6
            Disable-GeolocationService
        }
    }
    "enable" {
        if ($IPv6Only) {
            Enable-IPv6
        } elseif ($GeolocationOnly) {
            Enable-GeolocationService
        } else {
            Enable-IPv6
            Enable-GeolocationService
        }
    }
    "status" {
        Show-CurrentStatus
    }
    default {
        Write-Host "❌ Invalid action!" -ForegroundColor $Color.Red
        Write-Host "Available actions: menu, disable, enable, status" -ForegroundColor $Color.Yellow
        Write-Host "Available switches: -IPv6Only, -GeolocationOnly, -EnableAll, -Restore" -ForegroundColor $Color.Yellow
    }
}

Write-Host ""
Write-Host "📋 Script completed. Remember to use these tools responsibly!" -ForegroundColor $Color.Green
Write-Host "⚠️  Some changes may require a system restart to take full effect." -ForegroundColor $Color.Yellow
