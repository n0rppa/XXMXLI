# DNS Security Setup Tool - Windows PowerShell Version
# Windows DNS Security and Privacy Configuration
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization
#
# SECURITY WARNING: This system is actively monitored and protected.
# Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
# will be logged and reported to the appropriate authorities. IP addresses and metadata 
# may be retained and used for legal enforcement, in compliance with applicable laws.
# By continuing, you acknowledge that you are authorized to use this system and that 
# any misuse may result in account suspension, firewall bans, or prosecution under 
# national and international law. Violators may be subject to civil and/or criminal 
# penalties. Your access is being monitored.

#Requires -Version 5.1

param(
    [switch]$Help,
    [switch]$Status,
    [switch]$Backup,
    [switch]$Restore,
    [ValidateSet("1", "2", "3", "4", "5", "6")]
    [string]$Provider
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Configuration
$ConfigDir = Join-Path $env:USERPROFILE ".dns_security"
$BackupDir = Join-Path $ConfigDir "backups"
$LogFile = Join-Path $ConfigDir "dns_security.log"

# Create directories
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

# Logging function
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [ValidateSet("White", "Red", "Green", "Yellow", "Cyan", "Magenta", "Blue")]
        [string]$Color = "White"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $Message"
        Write-Host $Message -ForegroundColor $Color
        Add-Content -Path $LogFile -Value $logEntry
    }
    catch {
        Write-Host "Failed to write log: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Banner
function Show-Banner {
    [CmdletBinding()]
    param()

    try {
        Write-Host ""
        Write-Host " ██████╗ ███╗   ██╗███████╗    ███████╗███████╗ ██████╗" -ForegroundColor Cyan
        Write-Host " ██╔══██╗████╗  ██║██╔════╝    ██╔════╝██╔════╝██╔════╝" -ForegroundColor Cyan
        Write-Host " ██║  ██║██╔██╗ ██║███████╗    ███████╗█████╗  ██║     " -ForegroundColor Cyan
        Write-Host " ██║  ██║██║╚██╗██║╚════██║    ╚════██║██╔══╝  ██║     " -ForegroundColor Cyan
        Write-Host " ██████╔╝██║ ╚████║███████║    ███████║███████╗╚██████╗" -ForegroundColor Cyan
        Write-Host " ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝╚══════╝ ╚═════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "    DNS Security Setup Tool - Windows PowerShell" -ForegroundColor Green
        Write-Host "    Comprehensive DNS Security and Privacy Configuration" -ForegroundColor Green
        Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
        Write-Host ""
    }
    catch {
        Write-Log "Failed to show banner: $($_.Exception.Message)" "Red"
        throw
    }
}

# DNS Provider configurations
$DNSProviders = @{
    "1" = @{
        Name = "Cloudflare (Privacy-focused)"
        Primary = "1.1.1.1"
        Secondary = "1.0.0.1"
        IPv6Primary = "2606:4700:4700::1111"
        IPv6Secondary = "2606:4700:4700::1001"
        DoH = "https://cloudflare-dns.com/dns-query"
        DoHServerAddress = "1.1.1.1"
    }
    "2" = @{
        Name = "Quad9 (Security-focused)"
        Primary = "9.9.9.9"
        Secondary = "149.112.112.112"
        IPv6Primary = "2620:fe::fe"
        IPv6Secondary = "2620:fe::9"
        DoH = "https://dns.quad9.net/dns-query"
        DoHServerAddress = "9.9.9.9"
    }
    "3" = @{
        Name = "OpenDNS (Content filtering)"
        Primary = "208.67.222.222"
        Secondary = "208.67.220.220"
        IPv6Primary = "2620:119:35::35"
        IPv6Secondary = "2620:119:53::53"
        DoH = "https://doh.opendns.com/dns-query"
        DoHServerAddress = "208.67.222.222"
    }
    "4" = @{
        Name = "Google (Fast, reliable)"
        Primary = "8.8.8.8"
        Secondary = "8.8.4.4"
        IPv6Primary = "2001:4860:4860::8888"
        IPv6Secondary = "2001:4860:4860::8844"
        DoH = "https://dns.google/dns-query"
        DoHServerAddress = "8.8.8.8"
    }
    "5" = @{
        Name = "AdGuard (Ad blocking)"
        Primary = "94.140.14.14"
        Secondary = "94.140.15.15"
        IPv6Primary = "2a10:50c0::ad1:ff"
        IPv6Secondary = "2a10:50c0::ad2:ff"
        DoH = "https://dns.adguard.com/dns-query"
        DoHServerAddress = "94.140.14.14"
    }
    "6" = @{
        Name = "CleanBrowsing (Family safe)"
        Primary = "185.228.168.9"
        Secondary = "185.228.169.9"
        IPv6Primary = "2a0d:2a00:1::2"
        IPv6Secondary = "2a0d:2a00:2::2"
        DoH = "https://doh.cleanbrowsing.org/doh/family-filter/"
        DoHServerAddress = "185.228.168.9"
    }
}

# Create backup
function New-DNSBackup {
    [CmdletBinding()]
    param()

    try {
        Write-Log "Creating DNS configuration backup..." "Yellow"

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = Join-Path $BackupDir "dns_backup_$timestamp"
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

        # Backup current DNS settings
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        $dnsSettings = @()

        foreach ($adapter in $adapters) {
            $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex
            $dnsSettings += @{
                InterfaceIndex = $adapter.InterfaceIndex
                InterfaceName = $adapter.Name
                IPv4DNS = $dns | Where-Object { $_.AddressFamily -eq 2 } | Select-Object -ExpandProperty ServerAddresses
                IPv6DNS = $dns | Where-Object { $_.AddressFamily -eq 23 } | Select-Object -ExpandProperty ServerAddresses
            }
        }

        $dnsSettings | ConvertTo-Json -Depth 3 -Compress | Out-File (Join-Path $backupPath "dns_settings.json")

        # Backup hosts file
        $hostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
        if (Test-Path $hostsPath) {
            Copy-Item $hostsPath (Join-Path $backupPath "hosts.backup")
        }

        Write-Log "Backup created: $backupPath" "Green"
        return $backupPath
    }
    catch {
        Write-Log "Failed to create backup: $($_.Exception.Message)" "Red"
        throw
    }
}

# Restore backup
function Restore-DNSBackup {
    [CmdletBinding()]
    param()

    try {
        $backups = Get-ChildItem -Path $BackupDir -Directory | Sort-Object CreationTime -Descending

        if ($backups.Count -eq 0) {
            Write-Log "No backups found" "Yellow"
            return
        }

        Write-Host "Available backups:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $backups.Count; $i++) {
            Write-Host "[$($i+1)] $($backups[$i].Name)" -ForegroundColor White
        }

        $choice = Read-Host "Select backup to restore (1-$($backups.Count))"

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $backups.Count) {
            $selectedBackup = $backups[[int]$choice - 1]
            $backupFile = Join-Path $selectedBackup.FullName "dns_settings.json"

            if (Test-Path $backupFile) {
                $dnsSettings = Get-Content $backupFile | ConvertFrom-Json

                foreach ($setting in $dnsSettings) {
                    if ($setting.IPv4DNS) {
                        Set-DnsClientServerAddress -InterfaceIndex $setting.InterfaceIndex -ServerAddresses $setting.IPv4DNS
                    }
                    if ($setting.IPv6DNS) {
                        Set-DnsClientServerAddress -InterfaceIndex $setting.InterfaceIndex -ServerAddresses $setting.IPv6DNS
                    }
                }

                Write-Log "DNS settings restored from backup: $($selectedBackup.Name)" "Green"
                Clear-DnsClientCache
                Write-Log "DNS cache cleared" "Green"
            }
        }
    }
    catch {
        Write-Log "Failed to restore backup: $($_.Exception.Message)" "Red"
        throw
    }
}

