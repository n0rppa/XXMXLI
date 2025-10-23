<#
XXMXLI Windows Security Suite - All-in-One
Combines: Firewall rules, Registry hardening, User account security, Windows Defender config, and System diagnostics
Single entry point so you can download/run one script only
#>

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Global: check admin
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
}

# ===== Module: Firewall Rules =====
function Enable-FirewallProfiles {
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
        Write-Host "✓ Windows Firewall enabled for all profiles (Inbound=Block, Outbound=Allow)" -ForegroundColor Green
    } catch { Write-Host "× Error enabling firewall: $($_.Exception.Message)" -ForegroundColor Red }
}

function Configure-SecurityRules {
    try {
        $attackPorts = @(135,139,445,1433,1434,3389,5985,5986)
        foreach ($port in $attackPorts) {
            $name = "XXMXLI_Block_Port_$port"
            if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort $port -Action Block | Out-Null
                Write-Host "  ✓ Blocked inbound TCP $port" -ForegroundColor Green
            }
        }
        $essential = @(
            @{Name="XXMXLI_Allow_HTTP"; Proto="TCP"; Port=80; Dir="Outbound"},
            @{Name="XXMXLI_Allow_HTTPS"; Proto="TCP"; Port=443; Dir="Outbound"},
            @{Name="XXMXLI_Allow_DNS"; Proto="UDP"; Port=53; Dir="Outbound"}
        )
        foreach ($r in $essential) {
            if (-not (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $r.Name -Direction $r.Dir -Protocol $r.Proto -LocalPort $r.Port -Action Allow | Out-Null
                Write-Host "  ✓ Allowed $($r.Dir) $($r.Proto) $($r.Port)" -ForegroundColor Green
            }
        }
        Write-Host "✓ Security rules configured" -ForegroundColor Green
    } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red }
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
                New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol $p.Protocol -LocalPort $p.Port -Action Block | Out-Null
                Write-Host "  ✓ Blocked $($p.Desc) $($p.Port)/$($p.Protocol)" -ForegroundColor Green
            }
        }
        Write-Host "✓ Suspicious ports blocked" -ForegroundColor Green
    } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red }
}

function Show-FirewallStatus {
    $profiles = Get-NetFirewallProfile
    foreach ($profile in $profiles) {
        if ($profile.Enabled) { $status = "ENABLED"; $color = "Green" } else { $status = "DISABLED"; $color = "Red" }
        Write-Host "$($profile.Name) Profile: $status" -ForegroundColor $color
        Write-Host "  Default Inbound: $($profile.DefaultInboundAction) | Default Outbound: $($profile.DefaultOutboundAction)"
    }
    $rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" }
    if ($rules) { Write-Host "XXMXLI Custom Rules:" -ForegroundColor Yellow; $rules | Select DisplayName,Direction,Action,Enabled | Format-Table -AutoSize }
}

function Reset-FirewallRules {
    $c = Read-Host "Remove XXMXLI rules and reset firewall to defaults? (y/N)"
    if ($c -match '^(y|Y)$') {
        try {
            Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" } | Remove-NetFirewallRule -ErrorAction SilentlyContinue
            netsh advfirewall reset | Out-Null
            Write-Host "✓ Firewall reset" -ForegroundColor Green
        } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red }
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
    param([string]$Path,[string]$Name,[object]$Value,[string]$Type="DWORD",[string]$Description="")
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        if ($Description) { Write-Host "  ✓ $Description" -ForegroundColor Green } else { Write-Host "  ✓ $Path\$Name=$Value" -ForegroundColor Green }
    } catch { Write-Host "  × Error setting $Path\$Name: $($_.Exception.Message)" -ForegroundColor Red }
}

function Create-RegistryBackup {
    $BackupPath = Join-Path $ScriptDir "registry_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
    try { reg export HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies "$BackupPath" | Out-Null; Write-Host "✓ Backup: $BackupPath" -ForegroundColor Green; return $BackupPath } catch { Write-Host "× Backup failed: $($_.Exception.Message)" -ForegroundColor Red; return $null }
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
    Write-Host "Note: Service changes take effect after reboot" -ForegroundColor Yellow
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
        try { $v = Get-ItemProperty -Path $c.Path -Name $c.Name -ErrorAction SilentlyContinue; if ($v -and $v.($c.Name) -eq $c.Expected) { Write-Host "✓ $($c.Desc)" -ForegroundColor Green } else { Write-Host "× $($c.Desc)" -ForegroundColor Red } } catch { Write-Host "? $($c.Desc) - Unable to check" -ForegroundColor Yellow }
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
            default { Write-Host "Invalid" -ForegroundColor Red }
        }
    } while ($true)
}

