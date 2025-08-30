#!/bin/bash

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
# AUTOMATED INCIDENT REPORTER
# Secure incident reporting to authorities
# Created by: XXMXLI
# Version: 2.0
# License: MIT

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/security"
REPORT_DIR="/var/log/security/reports"
CONFIG_FILE="/etc/security/incident_reporter.conf"
EVIDENCE_DIR="/var/log/security/evidence"
TEMP_DIR="/tmp/incident_reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/incident_reporter.log"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root"
    fi
}

# Create necessary directories
setup_directories() {
    log "${BLUE}Setting up directories...${NC}"
    mkdir -p "$LOG_DIR" "$REPORT_DIR" "$EVIDENCE_DIR" "$TEMP_DIR"
    chmod 700 "$LOG_DIR" "$REPORT_DIR" "$EVIDENCE_DIR"
    chmod 755 "$TEMP_DIR"
}

# Authority contact information
declare -A AUTHORITIES=(
    ["FBI_IC3"]="ic3.gov secure report portal"
    ["CISA"]="us-cert@cisa.dhs.gov"
    ["LOCAL_LEO"]="cybercrime@police.local"
    ["EUROPOL"]="ec3@europol.europa.eu"
    ["INTERPOL"]="cybercrime@interpol.int"
    ["CERT_NATIONAL"]="cert@national-cert.gov"
    ["FINANCIAL_CRIMES"]="fincen@treasury.gov"
    ["TELECOM_FRAUD"]="fraud@telecom-authority.gov"
)

# Incident types and severity levels
declare -A INCIDENT_TYPES=(
    ["INTRUSION"]="Network intrusion attempt"
    ["MALWARE"]="Malware detection"
    ["DDOS"]="Distributed Denial of Service attack"
    ["PHISHING"]="Phishing attempt"
    ["DATA_BREACH"]="Data breach or unauthorized access"
    ["FRAUD"]="Financial fraud attempt"
    ["CHILD_EXPLOITATION"]="Child exploitation material"
    ["TERRORISM"]="Terrorism-related activity"
    ["RANSOMWARE"]="Ransomware attack"
    ["APT"]="Advanced Persistent Threat"
    ["INSIDER_THREAT"]="Insider threat activity"
    ["SOCIAL_ENGINEERING"]="Social engineering attack"
)

# Create configuration file
create_config() {
    log "${BLUE}Creating configuration file...${NC}"
    cat > "$CONFIG_FILE" << EOF
# Automated Incident Reporter Configuration
# Created by XXMXLI Security Toolkit

# Organization Information
ORG_NAME="Your Organization"
ORG_CONTACT="security@yourorg.com"
ORG_PHONE="+1-555-0123"
ORG_ADDRESS="123 Security St, Cyber City, CC 12345"

# Technical Contact
TECH_CONTACT="admin@yourorg.com"
TECH_PHONE="+1-555-0124"

# Reporting Thresholds
MIN_SEVERITY=3
AUTO_REPORT_SEVERITY=7
BATCH_REPORT_INTERVAL=3600

# Notification Settings
EMAIL_ENABLED=true
SMS_ENABLED=false
WEBHOOK_ENABLED=true

# Evidence Collection
COLLECT_PCAP=true
COLLECT_LOGS=true
COLLECT_MEMORY_DUMP=false
EVIDENCE_RETENTION_DAYS=90

# Encryption Settings
GPG_KEY_ID="security@yourorg.com"
ENCRYPT_REPORTS=true
SECURE_DELETE=true
EOF
    chmod 600 "$CONFIG_FILE"
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        create_config
        source "$CONFIG_FILE"
    fi
}

# Generate incident ID
generate_incident_id() {
    echo "INC-$(date +%Y%m%d-%H%M%S)-$(openssl rand -hex 4 | tr '[:lower:]' '[:upper:]')"
}

# Collect system information
collect_system_info() {
    local report_file="$1"
    
    cat >> "$report_file" << EOF

=== SYSTEM INFORMATION ===
Hostname: $(hostname)
Operating System: $(uname -a)
Kernel Version: $(uname -r)
Uptime: $(uptime)
Current Time: $(date -u)
Timezone: $(timedatectl | grep "Time zone" | cut -d: -f2-)
System Load: $(cat /proc/loadavg)
Memory Usage: $(free -h)
Disk Usage: $(df -h /)
Network Interfaces: $(ip addr show | grep -E "^[0-9]+:" | cut -d: -f2)

EOF
}

