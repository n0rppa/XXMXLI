<#
XXMXLI Windows Security Suite - All-in-One
Combines: Firewall rules, Registry hardening, User account security, Windows Defender config, and System diagnostics
Single entry point so you can download/run one script only
#>

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Harden defaults and enable robust error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Centralized logging
$logFile = Join-Path $ScriptDir "xxmxli_security_suite.log"
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')][string]$Level = 'INFO'
    )
    try {
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -Path $logFile -Value ("$ts [$Level] $Message") -Encoding UTF8
    } catch { }
}
function Log-Info { param([string]$Message) Write-Host $Message -ForegroundColor Cyan; Write-Log -Message $Message -Level 'INFO' }
function Log-Success { param([string]$Message) Write-Host $Message -ForegroundColor Green; Write-Log -Message $Message -Level 'SUCCESS' }
function Log-Warn { param([string]$Message) Write-Host $Message -ForegroundColor Yellow; Write-Log -Message $Message -Level 'WARN' }
function Log-Error { param([string]$Message) Write-Host $Message -ForegroundColor Red; Write-Log -Message $Message -Level 'ERROR' }

# Capture full console transcript (best-effort)
try { Start-Transcript -Path $logFile -Append -ErrorAction SilentlyContinue | Out-Null } catch {}

# Global trap to log unexpected errors without crashing the session
trap {
    Log-Error ("Unhandled error: " + $_.Exception.Message)
    continue
}

# Global: check admin
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Log-Error "This script requires administrator privileges"
    Log-Warn "Please run PowerShell as Administrator and try again"
    Read-Host "Press Enter to exit"
    exit 1
}

# ===== Shared UI helpers =====
function Pause-Clear {
    Write-Host ""
    Read-Host "Press Enter to continue"
    Clear-Host
}

function Write-Section($title, $color = 'Blue') {
    Write-Host "================================================================" -ForegroundColor $color
    Write-Host $title -ForegroundColor $color
    Write-Host "================================================================" -ForegroundColor $color
    Write-Host ""
    Write-Log -Message ("SECTION: " + $title) -Level 'INFO'
}

# ===== Module: Firewall Rules =====
function Enable-FirewallProfiles {
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True -ErrorAction Stop
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -ErrorAction Stop
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow -ErrorAction Stop
        Log-Success "Windows Firewall enabled for all profiles (Inbound=Block, Outbound=Allow)"
    } catch { Log-Error ("Error enabling firewall: " + $_.Exception.Message) }
}

function Configure-SecurityRules {
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
        foreach ($r in $essential) {
            if (-not (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $r.Name -Direction $r.Dir -Protocol $r.Proto -LocalPort $r.Port -Action Allow -ErrorAction Stop | Out-Null
                Log-Success "Allowed $($r.Dir) $($r.Proto) $($r.Port)"
            }
        }
        Log-Success "Security rules configured"
    } catch { Log-Error ("Error configuring security rules: " + $_.Exception.Message) }
}

function Block-SuspiciousPorts {
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
    try {
        foreach ($p in $ports) {
            $name = "XXMXLI_Block_$($p.Desc)_$($p.Port)"
            if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol $p.Protocol -LocalPort $p.Port -Action Block -ErrorAction Stop | Out-Null
                Log-Success "Blocked $($p.Desc) $($p.Port)/$($p.Protocol)"
            }
        }
        Log-Success "Suspicious ports blocked"
    } catch { Log-Error ("Error blocking ports: " + $_.Exception.Message) }
}

function Show-FirewallStatus {
    $profiles = Get-NetFirewallProfile
    foreach ($profile in $profiles) {
        $status = ''
        $color = 'White'
        if ($profile.Enabled) { $status = "ENABLED"; $color = "Green" } else { $status = "DISABLED"; $color = "Red" }
        Write-Host "$($profile.Name) Profile: $status" -ForegroundColor $color
        Write-Host "  Default Inbound: $($profile.DefaultInboundAction) | Default Outbound: $($profile.DefaultOutboundAction)"
    }
    $rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" }
    if ($rules) { Log-Warn "XXMXLI Custom Rules:"; $rules | Select DisplayName,Direction,Action,Enabled | Format-Table -AutoSize }
}

