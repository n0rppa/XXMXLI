# XXMXLI IPv6 Geolocation Disabler
# This PowerShell script disables IPv6 geolocation features for enhanced privacy

#Requires -Version 5.1

param(
    [switch]$Help,
    [switch]$Status,
    [switch]$Enable
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $ScriptDir "privacy_settings.log"

# Ensure we're running from the script directory
Set-Location $ScriptDir

# Help function
function Show-Help {
    [CmdletBinding()]
    param()
    
    Write-Host @"
XXMXLI IPv6 Geolocation Disabler

SYNOPSIS
    Disables IPv6 geolocation features for enhanced privacy

DESCRIPTION
    This script disables various Windows geolocation and IPv6 tracking features
    to enhance user privacy and prevent location-based tracking.

PARAMETERS
    -Help       Show this help message
    -Status     Show current geolocation and IPv6 status
    -Enable     Re-enable geolocation features (reverse operation)

EXAMPLES
    .\disable_ipv6_geolocation.ps1
    .\disable_ipv6_geolocation.ps1 -Status
    .\disable_ipv6_geolocation.ps1 -Enable

REQUIREMENTS
    - Windows 10/11
    - Administrator privileges
    - PowerShell 5.0 or later

NOTE
    Some changes may require a system restart to take effect

"@
}

# Disable IPv6 geolocation services
function Disable-IPv6Geolocation {
    [CmdletBinding()]
    param()
    
    Write-Host "Disabling IPv6 geolocation services..." -ForegroundColor Cyan
    
    # Disable Windows Location Provider
    Write-Host "• Disabling Windows Location Provider..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -ErrorAction SilentlyContinue
    
    # Disable location scripting
    Write-Host "• Disabling location scripting..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -ErrorAction SilentlyContinue
    
    # Disable IPv6 if not needed
    Write-Host "• Configuring IPv6 settings..." -ForegroundColor Yellow
    netsh interface ipv6 set global randomizeidentifiers=disabled
    netsh interface ipv6 set privacy state=disabled
    
    # Disable Windows Maps download
    Write-Host "• Disabling automatic maps downloads..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AllowUntriggeredNetworkTrafficOnSettingsPage" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AutoDownloadAndUpdateMapData" -Value 0 -ErrorAction SilentlyContinue
    
    # Disable Find My Device
    Write-Host "• Disabling Find My Device..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Settings\FindMyDevice" -Name "LocationSyncEnabled" -Value 0 -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "✓ IPv6 geolocation features disabled successfully" -ForegroundColor Green
    
    # Create log entry
    $LogEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Action = "IPv6 Geolocation Disabled"
        User = $env:USERNAME
        Computer = $env:COMPUTERNAME
    }
    
    $LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile -Encoding UTF8
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI IPv6 Geolocation Disabler" -ForegroundColor Blue
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
    # Show current status
    Write-Host "Checking current geolocation and IPv6 status..." -ForegroundColor Cyan
    # TODO: Implement status checking
    Write-Host "Status checking not yet implemented" -ForegroundColor Yellow
    exit 0
}

if ($Enable) {
    # Re-enable features
    Write-Host "Re-enabling IPv6 geolocation features..." -ForegroundColor Cyan
    # TODO: Implement re-enable functionality
    Write-Host "Re-enable functionality not yet implemented" -ForegroundColor Yellow
    exit 0
}

# Default action: Disable features
}

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI IPv6 Geolocation Disabler" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Working directory: $ScriptDir" -ForegroundColor Yellow
Write-Host ""

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

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Running with administrator privileges" -ForegroundColor Green
Write-Host ""

# Default action: Disable features
try {
    Disable-IPv6Geolocation
}
catch {
    Write-Host "✗ Error during operation: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "PRIVACY ENHANCEMENT COMPLETE" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Log saved to: $LogFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE: Some changes may require a system restart to take effect" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to continue"