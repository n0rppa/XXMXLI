<#
XXMXLI Windows Security Suite - All-in-One
Combines: Firewall rules, Registry hardening, User account security, Windows Defender config, and System diagnostics
Single entry point so you can download/run one script only
#>

#Requires -Version 5.1
#Requires -Modules NetSecurity, Defender
#Requires -RunAsAdministrator

[CmdletBinding()]
param()

# Ensure we're running from the script directory - use absolute paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Harden defaults and enable robust error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Define classes for object-oriented approach
class SystemStateManager {
    [hashtable]$OriginalFirewallProfiles = @{}
    [hashtable]$OriginalRegistryValues = @{}
    [hashtable]$OriginalDefenderSettings = @{}

    [void]SaveFirewallState() {
        try {
            $profiles = Get-NetFirewallProfile
            foreach ($profile in $profiles) {
                $this.OriginalFirewallProfiles[$profile.Name] = @{
                    Enabled = $profile.Enabled
                    DefaultInboundAction = $profile.DefaultInboundAction
                    DefaultOutboundAction = $profile.DefaultOutboundAction
                }
            }
            Write-Verbose "Firewall state saved"
        } catch {
            Write-Warning "Failed to save firewall state: $($_.Exception.Message)"
        }
    }

    [void]SaveRegistryState([string[]]$RegistryPaths) {
        try {
            foreach ($path in $RegistryPaths) {
                if (Test-Path $path) {
                    $this.OriginalRegistryValues[$path] = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
                }
            }
            Write-Verbose "Registry state saved for $($RegistryPaths.Count) paths"
        } catch {
            Write-Warning "Failed to save registry state: $($_.Exception.Message)"
        }
    }

    [void]SaveDefenderState() {
        try {
            $defenderPrefs = Get-MpPreference -ErrorAction SilentlyContinue
            if ($defenderPrefs) {
                $this.OriginalDefenderSettings = @{
                    DisableRealtimeMonitoring = $defenderPrefs.DisableRealtimeMonitoring
                    MAPSReporting = $defenderPrefs.MAPSReporting
                    SubmitSamplesConsent = $defenderPrefs.SubmitSamplesConsent
                }
            }
            Write-Verbose "Defender state saved"
        } catch {
            Write-Warning "Failed to save Defender state: $($_.Exception.Message)"
        }
    }

    [void]RestoreFirewallState() {
        try {
            foreach ($profileName in $this.OriginalFirewallProfiles.Keys) {
                $original = $this.OriginalFirewallProfiles[$profileName]
                Set-NetFirewallProfile -Name $profileName -Enabled $original.Enabled -DefaultInboundAction $original.DefaultInboundAction -DefaultOutboundAction $original.DefaultOutboundAction -ErrorAction Stop
            }
            Write-Host "Firewall state restored" -ForegroundColor Green
        } catch {
            Write-Error "Failed to restore firewall state: $($_.Exception.Message)"
        }
    }

    [void]RestoreRegistryState() {
        try {
            foreach ($path in $this.OriginalRegistryValues.Keys) {
                $original = $this.OriginalRegistryValues[$path]
                if ($original) {
                    # Get all properties except PS* properties
                    $properties = $original | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -notlike 'PS*' }
                    foreach ($prop in $properties) {
                        $propName = $prop.Name
                        $propValue = $original.$propName
                        try {
                            Set-ItemProperty -Path $path -Name $propName -Value $propValue -ErrorAction Stop
                        } catch {
                            Write-Warning "Failed to restore registry value $path\$propName`: $($_.Exception.Message)"
                        }
                    }
                }
            }
            Write-Host "Registry state restored" -ForegroundColor Green
        } catch {
            Write-Error "Failed to restore registry state: $($_.Exception.Message)"
        }
    }

    [void]RestoreDefenderState() {
        try {
            Set-MpPreference -DisableRealtimeMonitoring $this.OriginalDefenderSettings.RealtimeMonitoring -ErrorAction Stop
            Set-MpPreference -MAPSReporting $this.OriginalDefenderSettings.MAPSReporting -ErrorAction Stop
            Set-MpPreference -SubmitSamplesConsent $this.OriginalDefenderSettings.SubmitSamplesConsent -ErrorAction Stop
            Write-Host "Defender state restored" -ForegroundColor Green
        } catch {
            Write-Error "Failed to restore Defender state: $($_.Exception.Message)"
        }
    }
}