function Reset-FirewallRules {
    $c = Read-Host "Remove XXMXLI rules and reset firewall to defaults? (y/N)"
    if ($c -match '^(y|Y)$') {
        try {
            Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" } | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            & netsh advfirewall reset | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "netsh advfirewall reset failed with exit code $LASTEXITCODE" }
            Log-Success "Firewall reset"
        } catch { Log-Error ("Error resetting firewall: " + $_.Exception.Message) }
    }
}

function Module-Firewall {
    Write-Section "XXMXLI Windows Firewall Configuration"
    do {
        Write-Host "1) Enable firewall (all profiles)"
        Write-Host "2) Configure security rules"
        Write-Host "3) Block suspicious ports"
        Write-Host "4) Show current firewall status"
        Write-Host "5) Reset to default rules"
        Write-Host "0) Back"
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
    } while ($true)
}

# ===== Module: Registry Hardening =====
function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value,
        [string]$Type = "DWORD",
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
    } catch { Log-Error ("Error setting $Path\$Name: " + $_.Exception.Message) }
}

function Create-RegistryBackup {
    $BackupPath = Join-Path $ScriptDir "registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    try {
        & reg export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies "$BackupPath" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "reg export failed with exit code $LASTEXITCODE" }
        Log-Success "Backup: $BackupPath"; return $BackupPath
    } catch { Log-Error ("Backup failed: " + $_.Exception.Message); return $null }
}

function Disable-DangerousFeatures {
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255 "Disabled AutoRun (system)"
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" "NoDriveTypeAutoRun" 255 "Disabled AutoRun (user)"
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings" "Enabled" 0 "Disabled Windows Script Host"
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" "ExecutionPolicy" "RemoteSigned" "Set PS execution policy RemoteSigned"
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" "AlwaysInstallElevated" 0 "Disabled AlwaysInstallElevated"
    Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer" "AlwaysInstallElevated" 0 "Disabled AlwaysInstallElevated (user)"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "limitblankpassworduse" 1 "Limit blank password use"
}

function Harden-SecurityPolicies {
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 0 "Enable Defender Anti-Spyware"
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableRealtimeMonitoring" 0 "Enable Real-Time Protection"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "RequireSecuritySignature" 1 "Require SMB server signing"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" "RequireSecuritySignature" 1 "Require SMB client signing"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "LmCompatibilityLevel" 5 "NTLMv2 only"
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" 1 "Enable UAC"
    Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" 2 "UAC prompt for consent"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RestrictAnonymous" 1 "Restrict anonymous"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RestrictAnonymousSAM" 1 "Restrict anonymous SAM"
    Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" "MaximumPasswordAge" 42 "Max password age 42 days"
}

function Disable-UnnecessaryServices {
    $svc = @(
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Fax"; Desc="Fax Service"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\TlntSvr"; Desc="Telnet Server"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\SSDPSRV"; Desc="SSDP Discovery"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\upnphost"; Desc="UPnP Device Host"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess"; Desc="Routing and Remote Access"}
    )
    foreach ($s in $svc) { if (Test-Path $s.Path) { Set-RegistryValue $s.Path "Start" 4 "Disabled $($s.Desc)" } }
    Log-Warn "Note: Service changes take effect after reboot"
}

function Configure-PrivacySettings {
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 "Disable telemetry"
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1 "Disable Error Reporting"
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" "DisableLocation" 1 "Disable location services"
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" "SubmitSamplesConsent" 2 "Disable Defender sample submission"
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0 "Disable Update P2P delivery"
}

function Show-SecurityStatus-Registry {
    $checks = @(
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"; Name="NoDriveTypeAutoRun"; Expected=255; Desc="AutoRun Disabled"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"; Name="Enabled"; Expected=0; Desc="Script Host Disabled"},
        @{Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Name="EnableLUA"; Expected=1; Desc="UAC Enabled"},
        @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"; Name="RestrictAnonymous"; Expected=1; Desc="Anonymous Restricted"},
        @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name="AllowTelemetry"; Expected=0; Desc="Telemetry Disabled"}
    )
    foreach ($c in $checks) {
        try {
            $v = Get-ItemProperty -Path $c.Path -Name $c.Name -ErrorAction SilentlyContinue
            if ($v -and $v.($c.Name) -eq $c.Expected) { Log-Success $c.Desc } else { Log-Error $c.Desc }
        } catch { Log-Warn ("Unable to check: " + $c.Desc) }
    }
}