# Configure DNS servers
function Set-DNSProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("1", "2", "3", "4", "5", "6")]
        [string]$ProviderId
    )

    try {
        $provider = $DNSProviders[$ProviderId]
        if (-not $provider) {
            Write-Log "Invalid provider ID" "Red"
            return
        }

        Write-Log "Configuring DNS provider: $($provider.Name)" "Yellow"

        # Create backup first
        $backupPath = New-DNSBackup
        if (-not $backupPath) {
            Write-Log "Failed to create backup. Aborting." "Red"
            return
        }

        # Get active network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

        foreach ($adapter in $adapters) {
            Write-Log "Configuring adapter: $($adapter.Name)" "Cyan"

            # Set IPv4 DNS
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @($provider.Primary, $provider.Secondary)

            # Set IPv6 DNS if available
            if ($provider.IPv6Primary) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @($provider.IPv6Primary, $provider.IPv6Secondary)
            }
        }

        # Clear DNS cache
        Clear-DnsClientCache
        Write-Log "DNS cache cleared" "Green"

        # Test DNS resolution
        Write-Log "Testing DNS resolution..." "Yellow"
        $testResults = @()
        $testDomains = @("google.com", "cloudflare.com", "github.com")

        foreach ($domain in $testDomains) {
            try {
                $result = Resolve-DnsName -Name $domain -Type A -ErrorAction Stop
                $testResults += "✓ $domain resolved to $($result[0].IPAddress)"
            }
            catch {
                $testResults += "✗ $domain failed to resolve"
            }
        }

        Write-Log "DNS Test Results:" "Cyan"
        foreach ($result in $testResults) {
            Write-Log "  $result" "White"
        }

        Write-Log "DNS provider configured successfully: $($provider.Name)" "Green"
    }
    catch {
        Write-Log "Failed to configure DNS: $($_.Exception.Message)" "Red"
        Write-Log "Attempting to restore from backup..." "Yellow"
        Restore-DNSBackup
        throw
    }
}

