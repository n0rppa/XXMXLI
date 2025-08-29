# Network Monitor - Windows PowerShell # Banner
function Show-Banner {
    Write-Host ""
    Write-Host " ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗" -ForegroundColor Cyan
    Write-Host " ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝" -ForegroundColor Cyan
    Write-Host " ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ " -ForegroundColor Cyan
    Write-Host " ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ " -ForegroundColor Cyan
    Write-Host " ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗" -ForegroundColor Cyan
    Write-Host " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║" -ForegroundColor Cyan
    Write-Host "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║" -ForegroundColor Cyan
    Write-Host " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Network Monitor - Windows PowerShell" -ForegroundColor Green
    Write-Host "    Network Traffic Analysis and Monitoring Tool" -ForegroundColor Green
    Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
    Write-Host ""
}rk Traffic Monitoring and Security Analysis
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

param(
    [switch]$Help,
    [switch]$Status,
    [switch]$Connections,
    [string]$Interface
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Configuration
$ConfigDir = "$env:USERPROFILE\.network_monitor"
$LogDir = "$ConfigDir\logs"
$LogFile = "$LogDir\network_monitor.log"
$AlertThresholdConnections = 100
$ScanInterval = 5

# Create directories
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

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
    Write-Host " ███╗   ██╗███████╗████████╗███╗   ███╗ ██████╗ ███╗   ██╗" -ForegroundColor Cyan
    Write-Host " ████╗  ██║██╔════╝╚══██╔══╝████╗ ████║██╔═══██╗████╗  ██║" -ForegroundColor Cyan
    Write-Host " ██╔██╗ ██║█████╗     ██║   ██╔████╔██║██║   ██║██╔██╗ ██║" -ForegroundColor Cyan
    Write-Host " ██║╚██╗██║██╔══╝     ██║   ██║╚██╔╝██║██║   ██║██║╚██╗██║" -ForegroundColor Cyan
    Write-Host " ██║ ╚████║███████╗   ██║   ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Network Monitor - Windows PowerShell" -ForegroundColor Green
    Write-Host "    Network Traffic Monitoring and Security Analysis" -ForegroundColor Green
    Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
    Write-Host ""
}

# Get network interfaces
function Get-NetworkInterfaces {
    Write-Host "Available Network Interfaces:" -ForegroundColor Cyan
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    
    for ($i = 0; $i -lt $adapters.Count; $i++) {
        $adapter = $adapters[$i]
        Write-Host "[$($i+1)] $($adapter.Name) - $($adapter.InterfaceDescription)" -ForegroundColor White
        Write-Host "    Status: $($adapter.Status) | Speed: $($adapter.LinkSpeed)" -ForegroundColor Gray
    }
    
    return $adapters
}

# Monitor network connections
function Watch-NetworkConnections {
    Write-Log "Starting network connection monitoring..." "Yellow"
    
    try {
        while ($true) {
            Clear-Host
            Show-Banner
            
            Write-Host "Network Connection Monitoring - $(Get-Date)" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            
            # Get listening ports
            Write-Host "`nListening Ports:" -ForegroundColor Yellow
            $listening = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" } | Select-Object LocalAddress, LocalPort, OwningProcess | Sort-Object LocalPort | Select-Object -First 15
            
            foreach ($conn in $listening) {
                try {
                    $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                    $processName = if ($process) { $process.ProcessName } else { "Unknown" }
                    Write-Host "  $($conn.LocalAddress):$($conn.LocalPort) - $processName" -ForegroundColor White
                }
                catch {
                    Write-Host "  $($conn.LocalAddress):$($conn.LocalPort) - System" -ForegroundColor White
                }
            }
            
            # Get established connections
            Write-Host "`nEstablished Connections:" -ForegroundColor Yellow
            $established = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" } | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess | Sort-Object RemoteAddress | Select-Object -First 15
            
            foreach ($conn in $established) {
                try {
                    $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                    $processName = if ($process) { $process.ProcessName } else { "Unknown" }
                    Write-Host "  $($conn.LocalAddress):$($conn.LocalPort) -> $($conn.RemoteAddress):$($conn.RemotePort) [$processName]" -ForegroundColor White
                }
                catch {
                    Write-Host "  $($conn.LocalAddress):$($conn.LocalPort) -> $($conn.RemoteAddress):$($conn.RemotePort) [System]" -ForegroundColor White
                }
            }
            
            # Connection count alert
            $totalConnections = (Get-NetTCPConnection | Where-Object { $_.State -eq "Established" }).Count
            Write-Host "`nTotal Established Connections: $totalConnections" -ForegroundColor White
            
            if ($totalConnections -gt $AlertThresholdConnections) {
                Write-Host "⚠️ HIGH CONNECTION COUNT ALERT: $totalConnections connections" -ForegroundColor Red
                Write-Log "High connection count alert: $totalConnections connections" "Red"
            }
            
            Write-Host "`nPress Ctrl+C to return to menu" -ForegroundColor Magenta
            Start-Sleep -Seconds $ScanInterval
        }
    }
    catch {
        Write-Log "Connection monitoring stopped" "Yellow"
    }
}