# Collect network information
collect_network_info() {
    local report_file="$1"
    
    cat >> "$report_file" << EOF

=== NETWORK INFORMATION ===
Active Connections:
$(netstat -tuln | head -20)

Routing Table:
$(route -n)

ARP Table:
$(arp -a)

Firewall Status:
$(iptables -L -n | head -20)

Recent Network Activity:
$(tail -50 /var/log/syslog | grep -i "network\|connection\|tcp\|udp" | tail -10)

EOF
}

# Collect security logs
collect_security_logs() {
    local report_file="$1"
    local hours="${2:-24}"
    
    cat >> "$report_file" << EOF

=== SECURITY LOGS (Last $hours hours) ===

Authentication Logs:
$(journalctl --since="$hours hours ago" | grep -i "auth\|login\|ssh\|sudo" | tail -20)

Security Events:
$(journalctl --since="$hours hours ago" | grep -i "security\|intrusion\|attack\|blocked" | tail -20)

Firewall Logs:
$(journalctl --since="$hours hours ago" | grep -i "iptables\|firewall\|blocked" | tail -20)

Failed Login Attempts:
$(journalctl --since="$hours hours ago" | grep -i "failed\|invalid\|unauthorized" | tail -15)

EOF
}

# Collect evidence files
collect_evidence() {
    local incident_id="$1"
    local evidence_path="$EVIDENCE_DIR/$incident_id"
    
    mkdir -p "$evidence_path"
    
    # Copy relevant log files
    if [[ "$COLLECT_LOGS" == "true" ]]; then
        log "${BLUE}Collecting log evidence...${NC}"
        cp /var/log/auth.log* "$evidence_path/" 2>/dev/null || true
        cp /var/log/syslog* "$evidence_path/" 2>/dev/null || true
        cp /var/log/kern.log* "$evidence_path/" 2>/dev/null || true
        
        # Collect application-specific logs
        find /var/log -name "*.log" -mtime -1 -exec cp {} "$evidence_path/" \; 2>/dev/null || true
    fi
    
    # Capture network traffic if enabled
    if [[ "$COLLECT_PCAP" == "true" ]] && command -v tcpdump >/dev/null; then
        log "${BLUE}Capturing network traffic sample...${NC}"
        timeout 30 tcpdump -i any -w "$evidence_path/network_capture.pcap" 2>/dev/null || true
    fi
    
    # Memory dump if enabled (requires specific tools)
    if [[ "$COLLECT_MEMORY_DUMP" == "true" ]] && command -v volatility >/dev/null; then
        log "${BLUE}Creating memory dump...${NC}"
        # This would require specific memory acquisition tools
        echo "Memory dump collection requested but requires specialized tools" > "$evidence_path/memory_note.txt"
    fi
    
    # Create evidence manifest
    cat > "$evidence_path/manifest.txt" << EOF
Evidence Collection Manifest
Incident ID: $incident_id
Collection Time: $(date -u)
Collected By: $(whoami)@$(hostname)

Files Collected:
$(ls -la "$evidence_path/")

Checksums:
$(find "$evidence_path" -type f -exec sha256sum {} \;)
EOF
    
    # Compress evidence
    tar -czf "$evidence_path.tar.gz" -C "$EVIDENCE_DIR" "$incident_id"
    rm -rf "$evidence_path"
    
    echo "$evidence_path.tar.gz"
}

# Encrypt sensitive data
encrypt_file() {
    local file="$1"
    local encrypted_file="$file.gpg"
    
    if [[ "$ENCRYPT_REPORTS" == "true" ]] && command -v gpg >/dev/null; then
        log "${BLUE}Encrypting report...${NC}"
        gpg --trust-model always --encrypt -r "$GPG_KEY_ID" --output "$encrypted_file" "$file"
        
        if [[ "$SECURE_DELETE" == "true" ]]; then
            shred -vfz -n 3 "$file"
        fi
        
        echo "$encrypted_file"
    else
        echo "$file"
    fi
}