# Configure DNS over HTTPS (requires Windows 10 version 2004+)
function Enable-DoH {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DoHURL,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DoHServerAddress
    )

    try {
        Write-Log "Configuring DNS over HTTPS..." "Yellow"

        # Check Windows version
        $version = [System.Environment]::OSVersion.Version
        if ($version.Build -lt 19041) {
            Write-Log "DNS over HTTPS requires Windows 10 version 2004 or later" "Red"
            return
        }

        # Enable DoH
        Set-DnsClientDohServerAddress -ServerAddress $DoHServerAddress -DohTemplate $DoHURL -AllowFallbackToUdp $true
        Write-Log "DNS over HTTPS configured: $DoHURL" "Green"
    }
    catch {
        Write-Log "Failed to configure DNS over HTTPS: $($_.Exception.Message)" "Red"
        throw
    }
}

# Show current DNS status
function Show-DNSStatus {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Current DNS Configuration:" -ForegroundColor Cyan
        Write-Host "=========================" -ForegroundColor Cyan

        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

        foreach ($adapter in $adapters) {
            Write-Host "`nAdapter: $($adapter.Name)" -ForegroundColor Yellow

            $dns = Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex

            $ipv4DNS = $dns | Where-Object { $_.AddressFamily -eq 2 } | Select-Object -ExpandProperty ServerAddresses
            $ipv6DNS = $dns | Where-Object { $_.AddressFamily -eq 23 } | Select-Object -ExpandProperty ServerAddresses

            if ($ipv4DNS) {
                Write-Host "  IPv4 DNS: $($ipv4DNS -join ', ')" -ForegroundColor White
            }
            if ($ipv6DNS) {
                Write-Host "  IPv6 DNS: $($ipv6DNS -join ', ')" -ForegroundColor White
            }
        }

        # Show DoH status
        try {
            $dohSettings = Get-DnsClientDohServerAddress
            if ($dohSettings) {
                Write-Host "`nDNS over HTTPS:" -ForegroundColor Yellow
                foreach ($setting in $dohSettings) {
                    Write-Host "  Server: $($setting.ServerAddress)" -ForegroundColor White
                    Write-Host "  Template: $($setting.DohTemplate)" -ForegroundColor White
                }
            }
        }
        catch {
            Write-Host "`nDNS over HTTPS: Not configured" -ForegroundColor Gray
        }
    }
    catch {
        Write-Log "Failed to show DNS status: $($_.Exception.Message)" "Red"
        throw
    }
}

# Flush DNS and test
function Test-DNSConfiguration {
    [CmdletBinding()]
    param()

    try {
        Write-Log "Flushing DNS cache and testing configuration..." "Yellow"

        # Flush DNS cache
        Clear-DnsClientCache
        ipconfig /flushdns | Out-Null

        # Test DNS resolution speed
        $testDomains = @("google.com", "cloudflare.com", "github.com", "microsoft.com")

        Write-Host "`nDNS Resolution Test:" -ForegroundColor Cyan
        Write-Host "===================" -ForegroundColor Cyan

        foreach ($domain in $testDomains) {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $result = Resolve-DnsName -Name $domain -Type A -ErrorAction Stop
                $stopwatch.Stop()
                $ip = $result[0].IPAddress
                $time = $stopwatch.ElapsedMilliseconds
                Write-Host "✓ $domain -> $ip ($time ms)" -ForegroundColor Green
            }
            catch {
                $stopwatch.Stop()
                Write-Host "✗ $domain -> Failed" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Log "Failed to test DNS configuration: $($_.Exception.Message)" "Red"
        throw
    }
}

# Main menu
function Show-Menu {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nDNS Security Menu:" -ForegroundColor Green
        Write-Host "==================" -ForegroundColor Green
        Write-Host "[1] Show current DNS status" -ForegroundColor White
        Write-Host "[2] Configure DNS provider" -ForegroundColor White
        Write-Host "[3] Enable DNS over HTTPS" -ForegroundColor White
        Write-Host "[4] Test DNS configuration" -ForegroundColor White
        Write-Host "[5] Create backup" -ForegroundColor White
        Write-Host "[6] Restore from backup" -ForegroundColor White
        Write-Host "[7] Reset to automatic DNS" -ForegroundColor White
        Write-Host "[0] Exit" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Log "Failed to show menu: $($_.Exception.Message)" "Red"
        throw
    }
}

