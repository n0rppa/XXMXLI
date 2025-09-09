# Registry Security Configuration
# XXMXLI Advanced Registry Security Hardening

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI Registry Security Configuration" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "WARNING: This script modifies Windows Registry settings" -ForegroundColor Red
Write-Host "Always create a backup before making registry changes!" -ForegroundColor Red
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

function Create-RegistryBackup {
    $BackupPath = Join-Path $ScriptDir "registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    
    Write-Host "Creating registry backup..." -ForegroundColor Yellow
    
    try {
        # Export critical registry hives
        $regExportCmd = "reg export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies `"$BackupPath`""
        Invoke-Expression $regExportCmd
        
        Write-Host "✓ Registry backup created: $BackupPath" -ForegroundColor Green
        return $BackupPath
        
    } catch {
        Write-Host "✗ Error creating registry backup: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Show-Menu {
    Write-Host "Registry Security Configuration Options:" -ForegroundColor Cyan
    Write-Host "  1. Create registry backup"
    Write-Host "  2. Disable dangerous Windows features"
    Write-Host "  3. Harden Windows security policies"
    Write-Host "  4. Disable unnecessary services (registry)"
    Write-Host "  5. Configure privacy settings"
    Write-Host "  6. Show current security status"
    Write-Host "  7. Restore from backup"
    Write-Host "  8. Exit"
    Write-Host ""
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWORD",
        [string]$Description = ""
    )
    
    try {
        # Create the registry path if it doesn't exist
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        # Set the registry value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        
        if ($Description) {
            Write-Host "  ✓ $Description" -ForegroundColor Green
        } else {
            Write-Host "  ✓ Set $Path\$Name = $Value" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  ✗ Error setting $Path\$Name: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Disable-DangerousFeatures {
    Write-Host "Disabling dangerous Windows features..." -ForegroundColor Yellow
    
    # Disable AutoRun/AutoPlay
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Description "Disabled AutoRun for all drive types"
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Description "Disabled AutoRun for current user"
    
    # Disable Windows Script Host
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" -Name "Enabled" -Value 0 -Description "Disabled Windows Script Host"
    
    # Disable PowerShell script execution by default (can be overridden)
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "ExecutionPolicy" -Value "RemoteSigned" -Type "String" -Description "Set PowerShell execution policy to RemoteSigned"
    
    # Disable Windows Installer always install elevated
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -Value 0 -Description "Disabled Always Install Elevated"
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "AlwaysInstallElevated" -Value 0 -Description "Disabled Always Install Elevated for current user"
    
    # Disable Guest account
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "limitblankpassworduse" -Value 1 -Description "Limited blank password use"
    
    Write-Host "✓ Dangerous features disabled successfully" -ForegroundColor Green
}

function Harden-SecurityPolicies {
    Write-Host "Hardening Windows security policies..." -ForegroundColor Yellow
    
    # Enable Windows Defender features
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 0 -Description "Enabled Windows Defender Anti-Spyware"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Value 0 -Description "Enabled Real-Time Protection"
    
    # Harden SMB settings
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RequireSecuritySignature" -Value 1 -Description "Required SMB security signature"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 1 -Description "Required SMB client security signature"
    
    # Disable NTLM v1
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Value 5 -Description "Set NTLM compatibility to v2 only"
    
    # Enable UAC
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 1 -Description "Enabled User Account Control"
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 2 -Description "Set UAC to prompt for consent"
    
    # Disable anonymous enumeration
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymous" -Value 1 -Description "Restricted anonymous access"
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "RestrictAnonymousSAM" -Value 1 -Description "Restricted anonymous SAM access"
    
    # Configure password policy (informational - requires secpol.msc for full effect)
    Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name "MaximumPasswordAge" -Value 42 -Description "Set maximum password age to 42 days"
    
    Write-Host "✓ Security policies hardened successfully" -ForegroundColor Green
}

function Disable-UnnecessaryServices {
    Write-Host "Disabling unnecessary services via registry..." -ForegroundColor Yellow
    
    # List of services to disable (use with caution)
    $servicesToDisable = @(
        @{Name="Fax"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\Fax"; Description="Fax Service"},
        @{Name="TlntSvr"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\TlntSvr"; Description="Telnet Server"},
        @{Name="SSDPSRV"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV"; Description="SSDP Discovery"},
        @{Name="upnphost"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\upnphost"; Description="UPnP Device Host"},
        @{Name="RemoteAccess"; Path="HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess"; Description="Routing and Remote Access"}
    )
    
    foreach ($service in $servicesToDisable) {
        if (Test-Path $service.Path) {
            Set-RegistryValue -Path $service.Path -Name "Start" -Value 4 -Description "Disabled $($service.Description)"
        }
    }
    
    Write-Host "✓ Unnecessary services disabled successfully" -ForegroundColor Green
    Write-Host "Note: Service changes will take effect after reboot" -ForegroundColor Yellow
}

function Configure-PrivacySettings {
    Write-Host "Configuring privacy settings..." -ForegroundColor Yellow
    
    # Disable telemetry
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Description "Disabled telemetry collection"
    
    # Disable Windows Error Reporting
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1 -Description "Disabled Windows Error Reporting"
    
    # Disable location services
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" -Name "DisableLocation" -Value 1 -Description "Disabled location services"
    
    # Disable Windows Defender sample submission
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Value 2 -Description "Disabled automatic sample submission"
    
    # Disable Windows Update delivery optimization
    Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Description "Disabled Windows Update P2P delivery"
    
    Write-Host "✓ Privacy settings configured successfully" -ForegroundColor Green
}

function Show-SecurityStatus {
    Write-Host "Current Security Configuration Status:" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    
    # Check critical registry values
    $securityChecks = @(
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoDriveTypeAutoRun"; Expected=255; Description="AutoRun Disabled"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"; Name="Enabled"; Expected=0; Description="Script Host Disabled"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="EnableLUA"; Expected=1; Description="UAC Enabled"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name="RestrictAnonymous"; Expected=1; Description="Anonymous Access Restricted"},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Expected=0; Description="Telemetry Disabled"}
    )
    
    foreach ($check in $securityChecks) {
        try {
            $value = Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction SilentlyContinue
            if ($value -and $value.($check.Name) -eq $check.Expected) {
                Write-Host "✓ $($check.Description)" -ForegroundColor Green
            } else {
                Write-Host "✗ $($check.Description)" -ForegroundColor Red
            }
        } catch {
            Write-Host "? $($check.Description) - Unable to check" -ForegroundColor Yellow
        }
    }
}

function Restore-FromBackup {
    Write-Host "Available registry backup files:" -ForegroundColor Yellow
    $backupFiles = Get-ChildItem -Path $ScriptDir -Filter "registry_backup_*.reg" | Sort-Object LastWriteTime -Descending
    
    if ($backupFiles.Count -eq 0) {
        Write-Host "No backup files found in current directory" -ForegroundColor Red
        return
    }
    
    for ($i = 0; $i -lt $backupFiles.Count; $i++) {
        Write-Host "  $($i + 1). $($backupFiles[$i].Name) - $($backupFiles[$i].LastWriteTime)"
    }
    
    $choice = Read-Host "Select backup file to restore (1-$($backupFiles.Count)) or 0 to cancel"
    
    if ($choice -eq "0" -or $choice -eq "") {
        Write-Host "Restore cancelled" -ForegroundColor Yellow
        return
    }
    
    try {
        $selectedBackup = $backupFiles[$choice - 1]
        $confirm = Read-Host "Are you sure you want to restore from $($selectedBackup.Name)? (y/N)"
        
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            reg import "$($selectedBackup.FullName)"
            Write-Host "✓ Registry restored from backup" -ForegroundColor Green
            Write-Host "Note: Some changes may require a system restart" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "✗ Error restoring from backup: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (1-8)"
    
    switch ($choice) {
        "1" { 
            $backup = Create-RegistryBackup
            if ($backup) {
                Write-Host "Backup location: $backup" -ForegroundColor Blue
            }
        }
        "2" { Disable-DangerousFeatures }
        "3" { Harden-SecurityPolicies }
        "4" { Disable-UnnecessaryServices }
        "5" { Configure-PrivacySettings }
        "6" { Show-SecurityStatus }
        "7" { Restore-FromBackup }
        "8" { 
            Write-Host "Thank you for using XXMXLI Registry Security Configuration" -ForegroundColor Blue
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
    Action = "Registry Security Configuration Session"
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
}

$LogFile = Join-Path $ScriptDir "registry_changes.log"
$LogEntry | ConvertTo-Json | Add-Content $LogFile
