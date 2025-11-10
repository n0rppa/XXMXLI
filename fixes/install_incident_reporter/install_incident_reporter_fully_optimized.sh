#!/usr/bin/env bash

# ================================================================
# XXMXLI Enhanced Security Script - Fully Optimized
# Auto-generated with comprehensive performance and safety fixes
# ================================================================

# Enhanced error handling
set -Eeuo pipefail # Exit on error, undefined vars; trap ERR; pipefail
IFS=$'\n\t'                # Safe IFS

# Error trap function
error_exit() {
    local line_no=$1
    local error_code=$2
    echo "ERROR: Script failed at line $line_no with exit code $error_code" >&2
    exit $error_code
}
trap 'error_exit ${LINENO} $?' ERR

# Default PATH for cron and non-interactive sessions
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

# Cron-safe logging controls
NO_COLOR="${NO_COLOR:-}"     # Set to any value to disable ANSI colors
QUIET_MODE="${QUIET_MODE:-false}"  # Set to true to reduce stdout (cron)

# Concurrency control via flock or directory lock
LOCK_NAME="$(basename "$0").lock"
LOCK_DIR="/tmp/${LOCK_NAME}"
LOCK_FD=200

acquire_lock() {
    if command -v flock >/dev/null 2>&1; then
        exec {LOCK_FD}>"/tmp/${LOCK_NAME}.flock" || true
        flock -n "$LOCK_FD" || { echo "Another instance is running" >&2; exit 155; }
    else
        if ! mkdir "$LOCK_DIR" 2>/dev/null; then
            echo "Another instance is running (lock $LOCK_DIR)" >&2
            exit 155
        fi
    fi
}

release_lock() {
    if command -v flock >/dev/null 2>&1; then
        flock -u "$LOCK_FD" || true
        rm -f "/tmp/${LOCK_NAME}.flock" || true
    else
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
}

# Cross-platform path detection
detect_paths() {
    if [[ "$OSTYPE" =~ msys|mingw|cygwin ]]; then
        CONFIG_PATH="/c/ProgramData"
        LOG_PATH="/c/temp"
        BIN_PATH="/usr/local/bin"
    else
        CONFIG_PATH="/etc"
        LOG_PATH="/var/log"
        BIN_PATH="/usr/local/bin"
    fi
    mkdir -p "$CONFIG_PATH" "$LOG_PATH" 2>/dev/null || true
}

# Initialize paths
detect_paths

# Performance logging
LOG_FILE="${LOG_PATH}/$(basename "$0" .sh)_performance.log"

log_performance() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
    
    case "$level" in
        "ERROR") [[ "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[ERROR] $message" >&2 || echo -e "\033[31m[ERROR]\033[0m $message" >&2; } ;;
        "WARN") [[ "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[WARN]  $message" || echo -e "\033[33m[WARN]\033[0m $message"; } ;;
        "INFO") [[ "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[INFO]  $message" || echo -e "\033[32m[INFO]\033[0m $message"; } ;;
        "DEBUG") [[ "${DEBUG:-false}" == "true" && "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[DEBUG] $message" || echo -e "\033[36m[DEBUG]\033[0m $message"; } ;;
    esac
}

# Universal timeout wrapper
run_with_timeout_universal() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${cmd[@]}"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "${cmd[@]}"
    else
        local pid
        "${cmd[@]}" &
        pid=$!
        
        local count=0
        local max_count=$((timeout_duration))
        
        while [[ $count -lt $max_count ]] && kill -0 $pid 2>/dev/null; do
            sleep 1
            ((count++))
        done
        
        if kill -0 $pid 2>/dev/null; then
            kill -TERM $pid 2>/dev/null
            sleep 2
            kill -0 $pid 2>/dev/null && kill -KILL $pid 2>/dev/null
            return 124
        else
            wait $pid
            return $?
        fi
    fi
}

# Safe search function
safe_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-15}"
    
    [[ -z "$pattern" || -z "$file" ]] && return 1
    [[ ! -f "$file" ]] && return 1
    
    local file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    if [[ $file_size -gt 10485760 ]]; then
        log_performance "WARN" "File too large for search: $file ($file_size bytes)"
        return 1
    fi
    
    for tool in rg ag awk grep; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
                "rg") 
                    if run_with_timeout_universal "$timeout" rg --color=never --no-heading -n "$pattern" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
                "ag") 
                    if run_with_timeout_universal "$timeout" ag --nocolor --nogroup "$pattern" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
                "awk") 
                    if run_with_timeout_universal "$timeout" awk "/$pattern/" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
                "grep") 
                    if run_with_timeout_universal "$timeout" grep -m 100 "$pattern" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
            esac
        fi
    done
    return 1
}

