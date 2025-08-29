# DNS Security Setup Tool - Windows P# Banner
function Show-Banner {
    Write-Host ""
    Write-Host " ██████╗ ███╗   ██╗███████╗    ███████╗███████╗ ██████╗" -ForegroundColor Cyan
    Write-Host " ██╔══██╗████╗  ██║██╔════╝    ██╔════╝██╔════╝██╔════╝" -ForegroundColor Cyan
    Write-Host " ██║  ██║██╔██╗ ██║███████╗    ███████╗█████╗  ██║     " -ForegroundColor Cyan
    Write-Host " ██║  ██║██║╚██╗██║╚════██║    ╚════██║██╔══╝  ██║     " -ForegroundColor Cyan
    Write-Host " ██████╔╝██║ ╚████║███████║    ███████║███████╗╚██████╗" -ForegroundColor Cyan
    Write-Host " ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝╚══════╝ ╚═════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗" -ForegroundColor Cyan
    Write-Host " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║" -ForegroundColor Cyan
    Write-Host "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║" -ForegroundColor Cyan
    Write-Host " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    DNS Security Setup - Windows PowerShell" -ForegroundColor Green
    Write-Host "    DNS-over-HTTPS/TLS Configuration Tool" -ForegroundColor Green
    Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
    Write-Host ""
}on
# Comprehensive DNS Security and Privacy Configuration
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