# Global state manager instance
$Global:StateManager = [SystemStateManager]::new()

# Centralized logging with absolute paths
$logFile = Join-Path -Path $ScriptDir -ChildPath "xxmxli_security_suite.log"
$manualLogFile = Join-Path -Path $ScriptDir -ChildPath "xxmxli_security_manual.log"
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    try {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logEntry = "$timestamp [$Level] $Message"
        Add-Content -Path $manualLogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    } catch {
        Write-Warning "Failed to write to log: $($_.Exception.Message)"
    }
}

function Log-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Cyan
    Write-Log -Message $Message -Level 'INFO'
}

function Log-Success {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Green
    Write-Log -Message $Message -Level 'SUCCESS'
}

function Log-Warn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Yellow
    Write-Log -Message $Message -Level 'WARN'
}

function Log-Error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Red
    Write-Log -Message $Message -Level 'ERROR'
}

# Capture full console transcript (best-effort)
try { Start-Transcript -Path $logFile -Append -ErrorAction SilentlyContinue | Out-Null } catch {}

# Global trap to log unexpected errors without crashing the session
trap {
    Log-Error ("Unhandled error: " + $_.Exception.Message)
    continue
}

# Global: check admin with proper error handling
function Test-Administrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Error "Failed to check administrator privileges: $($_.Exception.Message)"
        return $false
    }
}

# Check admin privileges
if (-not (Test-Administrator)) {
    Log-Error "This script requires administrator privileges"
    Log-Warn "Please run PowerShell as Administrator and try again"
    Read-Host "Press Enter to exit"
    exit 1
}

# ===== Shared UI helpers with validation =====
function Pause-Clear {
    [CmdletBinding()]
    param()

    try {
        Write-Host ""
        Read-Host "Press Enter to continue" | Out-Null
        Clear-Host
    } catch {
        Write-Warning "Error in Pause-Clear: $($_.Exception.Message)"
    }
}

function Write-Section {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$title,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Blue','Green','Red','Yellow','Cyan','Magenta')]
        [string]$color = 'Blue'
    )

    try {
        Write-Host "================================================================" -ForegroundColor $color
        Write-Host $title -ForegroundColor $color
        Write-Host "================================================================" -ForegroundColor $color
        Write-Host ""
        Write-Log -Message ("SECTION: " + $title) -Level 'INFO'
    } catch {
        Write-Error "Failed to write section: $($_.Exception.Message)"
    }
}

# ===== Module: Firewall Rules with validation =====
function Enable-FirewallProfiles {
    [CmdletBinding()]
    param()

    try {
        # Save original state first
        $Global:StateManager.SaveFirewallState()

        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled $true -ErrorAction Stop
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -ErrorAction Stop
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow -ErrorAction Stop
        Log-Success "Windows Firewall enabled for all profiles (Inbound=Block, Outbound=Allow)"
    } catch {
        Log-Error ("Error enabling firewall: " + $_.Exception.Message)
        throw
    }
}

function Configure-SecurityRules {
    [CmdletBinding()]
    param()

    try {
        $attackPorts = @(135,139,445,1433,1434,3389,5985,5986)
        foreach ($port in $attackPorts) {
            $name = "XXMXLI_Block_Port_$port"
            if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort $port -Action Block -ErrorAction Stop | Out-Null
                Log-Success "Blocked inbound TCP $port"
            }
        }

        $essential = @(
            @{Name="XXMXLI_Allow_HTTP"; Proto="TCP"; Port=80; Dir="Outbound"},
            @{Name="XXMXLI_Allow_HTTPS"; Proto="TCP"; Port=443; Dir="Outbound"},
            @{Name="XXMXLI_Allow_DNS"; Proto="UDP"; Port=53; Dir="Outbound"}
        )
        foreach ($rule in $essential) {
            if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $rule.Name -Direction $rule.Dir -Protocol $rule.Proto -LocalPort $rule.Port -Action Allow -ErrorAction Stop | Out-Null
                Log-Success "Allowed $($rule.Dir) $($rule.Proto) $($rule.Port)"
            }
        }
        Log-Success "Security rules configured"
    } catch {
        Log-Error ("Error configuring security rules: " + $_.Exception.Message)
        throw
    }
}

