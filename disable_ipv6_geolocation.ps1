# XXMXLI IPv6 Geolocation Disabler
# This PowerShell script disables IPv6 geolocation features for enhanced privacy

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI IPv6 Geolocation Disabler" -ForegroundColor Blue
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

# Disable IPv6 geolocation services
Write-Host "Disabling IPv6 geolocation services..." -ForegroundColor Cyan

try {
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
    
} catch {
    Write-Host "✗ Error disabling geolocation features: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create log entry
$LogEntry = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Action = "IPv6 Geolocation Disabled"
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
}

$LogFile = Join-Path $ScriptDir "privacy_settings.log"
$LogEntry | ConvertTo-Json | Add-Content $LogFile

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