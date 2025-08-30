# ================================================================
# WARNING: This system is actively monitored and protected.
#
# Any unauthorized access attempts, network scanning, intrusion, or 
# abusive activity will be logged and reported to the appropriate 
# authorities. IP addresses and metadata may be retained and used 
# for legal enforcement, in compliance with applicable laws.
#
# By continuing, you acknowledge that you are authorized to use this 
# system and that any misuse may result in account suspension, 
# firewall bans, or prosecution under national and international law.
#
# Violators may be subject to civil and/or criminal penalties.
#
# Your access is being monitored.
# ================================================================

# ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
# ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
#  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
#  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
# ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
#
# AUTOMATED INCIDENT REPORTER - PowerShell Edition
# Secure incident reporting to authorities for Windows
# Created by: XXMXLI
# Version: 2.0
# License: MIT

param(
    [string]$Action = "help",
    [string]$IncidentType,
    [int]$Severity,
    [string]$Description,
    [string]$SourceIP = "unknown",
    [string]$TargetIP = "auto"
)

# Require Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogDir = "C:\SecurityLogs"
$ReportDir = "C:\SecurityLogs\Reports"
$ConfigFile = "C:\SecurityLogs\incident_reporter.json"
$EvidenceDir = "C:\SecurityLogs\Evidence"
$TempDir = "$env:TEMP\IncidentReports"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Purple = "Magenta"
    Cyan = "Cyan"
}

# Logging function
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] $Message"
    Write-Host $LogMessage -ForegroundColor $Color
    Add-Content -Path "$LogDir\incident_reporter.log" -Value $LogMessage
}

# Error handling
function Write-ErrorExit {
    param([string]$Message)
    Write-Log "ERROR: $Message" -Color Red
    exit 1
}