function Block-SuspiciousPorts {
    [CmdletBinding()]
    param()

    try {
        $ports = @(
            @{Port=23; Protocol="TCP"; Desc="Telnet"},
            @{Port=69; Protocol="UDP"; Desc="TFTP"},
            @{Port=135; Protocol="TCP"; Desc="RPC"},
            @{Port=139; Protocol="TCP"; Desc="NetBIOS"},
            @{Port=445; Protocol="TCP"; Desc="SMB"},
            @{Port=1433; Protocol="TCP"; Desc="SQL Server"},
            @{Port=1434; Protocol="UDP"; Desc="SQL Browser"},
            @{Port=3389; Protocol="TCP"; Desc="RDP (external)"},
            @{Port=5985; Protocol="TCP"; Desc="WinRM HTTP"},
            @{Port=5986; Protocol="TCP"; Desc="WinRM HTTPS"}
        )

        foreach ($portInfo in $ports) {
            $name = "XXMXLI_Block_$($portInfo.Desc)_$($portInfo.Port)"
            if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol $portInfo.Protocol -LocalPort $portInfo.Port -Action Block -ErrorAction Stop | Out-Null
                Log-Success "Blocked $($portInfo.Desc) $($portInfo.Port)/$($portInfo.Protocol)"
            }
        }
        Log-Success "Suspicious ports blocked"
    } catch {
        Log-Error ("Error blocking ports: " + $_.Exception.Message)
        throw
    }
}

function Show-FirewallStatus {
    [CmdletBinding()]
    param()

    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($profile in $profiles) {
            $status = ''
            $color = 'White'
            if ($profile.Enabled) {
                $status = "ENABLED"
                $color = "Green"
            } else {
                $status = "DISABLED"
                $color = "Red"
            }
            Write-Host "$($profile.Name) Profile: $status" -ForegroundColor $color
            Write-Host "  Default Inbound: $($profile.DefaultInboundAction) | Default Outbound: $($profile.DefaultOutboundAction)"
        }

        $rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" } -ErrorAction SilentlyContinue
        if ($rules) {
            Log-Warn "XXMXLI Custom Rules:"
            $rules | Select DisplayName,Direction,Action,Enabled | Format-Table -AutoSize
        }
    } catch {
        Log-Error ("Error showing firewall status: " + $_.Exception.Message)
        throw
    }
}

function Reset-FirewallRules {
    [CmdletBinding()]
    param()

    try {
        $c = Read-Host "Remove XXMXLI rules and reset firewall to defaults? (y/N)"
        if ($c -match '^(y|Y)$') {
            Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" } | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            & netsh advfirewall reset | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "netsh advfirewall reset failed with exit code $LASTEXITCODE"
            }
            Log-Success "Firewall reset"
        }
    } catch {
        Log-Error ("Error resetting firewall: " + $_.Exception.Message)
        throw
    }
}

function Module-Firewall {
    [CmdletBinding()]
    param()

    Write-Section "XXMXLI Windows Firewall Configuration"
    do {
        Write-Host "1) Enable firewall (all profiles)"
        Write-Host "2) Configure security rules"
        Write-Host "3) Block suspicious ports"
        Write-Host "4) Show current firewall status"
        Write-Host "5) Reset to default rules"
        Write-Host "0) Back"

        try {
            $ch = Read-Host "Choose"
            switch ($ch) {
                '1' { Enable-FirewallProfiles; Pause-Clear }
                '2' { Configure-SecurityRules; Pause-Clear }
                '3' { Block-SuspiciousPorts; Pause-Clear }
                '4' { Show-FirewallStatus; Pause-Clear }
                '5' { Reset-FirewallRules; Pause-Clear }
                '0' { break }
                default { Write-Host "Invalid" -ForegroundColor Red }
            }
        } catch {
            Log-Error ("Error in firewall module: " + $_.Exception.Message)
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host | Out-Null
        }
    } while ($true)
}