function Module-Registry {
    Write-Section "XXMXLI Registry Security Configuration"
    do {
        Write-Host "1) Create registry backup"
        Write-Host "2) Disable dangerous features"
        Write-Host "3) Harden security policies"
        Write-Host "4) Disable unnecessary services (registry)"
        Write-Host "5) Configure privacy settings"
        Write-Host "6) Show current security status"
        Write-Host "0) Back"
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
    } while ($true)
}

# ===== Module: Windows Defender =====
function Module-Defender {
    Write-Section "XXMXLI Windows Defender Configuration"
    try {
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
    } catch { Log-Error ("Error configuring Defender: " + $_.Exception.Message) }
    Pause-Clear
}

# ===== Module: User Account Security =====
function Audit-UserAccounts {
    $localUsers = Get-LocalUser
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
        $admins = Get-LocalGroupMember -Group Administrators
        Write-Host "Administrators:" -ForegroundColor Cyan
        foreach ($a in $admins) {
            $fg = 'White'
            if ($a.ObjectClass -eq 'User') { $fg = 'Red' } else { $fg = 'Yellow' }
            Write-Host "  $($a.Name) ($($a.ObjectClass))" -ForegroundColor $fg
        }
    } catch { Log-Error "Error getting Administrators" }
}

function Configure-PasswordPolicies {
    $c = Read-Host "Apply password policies (minlen 12, max age 90, min age 1, history 12)? (y/N)"
    if ($c -match '^(y|Y)$') { try { & net accounts /minpwlen:12; & net accounts /maxpwage:90; & net accounts /minpwage:1; & net accounts /uniquepw:12; Log-Success "Basic password policies applied" } catch { Log-Error ("Error configuring password policies: " + $_.Exception.Message) } }
}

function Manage-UserAccounts {
    foreach ($name in @('Guest','DefaultAccount')) {
        try {
            $acct = Get-LocalUser -Name $name -ErrorAction SilentlyContinue
            if ($acct) {
                $status = ''
                $fg = 'White'
                if ($acct.Enabled) { $status = 'ENABLED (RISK!)'; $fg = 'Red' } else { $status = 'DISABLED (OK)'; $fg = 'Green' }
                Write-Host "  $name: $status" -ForegroundColor $fg
                if ($acct.Enabled) {
                    $d = Read-Host "Disable $name? (y/N)"
                    if ($d -match '^(y|Y)$') { Disable-LocalUser -Name $name -ErrorAction Stop; Log-Success ("$name disabled") }
                }
            }
        } catch { Log-Warn ("$name: error - " + $_.Exception.Message) }
    }
    $mk = Read-Host "Create a new administrator account? (y/N)"; if ($mk -match '^(y|Y)$') { $n = Read-Host "New admin username"; if ($n) { try { $pw = Read-Host "Password for $n" -AsSecureString; New-LocalUser -Name $n -Password $pw -FullName "XXMXLI Administrator" -Description "Created by XXMXLI Security Suite" -ErrorAction Stop; Add-LocalGroupMember -Group Administrators -Member $n -ErrorAction Stop; Log-Success ("Admin '"+$n+"' created") } catch { Log-Error ("Error creating admin: " + $_.Exception.Message) } } }
}

function Configure-UserRights {
    $reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    try {
        Set-RegistryValue -Path $reg -Name DisableCAD -Value 0 -Type DWORD -Description "Enabled Ctrl+Alt+Del at logon"
        Set-RegistryValue -Path $reg -Name DontDisplayLastUserName -Value 1 -Type DWORD -Description "Hide last username at logon"
        Log-Success "Core logon requirements configured"
    } catch { Log-Error ("Error configuring logon requirements: " + $_.Exception.Message) }
    $ln = Read-Host "Set legal notice for logon? (y/N)"
    if ($ln -match '^(y|Y)$') {
        try {
            Set-RegistryValue -Path $reg -Name LegalNoticeCaption -Value "AUTHORIZED USE ONLY" -Type String -Description "Set logon legal notice caption"
            Set-RegistryValue -Path $reg -Name LegalNoticeText -Value "This system is for authorized users only. All activities are monitored." -Type String -Description "Set logon legal notice text"
            Log-Success "Legal notice configured"
        } catch { Log-Error ("Error setting legal notice: " + $_.Exception.Message) }
    }
}

