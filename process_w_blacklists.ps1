# XXMXLI IP Blacklist Processor for Windows PowerShell
# Processes IP blacklist files and generates Windows-compatible blocking rules
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
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceDir = "w",
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDir = (Join-Path "assets" "security"),
    
    [switch]$GenerateFirewallRules,
    [switch]$GenerateHostsFile,
    [switch]$Verbose
)

Write-Host "=== XXMXLI IP Blacklist Processor (Windows) ===" -ForegroundColor Green
Write-Host "Processing blacklists from: $SourceDir" -ForegroundColor Yellow

# Create output directory if it doesn't exist
try {
    if (!(Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Host "Created output directory: $OutputDir" -ForegroundColor Green
    }
}
catch {
    Write-Host "Failed to create output directory: $_" -ForegroundColor Red
    exit 1
}

# Initialize variables
$AllIPs = @()
$Statistics = @{
    "processed_files" = 0
    "total_ips" = 0
    "unique_ips" = 0
    "sources" = @{}
    "timestamp" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    "platform" = "Windows PowerShell"
}

try {
    # Process all blacklist files
    if (Test-Path $SourceDir) {
        $BlacklistFiles = Get-ChildItem -Path $SourceDir -Recurse -File | Where-Object {
            $_.Extension -in @('.txt', '.list', '.ipset', '.csv', '.dat', '.conf') -or $_.Extension -eq ''
        }
        
        foreach ($File in $BlacklistFiles) {
            $FileIPs = Process-BlacklistFile $File.FullName
            $AllIPs += $FileIPs
            $Statistics.processed_files++
        }
    }
    else {
        Write-Host "❌ Source directory '$SourceDir' not found!" -ForegroundColor Red
        exit 1
    }

    # Remove duplicates and process results
    $UniqueIPs = $AllIPs | Sort-Object | Get-Unique
    $Statistics.total_ips = $AllIPs.Count
    $Statistics.unique_ips = $UniqueIPs.Count

    Write-Host ""
    Write-Host "=== Processing Results ===" -ForegroundColor Green
    Write-Host "Files processed: $($Statistics.processed_files)" -ForegroundColor Yellow
    Write-Host "Total IPs found: $($Statistics.total_ips)" -ForegroundColor Yellow
    Write-Host "Unique IPs: $($Statistics.unique_ips)" -ForegroundColor Yellow
}
catch {
    Write-Host "Error during blacklist processing: $_" -ForegroundColor Red
    exit 1
}

# Initialize variables
$AllIPs = @()
$Statistics = @{
    "processed_files" = 0
    "total_ips" = 0
    "unique_ips" = 0
    "sources" = @{}
    "timestamp" = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    "platform" = "Windows PowerShell"
}

# Function to validate IP address
function Test-IPAddress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$IP
    )
    
    try {
        [System.Net.IPAddress]::Parse($IP) | Out-Null
        return $true
    }
    catch {
        Write-Host "Invalid IP address format: $IP" -ForegroundColor Red
        return $false
    }
}

# Function to process individual blacklist file
function Process-BlacklistFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )
    
    $FileIPs = @()
    $FileName = Split-Path $FilePath -Leaf
    
    try {
        if ($Verbose) {
            Write-Host "  Processing: $FileName" -ForegroundColor Cyan
        }
        
        $Content = Get-Content $FilePath -ErrorAction Stop
        $ValidIPs = 0
        
        foreach ($Line in $Content) {
            # Skip comments and empty lines
            if ($Line -match '^\s*#' -or $Line -match '^\s*$') {
                continue
            }
            
            # Extract IP addresses using regex
            $IPMatches = [regex]::Matches($Line, '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b')
            
            foreach ($Match in $IPMatches) {
                $IP = $Match.Value
                if (Test-IPAddress $IP) {
                    $FileIPs += $IP
                    $ValidIPs++
                }
            }
        }
        
        $Statistics.sources[$FileName] = @{
            "file_path" = $FilePath
            "ip_count" = $ValidIPs
            "file_size" = (Get-Item $FilePath).Length
        }
        
        if ($Verbose) {
            Write-Host "    Found $ValidIPs valid IPs" -ForegroundColor Green
        }
        
        return $FileIPs
    }
    catch {
        Write-Host "    Error processing $FileName`: $_" -ForegroundColor Red
        return @()
    }
}

# Process all blacklist files
if (Test-Path $SourceDir) {
    $BlacklistFiles = Get-ChildItem -Path $SourceDir -Recurse -File | Where-Object {
        $_.Extension -in @('.txt', '.list', '.ipset', '.csv', '.dat', '.conf') -or $_.Extension -eq ''
    }
    
    foreach ($File in $BlacklistFiles) {
        $FileIPs = Process-BlacklistFile $File.FullName
        $AllIPs += $FileIPs
        $Statistics.processed_files++
    }
}
else {
    Write-Host "❌ Source directory '$SourceDir' not found!" -ForegroundColor Red
    exit 1
}

# Remove duplicates and process results
$UniqueIPs = $AllIPs | Sort-Object | Get-Unique
$Statistics.total_ips = $AllIPs.Count
$Statistics.unique_ips = $UniqueIPs.Count

Write-Host ""
Write-Host "=== Processing Results ===" -ForegroundColor Green
Write-Host "Files processed: $($Statistics.processed_files)" -ForegroundColor Yellow
Write-Host "Total IPs found: $($Statistics.total_ips)" -ForegroundColor Yellow
Write-Host "Unique IPs: $($Statistics.unique_ips)" -ForegroundColor Yellow