# ===== Module: Registry Hardening =====
function Set-RegistryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DWORD", "QWORD", "String", "ExpandString", "Binary", "MultiString")]
        [string]$Type = "DWORD",

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }

        # Normalize PropertyType for New-ItemProperty (valid: String, ExpandString, Binary, DWord, MultiString, QWord)
        $propType = $null
        switch -Regex ($Type) {
            '^(dword|DWORD|DWord)$' { $propType = 'DWord' }
            '^(qword|QWORD|QWord)$' { $propType = 'QWord' }
            '^(string|STRING)$' { $propType = 'String' }
            '^(expandstring|EXPANDSTRING)$' { $propType = 'ExpandString' }
            '^(binary|BINARY)$' { $propType = 'Binary' }
            '^(multistring|MULTISTRING)$' { $propType = 'MultiString' }
            default { $propType = 'String' }
        }

        $existing = $null
        try { $existing = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop } catch { $existing = $null }

        if ($null -ne $existing) {
            # Property exists: only set the value (Set-ItemProperty doesn't accept -Type)
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction Stop | Out-Null
        } else {
            # Property doesn't exist: create with explicit PropertyType
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $propType -Force -ErrorAction Stop | Out-Null
        }

        if ($Description) { Log-Success $Description } else { Log-Success "$Path\$Name=$Value" }
    } catch {
        Log-Error ("Error setting ${Path}\${Name}: " + $_.Exception.Message)
        throw
    }
}

function Create-RegistryBackup {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    try {
        $BackupPath = Join-Path -Path $ScriptDir -ChildPath "registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        & reg export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies "$BackupPath" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "reg export failed with exit code $LASTEXITCODE" }
        Log-Success "Backup: $BackupPath"
        return $BackupPath
    } catch {
        Log-Error ("Backup failed: " + $_.Exception.Message)
        return $null
    }
}

function Disable-DangerousFeatures {
    [CmdletBinding()]
    param()

    try {
        # Save registry state first
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer",
            "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings",
            "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer",
            "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        )
        $Global:StateManager.SaveRegistryState($registryPaths)

        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255 -Type "DWORD" -Description "Disabled AutoRun (system)"
        Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255 -Type "DWORD" -Description "Disabled AutoRun (user)"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" "Enabled" 0 -Type "DWORD" -Description "Disabled Windows Script Host"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" "ExecutionPolicy" "RemoteSigned" -Type "String" -Description "Set PS execution policy RemoteSigned"
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" "AlwaysInstallElevated" 0 -Type "DWORD" -Description "Disabled AlwaysInstallElevated"
        Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer" "AlwaysInstallElevated" 0 -Type "DWORD" -Description "Disabled AlwaysInstallElevated (user)"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "limitblankpassworduse" 1 -Type "DWORD" -Description "Limit blank password use"
    } catch {
        Log-Error ("Error disabling dangerous features: " + $_.Exception.Message)
        throw
    }
}

function Harden-SecurityPolicies {
    [CmdletBinding()]
    param()

    try {
        # Save additional registry state
        $securityPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection",
            "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters",
            "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System",
            "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
        )
        $Global:StateManager.SaveRegistryState($securityPaths)

        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 0 -Type "DWORD" -Description "Enable Defender Anti-Spyware"
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 0 -Type "DWORD" -Description "Enable Real-Time Protection"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "RequireSecuritySignature" 1 -Type "DWORD" -Description "Require SMB server signing"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "RequireSecuritySignature" 1 -Type "DWORD" -Description "Require SMB client signing"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 5 -Type "DWORD" -Description "NTLMv2 only"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1 -Type "DWORD" -Description "Enable UAC"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 2 -Type "DWORD" -Description "UAC prompt for consent"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RestrictAnonymous" 1 -Type "DWORD" -Description "Restrict anonymous"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RestrictAnonymousSAM" 1 -Type "DWORD" -Description "Restrict anonymous SAM"
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" "MaximumPasswordAge" 42 -Type "DWORD" -Description "Max password age 42 days"
    } catch {
        Log-Error ("Error hardening security policies: " + $_.Exception.Message)
        throw
    }
}