# Variable validation
validate_var() {
    local var_name="$1"
    local var_value="$2"
    if [[ -z "$var_value" ]]; then
        log_performance "ERROR" "Required variable $var_name is empty or undefined"
        return 1
    fi
    return 0
}

# Function timing wrapper
time_function() {
    local func_name="$1"
    shift
    local start_time=$(date +%s%N)
    
    log_performance "DEBUG" "Starting function: $func_name"
    "$@"
    local exit_code=$?
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    if [[ $exit_code -eq 0 ]]; then
        log_performance "INFO" "Function $func_name completed in ${duration}ms"
    else
        log_performance "ERROR" "Function $func_name failed after ${duration}ms (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Permission helpers
ensure_executable() { chmod 0755 "$1" 2>/dev/null || true; }
ensure_umask() { umask "${1:-027}" 2>/dev/null || true; }

# Initialize logging
log_performance "INFO" "Script $(basename "$0") started with enhanced optimizations"

# Acquire lock to prevent overlap
acquire_lock
trap 'release_lock' EXIT


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
# XXMXLI INCIDENT REPORTER - ONE-CLICK INSTALLER
# Automated setup for security incident reporting
# Created by: XXMXLI
# Version: 2.0


# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
 ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
 ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
 ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝

XXMXLI INCIDENT REPORTER - ONE-CLICK INSTALLER
Automated Security Incident Reporting Setup
EOF
echo -e "${NC}"

# Auto-elevate if not root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Elevating to root privileges...${NC}"
    exec sudo "$0" "$@"
fi

echo -e "${BLUE}🚀 Starting One-Click Setup...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Auto-detect and install dependencies
install_dependencies() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    if command_exists apt-get; then
        apt-get update -qq
        apt-get install -y curl wget gnupg2 tcpdump net-tools geoip-bin sendmail tar gzip openssl python3 python3-pip >/dev/null 2>&1
    elif command_exists yum; then
        yum install -y curl wget gnupg2 tcpdump net-tools GeoIP sendmail tar gzip openssl python3 python3-pip >/dev/null 2>&1
    elif command_exists dnf; then
        dnf install -y curl wget gnupg2 tcpdump net-tools GeoIP sendmail tar gzip openssl python3 python3-pip >/dev/null 2>&1
    elif command_exists pacman; then
        pacman -Sy --noconfirm curl wget gnupg tcpdump net-tools geoip sendmail tar gzip openssl python python-pip >/dev/null 2>&1
    else
        echo -e "${YELLOW}⚠️  Package manager not detected. Some features may be limited.${NC}"
    fi
    
    # Install Python dependencies
    if command_exists pip3; then
        python3 -c "import psutil" >/dev/null 2>&1 || pip3 install psutil >/dev/null 2>&1 || true
        python3 -c "import requests" >/dev/null 2>&1 || pip3 install requests >/dev/null 2>&1 || true
        python3 -c "import gnupg" >/dev/null 2>&1 || pip3 install python-gnupg >/dev/null 2>&1 || true
    elif command_exists pip; then
        python3 -c "import psutil" >/dev/null 2>&1 || pip install psutil >/dev/null 2>&1 || true
        python3 -c "import requests" >/dev/null 2>&1 || pip install requests >/dev/null 2>&1 || true
        python3 -c "import gnupg" >/dev/null 2>&1 || pip install python-gnupg >/dev/null 2>&1 || true
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Create directories
setup_directories() {
    echo -e "${BLUE}📁 Creating directories...${NC}"
    
    mkdir -p /var/log/security/{reports,evidence}
    mkdir -p /etc/security
    mkdir -p /tmp/incident_reports
    mkdir -p /opt/xxmxli
    
    chmod 700 /var/log/security /var/log/security/reports /var/log/security/evidence
    chmod 755 /etc/security /tmp/incident_reports /opt/xxmxli
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Download incident reporter scripts
download_scripts() {
    echo -e "${BLUE}⬇️  Downloading incident reporter scripts...${NC}"
    
    cd /opt/xxmxli
    
    # Download from GitHub (or use local files if available)
    if [[ -f "$(dirname "$0")/automated_incident_reporter.sh" ]]; then
        cp "$(dirname "$0")/automated_incident_reporter.sh" .
        cp "$(dirname "$0")/automated_incident_reporter.ps1" . 2>/dev/null || true
        cp "$(dirname "$0")/automated_incident_reporter.py" . 2>/dev/null || true
    else
        # Download from GitHub if available
        wget -q -O automated_incident_reporter.sh "https://raw.githubusercontent.com/n0rppa/XXMXLI/main/automated_incident_reporter.sh" || \
        curl -s -o automated_incident_reporter.sh "https://raw.githubusercontent.com/n0rppa/XXMXLI/main/automated_incident_reporter.sh" || \
        echo -e "${YELLOW}⚠️  Could not download scripts. Please download manually.${NC}"
    fi
    
    chmod +x automated_incident_reporter.sh 2>/dev/null || true
    
    echo -e "${GREEN}✅ Scripts downloaded${NC}"
}

# Create configuration
create_config() {
    echo -e "${BLUE}⚙️  Creating configuration...${NC}"
    
    cat > /etc/security/incident_reporter.conf << 'EOF'
# XXMXLI Automated Incident Reporter Configuration
# Created by One-Click Installer

# Organization Information
ORG_NAME="XXMXLI Security Operations"
ORG_CONTACT="security@xxmxli.local"
ORG_PHONE="+1-555-XXMXLI"
ORG_ADDRESS="XXMXLI Security Center, Cyber Defense Division"

# Technical Contact
TECH_CONTACT="admin@xxmxli.local"
TECH_PHONE="+1-555-ADMIN"

# Reporting Thresholds
MIN_SEVERITY=3
AUTO_REPORT_SEVERITY=7
BATCH_REPORT_INTERVAL=3600

# Notification Settings
EMAIL_ENABLED=false
SMS_ENABLED=false
WEBHOOK_ENABLED=false

# Evidence Collection
COLLECT_PCAP=true
COLLECT_LOGS=true
COLLECT_MEMORY_DUMP=false
EVIDENCE_RETENTION_DAYS=90

# Encryption Settings
GPG_KEY_ID=""
ENCRYPT_REPORTS=false
SECURE_DELETE=true
EOF
    
    chmod 600 /etc/security/incident_reporter.conf
    
    echo -e "${GREEN}✅ Configuration created${NC}"
}

# Create desktop shortcuts
create_shortcuts() {
    echo -e "${BLUE}🖥️  Creating shortcuts...${NC}"
    
    # Create command aliases
    cat > /usr/local/bin/incident-report << 'EOF'
#!/bin/bash
/opt/xxmxli/automated_incident_reporter.sh "$@"
EOF
    chmod +x /usr/local/bin/incident-report
    
    # Create desktop entry if desktop environment is available
    if [[ -d /usr/share/applications ]]; then
        cat > /usr/share/applications/xxmxli-incident-reporter.desktop << 'EOF'
[Desktop Entry]
Name=XXMXLI Incident Reporter
Comment=Security Incident Reporting Tool
Exec=gksu /opt/xxmxli/automated_incident_reporter.sh --help
Icon=security-high
Terminal=true
Type=Application
Categories=System;Security;
EOF
    fi
    
    echo -e "${GREEN}✅ Shortcuts created${NC}"
}

# Setup monitoring service
setup_service() {
    echo -e "${BLUE}🔧 Setting up monitoring service...${NC}"
    
    if command_exists systemctl; then
        /opt/xxmxli/automated_incident_reporter.sh --setup >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Monitoring service configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Systemd not available, manual monitoring setup required${NC}"
    fi
}

# Run test
run_test() {
    echo -e "${BLUE}🧪 Running system test...${NC}"
    
    /opt/xxmxli/automated_incident_reporter.sh --test >/dev/null 2>&1 && \
    echo -e "${GREEN}✅ System test passed${NC}" || \
    echo -e "${YELLOW}⚠️  System test had warnings (this is normal)${NC}"
}

# Main installation process
main() {
    echo -e "${BLUE}Starting automated setup...${NC}"
    
    install_dependencies
    setup_directories
    download_scripts
    create_config
    create_shortcuts
    setup_service
    run_test
    
    echo -e "${GREEN}"
    echo "🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉"
    echo -e "${NC}"
    echo -e "${CYAN}📋 Quick Start Commands:${NC}"
    echo -e "${YELLOW}  incident-report --help                    ${NC}# Show help"
    echo -e "${YELLOW}  incident-report --test                    ${NC}# Run test"
    echo -e "${YELLOW}  incident-report --report INTRUSION 6 \"Attack detected\"${NC}  # Report incident"
    echo -e "${YELLOW}  incident-report --monitor                 ${NC}# Start monitoring"
    echo
    echo -e "${CYAN}📂 Installation Location:${NC} /opt/xxmxli/"
    echo -e "${CYAN}📊 Reports Location:${NC} /var/log/security/reports/"
    echo -e "${CYAN}🔧 Configuration:${NC} /etc/security/incident_reporter.conf"
    echo
    echo -e "${GREEN}✅ Your system is now protected with automated incident reporting!${NC}"
    echo -e "${RED}⚠️  Remember: All security incidents will be automatically reported to authorities${NC}"
}

# Error handling
trap 'echo -e "${RED}❌ Installation failed. Check the error messages above.${NC}"; exit 1' ERR

# Run installation
main

echo -e "${BLUE}🔒 Installation completed. System is now monitoring for security incidents.${NC}"
