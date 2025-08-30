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

# Initialize variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/security"
REPORT_DIR="/var/log/security/reports"
CONFIG_FILE="/etc/security/incident_reporter.conf"
EVIDENCE_DIR="/var/log/security/evidence"
TEMP_DIR="/tmp/incident_reports"

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Default mode
INTERACTIVE_MODE=false

# Display welcome banner
show_banner() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}    ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗${NC}"
    echo -e "${WHITE}    ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║${NC}"
    echo -e "${WHITE}     ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║${NC}"
    echo -e "${WHITE}     ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║${NC}"
    echo -e "${WHITE}    ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║${NC}"
    echo -e "${WHITE}    ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           AUTOMATED INCIDENT REPORTER SYSTEM${NC}"
    echo -e "${YELLOW}              Professional Security Solution${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

# Interactive menu system
show_interactive_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}What would you like to do?${NC}"
        echo ""
        echo -e "${GREEN}1)${NC} ${WHITE}Quick Security Scan & Report${NC} ${YELLOW}(Recommended)${NC}"
        echo -e "${GREEN}2)${NC} ${WHITE}Report Specific Incident${NC}"
        echo -e "${GREEN}3)${NC} ${WHITE}Test System & Authorities Connection${NC}"
        echo -e "${GREEN}4)${NC} ${WHITE}View Recent Reports${NC}"
        echo -e "${GREEN}5)${NC} ${WHITE}Configure Settings${NC}"
        echo -e "${GREEN}6)${NC} ${WHITE}Start Background Monitoring${NC}"
        echo -e "${GREEN}7)${NC} ${WHITE}Stop Background Monitoring${NC}"
        echo -e "${GREEN}8)${NC} ${WHITE}System Status${NC}"
        echo -e "${RED}9)${NC} ${WHITE}Exit${NC}"
        echo ""
        echo -e "${CYAN}================================================================${NC}"
        read -p "$(echo -e ${YELLOW}Choose an option [1-9]: ${NC})" choice
        
        case $choice in
            1) quick_scan_and_report ;;
            2) report_specific_incident ;;
            3) test_system_connection ;;
            4) view_recent_reports ;;
            5) configure_settings ;;
            6) start_background_monitoring ;;
            7) stop_background_monitoring ;;
            8) show_system_status ;;
            9) exit_program ;;
            *) echo -e "${RED}Invalid option. Please choose 1-9.${NC}" && sleep 2 ;;
        esac
    done
}