function Disable-UnnecessaryServices {
    [CmdletBinding()]
    param()

    try {
        $svc = @(
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Fax"; Desc="Fax Service"},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\TlntSvr"; Desc="Telnet Server"},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV"; Desc="SSDP Discovery"},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\upnphost"; Desc="UPnP Device Host"},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess"; Desc="Routing and Remote Access"}
        )

        foreach ($service in $svc) {
            if (Test-Path $service.Path) {
                Set-RegistryValue -Path $service.Path -Name "Start" -Value 4 -Type "DWORD" -Description "Disabled $($service.Desc)"
            }
        }
        Log-Warn "Note: Service changes take effect after reboot"
    } catch {
        Log-Error ("Error disabling services: " + $_.Exception.Message)
        throw
    }
}

function Configure-PrivacySettings {
    [CmdletBinding()]
    param()

    try {
        # Save privacy settings state
        $privacyPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        )
        $Global:StateManager.SaveRegistryState($privacyPaths)

        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0 -Type "DWORD" -Description "Disable tailored experiences"
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1 -Type "DWORD" -Description "Disable advertising ID"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0 -Type "DWORD" -Description "Disable telemetry"
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 -Type "DWORD" -Description "Disable activity publishing"
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1 -Type "DWORD" -Description "Disable consumer features"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "AllowOnlineTips" 0 -Type "DWORD" -Description "Disable online tips"
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0 -Type "DWORD" -Description "Disable Start menu suggestions"
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0 -Type "DWORD" -Description "Disable silent app installs"
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled" 0 -Type "DWORD" -Description "Disable pre-installed apps"
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed" 0 -Type "DWORD" -Description "Disable content delivery"
    } catch {
        Log-Error ("Error configuring privacy settings: " + $_.Exception.Message)
        throw
    }
}

function Show-SecurityStatus-Registry {
    [CmdletBinding()]
    param()

    try {
        $checks = @(
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoDriveTypeAutoRun"; Expected=255; Desc="AutoRun Disabled"},
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"; Name="Enabled"; Expected=0; Desc="Script Host Disabled"},
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="EnableLUA"; Expected=1; Desc="UAC Enabled"},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name="RestrictAnonymous"; Expected=1; Desc="Anonymous Restricted"},
            @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Expected=0; Desc="Telemetry Disabled"}
        )

        foreach ($check in $checks) {
            try {
                $value = Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction SilentlyContinue
                if ($value -and $value.($check.Name) -eq $check.Expected) {
                    Log-Success $check.Desc
                } else {
                    Log-Error $check.Desc
                }
            } catch {
                Log-Warn ("Unable to check: " + $check.Desc)
            }
        }
    } catch {
        Log-Error ("Error checking security status: " + $_.Exception.Message)
        throw
    }
}

function Module-Registry {
    [CmdletBinding()]
    param()

    Write-Section "XXMXLI Registry Security Configuration"
    do {
        Write-Host "1) Create registry backup"
        Write-Host "2) Disable dangerous features"
        Write-Host "3) Harden security policies"
        Write-Host "4) Disable unnecessary services (registry)"
        Write-Host "5) Configure privacy settings"
        Write-Host "6) Show current security status"
        Write-Host "0) Back"

        try {
            $ch = Read-Host "Choose"
            switch ($ch) {
                '1' { Create-RegistryBackup | Out-Null; Pause-Clear }
                '2' { Disable-DangerousFeatures; Pause-Clear }
                '3' { Harden-SecurityPolicies; Pause-Clear }
                '4' { Disable-UnnecessaryServices; Pause-Clear }
                '5' { Configure-PrivacySettings; Pause-Clear }
                '6' { Show-SecurityStatus-Registry; Pause-Clear }
                '0' { break }
                default { Log-Warn "Invalid choice in Registry module" }
            }
        } catch {
            Log-Error ("Error in registry module: " + $_.Exception.Message)
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host | Out-Null
        }
    } while ($true)
}