# Monitor bandwidth usage
function Watch-NetworkBandwidth {
    Write-Log "Starting bandwidth monitoring..." "Yellow"
    
    $adapters = Get-NetworkInterfaces
    Write-Host "`nSelect interface for monitoring:"
    $choice = Read-Host "Enter interface number"
    
    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $adapters.Count) {
        $selectedAdapter = $adapters[[int]$choice - 1]
        Write-Log "Monitoring bandwidth on: $($selectedAdapter.Name)" "Green"
        
        try {
            $previousStats = Get-NetAdapterStatistics -Name $selectedAdapter.Name
            
            while ($true) {
                Start-Sleep -Seconds $ScanInterval
                Clear-Host
                Show-Banner
                
                Write-Host "Bandwidth Monitoring - $($selectedAdapter.Name)" -ForegroundColor Cyan
                Write-Host "===============================================" -ForegroundColor Cyan
                
                $currentStats = Get-NetAdapterStatistics -Name $selectedAdapter.Name
                
                # Calculate bandwidth
                $timeDiff = $ScanInterval
                $bytesSentDiff = $currentStats.BytesSent - $previousStats.BytesSent
                $bytesReceivedDiff = $currentStats.BytesReceived - $previousStats.BytesReceived
                
                $sendSpeedBps = $bytesSentDiff / $timeDiff
                $receiveSpeedBps = $bytesReceivedDiff / $timeDiff
                
                $sendSpeedKbps = [math]::Round($sendSpeedBps / 1024, 2)
                $receiveSpeedKbps = [math]::Round($receiveSpeedBps / 1024, 2)
                
                Write-Host "`nCurrent Bandwidth Usage:" -ForegroundColor Yellow
                Write-Host "Upload Speed: $sendSpeedKbps KB/s" -ForegroundColor Green
                Write-Host "Download Speed: $receiveSpeedKbps KB/s" -ForegroundColor Green
                
                Write-Host "`nTotal Statistics:" -ForegroundColor Yellow
                Write-Host "Bytes Sent: $($currentStats.BytesSent)" -ForegroundColor White
                Write-Host "Bytes Received: $($currentStats.BytesReceived)" -ForegroundColor White
                Write-Host "Packets Sent: $($currentStats.PacketsSent)" -ForegroundColor White
                Write-Host "Packets Received: $($currentStats.PacketsReceived)" -ForegroundColor White
                
                if ($currentStats.PacketsOutboundErrors -gt 0 -or $currentStats.PacketsInboundErrors -gt 0) {
                    Write-Host "`nErrors Detected:" -ForegroundColor Red
                    Write-Host "Outbound Errors: $($currentStats.PacketsOutboundErrors)" -ForegroundColor Red
                    Write-Host "Inbound Errors: $($currentStats.PacketsInboundErrors)" -ForegroundColor Red
                }
                
                Write-Host "`nPress Ctrl+C to return to menu" -ForegroundColor Magenta
                $previousStats = $currentStats
            }
        }
        catch {
            Write-Log "Bandwidth monitoring stopped" "Yellow"
        }
    }
}