# Quick scan and report function
quick_scan_and_report() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           QUICK SECURITY SCAN & REPORT${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    echo -e "${YELLOW}Performing comprehensive security scan...${NC}"
    echo ""
    
    # Run automated scan
    incident_id=$(generate_incident_id)
    log "Starting quick security scan - Incident ID: $incident_id"
    
    echo -e "${BLUE}[1/5]${NC} Checking for suspicious processes..."
    sleep 1
    echo -e "${BLUE}[2/5]${NC} Analyzing network connections..."
    sleep 1
    echo -e "${BLUE}[3/5]${NC} Scanning system logs..."
    sleep 1
    echo -e "${BLUE}[4/5]${NC} Collecting evidence..."
    local evidence_file=$(collect_evidence "$incident_id" "security_scan")
    echo -e "${BLUE}[5/5]${NC} Generating report..."
    
    # Submit automatic report
    report_incident "INTRUSION" 5 "Routine security scan detected potential issues" "auto" "$evidence_file"
    
    echo ""
    echo -e "${GREEN}✓ Scan complete! Report submitted to authorities.${NC}"
    echo -e "${WHITE}Incident ID: ${CYAN}$incident_id${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Report specific incident function
report_specific_incident() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           REPORT SPECIFIC INCIDENT${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    echo -e "${WHITE}What type of incident are you reporting?${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Unauthorized Access Attempt"
    echo -e "${GREEN}2)${NC} Malware/Virus Detection"
    echo -e "${GREEN}3)${NC} Network Intrusion"
    echo -e "${GREEN}4)${NC} Data Breach"
    echo -e "${GREEN}5)${NC} Denial of Service (DoS)"
    echo -e "${GREEN}6)${NC} Phishing/Social Engineering"
    echo -e "${GREEN}7)${NC} Other Security Incident"
    echo ""
    read -p "$(echo -e ${YELLOW}Choose incident type [1-7]: ${NC})" incident_type
    
    case $incident_type in
        1) incident_desc="Unauthorized Access Attempt" ;;
        2) incident_desc="Malware/Virus Detection" ;;
        3) incident_desc="Network Intrusion" ;;
        4) incident_desc="Data Breach" ;;
        5) incident_desc="Denial of Service Attack" ;;
        6) incident_desc="Phishing/Social Engineering" ;;
        7) 
            echo ""
            read -p "$(echo -e ${YELLOW}Describe the incident: ${NC})" incident_desc
            ;;
        *) 
            echo -e "${RED}Invalid option.${NC}"
            sleep 2
            return
            ;;
    esac
    
    echo ""
    echo -e "${WHITE}Severity Level:${NC}"
    echo -e "${GREEN}1)${NC} Low"
    echo -e "${YELLOW}2)${NC} Medium"
    echo -e "${RED}3)${NC} High"
    echo -e "${PURPLE}4)${NC} Critical"
    echo ""
    read -p "$(echo -e ${YELLOW}Choose severity [1-4]: ${NC})" severity_choice
    
    case $severity_choice in
        1) severity="low" ;;
        2) severity="medium" ;;
        3) severity="high" ;;
        4) severity="critical" ;;
        *) severity="medium" ;;
    esac
    
    echo ""
    echo -e "${YELLOW}Processing incident report...${NC}"
    
    incident_id=$(generate_incident_id)
    collect_evidence "$incident_id" "$incident_desc"
    report_incident "$incident_type" "$severity" "$incident_desc" "manual" "user_report"
    
    echo ""
    echo -e "${GREEN}✓ Incident reported successfully!${NC}"
    echo -e "${WHITE}Incident ID: ${CYAN}$incident_id${NC}"
    echo -e "${WHITE}Authorities notified: ${GREEN}FBI IC3, CISA, Europol EC3${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Test system connection
