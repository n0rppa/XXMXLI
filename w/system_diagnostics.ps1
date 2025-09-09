# XXMXLI Windows System Information and Diagnostics
# Comprehensive system analysis and security reporting

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI System Information and Security Diagnostics" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""

function Show-Menu {
    Write-Host "System Information and Diagnostics Options:" -ForegroundColor Cyan
    Write-Host "  1. System overview and specifications"
    Write-Host "  2. Security configuration status"
    Write-Host "  3. Network configuration and security"
    Write-Host "  4. Installed software audit"
    Write-Host "  5. Running processes and services"
    Write-Host "  6. Event log security analysis"
    Write-Host "  7. Generate comprehensive report"
    Write-Host "  8. Export findings to file"
    Write-Host "  9. Exit"
    Write-Host ""
}

function Get-SystemOverview {
    Write-Host "System Overview and Specifications:" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
    
    # Basic system information
    $computerInfo = Get-ComputerInfo
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $memory = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    
    Write-Host ""
    Write-Host "Computer Name: $($computerInfo.CsName)" -ForegroundColor Cyan
    Write-Host "Domain/Workgroup: $($computerInfo.CsDomain)"
    Write-Host "OS: $($os.Caption) $($os.Version)"
    Write-Host "Architecture: $($os.OSArchitecture)"
    Write-Host "Install Date: $($os.InstallDate)"
    Write-Host "Last Boot: $($os.LastBootUpTime)"
    Write-Host "CPU: $($cpu.Name)"
    Write-Host "CPU Cores: $($cpu.NumberOfCores)"
    Write-Host "Total RAM: $([math]::Round($memory.Sum / 1GB, 2)) GB"
    Write-Host "Current User: $($env:USERNAME)"
    Write-Host "User Domain: $($env:USERDOMAIN)"
    Write-Host ""
    
    # Windows features status
    Write-Host "Windows Features Status:" -ForegroundColor Cyan
    $features = @(
        @{Name="Windows Defender"; Service="WinDefend"},
        @{Name="Windows Firewall"; Service="MpsSvc"},
        @{Name="Windows Update"; Service="wuauserv"},
        @{Name="Remote Desktop"; Registry="HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"; Value="fDenyTSConnections"}
    )
    
    foreach ($feature in $features) {
        if ($feature.Service) {
            $service = Get-Service -Name $feature.Service -ErrorAction SilentlyContinue
            if ($service) {
                $status = $service.Status
                $color = if ($status -eq "Running") { "Green" } else { "Red" }
                Write-Host "  $($feature.Name): $status" -ForegroundColor $color
            }
        } elseif ($feature.Registry) {
            try {
                $regValue = Get-ItemProperty -Path $feature.Registry -Name $feature.Value -ErrorAction SilentlyContinue
                $rdpStatus = if ($regValue.($feature.Value) -eq 0) { "Enabled" } else { "Disabled" }
                $color = if ($rdpStatus -eq "Disabled") { "Green" } else { "Yellow" }
                Write-Host "  $($feature.Name): $rdpStatus" -ForegroundColor $color
            } catch {
                Write-Host "  $($feature.Name): Unable to check" -ForegroundColor Yellow
            }
        }
    }
}