# Network scan
function Start-NetworkScan {
    Write-Log "Starting network scan..." "Yellow"
    
    # Get local network range
    $networkConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -and $_.IPv4DefaultGateway }
    
    if ($networkConfig) {
        $ipAddress = $networkConfig.IPv4Address.IPAddress
        $prefixLength = $networkConfig.IPv4Address.PrefixLength
        
        # Calculate network range
        $ipBytes = [System.Net.IPAddress]::Parse($ipAddress).GetAddressBytes()
        $maskBytes = [BitConverter]::GetBytes([UInt32]([Math]::Pow(2, 32) - [Math]::Pow(2, 32 - $prefixLength)))
        [Array]::Reverse($maskBytes)
        
        $networkBytes = @()
        for ($i = 0; $i -lt 4; $i++) {
            $networkBytes += $ipBytes[$i] -band $maskBytes[$i]
        }
        
        $networkAddress = $networkBytes -join '.'
        $networkRange = "$networkAddress/$prefixLength"
        
        Write-Host "Scanning network range: $networkRange" -ForegroundColor Cyan
        Write-Host "This may take a few minutes..." -ForegroundColor Yellow
        
        # Ping sweep
        $baseIP = $networkBytes[0..2] -join '.'
        $liveHosts = @()
        
        1..254 | ForEach-Object -Parallel {
            $ip = "$using:baseIP.$_"
            if (Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 1) {
                $ip
            }
        } -ThrottleLimit 50 | ForEach-Object {
            $liveHosts += $_
            Write-Host "✓ Found host: $_" -ForegroundColor Green
        }
        
        Write-Host "`nScan completed. Found $($liveHosts.Count) live hosts:" -ForegroundColor Cyan
        foreach ($host in $liveHosts) {
            try {
                $hostname = [System.Net.Dns]::GetHostEntry($host).HostName
                Write-Host "  $host - $hostname" -ForegroundColor White
            }
            catch {
                Write-Host "  $host - Unknown hostname" -ForegroundColor Gray
            }
        }
    }
    else {
        Write-Host "Could not determine network range" -ForegroundColor Red
    }
}

# Monitor processes network usage
function Watch-ProcessNetworkUsage {
    Write-Log "Starting process network usage monitoring..." "Yellow"
    
    try {
        while ($true) {
            Clear-Host
            Show-Banner
            
            Write-Host "Process Network Usage - $(Get-Date)" -ForegroundColor Cyan
            Write-Host "=====================================" -ForegroundColor Cyan
            
            # Get network connections with process info
            $connections = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" }
            $processStats = @{}
            
            foreach ($conn in $connections) {
                try {
                    $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                    if ($process) {
                        $processName = $process.ProcessName
                        if ($processStats.ContainsKey($processName)) {
                            $processStats[$processName]++
                        }
                        else {
                            $processStats[$processName] = 1
                        }
                    }
                }
                catch {
                    # Skip system processes
                }
            }
            
            Write-Host "`nTop Network-Active Processes:" -ForegroundColor Yellow
            $sortedProcesses = $processStats.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15
            
            foreach ($proc in $sortedProcesses) {
                Write-Host "  $($proc.Name): $($proc.Value) connections" -ForegroundColor White
            }
            
            # Show network adapters status
            Write-Host "`nNetwork Adapters:" -ForegroundColor Yellow
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            foreach ($adapter in $adapters) {
                $stats = Get-NetAdapterStatistics -Name $adapter.Name
                $mbSent = [math]::Round($stats.BytesSent / 1MB, 2)
                $mbReceived = [math]::Round($stats.BytesReceived / 1MB, 2)
                Write-Host "  $($adapter.Name): Sent $mbSent MB, Received $mbReceived MB" -ForegroundColor White
            }
            
            Write-Host "`nPress Ctrl+C to return to menu" -ForegroundColor Magenta
            Start-Sleep -Seconds $ScanInterval
        }
    }
    catch {
        Write-Log "Process monitoring stopped" "Yellow"
    }
}