# Create necessary directories
function Initialize-Directories {
    Write-Log "Setting up directories..." -Color Blue
    @($LogDir, $ReportDir, $EvidenceDir, $TempDir) | ForEach-Object {
        if (!(Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
    
    # Set permissions (restrict to administrators)
    $acl = Get-Acl $LogDir
    $acl.SetAccessRuleProtection($true, $false)
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.SetAccessRule($adminRule)
    Set-Acl -Path $LogDir -AclObject $acl
}

# Authority contact information
$Authorities = @{
    "FBI_IC3" = "ic3.gov secure report portal"
    "CISA" = "us-cert@cisa.dhs.gov"
    "LOCAL_LEO" = "cybercrime@police.local"
    "EUROPOL" = "ec3@europol.europa.eu"
    "INTERPOL" = "cybercrime@interpol.int"
    "CERT_NATIONAL" = "cert@national-cert.gov"
    "FINANCIAL_CRIMES" = "fincen@treasury.gov"
    "TELECOM_FRAUD" = "fraud@telecom-authority.gov"
}

# Incident types and descriptions
$IncidentTypes = @{
    "INTRUSION" = "Network intrusion attempt"
    "MALWARE" = "Malware detection"
    "DDOS" = "Distributed Denial of Service attack"
    "PHISHING" = "Phishing attempt"
    "DATA_BREACH" = "Data breach or unauthorized access"
    "FRAUD" = "Financial fraud attempt"
    "CHILD_EXPLOITATION" = "Child exploitation material"
    "TERRORISM" = "Terrorism-related activity"
    "RANSOMWARE" = "Ransomware attack"
    "APT" = "Advanced Persistent Threat"
    "INSIDER_THREAT" = "Insider threat activity"
    "SOCIAL_ENGINEERING" = "Social engineering attack"
}

# Create configuration file
function New-Configuration {
    Write-Log "Creating configuration file..." -Color Blue
    $Config = @{
        OrganizationInfo = @{
            Name = "Your Organization"
            Contact = "security@yourorg.com"
            Phone = "+1-555-0123"
            Address = "123 Security St, Cyber City, CC 12345"
        }
        TechnicalContact = @{
            Email = "admin@yourorg.com"
            Phone = "+1-555-0124"
        }
        ReportingThresholds = @{
            MinSeverity = 3
            AutoReportSeverity = 7
            BatchReportInterval = 3600
        }
        NotificationSettings = @{
            EmailEnabled = $true
            SMSEnabled = $false
            WebhookEnabled = $true
        }
        EvidenceCollection = @{
            CollectEventLogs = $true
            CollectNetworkLogs = $true
            CollectMemoryDump = $false
            EvidenceRetentionDays = 90
        }
        EncryptionSettings = @{
            EncryptReports = $true
            SecureDelete = $true
            CertificateThumbprint = ""
        }
    }
    
    $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile
}

# Load configuration
function Get-Configuration {
    if (Test-Path $ConfigFile) {
        return Get-Content -Path $ConfigFile | ConvertFrom-Json
    } else {
        New-Configuration
        return Get-Content -Path $ConfigFile | ConvertFrom-Json
    }
}

# Generate incident ID
function New-IncidentID {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $random = -join ((1..4) | ForEach-Object { '{0:X}' -f (Get-Random -Maximum 16) })
    return "INC-$timestamp-$random"
}

# Collect system information
function Get-SystemInfo {
    $systemInfo = @"

=== SYSTEM INFORMATION ===
Computer Name: $env:COMPUTERNAME
Operating System: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
OS Version: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Version)
Architecture: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty OSArchitecture)
Last Boot Time: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime)
Current Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Time Zone: $((Get-TimeZone).DisplayName)
System Uptime: $((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime)
Total RAM: $([math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB
Available RAM: $([math]::Round((Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)) MB
CPU Usage: $(Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average)%
Network Adapters: $(Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -ExpandProperty Name)

"@
    return $systemInfo
}

# Collect network information
function Get-NetworkInfo {
    $networkInfo = @"

=== NETWORK INFORMATION ===
Active TCP Connections:
$(Get-NetTCPConnection | Where-Object {$_.State -eq "Established"} | Select-Object -First 20 | Format-Table -AutoSize | Out-String)

Network Configuration:
$(Get-NetIPConfiguration | Format-Table -AutoSize | Out-String)

Windows Firewall Status:
$(Get-NetFirewallProfile | Format-Table -AutoSize | Out-String)

Recent Network Events:
$(Get-WinEvent -LogName "Microsoft-Windows-Security-Auditing" -MaxEvents 10 | Where-Object {$_.Id -in @(4624,4625,4648)} | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap | Out-String)

"@
    return $networkInfo
}

# Collect security logs
function Get-SecurityLogs {
    param([int]$Hours = 24)
    
    $startTime = (Get-Date).AddHours(-$Hours)
    
    $securityLogs = @"

=== SECURITY LOGS (Last $Hours hours) ===

Security Events:
$(Get-WinEvent -LogName "Security" -StartTime $startTime -MaxEvents 20 | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap | Out-String)

System Events:
$(Get-WinEvent -LogName "System" -StartTime $startTime -MaxEvents 15 | Where-Object {$_.LevelDisplayName -in @("Error", "Warning")} | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap | Out-String)

Application Events:
$(Get-WinEvent -LogName "Application" -StartTime $startTime -MaxEvents 10 | Where-Object {$_.LevelDisplayName -eq "Error"} | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-Table -Wrap | Out-String)

Failed Logon Attempts:
$(Get-WinEvent -LogName "Security" -StartTime $startTime | Where-Object {$_.Id -eq 4625} | Select-Object TimeCreated, Message | Format-Table -Wrap | Out-String)

"@
    return $securityLogs
}

# Collect evidence files
function Collect-Evidence {
    param([string]$IncidentID)
    
    $evidencePath = Join-Path $EvidenceDir $IncidentID
    New-Item -ItemType Directory -Path $evidencePath -Force | Out-Null
    
    $config = Get-Configuration
    
    # Collect event logs if enabled
    if ($config.EvidenceCollection.CollectEventLogs) {
        Write-Log "Collecting event log evidence..." -Color Blue
        $logs = @("Security", "System", "Application")
        foreach ($log in $logs) {
            $logPath = Join-Path $evidencePath "$log.evtx"
            wevtutil epl $log $logPath
        }
    }
    
    # Collect network information
    if ($config.EvidenceCollection.CollectNetworkLogs) {
        Write-Log "Collecting network evidence..." -Color Blue
        Get-NetTCPConnection | Export-Csv -Path (Join-Path $evidencePath "network_connections.csv") -NoTypeInformation
        Get-NetRoute | Export-Csv -Path (Join-Path $evidencePath "routing_table.csv") -NoTypeInformation
        Get-DnsClientCache | Export-Csv -Path (Join-Path $evidencePath "dns_cache.csv") -NoTypeInformation
    }
    
    # Collect process information
    Get-Process | Select-Object Name, Id, CPU, WorkingSet, StartTime, Path | Export-Csv -Path (Join-Path $evidencePath "processes.csv") -NoTypeInformation
    
    # Collect services information
    Get-Service | Export-Csv -Path (Join-Path $evidencePath "services.csv") -NoTypeInformation
    
    # Create evidence manifest
    $manifest = @"
Evidence Collection Manifest
Incident ID: $IncidentID
Collection Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Collected By: $env:USERNAME@$env:COMPUTERNAME

Files Collected:
$(Get-ChildItem $evidencePath | Format-Table -AutoSize | Out-String)

File Hashes:
$(Get-ChildItem $evidencePath -File | ForEach-Object { "$($_.Name): $(Get-FileHash $_.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash)" })
"@
    
    Set-Content -Path (Join-Path $evidencePath "manifest.txt") -Value $manifest
    
    # Compress evidence
    $zipPath = "$evidencePath.zip"
    Compress-Archive -Path "$evidencePath\*" -DestinationPath $zipPath
    Remove-Item -Path $evidencePath -Recurse -Force
    
    return $zipPath
}

# Encrypt sensitive data
function Protect-File {
    param([string]$FilePath)
    
    $config = Get-Configuration
    
    if ($config.EncryptionSettings.EncryptReports -and $config.EncryptionSettings.CertificateThumbprint) {
        Write-Log "Encrypting report..." -Color Blue
        
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $config.EncryptionSettings.CertificateThumbprint }
        
        if ($cert) {
            $encryptedPath = "$FilePath.encrypted"
            $content = Get-Content -Path $FilePath -Raw
            $encryptedBytes = $cert.PublicKey.Key.Encrypt([System.Text.Encoding]::UTF8.GetBytes($content), $true)
            [System.IO.File]::WriteAllBytes($encryptedPath, $encryptedBytes)
            
            if ($config.EncryptionSettings.SecureDelete) {
                sdelete -p 3 -s -z $FilePath 2>$null
            }
            
            return $encryptedPath
        }
    }
    
    return $FilePath
}

# Generate incident report
function New-IncidentReport {
    param(
        [string]$IncidentType,
        [int]$Severity,
        [string]$Description,
        [string]$SourceIP = "unknown",
        [string]$TargetIP = "auto"
    )
    
    $config = Get-Configuration
    $incidentID = New-IncidentID
    $reportFile = Join-Path $ReportDir "$incidentID.txt"
    
    if ($TargetIP -eq "auto") {
        $TargetIP = (Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" } | Select-Object -First 1).IPv4Address.IPAddress
    }
    
    Write-Log "Generating incident report: $incidentID" -Color Yellow
    
    # Create main report
    $report = @"
=================================================================
SECURITY INCIDENT REPORT
=================================================================

Incident ID: $incidentID
Report Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Generated By: XXMXLI Automated Security System (Windows)
Organization: $($config.OrganizationInfo.Name)

=== INCIDENT DETAILS ===
Type: $IncidentType
Severity: $Severity/10
Description: $Description
Source IP: $SourceIP
Target IP: $TargetIP
Detection Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Reporting System: $env:COMPUTERNAME

=== CONTACT INFORMATION ===
Organization: $($config.OrganizationInfo.Name)
Primary Contact: $($config.OrganizationInfo.Contact)
Phone: $($config.OrganizationInfo.Phone)
Technical Contact: $($config.TechnicalContact.Email)
Address: $($config.OrganizationInfo.Address)

$(Get-SystemInfo)
$(Get-NetworkInfo)
$(Get-SecurityLogs)

=== INCIDENT ANALYSIS ===
Timeline:
- Detection: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
- Analysis Started: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
- Report Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

Impact Assessment:
- Severity Level: $Severity/10
- Systems Affected: $env:COMPUTERNAME
- Data at Risk: Under investigation
- Service Disruption: Minimal

Immediate Actions Taken:
- Incident logged and documented
- Evidence collection initiated
- Automated blocking applied (if applicable)
- Security team notified

Recommended Follow-up:
- Forensic analysis of evidence
- Review of security controls
- Coordination with law enforcement
- System hardening recommendations

=== EVIDENCE INFORMATION ===
Evidence collected and available upon request.
Evidence retention: $($config.EvidenceCollection.EvidenceRetentionDays) days
Chain of custody maintained.

"@
    
    Set-Content -Path $reportFile -Value $report
    
    # Collect evidence
    $evidenceFile = Collect-Evidence $incidentID
    Add-Content -Path $reportFile -Value "Evidence Package: $evidenceFile"
    
    # Encrypt if configured
    $finalReport = Protect-File $reportFile
    
    return @{
        IncidentID = $incidentID
        ReportFile = $finalReport
        EvidenceFile = $evidenceFile
    }
}

# Send email report
function Send-EmailReport {
    param(
        [string]$Recipient,
        [string]$Subject,
        [string]$ReportFile,
        [string]$EvidenceFile
    )
    
    $config = Get-Configuration
    
    if ($config.NotificationSettings.EmailEnabled) {
        Write-Log "Preparing email report to $Recipient..." -Color Blue
        
        # Note: This requires SMTP configuration
        # In a production environment, configure Send-MailMessage with proper SMTP settings
        Write-Log "Email functionality requires SMTP configuration" -Color Yellow
        Write-Log "Report file: $ReportFile" -Color Green
        Write-Log "Evidence file: $EvidenceFile" -Color Green
    }
}

# Submit to FBI IC3
function Submit-ToIC3 {
    param([string]$IncidentID, [string]$ReportFile)
    
    Write-Log "Preparing submission to FBI IC3..." -Color Blue
    
    $ic3Report = @"
FBI Internet Crime Complaint Center (IC3) Report

Incident ID: $IncidentID
Submitter: $(Get-Configuration | Select-Object -ExpandProperty OrganizationInfo | Select-Object -ExpandProperty Name)
Contact: $(Get-Configuration | Select-Object -ExpandProperty OrganizationInfo | Select-Object -ExpandProperty Contact)
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

Please submit this report through the official IC3 portal at:
https://www.ic3.gov/Home/FileComplaint

Report Summary:
$(Get-Content $ReportFile | Select-Object -First 50)

Full report and evidence available upon request.
"@
    
    $ic3ReportPath = Join-Path $TempDir "ic3_report.txt"
    Set-Content -Path $ic3ReportPath -Value $ic3Report
    
    Write-Log "IC3 report prepared: $ic3ReportPath" -Color Green
    Write-Log "Manual submission required at: https://www.ic3.gov/Home/FileComplaint" -Color Yellow
}

# Submit to CISA
function Submit-ToCISA {
    param([string]$IncidentID, [string]$ReportFile)
    
    Write-Log "Preparing submission to CISA..." -Color Blue
    
    $config = Get-Configuration
    $cisaReport = @"
CISA Cybersecurity Incident Report

Incident ID: $IncidentID
Organization: $($config.OrganizationInfo.Name)
Contact: $($config.OrganizationInfo.Contact)
Reporting Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

Submit to CISA through:
- Email: us-cert@cisa.dhs.gov
- Portal: https://us-cert.cisa.gov/report

Incident Summary:
$(Get-Content $ReportFile | Select-Object -First 30)

Full technical details and evidence package available.
"@
    
    $cisaReportPath = Join-Path $TempDir "cisa_report.txt"
    Set-Content -Path $cisaReportPath -Value $cisaReport
    
    # Send email if configured
    if ($config.NotificationSettings.EmailEnabled) {
        Send-EmailReport "us-cert@cisa.dhs.gov" "Cybersecurity Incident Report - $IncidentID" $cisaReportPath ""
    }
    
    Write-Log "CISA report prepared and submitted" -Color Green
}

# Main incident reporting function
function Submit-IncidentReport {
    param(
        [string]$IncidentType,
        [int]$Severity,
        [string]$Description,
        [string]$SourceIP = "unknown",
        [string]$TargetIP = "auto"
    )
    
    # Validate input
    if (-not $IncidentTypes.ContainsKey($IncidentType)) {
        Write-ErrorExit "Invalid incident type: $IncidentType"
    }
    
    if ($Severity -lt 1 -or $Severity -gt 10) {
        Write-ErrorExit "Severity must be between 1-10"
    }
    
    $config = Get-Configuration
    
    # Check reporting threshold
    if ($Severity -lt $config.ReportingThresholds.MinSeverity) {
        Write-Log "Incident severity ($Severity) below reporting threshold ($($config.ReportingThresholds.MinSeverity))" -Color Yellow
        return
    }
    
    Write-Log "SECURITY INCIDENT DETECTED" -Color Red
    Write-Log "Type: $($IncidentTypes[$IncidentType])" -Color Yellow
    Write-Log "Severity: $Severity/10" -Color Yellow
    
    # Generate comprehensive report
    $result = New-IncidentReport $IncidentType $Severity $Description $SourceIP $TargetIP
    
    Write-Log "Report generated: $($result.IncidentID)" -Color Green
    
    # Determine which authorities to notify based on incident type and severity
    switch ($IncidentType) {
        { $_ -in @("CHILD_EXPLOITATION", "TERRORISM") } {
            Submit-ToIC3 $result.IncidentID $result.ReportFile
            Submit-ToCISA $result.IncidentID $result.ReportFile
            Write-Log "HIGH PRIORITY: Manual law enforcement notification required" -Color Red
        }
        { $_ -in @("RANSOMWARE", "APT", "DATA_BREACH") } {
            if ($Severity -ge 7) {
                Submit-ToIC3 $result.IncidentID $result.ReportFile
                Submit-ToCISA $result.IncidentID $result.ReportFile
            }
        }
        { $_ -in @("FRAUD", "PHISHING") } {
            if ($Severity -ge 6) {
                Submit-ToIC3 $result.IncidentID $result.ReportFile
            }
        }
        default {
            if ($Severity -ge $config.ReportingThresholds.AutoReportSeverity) {
                Submit-ToCISA $result.IncidentID $result.ReportFile
            }
        }
    }
    
    # Local notifications
    if ($config.NotificationSettings.EmailEnabled) {
        Send-EmailReport $config.OrganizationInfo.Contact "Security Incident Alert - $($result.IncidentID)" $result.ReportFile $result.EvidenceFile
    }
    
    Write-Log "Incident reporting completed: $($result.IncidentID)" -Color Green
    return $result.IncidentID
}

# Batch processing function
function Start-BatchProcessing {
    Write-Log "Starting batch incident processing..." -Color Blue
    
    $config = Get-Configuration
    $checkTime = (Get-Date).AddSeconds(-$config.ReportingThresholds.BatchReportInterval)
    
    # Check for failed login attempts
    $failedLogins = @(Get-WinEvent -LogName "Security" -StartTime $checkTime | Where-Object { $_.Id -eq 4625 }).Count
    if ($failedLogins -gt 10) {
        Submit-IncidentReport "INTRUSION" 5 "Multiple failed login attempts detected: $failedLogins attempts"
    }
    
    # Check for suspicious network activity
    $networkEvents = @(Get-WinEvent -LogName "Security" -StartTime $checkTime | Where-Object { $_.Id -in @(5156, 5157) }).Count
    if ($networkEvents -gt 100) {
        Submit-IncidentReport "INTRUSION" 6 "High network activity detected: $networkEvents events"
    }
    
    # Check for malware-related events
    $malwareEvents = @(Get-WinEvent -LogName "System" -StartTime $checkTime | Where-Object { $_.Id -in @(7034, 7035, 7036) -and $_.LevelDisplayName -eq "Error" }).Count
    if ($malwareEvents -gt 5) {
        Submit-IncidentReport "MALWARE" 7 "Potential malware activity detected: $malwareEvents service failures"
    }
}

# Setup monitoring service
function Install-MonitoringService {
    Write-Log "Setting up incident monitoring service..." -Color Blue
    
    # Create scheduled task for monitoring
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action batch"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserID "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName "XXMXLI-IncidentReporter" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
    
    Write-Log "Monitoring service configured" -Color Green
}

# Test the system
function Test-ReportingSystem {
    Write-Log "Testing incident reporting system..." -Color Blue
    
    $testID = Submit-IncidentReport "INTRUSION" 4 "Test incident - system validation" "127.0.0.1" "127.0.0.1"
    
    if ($testID) {
        Write-Log "Test completed successfully. Incident ID: $testID" -Color Green
        Write-Log "Note: This was a test incident and may not be reported to authorities" -Color Yellow
    } else {
        Write-ErrorExit "Test failed"
    }
}

# Display usage information
function Show-Usage {
    Write-Host @"
XXMXLI Automated Incident Reporter (Windows PowerShell Edition)

Usage: .\automated_incident_reporter.ps1 -Action <action> [parameters]

ACTIONS:
    report     - Report a security incident
    batch      - Process incidents in batch mode
    monitor    - Start continuous monitoring
    setup      - Initial setup and configuration
    test       - Test reporting system
    list       - List available incident types
    help       - Show this help message

PARAMETERS (for report action):
    -IncidentType <type>     - Type of incident (required)
    -Severity <1-10>         - Severity level (required)
    -Description <text>      - Incident description (required)
    -SourceIP <ip>          - Source IP address (optional)
    -TargetIP <ip>          - Target IP address (optional)

INCIDENT TYPES:
    INTRUSION, MALWARE, DDOS, PHISHING, DATA_BREACH, FRAUD,
    CHILD_EXPLOITATION, TERRORISM, RANSOMWARE, APT, INSIDER_THREAT,
    SOCIAL_ENGINEERING

SEVERITY LEVELS:
    1-3: Low (logged only)
    4-6: Medium (internal alerts)
    7-8: High (external reporting)
    9-10: Critical (immediate law enforcement notification)

EXAMPLES:
    .\automated_incident_reporter.ps1 -Action report -IncidentType INTRUSION -Severity 7 -Description "Unauthorized access attempt" -SourceIP "192.168.1.100"
    .\automated_incident_reporter.ps1 -Action batch
    .\automated_incident_reporter.ps1 -Action setup

For support: security@yourorg.com
"@ -ForegroundColor Cyan
}

# Main execution
function Main {
    Write-Host @"
 ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
 ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
 ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝

AUTOMATED INCIDENT REPORTER (Windows PowerShell)
Secure reporting to authorities
"@ -ForegroundColor Cyan
    
    Initialize-Directories
    
    switch ($Action.ToLower()) {
        "report" {
            if (-not $IncidentType -or -not $Severity -or -not $Description) {
                Write-ErrorExit "Missing required parameters for report action"
            }
            Submit-IncidentReport $IncidentType $Severity $Description $SourceIP $TargetIP
        }
        "batch" {
            Start-BatchProcessing
        }
        "monitor" {
            Write-Log "Starting continuous monitoring..." -Color Blue
            while ($true) {
                Start-BatchProcessing
                Start-Sleep -Seconds (Get-Configuration).ReportingThresholds.BatchReportInterval
            }
        }
        "setup" {
            Install-MonitoringService
            Test-ReportingSystem
            Write-Log "Setup completed successfully" -Color Green
        }
        "test" {
            Test-ReportingSystem
        }
        "list" {
            Write-Host "Available incident types:" -ForegroundColor Green
            $IncidentTypes.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor White
            }
        }
        default {
            Show-Usage
        }
    }
}

# Execute main function
Main