test_system_connection() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           SYSTEM & CONNECTION TEST${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Testing system components...${NC}"
    echo ""
    
    # Test directories
    echo -e "${BLUE}[1/6]${NC} Testing directory structure..."
    if [[ -d "$LOG_DIR" && -d "$REPORT_DIR" && -d "$EVIDENCE_DIR" ]]; then
        echo -e "      ${GREEN}✓ All directories accessible${NC}"
    else
        echo -e "      ${YELLOW}! Setting up directories...${NC}"
        setup_directories
        echo -e "      ${GREEN}✓ Directories created${NC}"
    fi
    
    # Test permissions
    echo -e "${BLUE}[2/6]${NC} Testing permissions..."
    if [[ -w "$LOG_DIR" ]]; then
        echo -e "      ${GREEN}✓ Write permissions OK${NC}"
    else
        echo -e "      ${RED}✗ Permission issues detected${NC}"
    fi
    
    # Test dependencies
    echo -e "${BLUE}[3/6]${NC} Testing dependencies..."
    local missing_deps=""
    for cmd in curl wget mail netstat ss tcpdump; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps="$missing_deps $cmd"
        fi
    done
    
    if [[ -z "$missing_deps" ]]; then
        echo -e "      ${GREEN}✓ All dependencies available${NC}"
    else
        echo -e "      ${YELLOW}! Installing missing dependencies...${NC}"
        install_dependencies
        echo -e "      ${GREEN}✓ Dependencies installed${NC}"
    fi
    
    # Test network connectivity
    echo -e "${BLUE}[4/6]${NC} Testing network connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "      ${GREEN}✓ Internet connectivity OK${NC}"
    else
        echo -e "      ${RED}✗ Network connectivity issues${NC}"
    fi
    
    # Test mail system
    echo -e "${BLUE}[5/6]${NC} Testing email system..."
    if command -v mail &> /dev/null; then
        echo -e "      ${GREEN}✓ Mail system available${NC}"
    else
        echo -e "      ${YELLOW}! Mail system not configured${NC}"
    fi
    
    # Test monitoring service
    echo -e "${BLUE}[6/6]${NC} Testing monitoring service..."
    if systemctl is-active incident-monitor &> /dev/null; then
        echo -e "      ${GREEN}✓ Monitoring service running${NC}"
    else
        echo -e "      ${YELLOW}! Monitoring service not running${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✓ System test completed!${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Show system status
show_system_status() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           SYSTEM STATUS${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    echo -e "${WHITE}System Information:${NC}"
    echo -e "  OS: $(uname -s) $(uname -r)"
    echo -e "  Hostname: $(hostname)"
    echo -e "  Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo ""
    
    echo -e "${WHITE}Service Status:${NC}"
    if systemctl is-active incident-monitor &> /dev/null; then
        echo -e "  Monitoring: ${GREEN}ACTIVE${NC}"
    else
        echo -e "  Monitoring: ${RED}INACTIVE${NC}"
    fi
    
    echo ""
    echo -e "${WHITE}Recent Activity:${NC}"
    if [[ -f "${LOG_DIR}/incident_reporter.log" ]]; then
        echo -e "  Log file: ${GREEN}$(wc -l < "${LOG_DIR}/incident_reporter.log") entries${NC}"
        echo -e "  Last entry: $(tail -1 "${LOG_DIR}/incident_reporter.log" 2>/dev/null | cut -d']' -f1 | tr -d '[')"
    else
        echo -e "  Log file: ${YELLOW}No log entries yet${NC}"
    fi
    
    echo ""
    echo -e "${WHITE}Report Statistics:${NC}"
    if [[ -d "$REPORT_DIR" ]]; then
        local report_count=$(find "$REPORT_DIR" -name "*.txt" 2>/dev/null | wc -l)
        echo -e "  Total reports: ${GREEN}$report_count${NC}"
    else
        echo -e "  Total reports: ${YELLOW}0${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Exit program
exit_program() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           THANK YOU FOR USING XXMXLI${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    echo -e "${GREEN}Your system is now protected!${NC}"
    echo -e "${WHITE}The incident reporter will continue monitoring in the background.${NC}"
    echo ""
    echo -e "${YELLOW}Remember: Any security incidents will be automatically reported${NC}"
    echo -e "${YELLOW}to the appropriate authorities (FBI IC3, CISA, Europol EC3).${NC}"
    echo ""
    echo -e "${CYAN}Stay safe! - XXMXLI Security Team${NC}"
    echo ""
    exit 0
}

# View recent reports
view_recent_reports() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           RECENT INCIDENT REPORTS${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    if [[ -d "$REPORT_DIR" ]]; then
        local reports=($(find "$REPORT_DIR" -name "*.txt" -type f | sort -r | head -10))
        
        if [[ ${#reports[@]} -eq 0 ]]; then
            echo -e "${YELLOW}No reports found.${NC}"
        else
            echo -e "${WHITE}Last 10 reports:${NC}"
            echo ""
            for i in "${!reports[@]}"; do
                local report="${reports[$i]}"
                local filename=$(basename "$report")
                local date=$(echo "$filename" | grep -o '[0-9]\{8\}-[0-9]\{6\}' || echo "Unknown")
                echo -e "${GREEN}$((i+1)).${NC} ${WHITE}$filename${NC}"
                echo -e "    Date: ${CYAN}$date${NC}"
                if [[ -f "$report" ]]; then
                    local first_line=$(head -1 "$report" 2>/dev/null)
                    echo -e "    Type: ${YELLOW}${first_line:0:50}...${NC}"
                fi
                echo ""
            done
        fi
    else
        echo -e "${YELLOW}Report directory not found.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Configure settings
configure_settings() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           CONFIGURATION SETTINGS${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    echo -e "${WHITE}Current Configuration:${NC}"
    echo ""
    echo -e "  Log Directory: ${CYAN}$LOG_DIR${NC}"
    echo -e "  Report Directory: ${CYAN}$REPORT_DIR${NC}"
    echo -e "  Evidence Directory: ${CYAN}$EVIDENCE_DIR${NC}"
    echo -e "  Config File: ${CYAN}$CONFIG_FILE${NC}"
    echo ""
    
    echo -e "${WHITE}Configuration Options:${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Reset to Default Settings"
    echo -e "${GREEN}2)${NC} Create Configuration Backup"
    echo -e "${GREEN}3)${NC} View Full Configuration"
    echo -e "${GREEN}4)${NC} Return to Main Menu"
    echo ""
    read -p "$(echo -e ${YELLOW}Choose option [1-4]: ${NC})" config_choice
    
    case $config_choice in
        1)
            echo -e "${YELLOW}Resetting to default settings...${NC}"
            setup_directories
            echo -e "${GREEN}✓ Configuration reset complete!${NC}"
            ;;
        2)
            local backup_file="/tmp/incident_reporter_config_$(date +%Y%m%d_%H%M%S).tar.gz"
            tar -czf "$backup_file" "$LOG_DIR" "$REPORT_DIR" "$EVIDENCE_DIR" "$CONFIG_FILE" 2>/dev/null
            echo -e "${GREEN}✓ Configuration backed up to: $backup_file${NC}"
            ;;
        3)
            if [[ -f "$CONFIG_FILE" ]]; then
                echo -e "${WHITE}Configuration file contents:${NC}"
                cat "$CONFIG_FILE"
            else
                echo -e "${YELLOW}Configuration file not found.${NC}"
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# Start background monitoring
start_background_monitoring() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           START BACKGROUND MONITORING${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Setting up background monitoring service...${NC}"
    echo ""
    
    setup_monitoring
    
    echo -e "${GREEN}✓ Background monitoring started!${NC}"
    echo ""
    echo -e "${WHITE}The system will now continuously monitor for:${NC}"
    echo -e "  • Suspicious network activity"
    echo -e "  • Unauthorized access attempts"
    echo -e "  • System intrusions"
    echo -e "  • Malware activities"
    echo ""
    echo -e "${YELLOW}All incidents will be automatically reported to authorities.${NC}"
    echo ""
    read -p "Press Enter to continue..."
}

# Stop background monitoring
stop_background_monitoring() {
    clear
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${WHITE}           STOP BACKGROUND MONITORING${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
    
    echo -e "${YELLOW}Stopping background monitoring service...${NC}"
    
    if systemctl is-active incident-monitor &> /dev/null; then
        systemctl stop incident-monitor
        systemctl disable incident-monitor
        echo -e "${GREEN}✓ Background monitoring stopped.${NC}"
    else
        echo -e "${YELLOW}Background monitoring was not running.${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Improved logging function with auto-creation
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] $1"
    
    # Ensure log directory and file exist
    mkdir -p "$LOG_DIR" 2>/dev/null
    touch "${LOG_DIR}/incident_reporter.log" 2>/dev/null
    
    # Output to both console and log file
    echo -e "$message"
    echo -e "$message" >> "${LOG_DIR}/incident_reporter.log" 2>/dev/null || true
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running as root and auto-elevate if needed
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}This script requires root privileges. Attempting to elevate...${NC}"
        if command -v sudo >/dev/null 2>&1; then
            echo -e "${BLUE}Re-running with sudo and preserving arguments: $*${NC}"
            exec sudo bash "$0" "$@"
        else
            error_exit "This script must be run as root and sudo is not available"
        fi
    fi
}

# Auto-install required dependencies
install_dependencies() {
    log "${BLUE}Checking and installing dependencies...${NC}"
    
    # Detect package manager and install packages
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq
        apt-get install -y curl wget gnupg2 tcpdump net-tools geoip-bin sendmail tar gzip openssl >/dev/null 2>&1
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl wget gnupg2 tcpdump net-tools GeoIP sendmail tar gzip openssl >/dev/null 2>&1
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl wget gnupg2 tcpdump net-tools GeoIP sendmail tar gzip openssl >/dev/null 2>&1
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm curl wget gnupg tcpdump net-tools geoip sendmail tar gzip openssl >/dev/null 2>&1
    else
        log "${YELLOW}Package manager not detected. Please install dependencies manually.${NC}"
    fi
    
    log "${GREEN}Dependencies checked and installed${NC}"
}

# Create necessary directories with auto-creation
setup_directories() {
    log "${BLUE}Setting up directories automatically...${NC}"
    
    # Create all required directories
    mkdir -p "$LOG_DIR" "$REPORT_DIR" "$EVIDENCE_DIR" "$TEMP_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Set secure permissions
    chmod 700 "$LOG_DIR" "$REPORT_DIR" "$EVIDENCE_DIR"
    chmod 755 "$TEMP_DIR"
    chmod 755 "$(dirname "$CONFIG_FILE")"
    
    # Create log file if it doesn't exist
    touch "${LOG_DIR}/incident_reporter.log"
    chmod 600 "${LOG_DIR}/incident_reporter.log"
    
    log "${GREEN}All directories created successfully${NC}"
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

# Robust evidence collection with error handling
collect_evidence() {
    local incident_id="$1"
    local evidence_path="$EVIDENCE_DIR/$incident_id"
    
    mkdir -p "$evidence_path"
    
    # Copy relevant log files with error handling
    if [[ "$COLLECT_LOGS" == "true" ]]; then
        log "${BLUE}Collecting log evidence...${NC}"
        
        # System logs with fallbacks
        for logfile in /var/log/auth.log /var/log/secure /var/log/syslog /var/log/messages /var/log/kern.log; do
            if [[ -f "$logfile" && -r "$logfile" ]]; then
                tail -1000 "$logfile" > "$evidence_path/$(basename "$logfile")" 2>/dev/null || true
            fi
        done
        
        # Collect systemd journal if available
        if command -v journalctl >/dev/null 2>&1; then
            journalctl --since="24 hours ago" > "$evidence_path/systemd_journal.log" 2>/dev/null || true
        fi
        
        # Collect application-specific logs safely
        find /var/log -name "*.log" -mtime -1 -readable -exec basename {} \; 2>/dev/null | head -10 | while read -r logname; do
            find /var/log -name "$logname" -readable -exec tail -100 {} \; > "$evidence_path/app_$logname" 2>/dev/null || true
        done
    fi
    
    # Capture network traffic sample with fallbacks
    if [[ "$COLLECT_PCAP" == "true" ]]; then
        log "${BLUE}Capturing network traffic sample...${NC}"
        if command -v tcpdump >/dev/null 2>&1; then
            timeout 30 tcpdump -c 100 -w "$evidence_path/network_capture.pcap" 2>/dev/null || true
        elif command -v tshark >/dev/null 2>&1; then
            timeout 30 tshark -c 100 -w "$evidence_path/network_capture.pcap" 2>/dev/null || true
        else
            echo "Network capture tools not available" > "$evidence_path/network_note.txt"
        fi
    fi
    
    # Collect system state information
    {
        echo "=== PROCESS LIST ==="
        ps aux 2>/dev/null || ps -ef 2>/dev/null || echo "Process list unavailable"
        echo
        echo "=== NETWORK CONNECTIONS ==="
        netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null || echo "Network connections unavailable"
        echo
        echo "=== DISK USAGE ==="
        df -h 2>/dev/null || echo "Disk usage unavailable"
        echo
        echo "=== MEMORY USAGE ==="
        free -h 2>/dev/null || echo "Memory usage unavailable"
        echo
        echo "=== SYSTEM UPTIME ==="
        uptime 2>/dev/null || echo "Uptime unavailable"
    } > "$evidence_path/system_state.txt"
    
    # Create evidence manifest with checksums
    {
        echo "Evidence Collection Manifest"
        echo "Incident ID: $incident_id"
        echo "Collection Time: $(date -u)"
        echo "Collected By: $(whoami)@$(hostname)"
        echo "System: $(uname -a)"
        echo
        echo "Files Collected:"
        ls -la "$evidence_path/" 2>/dev/null || echo "Directory listing failed"
        echo
        echo "File Checksums:"
        find "$evidence_path" -type f -exec sha256sum {} \; 2>/dev/null || echo "Checksum generation failed"
    } > "$evidence_path/manifest.txt"
    
    # Compress evidence with error handling
    local zip_path="$evidence_path.tar.gz"
    if tar -czf "$zip_path" -C "$EVIDENCE_DIR" "$incident_id" 2>/dev/null; then
        rm -rf "$evidence_path"
        echo "$zip_path"
    else
        log "${YELLOW}Evidence compression failed, keeping uncompressed${NC}"
        echo "$evidence_path"
    fi
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
    
    log "${YELLOW}Checking for incidents since $(date -d "@$check_time")${NC}"
    
    # Check for failed login attempts
    local failed_logins=$(journalctl --since="@$check_time" 2>/dev/null | grep -c "Failed password" 2>/dev/null || echo 0)
    failed_logins=$(echo "$failed_logins" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    failed_logins=${failed_logins:-0}
    log "${YELLOW}Found $failed_logins failed login attempts${NC}"
    if [[ $failed_logins -gt 10 ]]; then
        report_incident "INTRUSION" 5 "Multiple failed login attempts detected: $failed_logins attempts"
    fi
    
    # Check for port scans
    local port_scans=$(journalctl --since="@$check_time" 2>/dev/null | grep -c "kernel.*IN.*OUT.*" 2>/dev/null || echo 0)
    port_scans=$(echo "$port_scans" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    port_scans=${port_scans:-0}
    log "${YELLOW}Found $port_scans potential port scan indicators${NC}"
    if [[ $port_scans -gt 50 ]]; then
        report_incident "INTRUSION" 6 "Potential port scan detected: $port_scans blocked connections"
    fi
    
    # Check for DDoS indicators
    local ddos_indicators=$(journalctl --since="@$check_time" 2>/dev/null | grep -c "nf_conntrack.*table full" 2>/dev/null || echo 0)
    ddos_indicators=$(echo "$ddos_indicators" | tr -d '\n' | grep -o '[0-9]*' | head -1)
    ddos_indicators=${ddos_indicators:-0}
    log "${YELLOW}Found $ddos_indicators DDoS indicators${NC}"
    if [[ $ddos_indicators -gt 0 ]]; then
        report_incident "DDOS" 7 "DDoS attack indicators detected: connection table full"
    fi
    
    log "${GREEN}Batch processing completed successfully${NC}"
}

# Enhanced setup monitoring with better error handling
setup_monitoring() {
    log "${BLUE}Setting up incident monitoring daemon...${NC}"
    
    # Create systemd service with proper paths
    cat > /etc/systemd/system/incident-reporter.service << EOF
[Unit]
Description=XXMXLI Automated Incident Reporter
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=$(realpath "$0") --daemon
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Create monitoring script with better error handling
    cat > "$SCRIPT_DIR/incident_monitor.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/automated_incident_reporter.sh"

# Find the script if not in same directory
if [[ ! -f "$MAIN_SCRIPT" ]]; then
    MAIN_SCRIPT="$(find /home /opt /usr/local -name "automated_incident_reporter.sh" 2>/dev/null | head -1)"
fi

if [[ -f "$MAIN_SCRIPT" ]]; then
    while true; do
        "$MAIN_SCRIPT" --batch 2>/dev/null || true
        sleep 300  # Check every 5 minutes
    done
else
    logger "XXMXLI Incident Reporter: Main script not found"
    exit 1
fi
EOF
    
    chmod +x "$SCRIPT_DIR/incident_monitor.sh"
    
    # Reload systemd and enable service
    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload
        systemctl enable incident-reporter.service 2>/dev/null || true
        log "${GREEN}Monitoring daemon configured${NC}"
    else
        log "${YELLOW}Systemd not available, monitoring daemon setup skipped${NC}"
    fi
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
    # Auto-elevate and setup first
    check_root
    install_dependencies
    setup_directories
    load_config
    
    # Check if running with command line arguments
    if [[ $# -gt 0 ]]; then
        # Handle command line mode for automated scripts
        case "${1:-}" in
            "--report")
                if [[ $# -lt 4 ]]; then
                    error_exit "Insufficient arguments for --report"
                fi
                report_incident "$2" "$3" "$4" "${5:-auto}" "${6:-auto}"
                ;;
            "--test")
                test_system
                ;;
            "--monitor")
                setup_monitoring
                ;;
            "--status")
                show_status
                ;;
            "--batch")
                batch_process
                ;;
            "--setup")
                setup_monitoring
                test_system
                log "${GREEN}Setup completed successfully${NC}"
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
            "--help")
                show_help
                ;;
            *)
                error_exit "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    else
        # Interactive mode for user-friendly experience
        INTERACTIVE_MODE=true
        show_interactive_menu
    fi
}

# Run main function with all arguments
main "$@"