# Generate network report
function New-NetworkReport {
    Write-Log "Generating network report..." "Yellow"
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = "$LogDir\network_report_$timestamp.html"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Network Report - $timestamp</title>
    <style>
        body { font-family: 'Courier New', monospace; background: #000; color: #00ff00; margin: 20px; }
        h1, h2 { color: #00ff00; border-bottom: 1px solid #00ff00; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #00ff00; padding: 8px; text-align: left; }
        th { background: #003300; }
        .warning { color: #ff4444; }
        .info { color: #00ccff; }
    </style>
</head>
<body>
    <h1>Network Security Report</h1>
    <p>Generated: $(Get-Date)</p>
    <p>Computer: $env:COMPUTERNAME</p>
    
    <h2>Network Interfaces</h2>
    <table>
        <tr><th>Name</th><th>Status</th><th>Speed</th><th>Description</th></tr>
"@
    
    $adapters = Get-NetAdapter
    foreach ($adapter in $adapters) {
        $html += "<tr><td>$($adapter.Name)</td><td>$($adapter.Status)</td><td>$($adapter.LinkSpeed)</td><td>$($adapter.InterfaceDescription)</td></tr>"
    }
    
    $html += @"
    </table>
    
    <h2>Listening Ports</h2>
    <table>
        <tr><th>Address</th><th>Port</th><th>Process</th></tr>
"@
    
    $listening = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" }
    foreach ($conn in $listening) {
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "System" }
            $html += "<tr><td>$($conn.LocalAddress)</td><td>$($conn.LocalPort)</td><td>$processName</td></tr>"
        }
        catch {
            $html += "<tr><td>$($conn.LocalAddress)</td><td>$($conn.LocalPort)</td><td>System</td></tr>"
        }
    }
    
    $html += @"
    </table>
    
    <h2>Established Connections</h2>
    <table>
        <tr><th>Local</th><th>Remote</th><th>Process</th></tr>
"@
    
    $established = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" } | Select-Object -First 50
    foreach ($conn in $established) {
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "System" }
            $html += "<tr><td>$($conn.LocalAddress):$($conn.LocalPort)</td><td>$($conn.RemoteAddress):$($conn.RemotePort)</td><td>$processName</td></tr>"
        }
        catch {
            $html += "<tr><td>$($conn.LocalAddress):$($conn.LocalPort)</td><td>$($conn.RemoteAddress):$($conn.RemotePort)</td><td>System</td></tr>"
        }
    }
    
    $html += @"
    </table>
    
    <h2>Firewall Status</h2>
    <table>
        <tr><th>Profile</th><th>Status</th><th>Inbound</th><th>Outbound</th></tr>
"@
    
    $firewallProfiles = Get-NetFirewallProfile
    foreach ($profile in $firewallProfiles) {
        $html += "<tr><td>$($profile.Name)</td><td>$($profile.Enabled)</td><td>$($profile.DefaultInboundAction)</td><td>$($profile.DefaultOutboundAction)</td></tr>"
    }
    
    $html += @"
    </table>
    
    <h2>Network Statistics</h2>
    <table>
        <tr><th>Adapter</th><th>Bytes Sent</th><th>Bytes Received</th><th>Packets Sent</th><th>Packets Received</th></tr>
"@
    
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        $stats = Get-NetAdapterStatistics -Name $adapter.Name
        $html += "<tr><td>$($adapter.Name)</td><td>$($stats.BytesSent)</td><td>$($stats.BytesReceived)</td><td>$($stats.PacketsSent)</td><td>$($stats.PacketsReceived)</td></tr>"
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    $html | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Log "Report saved to: $reportFile" "Green"
    
    # Open report
    $openReport = Read-Host "Open report in browser? (y/N)"
    if ($openReport -eq 'y' -or $openReport -eq 'Y') {
        Start-Process $reportFile
    }
}

# Show network status
function Show-NetworkStatus {
    Write-Host "Network Status Summary:" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    
    # Network adapters
    Write-Host "`nNetwork Adapters:" -ForegroundColor Yellow
    $adapters = Get-NetAdapter
    foreach ($adapter in $adapters) {
        $color = if ($adapter.Status -eq "Up") { "Green" } else { "Gray" }
        Write-Host "  $($adapter.Name): $($adapter.Status)" -ForegroundColor $color
    }
    
    # Connection counts
    Write-Host "`nConnection Summary:" -ForegroundColor Yellow
    $established = (Get-NetTCPConnection | Where-Object { $_.State -eq "Established" }).Count
    $listening = (Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" }).Count
    Write-Host "  Established: $established" -ForegroundColor White
    Write-Host "  Listening: $listening" -ForegroundColor White
    
    # Firewall status
    Write-Host "`nFirewall Status:" -ForegroundColor Yellow
    $profiles = Get-NetFirewallProfile
    foreach ($profile in $profiles) {
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "  $($profile.Name): $($profile.Enabled)" -ForegroundColor $color
    }
}

# Show menu
function Show-Menu {
    Write-Host "`nNetwork Monitoring Menu:" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host "[1] Show network status" -ForegroundColor White
    Write-Host "[2] Monitor connections" -ForegroundColor White
    Write-Host "[3] Monitor bandwidth" -ForegroundColor White
    Write-Host "[4] Monitor process usage" -ForegroundColor White
    Write-Host "[5] Network scan" -ForegroundColor White
    Write-Host "[6] Generate report" -ForegroundColor White
    Write-Host "[7] View network interfaces" -ForegroundColor White
    Write-Host "[0] Exit" -ForegroundColor White
    Write-Host ""
}

# Help function
function Show-Help {
    Write-Host @"
Network Monitor - Windows PowerShell

SYNOPSIS
    Network traffic monitoring and security analysis tool

DESCRIPTION
    This tool provides comprehensive network monitoring including:
    - Real-time connection monitoring
    - Bandwidth usage tracking
    - Process network usage analysis
    - Network scanning capabilities
    - Security report generation

PARAMETERS
    -Help          Show this help message
    -Status        Show current network status
    -Connections   Monitor active connections
    -Interface     Specify interface for monitoring

EXAMPLES
    .\network_monitor.ps1
    .\network_monitor.ps1 -Status
    .\network_monitor.ps1 -Connections

REQUIREMENTS
    - Windows 10/11 or Windows Server
    - Administrator privileges
    - PowerShell 5.0 or later

FEATURES
    - Real-time connection monitoring
    - Bandwidth usage tracking
    - Network device discovery
    - Process network analysis
    - HTML report generation
    - Firewall status monitoring

NOTES
    - Requires administrator privileges
    - Monitor system performance during intensive scans
    - Use only for legitimate network administration
    - Reports are saved in HTML format

"@
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Show-Banner

if ($Status) {
    Show-NetworkStatus
    exit 0
}

if ($Connections) {
    Watch-NetworkConnections
    exit 0
}

# Main interactive loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (0-7)"
    
    switch ($choice) {
        "1" {
            Show-NetworkStatus
            Read-Host "Press Enter to continue"
        }
        "2" {
            Watch-NetworkConnections
        }
        "3" {
            Watch-NetworkBandwidth
        }
        "4" {
            Watch-ProcessNetworkUsage
        }
        "5" {
            Start-NetworkScan
            Read-Host "Press Enter to continue"
        }
        "6" {
            New-NetworkReport
            Read-Host "Press Enter to continue"
        }
        "7" {
            Get-NetworkInterfaces
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