# ===== Module: Windows Defender =====
function Module-Defender {
    Write-Section "XXMXLI Windows Defender Configuration"
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false
        Write-Host "✓ Real-time protection enabled" -ForegroundColor Green
        Set-MpPreference -MAPSReporting Advanced
        Set-MpPreference -SubmitSamplesConsent SendAllSamples
        Write-Host "✓ Cloud protection configured" -ForegroundColor Green
        Set-MpPreference -ScanAvgCPULoadFactor 50
        Set-MpPreference -ScanPurgeItemsAfterDelay 30
        Write-Host "✓ Scan settings optimized" -ForegroundColor Green
        Set-MpPreference -EnableNetworkProtection Enabled
        Write-Host "✓ Network protection enabled" -ForegroundColor Green
        Write-Host "Updating virus definitions..." -ForegroundColor Yellow
        Update-MpSignature
        Write-Host "✓ Definitions updated" -ForegroundColor Green
    } catch { Write-Host "× Error configuring Defender: $($_.Exception.Message)" -ForegroundColor Red }
    Pause-Clear
}

# ===== Module: User Account Security =====
function Audit-UserAccounts {
    $localUsers = Get-LocalUser
    foreach ($u in $localUsers) {
        if ($u.Enabled) {
            $status = 'ENABLED'
            if ($u.Name -in @('Guest','DefaultAccount')) { $color = 'Red' } else { $color = 'Green' }
        } else {
            $status = 'DISABLED'
            $color = 'Yellow'
        }
        Write-Host "User: $($u.Name)" -ForegroundColor $color
        Write-Host "  Status: $status"; Write-Host "  Last Logon: $($u.LastLogon)"; Write-Host "  Password Last Set: $($u.PasswordLastSet)"; Write-Host "  Password Required: $($u.PasswordRequired)"; Write-Host ""
    }
    try {
        $admins = Get-LocalGroupMember -Group Administrators
        Write-Host "Administrators:" -ForegroundColor Cyan
        foreach ($a in $admins) {
            if ($a.ObjectClass -eq 'User') { $fg = 'Red' } else { $fg = 'Yellow' }
            Write-Host "  $($a.Name) ($($a.ObjectClass))" -ForegroundColor $fg
        }
    } catch { Write-Host "Error getting Administrators" -ForegroundColor Red }
}

function Configure-PasswordPolicies {
    $c = Read-Host "Apply password policies (minlen 12, max age 90, min age 1, history 12)? (y/N)"
    if ($c -match '^(y|Y)$') { try { & net accounts /minpwlen:12; & net accounts /maxpwage:90; & net accounts /minpwage:1; & net accounts /uniquepw:12; Write-Host "✓ Basic password policies applied" -ForegroundColor Green } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red } }
}

function Manage-UserAccounts {
    foreach ($name in @('Guest','DefaultAccount')) {
        try {
            $acct = Get-LocalUser -Name $name -ErrorAction SilentlyContinue
            if ($acct) {
                if ($acct.Enabled) { $status = 'ENABLED (RISK!)'; $fg = 'Red' } else { $status = 'DISABLED (OK)'; $fg = 'Green' }
                Write-Host "  $name: $status" -ForegroundColor $fg
                if ($acct.Enabled) {
                    $d = Read-Host "Disable $name? (y/N)"
                    if ($d -match '^(y|Y)$') { Disable-LocalUser -Name $name; Write-Host "  ✓ $name disabled" -ForegroundColor Green }
                }
            }
        } catch { Write-Host "  $name: error" -ForegroundColor Yellow }
    }
    $mk = Read-Host "Create a new administrator account? (y/N)"; if ($mk -match '^(y|Y)$') { $n = Read-Host "New admin username"; if ($n) { try { $pw = Read-Host "Password for $n" -AsSecureString; New-LocalUser -Name $n -Password $pw -FullName "XXMXLI Administrator" -Description "Created by XXMXLI Security Suite"; Add-LocalGroupMember -Group Administrators -Member $n; Write-Host "✓ Admin '$n' created" -ForegroundColor Green } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red } } }
}