# Show provider menu
function Show-ProviderMenu {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nAvailable DNS Providers:" -ForegroundColor Cyan
        Write-Host "========================" -ForegroundColor Cyan

        foreach ($key in $DNSProviders.Keys | Sort-Object) {
            $provider = $DNSProviders[$key]
            Write-Host "[$key] $($provider.Name)" -ForegroundColor White
            Write-Host "    Primary: $($provider.Primary), Secondary: $($provider.Secondary)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    catch {
        Write-Log "Failed to show provider menu: $($_.Exception.Message)" "Red"
        throw
    }
}

# Reset DNS to automatic
function Reset-DNSToAutomatic {
    [CmdletBinding()]
    param()

    try {
        Write-Log "Resetting DNS to automatic (DHCP)..." "Yellow"

        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
        }

        Clear-DnsClientCache
        Write-Log "DNS reset to automatic configuration" "Green"
    }
    catch {
        Write-Log "Failed to reset DNS: $($_.Exception.Message)" "Red"
        throw
    }
}

# Help function
function Show-Help {
    [CmdletBinding()]
    param()

    try {
        Write-Host @"
DNS Security Setup Tool - Windows PowerShell

SYNOPSIS
    DNS security and privacy configuration tool for Windows

DESCRIPTION
    This tool helps configure secure DNS settings including:
    - Multiple DNS provider options
    - DNS over HTTPS (DoH) support
    - Backup and restore functionality
    - DNS performance testing

PARAMETERS
    -Help       Show this help message
    -Status     Show current DNS configuration
    -Backup     Create backup of current settings
    -Restore    Restore from backup

EXAMPLES
    .\dns_security_setup.ps1
    .\dns_security_setup.ps1 -Status
    .\dns_security_setup.ps1 -Backup

REQUIREMENTS
    - Windows 10/11
    - Administrator privileges
    - PowerShell 5.0 or later

DNS PROVIDERS
    1. Cloudflare - Privacy-focused (1.1.1.1)
    2. Quad9 - Security-focused (9.9.9.9)
    3. OpenDNS - Content filtering (208.67.222.222)
    4. Google - Fast and reliable (8.8.8.8)
    5. AdGuard - Ad blocking (94.140.14.14)
    6. CleanBrowsing - Family safe (185.228.168.9)

NOTES
    - Creates automatic backups before changes
    - Supports both IPv4 and IPv6 DNS
    - DNS over HTTPS requires Windows 10 version 2004+
    - Use only for legitimate purposes

"@
    }
    catch {
        Write-Log "Failed to show help: $($_.Exception.Message)" "Red"
        throw
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Show-Banner

if ($Status) {
    Show-DNSStatus
    exit 0
}

if ($Backup) {
    New-DNSBackup
    exit 0
}

if ($Restore) {
    Restore-DNSBackup
    exit 0
}

if ($Provider) {
    Set-DNSProvider -ProviderId $Provider
    exit 0
}

# Main interactive loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (0-7)"
    
    switch ($choice) {
        "1" {
            Show-DNSStatus
            Read-Host "Press Enter to continue"
        }
        "2" {
            Show-ProviderMenu
            $providerId = Read-Host "Select DNS provider (1-6)"
            if ($DNSProviders.ContainsKey($providerId)) {
                $confirm = Read-Host "Configure $($DNSProviders[$providerId].Name)? (y/N)"
                if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                    Set-DNSProvider $providerId
                }
            } else {
                Write-Log "Invalid provider selection" "Red"
            }
            Read-Host "Press Enter to continue"
        }
        "3" {
            Show-ProviderMenu
            $providerId = Read-Host "Select provider for DoH (1-6)"
            if ($DNSProviders.ContainsKey($providerId)) {
                Enable-DoH $DNSProviders[$providerId].DoH $DNSProviders[$providerId].DoHServerAddress
            } else {
                Write-Log "Invalid provider selection" "Red"
            }
            Read-Host "Press Enter to continue"
        }
        "4" {
            Test-DNSConfiguration
            Read-Host "Press Enter to continue"
        }
        "5" {
            New-DNSBackup
            Read-Host "Press Enter to continue"
        }
        "6" {
            Restore-DNSBackup
            Read-Host "Press Enter to continue"
        }
        "7" {
            $confirm = Read-Host "Reset DNS to automatic? This will remove custom DNS settings. (y/N)"
            if ($confirm -eq 'y' -or $confirm -eq 'Y') {
                Reset-DNSToAutomatic
            }
            Read-Host "Press Enter to continue"
        }
        "0" {
            Write-Log "Goodbye!" "Green"
            exit 0
        }
        default {
            Write-Log "Invalid choice!" "Red"
            Read-Host "Press Enter to continue"
        }
    }
}