# Generate JavaScript file for web protection
try {
    $JSContent = @"
// XXMXLI Blocked IPs - Generated $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
// Platform: Windows PowerShell
// Total blocked IPs: $($Statistics.unique_ips)

const blockedIPs = [
$($UniqueIPs | ForEach-Object { "    '$_'," })
];

// Function to check if an IP is blocked
function isIPBlocked(ip) {
    return blockedIPs.includes(ip);
}

// Function to get blocked IP count
function getBlockedIPCount() {
    return blockedIPs.length;
}

// Export for use in web applications
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { blockedIPs, isIPBlocked, getBlockedIPCount };
}
"@

    $JSOutput = Join-Path $OutputDir "blocked_ips.js"
    $JSContent | Out-File -FilePath $JSOutput -Encoding UTF8
    Write-Host "✅ JavaScript file created: $JSOutput" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create JavaScript file: $_" -ForegroundColor Red
}

# Generate JSON file
try {
    $JSONOutput = Join-Path $OutputDir "blocked_ips.json"
    @{
        "blocked_ips" = $UniqueIPs
        "statistics" = $Statistics
    } | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $JSONOutput -Encoding UTF8
    Write-Host "✅ JSON file created: $JSONOutput" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create JSON file: $_" -ForegroundColor Red
}

# Generate statistics file
try {
    $StatsOutput = Join-Path $OutputDir "blacklist_stats.json"
    $Statistics | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath $StatsOutput -Encoding UTF8
    Write-Host "✅ Statistics file created: $StatsOutput" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create statistics file: $_" -ForegroundColor Red
}

# Generate Windows Firewall rules if requested
if ($GenerateFirewallRules) {
    Write-Host ""
    Write-Host "=== Generating Windows Firewall Rules ===" -ForegroundColor Green
    
    try {
        $FirewallScript = Join-Path $OutputDir "apply_firewall_rules.ps1"
        $FirewallContent = @"
# XXMXLI IP Blacklist - Windows Firewall Rules
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Run as Administrator

Write-Host "Applying XXMXLI IP blacklist to Windows Firewall..." -ForegroundColor Green

# Remove existing XXMXLI rules
Get-NetFirewallRule -DisplayName "XXMXLI-Block-*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# Add new blocking rules (in batches to avoid rule limits)
`$BlockedIPs = @(
$($UniqueIPs | ForEach-Object { "    '$_'," })
)

`$BatchSize = 100
`$BatchCount = 0

for (`$i = 0; `$i -lt `$BlockedIPs.Count; `$i += `$BatchSize) {
    `$BatchCount++
    `$Batch = `$BlockedIPs[`$i..([Math]::Min(`$i + `$BatchSize - 1, `$BlockedIPs.Count - 1))]
    `$RuleName = "XXMXLI-Block-Batch-`$BatchCount"
    
    Write-Host "Creating rule: `$RuleName (IPs: `$(`$Batch.Count))" -ForegroundColor Yellow
    
    New-NetFirewallRule -DisplayName `$RuleName -Direction Inbound -Action Block -RemoteAddress `$Batch -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "`$RuleName-Out" -Direction Outbound -Action Block -RemoteAddress `$Batch -ErrorAction SilentlyContinue
}

Write-Host "✅ Firewall rules applied successfully!" -ForegroundColor Green
Write-Host "Total rules created: `$(`$BatchCount * 2)" -ForegroundColor Yellow
"@
        
        $FirewallContent | Out-File -FilePath $FirewallScript -Encoding UTF8
        Write-Host "✅ Firewall rules script created: $FirewallScript" -ForegroundColor Green
        Write-Host "   Run as Administrator to apply firewall rules" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Failed to generate firewall rules: $_" -ForegroundColor Red
    }
}

# Generate hosts file entries if requested
if ($GenerateHostsFile) {
    Write-Host ""
    Write-Host "=== Generating Hosts File Entries ===" -ForegroundColor Green
    
    try {
        $HostsOutput = Join-Path $OutputDir "hosts_blacklist.txt"
        $HostsContent = @"
# XXMXLI IP Blacklist for Windows Hosts File
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Total blocked IPs: $($Statistics.unique_ips)
#
# To apply these entries:
# 1. Run Notepad as Administrator
# 2. Open C:\Windows\System32\drivers\etc\hosts
# 3. Append the content below to the file
# 4. Save the file

"@
        
        foreach ($IP in $UniqueIPs) {
            $HostsContent += "`n127.0.0.1 $IP"
        }
        
        $HostsContent | Out-File -FilePath $HostsOutput -Encoding UTF8
        Write-Host "✅ Hosts file entries created: $HostsOutput" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to generate hosts file entries: $_" -ForegroundColor Red
    }
}

# Generate batch file wrapper
try {
    $BatchOutput = Join-Path $OutputDir "run_blacklist_processor.bat"
    $BatchContent = @"
@echo off
REM XXMXLI IP Blacklist Processor - Windows Batch Wrapper
REM Run this file to process blacklists with default settings

echo === XXMXLI IP Blacklist Processor ===
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: PowerShell not found. Please install PowerShell.
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "process_w_blacklists.ps1" -Verbose

echo.
echo Processing complete! Check the assets/security folder for generated files.
pause
"@

    $BatchContent | Out-File -FilePath $BatchOutput -Encoding UTF8
    Write-Host "✅ Batch wrapper created: $BatchOutput" -ForegroundColor Green
}
catch {
    Write-Host "Failed to create batch wrapper: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== All Files Generated Successfully! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Usage Instructions:" -ForegroundColor Yellow
Write-Host "1. JavaScript/JSON files: Use in web applications" -ForegroundColor White
Write-Host "2. Firewall script: Run as Administrator to block IPs at network level" -ForegroundColor White
Write-Host "3. Hosts file: Append entries to system hosts file" -ForegroundColor White
Write-Host "4. Batch file: Double-click for easy execution" -ForegroundColor White
Write-Host ""