function Configure-UserRights {
    try { $reg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Set-ItemProperty -Path $reg -Name DisableCAD -Value 0 -Type DWORD; Set-ItemProperty -Path $reg -Name DontDisplayLastUserName -Value 1 -Type DWORD; Write-Host "✓ Enabled Ctrl+Alt+Del and hide last username" -ForegroundColor Green } catch { Write-Host "× Error configuring logon requirements: $($_.Exception.Message)" -ForegroundColor Red }
    $ln = Read-Host "Set legal notice for logon? (y/N)"; if ($ln -match '^(y|Y)$') { try { Set-ItemProperty -Path $reg -Name LegalNoticeCaption -Value "AUTHORIZED USE ONLY" -Type String; Set-ItemProperty -Path $reg -Name LegalNoticeText -Value "This system is for authorized users only. All activities are monitored." -Type String; Write-Host "✓ Legal notice configured" -ForegroundColor Green } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red } }
}

function Configure-AccountLockout { try { & net accounts /lockoutthreshold:5; & net accounts /lockoutduration:30; & net accounts /lockoutwindow:30; Write-Host "✓ Account lockout policies applied" -ForegroundColor Green } catch { Write-Host "× Error: $($_.Exception.Message)" -ForegroundColor Red } }

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
            default { Write-Host "Invalid" -ForegroundColor Red }
        }
    } while ($true)
}

# ===== Module: Diagnostics =====
function Module-Diagnostics {
    Write-Section "XXMXLI System Diagnostics"
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
        Write-Host "OS: $($os.Caption) $($os.Version) ($($os.OSArchitecture))"
        Write-Host "Last Boot: $($os.LastBootUpTime)"
        $def = $null; try { $def = Get-MpComputerStatus } catch {}
        if ($def) {
            if ($def.RealTimeProtectionEnabled) { $rtp = 'Enabled' } else { $rtp = 'Disabled' }
            Write-Host "Defender RTP: $rtp"
        }
        $fw = Get-NetFirewallProfile
        foreach ($p in $fw) {
            if ($p.Enabled) { $fwStatus = 'Enabled' } else { $fwStatus = 'Disabled' }
            Write-Host "Firewall $($p.Name): $fwStatus"
        }
    } catch { Write-Host "× Diagnostic error: $($_.Exception.Message)" -ForegroundColor Red }
    $exp = Read-Host "Export quick report to files? (y/N)"; if ($exp -match '^(y|Y)$') { $ts = Get-Date -Format "yyyyMMdd_HHmmss"; $txt = Join-Path $ScriptDir "XXMXLI_Security_Report_$ts.txt"; $json = Join-Path $ScriptDir "XXMXLI_Security_Report_$ts.json"; $data = @{ Timestamp=(Get-Date); Computer=$env:COMPUTERNAME; User=$env:USERNAME }; try { ($data | Out-String) | Out-File -FilePath $txt -Encoding UTF8; $data | ConvertTo-Json -Depth 3 | Out-File -FilePath $json -Encoding UTF8; Write-Host "✓ Exported: $txt, $json" -ForegroundColor Green } catch { Write-Host "× Export failed: $($_.Exception.Message)" -ForegroundColor Red } }
    Pause-Clear
}

# ===== Main Menu =====
Clear-Host
Write-Section "XXMXLI Windows Security Suite - All-in-One"

$logFile = Join-Path $ScriptDir "xxmxli_security_suite.log"

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
            '0' { Write-Host "Exiting..." -ForegroundColor Cyan; break }
            default { Write-Host "Invalid choice" -ForegroundColor Red }
        }
    } finally {
        # lightweight session logging
        $entry = @{ Timestamp=$ts; User=$env:USERNAME; Computer=$env:COMPUTERNAME; Action=$choice }
        try { $entry | ConvertTo-Json | Add-Content -Path $logFile } catch {}
    }
}