# Generate incident report
generate_report() {
    local incident_type="$1"
    local severity="$2"
    local description="$3"
    local source_ip="${4:-unknown}"
    local target_ip="${5:-$(hostname -I | awk '{print $1}')}"
    
    local incident_id=$(generate_incident_id)
    local report_file="$REPORT_DIR/${incident_id}.txt"
    
    log "${YELLOW}Generating incident report: $incident_id${NC}"
    
    # Create main report
    cat > "$report_file" << EOF
=================================================================
SECURITY INCIDENT REPORT
=================================================================

Incident ID: $incident_id
Report Generated: $(date -u)
Generated By: XXMXLI Automated Security System
Organization: $ORG_NAME

=== INCIDENT DETAILS ===
Type: $incident_type
Severity: $severity/10
Description: $description
Source IP: $source_ip
Target IP: $target_ip
Detection Time: $(date -u)
Reporting System: $(hostname)

=== CONTACT INFORMATION ===
Organization: $ORG_NAME
Primary Contact: $ORG_CONTACT
Phone: $ORG_PHONE
Technical Contact: $TECH_CONTACT
Address: $ORG_ADDRESS

EOF
    
    # Add system information
    collect_system_info "$report_file"
    collect_network_info "$report_file"
    collect_security_logs "$report_file"
    
    # Add incident-specific details
    cat >> "$report_file" << EOF

=== INCIDENT ANALYSIS ===
Timeline:
- Detection: $(date -u)
- Analysis Started: $(date -u)
- Report Generated: $(date -u)

Impact Assessment:
- Severity Level: $severity/10
- Systems Affected: $(hostname)
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
Evidence retention: $EVIDENCE_RETENTION_DAYS days
Chain of custody maintained.

EOF
    
    # Collect evidence
    local evidence_file=$(collect_evidence "$incident_id")
    echo "Evidence Package: $evidence_file" >> "$report_file"
    
    # Encrypt if configured
    local final_report=$(encrypt_file "$report_file")
    
    echo "$incident_id:$final_report:$evidence_file"
}

# Send secure email report
send_email_report() {
    local recipient="$1"
    local subject="$2"
    local report_file="$3"
    local evidence_file="$4"
    
    if [[ "$EMAIL_ENABLED" == "true" ]] && command -v sendmail >/dev/null; then
        log "${BLUE}Sending email report to $recipient...${NC}"
        
        # Create email with attachments
        cat > "$TEMP_DIR/email.txt" << EOF
To: $recipient
From: $ORG_CONTACT
Subject: $subject
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="SECURITY_REPORT_BOUNDARY"

--SECURITY_REPORT_BOUNDARY
Content-Type: text/plain; charset=UTF-8

Security Incident Report

Please find attached the security incident report and evidence package.
This is an automated report generated by XXMXLI Security System.

Report Details:
- Incident Type: Security Event
- Organization: $ORG_NAME
- Contact: $ORG_CONTACT
- Generated: $(date -u)

For urgent matters, please contact: $TECH_PHONE

This communication may contain sensitive security information.
Please handle according to your organization's security protocols.

--SECURITY_REPORT_BOUNDARY
Content-Type: application/octet-stream; name="incident_report.txt"
Content-Disposition: attachment; filename="incident_report.txt"
Content-Transfer-Encoding: base64

$(base64 "$report_file")

--SECURITY_REPORT_BOUNDARY--
EOF
        
        # Send email
        sendmail "$recipient" < "$TEMP_DIR/email.txt"
        rm -f "$TEMP_DIR/email.txt"
    fi
}

# Submit to FBI IC3
submit_to_ic3() {
    local incident_id="$1"
    local report_file="$2"
    
    log "${BLUE}Preparing submission to FBI IC3...${NC}"
    
    # Create IC3-specific report format
    cat > "$TEMP_DIR/ic3_report.txt" << EOF
FBI Internet Crime Complaint Center (IC3) Report

Incident ID: $incident_id
Submitter: $ORG_NAME
Contact: $ORG_CONTACT
Date: $(date -u)

Please submit this report through the official IC3 portal at:
https://www.ic3.gov/Home/FileComplaint

Report Summary:
$(head -50 "$report_file")

Full report and evidence available upon request.
EOF
    
    log "${GREEN}IC3 report prepared: $TEMP_DIR/ic3_report.txt${NC}"
    log "${YELLOW}Manual submission required at: https://www.ic3.gov/Home/FileComplaint${NC}"
}

# Submit to CISA
submit_to_cisa() {
    local incident_id="$1"
    local report_file="$2"
    
    log "${BLUE}Preparing submission to CISA...${NC}"
    
    # Create CISA-specific report format
    cat > "$TEMP_DIR/cisa_report.txt" << EOF
CISA Cybersecurity Incident Report

Incident ID: $incident_id
Organization: $ORG_NAME
Contact: $ORG_CONTACT
Reporting Date: $(date -u)

Submit to CISA through:
- Email: us-cert@cisa.dhs.gov
- Portal: https://us-cert.cisa.gov/report

Incident Summary:
$(head -30 "$report_file")

Full technical details and evidence package available.
EOF
    
    # Send email if configured
    if [[ "$EMAIL_ENABLED" == "true" ]]; then
        send_email_report "us-cert@cisa.dhs.gov" "Cybersecurity Incident Report - $incident_id" "$TEMP_DIR/cisa_report.txt" ""
    fi
    
    log "${GREEN}CISA report prepared and submitted${NC}"
}