# ===== Module: Windows Defender with validation =====
function Module-Defender {
    [CmdletBinding()]
    param()

    try {
        # Save Defender state first
        $Global:StateManager.SaveDefenderState()

        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
        Log-Success "Real-time protection enabled"

        Set-MpPreference -MAPSReporting Advanced -ErrorAction Stop
        Set-MpPreference -SubmitSamplesConsent SendAllSamples -ErrorAction Stop
        Log-Success "Cloud protection configured"

        Set-MpPreference -ScanAvgCPULoadFactor 50 -ErrorAction Stop
        Set-MpPreference -ScanPurgeItemsAfterDelay 30 -ErrorAction Stop
        Log-Success "Scan settings optimized"

        Set-MpPreference -EnableNetworkProtection Enabled -ErrorAction Stop
        Log-Success "Network protection enabled"

        Log-Warn "Updating virus definitions..."
        Update-MpSignature -ErrorAction Stop
        Log-Success "Definitions updated"
    } catch {
        Log-Error ("Error configuring Defender: " + $_.Exception.Message)
        throw
    }

    Pause-Clear
}

# ===== Module: User Account Security =====
function Audit-UserAccounts {
    [CmdletBinding()]
    param()

    try {
        $localUsers = Get-LocalUser -ErrorAction Stop
        foreach ($u in $localUsers) {
            $status = ''
            $color = 'White'
            if ($u.Enabled) {
                $status = 'ENABLED'
                if ($u.Name -in @('Guest','DefaultAccount')) { $color = 'Red' } else { $color = 'Green' }
            } else {
                $status = 'DISABLED'
                $color = 'Yellow'
            }
            Write-Host "User: $($u.Name)" -ForegroundColor $color
            Write-Host "  Status: $status"; Write-Host "  Last Logon: $($u.LastLogon)"; Write-Host "  Password Last Set: $($u.PasswordLastSet)"; Write-Host "  Password Required: $($u.PasswordRequired)"; Write-Host ""
            Write-Log -Message ("AUDIT USER: " + $u.Name + ", Status=" + $status) -Level 'INFO'
        }
        try {
            $admins = Get-LocalGroupMember -Group Administrators -ErrorAction Stop
            Write-Host "Administrators:" -ForegroundColor Cyan
            foreach ($a in $admins) {
                $fg = 'White'
                if ($a.ObjectClass -eq 'User') { $fg = 'Red' } else { $fg = 'Yellow' }
                Write-Host "  $($a.Name) ($($a.ObjectClass))" -ForegroundColor $fg
            }
        } catch { Log-Error "Error getting Administrators" }
    } catch {
        Log-Error ("Error auditing user accounts: " + $_.Exception.Message)
        throw
    }
}

function Configure-PasswordPolicies {
    [CmdletBinding()]
    param()

    try {
        $c = Read-Host "Apply password policies (minlen 12, max age 90, min age 1, history 12)? (y/N)"
        if ($c -match '^(y|Y)$') {
            try {
                & net accounts /minpwlen:12 -ErrorAction Stop
                & net accounts /maxpwage:90 -ErrorAction Stop
                & net accounts /minpwage:1 -ErrorAction Stop
                & net accounts /uniquepw:12 -ErrorAction Stop
                Log-Success "Basic password policies applied"
            } catch {
                Log-Error ("Error configuring password policies: " + $_.Exception.Message)
                throw
            }
        }
    } catch {
        Log-Error ("Error in password policy configuration: " + $_.Exception.Message)
        throw
    }
}

function Manage-UserAccounts {
    [CmdletBinding()]
    param()

    try {
        foreach ($name in @('Guest','DefaultAccount')) {
            $acct = Get-LocalUser -Name $name -ErrorAction SilentlyContinue
            if ($acct) {
                $status = ''
                $fg = 'White'
                if ($acct.Enabled) {
                    $status = 'ENABLED (RISK!)'
                    $fg = 'Red'
                } else {
                    $status = 'DISABLED (OK)'
                    $fg = 'Green'
                }
                Write-Host "  ${name}: $status" -ForegroundColor $fg
                if ($acct.Enabled) {
                    $d = Read-Host "Disable $name? (y/N)"
                    if ($d -match '^(y|Y)$') {
                        Disable-LocalUser -Name $name -ErrorAction Stop
                        Log-Success ("$name disabled")
                    }
                }
            }
        }

        $mk = Read-Host "Create a new administrator account? (y/N)"
        if ($mk -match '^(y|Y)$') {
            $n = Read-Host "New admin username"
            if ($n -and $n -notmatch '^\s*$') {
                # Use secure password input - no hardcoded passwords
                $pw = Read-Host "Password for $n" -AsSecureString
                if ($pw.Length -gt 0) {
                    New-LocalUser -Name $n -Password $pw -FullName "XXMXLI Administrator" -Description "Created by XXMXLI Security Suite" -ErrorAction Stop
                    Add-LocalGroupMember -Group Administrators -Member $n -ErrorAction Stop
                    Log-Success ("Admin '$n' created")
                } else {
                    Log-Warn "Password cannot be empty"
                }
            } else {
                Log-Warn "Username cannot be empty"
            }
        }
    } catch {
        Log-Error ("Error managing user accounts: " + $_.Exception.Message)
        throw
    }
}