function Get-SecurityStatus {
    Write-Host "Security Configuration Status:" -ForegroundColor Yellow
    Write-Host "=============================" -ForegroundColor Yellow
    Write-Host ""
    
    # UAC Status
    try {
        $uacStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -ErrorAction SilentlyContinue
        $uacEnabled = $uacStatus.EnableLUA -eq 1
        Write-Host "User Account Control: $(if ($uacEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($uacEnabled) { "Green" } else { "Red" })
    } catch {
        Write-Host "User Account Control: Unable to check" -ForegroundColor Yellow
    }
    
    # Windows Defender status
    try {
        $defenderStatus = Get-MpComputerStatus
        Write-Host "Windows Defender Real-time Protection: $(if ($defenderStatus.RealTimeProtectionEnabled) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($defenderStatus.RealTimeProtectionEnabled) { "Green" } else { "Red" })
        Write-Host "Windows Defender Signatures: Last updated $($defenderStatus.AntivirusSignatureLastUpdated)"
    } catch {
        Write-Host "Windows Defender: Unable to check status" -ForegroundColor Yellow
    }
    
    # Firewall status
    try {
        $firewallProfiles = Get-NetFirewallProfile
        Write-Host ""
        Write-Host "Firewall Profiles:" -ForegroundColor Cyan
        foreach ($profile in $firewallProfiles) {
            $status = if ($profile.Enabled) { "Enabled" } else { "Disabled" }
            $color = if ($profile.Enabled) { "Green" } else { "Red" }
            Write-Host "  $($profile.Name): $status" -ForegroundColor $color
        }
    } catch {
        Write-Host "Firewall: Unable to check status" -ForegroundColor Yellow
    }
    
    # BitLocker status
    Write-Host ""
    Write-Host "BitLocker Status:" -ForegroundColor Cyan
    try {
        $bitLockerVolumes = Get-BitLockerVolume
        foreach ($volume in $bitLockerVolumes) {
            $status = $volume.ProtectionStatus
            $color = if ($status -eq "On") { "Green" } elseif ($status -eq "Off") { "Red" } else { "Yellow" }
            Write-Host "  Drive $($volume.MountPoint): $status" -ForegroundColor $color
        }
    } catch {
        Write-Host "  BitLocker: Not available or unable to check" -ForegroundColor Yellow
    }
    
    # Password policy
    Write-Host ""
    Write-Host "Password Policy:" -ForegroundColor Cyan
    try {
        $secPolicy = net accounts
        Write-Host "  $($secPolicy -join "`n  ")"
    } catch {
        Write-Host "  Unable to retrieve password policy" -ForegroundColor Yellow
    }
}

function Get-NetworkSecurity {
    Write-Host "Network Configuration and Security:" -ForegroundColor Yellow
    Write-Host "==================================" -ForegroundColor Yellow
    Write-Host ""
    
    # Network adapters
    Write-Host "Network Adapters:" -ForegroundColor Cyan
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    foreach ($adapter in $adapters) {
        Write-Host "  $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Green
        
        # Get IP configuration
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
        foreach ($ip in $ipConfig) {
            if ($ip.AddressFamily -eq "IPv4") {
                Write-Host "    IPv4: $($ip.IPAddress)/$($ip.PrefixLength)" -ForegroundColor Cyan
            }
        }
    }
    
    # Active network connections
    Write-Host ""
    Write-Host "Active Network Connections (listening ports):" -ForegroundColor Cyan
    $connections = Get-NetTCPConnection | Where-Object { $_.State -eq "Listen" } | Select-Object LocalAddress, LocalPort, OwningProcess | Sort-Object LocalPort
    
    foreach ($conn in $connections[0..19]) {  # Show first 20
        try {
            $process = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            $processName = if ($process) { $process.ProcessName } else { "Unknown" }
            Write-Host "  $($conn.LocalAddress):$($conn.LocalPort) - $processName (PID: $($conn.OwningProcess))"
        } catch {
            Write-Host "  $($conn.LocalAddress):$($conn.LocalPort) - Unknown process"
        }
    }
    
    if ($connections.Count -gt 20) {
        Write-Host "  ... and $($connections.Count - 20) more connections" -ForegroundColor Yellow
    }
    
    # DNS configuration
    Write-Host ""
    Write-Host "DNS Configuration:" -ForegroundColor Cyan
    $dnsServers = Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 -and $_.ServerAddresses }
    foreach ($dns in $dnsServers) {
        Write-Host "  Interface: $($dns.InterfaceAlias)"
        Write-Host "    DNS Servers: $($dns.ServerAddresses -join ', ')"
    }
}

function Get-InstalledSoftware {
    Write-Host "Installed Software Audit:" -ForegroundColor Yellow
    Write-Host "========================" -ForegroundColor Yellow
    Write-Host ""
    
    # Get installed programs from registry
    $software = @()
    
    # 64-bit programs
    $software += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, EstimatedSize
    
    # 32-bit programs on 64-bit systems
    if ([Environment]::Is64BitOperatingSystem) {
        $software += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, EstimatedSize
    }
    
    # Remove duplicates and sort
    $uniqueSoftware = $software | Sort-Object DisplayName -Unique | Sort-Object DisplayName
    
    Write-Host "Total installed programs: $($uniqueSoftware.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    # Show potentially risky software
    $riskyKeywords = @("Remote", "VNC", "TeamViewer", "AnyDesk", "Telnet", "FTP", "Torrent", "P2P")
    $riskySoftware = $uniqueSoftware | Where-Object { 
        $name = $_.DisplayName
        $riskyKeywords | ForEach-Object { if ($name -like "*$_*") { return $true } }
    }
    
    if ($riskySoftware) {
        Write-Host "Potentially risky software found:" -ForegroundColor Red
        foreach ($risky in $riskySoftware) {
            Write-Host "  ⚠️  $($risky.DisplayName) - $($risky.Publisher)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    # Show recently installed software (last 30 days)
    $recentSoftware = $uniqueSoftware | Where-Object { 
        $_.InstallDate -and 
        [datetime]::ParseExact($_.InstallDate, "yyyyMMdd", $null) -gt (Get-Date).AddDays(-30)
    } | Sort-Object InstallDate -Descending
    
    if ($recentSoftware) {
        Write-Host "Recently installed software (last 30 days):" -ForegroundColor Cyan
        foreach ($recent in $recentSoftware[0..9]) {  # Show first 10
            $installDate = [datetime]::ParseExact($recent.InstallDate, "yyyyMMdd", $null).ToString("yyyy-MM-dd")
            Write-Host "  $installDate - $($recent.DisplayName)" -ForegroundColor Green
        }
    }
}

function Get-ProcessesAndServices {
    Write-Host "Running Processes and Services Analysis:" -ForegroundColor Yellow
    Write-Host "=======================================" -ForegroundColor Yellow
    Write-Host ""
    
    # High CPU/Memory processes
    Write-Host "Top 10 CPU/Memory consuming processes:" -ForegroundColor Cyan
    $processes = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
    foreach ($proc in $processes) {
        $cpu = if ($proc.CPU) { [math]::Round($proc.CPU, 2) } else { 0 }
        $memory = [math]::Round($proc.WorkingSet / 1MB, 2)
        Write-Host "  $($proc.Name) (PID: $($proc.Id)) - CPU: $cpu s, Memory: $memory MB"
    }
    
    # Suspicious processes (common malware names)
    Write-Host ""
    Write-Host "Checking for suspicious process names:" -ForegroundColor Cyan
    $suspiciousNames = @("svchost", "csrss", "winlogon", "explorer") # These are normal but often mimicked
    $allProcesses = Get-Process
    
    foreach ($suspName in $suspiciousNames) {
        $matchingProcs = $allProcesses | Where-Object { $_.Name -like "$suspName*" }
        if ($matchingProcs.Count -gt 1) {
            Write-Host "  Multiple $suspName processes found ($($matchingProcs.Count)) - investigate if unusual" -ForegroundColor Yellow
        }
    }
    
    # Services analysis
    Write-Host ""
    Write-Host "Critical Services Status:" -ForegroundColor Cyan
    $criticalServices = @("Winmgmt", "EventLog", "PlugPlay", "RpcSs", "Dhcp", "Dnscache", "MpsSvc", "WinDefend")
    
    foreach ($serviceName in $criticalServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            $color = if ($service.Status -eq "Running") { "Green" } else { "Red" }
            Write-Host "  $($service.DisplayName): $($service.Status)" -ForegroundColor $color
        }
    }
    
    # Stopped services that should be running
    Write-Host ""
    Write-Host "Important stopped services:" -ForegroundColor Yellow
    $stoppedCritical = Get-Service | Where-Object { 
        $_.Status -eq "Stopped" -and 
        $criticalServices -contains $_.Name 
    }
    
    foreach ($stopped in $stoppedCritical) {
        Write-Host "  ⚠️  $($stopped.DisplayName) is stopped" -ForegroundColor Red
    }
}

function Get-EventLogAnalysis {
    Write-Host "Event Log Security Analysis:" -ForegroundColor Yellow
    Write-Host "============================" -ForegroundColor Yellow
    Write-Host ""
    
    # Security event analysis (last 24 hours)
    $yesterday = (Get-Date).AddDays(-1)
    
    Write-Host "Security Events (last 24 hours):" -ForegroundColor Cyan
    
    try {
        # Failed logon attempts
        $failedLogons = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625; StartTime=$yesterday} -ErrorAction SilentlyContinue
        if ($failedLogons) {
            Write-Host "  Failed logon attempts: $($failedLogons.Count)" -ForegroundColor $(if ($failedLogons.Count -gt 10) { "Red" } else { "Yellow" })
            
            # Group by user account
            $failedByUser = $failedLogons | ForEach-Object {
                [xml]$xml = $_.ToXml()
                $xml.Event.EventData.Data | Where-Object { $_.Name -eq "TargetUserName" } | Select-Object -ExpandProperty '#text'
            } | Group-Object | Sort-Object Count -Descending
            
            foreach ($user in $failedByUser[0..4]) {  # Top 5
                Write-Host "    $($user.Name): $($user.Count) attempts" -ForegroundColor Red
            }
        } else {
            Write-Host "  Failed logon attempts: 0" -ForegroundColor Green
        }
        
        # Successful logons
        $successfulLogons = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4624; StartTime=$yesterday} -ErrorAction SilentlyContinue
        if ($successfulLogons) {
            Write-Host "  Successful logons: $($successfulLogons.Count)" -ForegroundColor Green
        }
        
        # Account lockouts
        $lockouts = Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4740; StartTime=$yesterday} -ErrorAction SilentlyContinue
        if ($lockouts) {
            Write-Host "  Account lockouts: $($lockouts.Count)" -ForegroundColor Red
        } else {
            Write-Host "  Account lockouts: 0" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  Unable to access Security event log" -ForegroundColor Yellow
    }
    
    # System event analysis
    Write-Host ""
    Write-Host "System Events (last 24 hours):" -ForegroundColor Cyan
    
    try {
        $systemErrors = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=$yesterday} -ErrorAction SilentlyContinue
        if ($systemErrors) {
            Write-Host "  System errors/critical: $($systemErrors.Count)" -ForegroundColor $(if ($systemErrors.Count -gt 5) { "Red" } else { "Yellow" })
            
            # Show most common errors
            $errorGroups = $systemErrors | Group-Object Id | Sort-Object Count -Descending
            foreach ($error in $errorGroups[0..2]) {  # Top 3
                $sample = $systemErrors | Where-Object { $_.Id -eq $error.Name } | Select-Object -First 1
                Write-Host "    Event ID $($error.Name): $($error.Count) occurrences - $($sample.LevelDisplayName)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  System errors/critical: 0" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  Unable to access System event log" -ForegroundColor Yellow
    }
}

function Generate-ComprehensiveReport {
    Write-Host "Generating Comprehensive Security Report..." -ForegroundColor Yellow
    Write-Host ""
    
    $reportData = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
        User = $env:USERNAME
        SystemInfo = @{}
        SecurityStatus = @{}
        NetworkInfo = @{}
        Recommendations = @()
    }
    
    # Collect system information
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $reportData.SystemInfo = @{
            OS = $os.Caption
            Version = $os.Version
            LastBoot = $os.LastBootUpTime
            Architecture = $os.OSArchitecture
        }
    } catch {
        $reportData.SystemInfo.Error = "Unable to collect system information"
    }
    
    # Security status checks
    $securityChecks = @(
        @{Name="UAC"; Path="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"; Value="EnableLUA"; Expected=1},
        @{Name="WindowsDefender"; Service="WinDefend"},
        @{Name="Firewall"; Service="MpsSvc"},
        @{Name="RemoteDesktop"; Path="HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"; Value="fDenyTSConnections"; Expected=1}
    )
    
    foreach ($check in $securityChecks) {
        try {
            if ($check.Service) {
                $service = Get-Service -Name $check.Service -ErrorAction SilentlyContinue
                $status = if ($service -and $service.Status -eq "Running") { "OK" } else { "FAIL" }
            } else {
                $regValue = Get-ItemProperty -Path $check.Path -Name $check.Value -ErrorAction SilentlyContinue
                $status = if ($regValue -and $regValue.($check.Value) -eq $check.Expected) { "OK" } else { "FAIL" }
            }
            $reportData.SecurityStatus[$check.Name] = $status
        } catch {
            $reportData.SecurityStatus[$check.Name] = "ERROR"
        }
    }
    
    # Generate recommendations
    foreach ($checkName in $reportData.SecurityStatus.Keys) {
        if ($reportData.SecurityStatus[$checkName] -eq "FAIL") {
            switch ($checkName) {
                "UAC" { $reportData.Recommendations += "Enable User Account Control (UAC)" }
                "WindowsDefender" { $reportData.Recommendations += "Start Windows Defender service" }
                "Firewall" { $reportData.Recommendations += "Enable Windows Firewall" }
                "RemoteDesktop" { $reportData.Recommendations += "Consider disabling Remote Desktop if not needed" }
            }
        }
    }
    
    # Display summary
    Write-Host "Security Report Summary:" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    Write-Host "Computer: $($reportData.ComputerName)"
    Write-Host "Generated: $($reportData.Timestamp)"
    Write-Host ""
    
    Write-Host "Security Status:" -ForegroundColor Yellow
    foreach ($status in $reportData.SecurityStatus.GetEnumerator()) {
        $color = switch ($status.Value) {
            "OK" { "Green" }
            "FAIL" { "Red" }
            "ERROR" { "Yellow" }
        }
        Write-Host "  $($status.Key): $($status.Value)" -ForegroundColor $color
    }
    
    if ($reportData.Recommendations.Count -gt 0) {
        Write-Host ""
        Write-Host "Recommendations:" -ForegroundColor Yellow
        foreach ($rec in $reportData.Recommendations) {
            Write-Host "  • $rec" -ForegroundColor Red
        }
    }
    
    return $reportData
}

function Export-Findings {
    param($ReportData = $null)
    
    if (-not $ReportData) {
        Write-Host "Generating fresh report data..." -ForegroundColor Yellow
        $ReportData = Generate-ComprehensiveReport
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $reportFile = Join-Path $ScriptDir "XXMXLI_Security_Report_$timestamp.txt"
    $jsonFile = Join-Path $ScriptDir "XXMXLI_Security_Report_$timestamp.json"
    
    # Export as human-readable text
    $textReport = @"
================================================================
XXMXLI SECURITY REPORT
================================================================
Generated: $($ReportData.Timestamp)
Computer: $($ReportData.ComputerName)
User: $($ReportData.User)

SYSTEM INFORMATION:
OS: $($ReportData.SystemInfo.OS)
Version: $($ReportData.SystemInfo.Version)
Architecture: $($ReportData.SystemInfo.Architecture)
Last Boot: $($ReportData.SystemInfo.LastBoot)

SECURITY STATUS:
"@
    
    foreach ($status in $ReportData.SecurityStatus.GetEnumerator()) {
        $textReport += "`n$($status.Key): $($status.Value)"
    }
    
    if ($ReportData.Recommendations.Count -gt 0) {
        $textReport += "`n`nRECOMMENDATIONS:"
        foreach ($rec in $ReportData.Recommendations) {
            $textReport += "`n• $rec"
        }
    }
    
    $textReport += "`n`nReport generated by XXMXLI Security Suite"
    $textReport += "`nFor more information, visit the XXMXLI documentation"
    
    try {
        $textReport | Out-File -FilePath $reportFile -Encoding UTF8
        $ReportData | ConvertTo-Json -Depth 3 | Out-File -FilePath $jsonFile -Encoding UTF8
        
        Write-Host "✓ Reports exported successfully:" -ForegroundColor Green
        Write-Host "  Text report: $reportFile" -ForegroundColor Cyan
        Write-Host "  JSON report: $jsonFile" -ForegroundColor Cyan
        
    } catch {
        Write-Host "✗ Error exporting reports: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main loop
$reportData = $null

do {
    Show-Menu
    $choice = Read-Host "Select option (1-9)"
    
    switch ($choice) {
        "1" { Get-SystemOverview }
        "2" { Get-SecurityStatus }
        "3" { Get-NetworkSecurity }
        "4" { Get-InstalledSoftware }
        "5" { Get-ProcessesAndServices }
        "6" { Get-EventLogAnalysis }
        "7" { $reportData = Generate-ComprehensiveReport }
        "8" { Export-Findings -ReportData $reportData }
        "9" { 
            Write-Host "Thank you for using XXMXLI System Diagnostics" -ForegroundColor Blue
            break 
        }
        default { 
            Write-Host "Invalid choice. Please select 1-9." -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "9") {
        Write-Host ""
        Read-Host "Press Enter to continue"
        Clear-Host
    }
    
} while ($choice -ne "9")