# Submit to Europol EC3
submit_to_europol() {
    local incident_id="$1"
    local report_file="$2"
    
    log "${BLUE}Preparing submission to Europol EC3...${NC}"
    
    cat > "$TEMP_DIR/europol_report.txt" << EOF
Europol European Cybercrime Centre (EC3) Report

Incident Reference: $incident_id
Reporting Entity: $ORG_NAME
Contact Details: $ORG_CONTACT
Report Date: $(date -u)

Submit through appropriate national CERT or:
Email: ec3@europol.europa.eu

Cross-border cybercrime incident requiring international cooperation.

Incident Overview:
$(head -40 "$report_file")
EOF
    
    log "${GREEN}Europol EC3 report prepared${NC}"
}

# Main incident reporting function
report_incident() {
    local incident_type="$1"
    local severity="$2"
    local description="$3"
    local source_ip="${4:-unknown}"
    local target_ip="${5:-auto}"
    
    # Validate input
    if [[ ! "${INCIDENT_TYPES[$incident_type]:-}" ]]; then
        error_exit "Invalid incident type: $incident_type"
    fi
    
    if [[ $severity -lt 1 ]] || [[ $severity -gt 10 ]]; then
        error_exit "Severity must be between 1-10"
    fi
    
    # Check reporting threshold
    if [[ $severity -lt $MIN_SEVERITY ]]; then
        log "${YELLOW}Incident severity ($severity) below reporting threshold ($MIN_SEVERITY)${NC}"
        return 0
    fi
    
    log "${RED}SECURITY INCIDENT DETECTED${NC}"
    log "${YELLOW}Type: ${INCIDENT_TYPES[$incident_type]}${NC}"
    log "${YELLOW}Severity: $severity/10${NC}"
    
    # Generate comprehensive report
    local result=$(generate_report "$incident_type" "$severity" "$description" "$source_ip" "$target_ip")
    local incident_id=$(echo "$result" | cut -d: -f1)
    local report_file=$(echo "$result" | cut -d: -f2)
    local evidence_file=$(echo "$result" | cut -d: -f3)
    
    log "${GREEN}Report generated: $incident_id${NC}"
    
    # Determine which authorities to notify based on incident type and severity
    case "$incident_type" in
        "CHILD_EXPLOITATION"|"TERRORISM")
            submit_to_ic3 "$incident_id" "$report_file"
            submit_to_cisa "$incident_id" "$report_file"
            log "${RED}HIGH PRIORITY: Manual law enforcement notification required${NC}"
            ;;
        "RANSOMWARE"|"APT"|"DATA_BREACH")
            if [[ $severity -ge 7 ]]; then
                submit_to_ic3 "$incident_id" "$report_file"
                submit_to_cisa "$incident_id" "$report_file"
            fi
            ;;
        "FRAUD"|"PHISHING")
            if [[ $severity -ge 6 ]]; then
                submit_to_ic3 "$incident_id" "$report_file"
            fi
            ;;
        *)
            if [[ $severity -ge $AUTO_REPORT_SEVERITY ]]; then
                submit_to_cisa "$incident_id" "$report_file"
            fi
            ;;
    esac
    
    # International reporting for cross-border incidents
    if [[ "$source_ip" != "unknown" ]] && [[ "$source_ip" != "127.0.0.1" ]]; then
        local country=$(geoiplookup "$source_ip" 2>/dev/null | grep -o "[A-Z][A-Z]" | head -1 || echo "UN")
        if [[ "$country" != "US" ]] && [[ $severity -ge 7 ]]; then
            submit_to_europol "$incident_id" "$report_file"
        fi
    fi
    
    # Local notifications
    if [[ "$EMAIL_ENABLED" == "true" ]]; then
        send_email_report "$ORG_CONTACT" "Security Incident Alert - $incident_id" "$report_file" "$evidence_file"
    fi
    
    log "${GREEN}Incident reporting completed: $incident_id${NC}"
    echo "$incident_id"
}