function Configure-AccountLockout { try { & net accounts /lockoutthreshold:5; & net accounts /lockoutduration:30; & net accounts /lockoutwindow:30; Log-Success "Account lockout policies applied" } catch { Log-Error ("Error configuring lockout policies: " + $_.Exception.Message) } }

function Module-UserSecurity {
    Write-Section "XXMXLI User Account Security"
    do {
        Write-Host "1) Audit user accounts"
        Write-Host "2) Configure password policies"
        Write-Host "3) Disable/Enable accounts"
        Write-Host "4) Configure user rights"
        Write-Host "5) Configure account lockout"
        Write-Host "0) Back"
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
    } while ($true)
}

# ===== Module: Diagnostics =====
function Module-Diagnostics {
    Write-Section "XXMXLI System Diagnostics"
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
        Write-Host "OS: $($os.Caption) $($os.Version) ($($os.OSArchitecture))"
        Write-Host "Last Boot: $($os.LastBootUpTime)"
        $def = $null; try { $def = Get-MpComputerStatus -ErrorAction Stop } catch {}
        if ($def) {
            $rtp = 'Unknown'
            if ($def.RealTimeProtectionEnabled) { $rtp = 'Enabled' } else { $rtp = 'Disabled' }
            Write-Host "Defender RTP: $rtp"
        }
        $fw = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($p in $fw) {
            $fwStatus = 'Unknown'
            if ($p.Enabled) { $fwStatus = 'Enabled' } else { $fwStatus = 'Disabled' }
            Write-Host "Firewall $($p.Name): $fwStatus"
        }
    } catch { Log-Error ("Diagnostic error: " + $_.Exception.Message) }
    $exp = Read-Host "Export quick report to files? (y/N)"; if ($exp -match '^(y|Y)$') { $ts = Get-Date -Format "yyyyMMdd_HHmmss"; $txt = Join-Path $ScriptDir "XXMXLI_Security_Report_$ts.txt"; $json = Join-Path $ScriptDir "XXMXLI_Security_Report_$ts.json"; $data = @{ Timestamp=(Get-Date); Computer=$env:COMPUTERNAME; User=$env:USERNAME }; try { ($data | Out-String) | Out-File -FilePath $txt -Encoding UTF8; $data | ConvertTo-Json -Depth 3 -Compress | Out-File -FilePath $json -Encoding UTF8; Log-Success "Exported: $txt, $json" } catch { Log-Error ("Export failed: " + $_.Exception.Message) } }
    Pause-Clear
}

# ===== Main Menu =====
Clear-Host
Write-Section "XXMXLI Windows Security Suite - All-in-One"

while ($true) {
    Write-Host "1) Firewall configuration"
    Write-Host "2) Registry hardening"
    Write-Host "3) Windows Defender configuration"
    Write-Host "4) User account security"
    Write-Host "5) System diagnostics and reports"
    Write-Host "0) Exit"
    $choice = Read-Host "Select option"
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        switch ($choice) {
            '1' { Module-Firewall }
            '2' { Module-Registry }
            '3' { Module-Defender }
            '4' { Module-UserSecurity }
            '5' { Module-Diagnostics }
            '0' { Log-Info "Exiting..."; break }
            default { Log-Warn "Invalid choice in Main Menu" }
        }
    } finally {
        # lightweight session logging
        $entry = @{ Timestamp=$ts; User=$env:USERNAME; Computer=$env:COMPUTERNAME; Action=$choice }
    try { $entry | ConvertTo-Json -Compress | Add-Content -Path $logFile } catch {}
    }
}

# Stop transcript if started
try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch {}
