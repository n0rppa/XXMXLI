# Windows Defender Configuration Script
# XXMXLI Windows Defender Advanced Configuration

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI Windows Defender Configuration" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
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

# Configure Windows Defender settings
Write-Host "Configuring Windows Defender..." -ForegroundColor Cyan

try {
    # Enable real-time protection
    Set-MpPreference -DisableRealtimeMonitoring $false
    Write-Host "✓ Real-time protection enabled" -ForegroundColor Green
    
    # Enable cloud protection
    Set-MpPreference -MAPSReporting Advanced
    Set-MpPreference -SubmitSamplesConsent SendAllSamples
    Write-Host "✓ Cloud protection configured" -ForegroundColor Green
    
    # Configure scan settings
    Set-MpPreference -ScanAvgCPULoadFactor 50
    Set-MpPreference -ScanPurgeItemsAfterDelay 30
    Write-Host "✓ Scan settings optimized" -ForegroundColor Green
    
    # Enable network protection
    Set-MpPreference -EnableNetworkProtection Enabled
    Write-Host "✓ Network protection enabled" -ForegroundColor Green
    
    # Update definitions
    Write-Host "Updating virus definitions..." -ForegroundColor Yellow
    Update-MpSignature
    Write-Host "✓ Virus definitions updated" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "✓ Windows Defender configuration completed successfully" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Error configuring Windows Defender: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to continue"