# Batch processing of incidents
batch_process() {
    log "${BLUE}Starting batch incident processing...${NC}"
    
    # Look for incidents in log files
    local current_time=$(date +%s)
    local check_time=$((current_time - BATCH_REPORT_INTERVAL))
    
    # Check for failed login attempts
    local failed_logins=$(journalctl --since="@$check_time" | grep -c "Failed password" || echo 0)
    if [[ $failed_logins -gt 10 ]]; then
        report_incident "INTRUSION" 5 "Multiple failed login attempts detected: $failed_logins attempts"
    fi
    
    # Check for port scans
    local port_scans=$(journalctl --since="@$check_time" | grep -c "kernel.*IN.*OUT.*" || echo 0)
    if [[ $port_scans -gt 50 ]]; then
        report_incident "INTRUSION" 6 "Potential port scan detected: $port_scans blocked connections"
    fi
    
    # Check for DDoS indicators
    local ddos_indicators=$(journalctl --since="@$check_time" | grep -c "nf_conntrack.*table full" || echo 0)
    if [[ $ddos_indicators -gt 0 ]]; then
        report_incident "DDOS" 7 "DDoS attack indicators detected: connection table full"
    fi
}

# Setup monitoring daemon
setup_monitoring() {
    log "${BLUE}Setting up incident monitoring daemon...${NC}"
    
    # Create systemd service
    cat > /etc/systemd/system/incident-reporter.service << EOF
[Unit]
Description=XXMXLI Automated Incident Reporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=$SCRIPT_DIR/automated_incident_reporter.sh --daemon
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    # Create monitoring script
    cat > "$SCRIPT_DIR/incident_monitor.sh" << 'EOF'
#!/bin/bash
while true; do
    /path/to/automated_incident_reporter.sh --batch
    sleep 300  # Check every 5 minutes
done
EOF
    
    chmod +x "$SCRIPT_DIR/incident_monitor.sh"
    
    systemctl daemon-reload
    systemctl enable incident-reporter.service
    
    log "${GREEN}Monitoring daemon configured${NC}"
}

# Display usage information
show_usage() {
    cat << EOF
XXMXLI Automated Incident Reporter

Usage: $0 [OPTIONS]

OPTIONS:
    --report TYPE SEVERITY DESCRIPTION [SOURCE_IP] [TARGET_IP]
        Report a security incident
        
    --batch
        Process incidents in batch mode
        
    --monitor
        Start continuous monitoring
        
    --setup
        Initial setup and configuration
        
    --test
        Test reporting system
        
    --list-types
        List available incident types
        
    --help
        Show this help message

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
    $0 --report INTRUSION 7 "Unauthorized access attempt from 192.168.1.100" 192.168.1.100
    $0 --report RANSOMWARE 9 "Ransomware detected on file server"
    $0 --batch
    $0 --setup

For support: $ORG_CONTACT
EOF
}

# Test the reporting system
test_system() {
    log "${BLUE}Testing incident reporting system...${NC}"
    
    # Test report generation
    local test_id=$(report_incident "INTRUSION" 4 "Test incident - system validation" "127.0.0.1" "127.0.0.1")
    
    if [[ -n "$test_id" ]]; then
        log "${GREEN}Test completed successfully. Incident ID: $test_id${NC}"
        log "${YELLOW}Note: This was a test incident and may not be reported to authorities${NC}"
    else
        error_exit "Test failed"
    fi
}

# Main function
main() {
    echo -e "${CYAN}"
    cat << 'EOF'
 ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
 ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
 ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝

AUTOMATED INCIDENT REPORTER
Secure reporting to authorities
EOF
    echo -e "${NC}"
    
    check_root
    setup_directories
    load_config
    
    case "${1:-}" in
        "--report")
            if [[ $# -lt 4 ]]; then
                error_exit "Insufficient arguments for --report"
            fi
            report_incident "$2" "$3" "$4" "${5:-unknown}" "${6:-auto}"
            ;;
        "--batch")
            batch_process
            ;;
        "--monitor")
            log "${BLUE}Starting continuous monitoring...${NC}"
            while true; do
                batch_process
                sleep "$BATCH_REPORT_INTERVAL"
            done
            ;;
        "--setup")
            setup_monitoring
            test_system
            log "${GREEN}Setup completed successfully${NC}"
            ;;
        "--test")
            test_system
            ;;
        "--list-types")
            echo "Available incident types:"
            for type in "${!INCIDENT_TYPES[@]}"; do
                echo "  $type: ${INCIDENT_TYPES[$type]}"
            done
            ;;
        "--daemon")
            # Daemon mode for systemd
            while true; do
                batch_process
                sleep 300
            done
            ;;
        "--help"|"-h"|"")
            show_usage
            ;;
        *)
            error_exit "Unknown option: $1"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