param(
    [switch]$Help,
    [switch]$Status,
    [switch]$Backup,
    [switch]$Restore
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Configuration
$ConfigDir = "$env:USERPROFILE\.dns_security"
$BackupDir = "$ConfigDir\backups"
$LogFile = "$ConfigDir\dns_security.log"

# Create directories
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
if (!(Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

# Logging function
function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logEntry
}

# Banner
function Show-Banner {
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

# DNS Provider configurations
$DNSProviders = @{
    "1" = @{
        Name = "Cloudflare (Privacy-focused)"
        Primary = "1.1.1.1"
        Secondary = "1.0.0.1"
        IPv6Primary = "2606:4700:4700::1111"
        IPv6Secondary = "2606:4700:4700::1001"
        DoH = "https://cloudflare-dns.com/dns-query"
    }
    "2" = @{
        Name = "Quad9 (Security-focused)"
        Primary = "9.9.9.9"
        Secondary = "149.112.112.112"
        IPv6Primary = "2620:fe::fe"
        IPv6Secondary = "2620:fe::9"
        DoH = "https://dns.quad9.net/dns-query"
    }
    "3" = @{
        Name = "OpenDNS (Content filtering)"
        Primary = "208.67.222.222"
        Secondary = "208.67.220.220"
        IPv6Primary = "2620:119:35::35"
        IPv6Secondary = "2620:119:53::53"
        DoH = "https://doh.opendns.com/dns-query"
    }
    "4" = @{
        Name = "Google (Fast, reliable)"
        Primary = "8.8.8.8"
        Secondary = "8.8.4.4"
        IPv6Primary = "2001:4860:4860::8888"
        IPv6Secondary = "2001:4860:4860::8844"
        DoH = "https://dns.google/dns-query"
    }
    "5" = @{
        Name = "AdGuard (Ad blocking)"
        Primary = "94.140.14.14"
        Secondary = "94.140.15.15"
        IPv6Primary = "2a10:50c0::ad1:ff"
        IPv6Secondary = "2a10:50c0::ad2:ff"
        DoH = "https://dns.adguard.com/dns-query"
    }
    "6" = @{
        Name = "CleanBrowsing (Family safe)"
        Primary = "185.228.168.9"
        Secondary = "185.228.169.9"
        IPv6Primary = "2a0d:2a00:1::2"
        IPv6Secondary = "2a0d:2a00:2::2"
        DoH = "https://doh.cleanbrowsing.org/doh/family-filter/"
    }
}

# Create backup
function New-DNSBackup {
    Write-Log "Creating DNS configuration backup..." "Yellow"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$BackupDir\dns_backup_$timestamp"
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # Backup current DNS settings
    try {
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
        
        $dnsSettings | ConvertTo-Json -Depth 3 | Out-File "$backupPath\dns_settings.json"
        
        # Backup hosts file
        if (Test-Path "$env:SystemRoot\System32\drivers\etc\hosts") {
            Copy-Item "$env:SystemRoot\System32\drivers\etc\hosts" "$backupPath\hosts.backup"
        }
        
        Write-Log "Backup created: $backupPath" "Green"
        return $backupPath
    }
    catch {
        Write-Log "Failed to create backup: $($_.Exception.Message)" "Red"
        return $null
    }
}

# Restore backup
function Restore-DNSBackup {
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
        $backupFile = "$($selectedBackup.FullName)\dns_settings.json"
        
        if (Test-Path $backupFile) {
            try {
                $dnsSettings = Get-Content $backupFile | ConvertFrom-Json
                
                foreach ($setting in $dnsSettings) {
                    if ($setting.IPv4DNS) {
                        Set-DnsClientServerAddress -InterfaceIndex $setting.InterfaceIndex -ServerAddresses $setting.IPv4DNS
                    }
                    if ($setting.IPv6DNS) {
                        Set-DnsClientServerAddress -InterfaceIndex $setting.InterfaceIndex -ServerAddresses $setting.IPv6DNS -AddressFamily IPv6
                    }
                }
                
                Write-Log "DNS settings restored from backup: $($selectedBackup.Name)" "Green"
                Clear-DnsClientCache
                Write-Log "DNS cache cleared" "Green"
            }
            catch {
                Write-Log "Failed to restore backup: $($_.Exception.Message)" "Red"
            }
        }
    }
}

# Configure DNS servers
function Set-DNSProvider {
    param($ProviderId)
    
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
    
    try {
        # Get active network adapters
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $adapters) {
            Write-Log "Configuring adapter: $($adapter.Name)" "Cyan"
            
            # Set IPv4 DNS
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @($provider.Primary, $provider.Secondary)
            
            # Set IPv6 DNS if available
            if ($provider.IPv6Primary) {
                Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses @($provider.IPv6Primary, $provider.IPv6Secondary) -AddressFamily IPv6
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
    }
}

# Configure DNS over HTTPS (requires Windows 10 version 2004+)
function Enable-DoH {
    param($DoHURL)
    
    Write-Log "Configuring DNS over HTTPS..." "Yellow"
    
    try {
        # Check Windows version
        $version = [System.Environment]::OSVersion.Version
        if ($version.Build -lt 19041) {
            Write-Log "DNS over HTTPS requires Windows 10 version 2004 or later" "Red"
            return
        }
        
        # Enable DoH
        Set-DnsClientDohServerAddress -ServerAddress $DoHURL -DohTemplate $DoHURL -AllowFallbackToUdp $true
        Write-Log "DNS over HTTPS configured: $DoHURL" "Green"
    }
    catch {
        Write-Log "Failed to configure DNS over HTTPS: $($_.Exception.Message)" "Red"
    }
}

# Show current DNS status
function Show-DNSStatus {
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

# Flush DNS and test
function Test-DNSConfiguration {
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

# Main menu
function Show-Menu {
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

# Show provider menu
function Show-ProviderMenu {
    Write-Host "`nAvailable DNS Providers:" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    foreach ($key in $DNSProviders.Keys | Sort-Object) {
        $provider = $DNSProviders[$key]
        Write-Host "[$key] $($provider.Name)" -ForegroundColor White
        Write-Host "    Primary: $($provider.Primary), Secondary: $($provider.Secondary)" -ForegroundColor Gray
    }
    Write-Host ""
}

# Reset DNS to automatic
function Reset-DNSToAutomatic {
    Write-Log "Resetting DNS to automatic (DHCP)..." "Yellow"
    
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
        }
        
        Clear-DnsClientCache
        Write-Log "DNS reset to automatic configuration" "Green"
    }
    catch {
        Write-Log "Failed to reset DNS: $($_.Exception.Message)" "Red"
    }
}

# Help function
function Show-Help {
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
                Enable-DoH $DNSProviders[$providerId].DoH
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