function Configure-UserRights {
    [CmdletBinding()]
    param()

    try {
        $reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        Set-RegistryValue -Path $reg -Name DisableCAD -Value 0 -Type "DWORD" -Description "Enabled Ctrl+Alt+Del at logon"
        Set-RegistryValue -Path $reg -Name DontDisplayLastUserName -Value 1 -Type "DWORD" -Description "Hide last username at logon"
        Log-Success "Core logon requirements configured"
    } catch {
        Log-Error ("Error configuring logon requirements: " + $_.Exception.Message)
        throw
    }

    try {
        $ln = Read-Host "Set legal notice for logon? (y/N)"
        if ($ln -match '^(y|Y)$') {
            Set-RegistryValue -Path $reg -Name LegalNoticeCaption -Value "AUTHORIZED USE ONLY" -Type "String" -Description "Set logon legal notice caption"
            Set-RegistryValue -Path $reg -Name LegalNoticeText -Value "This system is for authorized users only. All activities are monitored." -Type "String" -Description "Set logon legal notice text"
            Log-Success "Legal notice configured"
        }
    } catch {
        Log-Error ("Error setting legal notice: " + $_.Exception.Message)
        throw
    }
}

function Configure-AccountLockout {
    [CmdletBinding()]
    param()

    try {
        & net accounts /lockoutthreshold:5 -ErrorAction Stop
        & net accounts /lockoutduration:30 -ErrorAction Stop
        & net accounts /lockoutwindow:30 -ErrorAction Stop
        Log-Success "Account lockout policies applied"
    } catch {
        Log-Error ("Error configuring lockout policies: " + $_.Exception.Message)
        throw
    }
}

function Module-UserSecurity {
    [CmdletBinding()]
    param()

    Write-Section "XXMXLI User Account Security"
    do {
        Write-Host "1) Audit user accounts"
        Write-Host "2) Configure password policies"
        Write-Host "3) Disable/Enable accounts"
        Write-Host "4) Configure user rights"
        Write-Host "5) Configure account lockout"
        Write-Host "0) Back"

        try {
            $ch = Read-Host "Choose"
            switch ($ch) {
                '1' { Audit-UserAccounts; Pause-Clear }
                '2' { Configure-PasswordPolicies; Pause-Clear }
                '3' { Manage-UserAccounts; Pause-Clear }
                '4' { Configure-UserRights; Pause-Clear }
                '5' { Configure-AccountLockout; Pause-Clear }
                '0' { break }
                default { Log-Warn "Invalid choice in User Account Security module" }
            }
        } catch {
            Log-Error ("Error in User Account Security module: " + $_.Exception.Message)
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host | Out-Null
        }
    } while ($true)
}

# ===== Module: Diagnostics with validation =====
function Module-Diagnostics {
    [CmdletBinding()]
    param()

    Write-Section "XXMXLI System Diagnostics"

    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
        Write-Host "OS: $($os.Caption) $($os.Version) ($($os.OSArchitecture))"
        Write-Host "Last Boot: $($os.LastBootUpTime)"

        $def = $null
        try { $def = Get-MpComputerStatus -ErrorAction Stop } catch {}
        if ($def) {
            $rtp = if ($def.RealTimeProtectionEnabled) { 'Enabled' } else { 'Disabled' }
            Write-Host "Defender RTP: $rtp"
        }

        $fw = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($profile in $fw) {
            $fwStatus = if ($profile.Enabled) { 'Enabled' } else { 'Disabled' }
            Write-Host "Firewall $($profile.Name): $fwStatus"
        }
    } catch {
        Log-Error ("Diagnostic error: " + $_.Exception.Message)
        throw
    }

    try {
        $exp = Read-Host "Export quick report to files? (y/N)"
        if ($exp -match '^(y|Y)$') {
            $ts = Get-Date -Format "yyyyMMdd_HHmmss"
            $txt = Join-Path -Path $ScriptDir -ChildPath "XXMXLI_Security_Report_$ts.txt"
            $json = Join-Path -Path $ScriptDir -ChildPath "XXMXLI_Security_Report_$ts.json"
            $data = @{
                Timestamp = (Get-Date)
                Computer = $env:COMPUTERNAME
                User = $env:USERNAME
            }
            ($data | Out-String) | Out-File -FilePath $txt -Encoding UTF8 -ErrorAction Stop
            $data | ConvertTo-Json -Depth 3 -Compress | Out-File -FilePath $json -Encoding UTF8 -ErrorAction Stop
            Log-Success "Exported: $txt, $json"
        }
    } catch {
        Log-Error ("Export failed: " + $_.Exception.Message)
        throw
    }

    Pause-Clear
}

# ===== Restore functionality =====
function Restore-SystemState {
    [CmdletBinding()]
    param()

    Write-Section "XXMXLI System State Restoration"

    try {
        $choice = Read-Host "What do you want to restore?`n1) Firewall settings`n2) Registry values`n3) Defender settings`n4) All settings`n0) Cancel`nChoice"

        switch ($choice) {
            '1' {
                if ($Global:StateManager.OriginalFirewallProfiles.Count -gt 0) {
                    $Global:StateManager.RestoreFirewallState()
                } else {
                    Log-Warn "No firewall state saved to restore"
                }
            }
            '2' {
                if ($Global:StateManager.OriginalRegistryValues.Count -gt 0) {
                    $Global:StateManager.RestoreRegistryState()
                } else {
                    Log-Warn "No registry state saved to restore"
                }
            }
            '3' {
                if ($Global:StateManager.OriginalDefenderSettings.Count -gt 0) {
                    $Global:StateManager.RestoreDefenderState()
                } else {
                    Log-Warn "No Defender state saved to restore"
                }
            }
            '4' {
                $Global:StateManager.RestoreFirewallState()
                $Global:StateManager.RestoreRegistryState()
                $Global:StateManager.RestoreDefenderState()
                Log-Success "All saved states restored"
            }
            '0' { return }
            default { Log-Warn "Invalid choice" }
        }
    } catch {
        Log-Error ("Error during restoration: " + $_.Exception.Message)
        throw
    }

    Pause-Clear
}

# ===== Main Menu with validation =====
Clear-Host
Write-Section "XXMXLI Windows Security Suite - All-in-One"

while ($true) {
    Write-Host "1) Firewall configuration"
    Write-Host "2) Registry hardening"
    Write-Host "3) Windows Defender configuration"
    Write-Host "4) User account security"
    Write-Host "5) System diagnostics and reports"
    Write-Host "6) Restore system state"
    Write-Host "0) Exit"

    try {
        $choice = Read-Host "Select option"
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        switch ($choice) {
            '1' { Module-Firewall }
            '2' { Module-Registry }
            '3' { Module-Defender }
            '4' { Module-UserSecurity }
            '5' { Module-Diagnostics }
            '6' { Restore-SystemState }
            '0' {
                Log-Info "Exiting..."
                break
            }
            default { Log-Warn "Invalid choice in Main Menu" }
        }
    } catch {
        Log-Error ("Error in main menu: " + $_.Exception.Message)
        Write-Host "Press Enter to continue..." -ForegroundColor Yellow
        Read-Host | Out-Null
        Clear-Host
    } finally {
        # lightweight session logging
        if ($choice) {
            $entry = @{
                Timestamp = $ts
                User = $env:USERNAME
                Computer = $env:COMPUTERNAME
                Action = $choice
            }
            try {
                $entry | ConvertTo-Json -Compress | Add-Content -Path $logFile -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

# Stop transcript if started
try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
