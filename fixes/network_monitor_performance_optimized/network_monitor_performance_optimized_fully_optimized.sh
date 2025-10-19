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


# Network M# Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ███╗   ██╗███████╗████████╗██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗"
    echo " ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝"
    echo " ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ "
    echo " ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██║   ██║██╔══██╗██╔═██╗ "
    echo " ██║ ╚████║███████╗   ██║   ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗"

# Optimized search function with timeout protection
optimized_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-30}"
    
    for tool in rg ag awk grep; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
                "rg") timeout "$timeout" rg --color=never "$pattern" "$file" 2>/dev/null && return 0 ;;
                "ag") timeout "$timeout" ag --nocolor "$pattern" "$file" 2>/dev/null && return 0 ;;
                "awk") timeout "$timeout" awk "/$pattern/" "$file" 2>/dev/null && return 0 ;;
                "grep") timeout "$timeout" grep "$pattern" "$file" 2>/dev/null && return 0 ;;
            esac
        fi
    done
    return 1
}

    echo " ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝"
    echo ""
    echo " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗"
    echo " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║"
    echo "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║"
    echo "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║"
    echo " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝"
    echo ""
    echo "    Network Traffic Monitor & Security Analysis Tool"
    echo "    Real-time Network Monitoring and Intrusion Detection"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
}lysis Tool
# Real-time Network Traffic Monitoring and Security Analysis
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
LOG_DIR="/var/log/network_monitor"
SCAN_INTERVAL=5
CAPTURE_FILE="network_capture.pcap"
ALERT_THRESHOLD_CONNECTIONS=100
ALERT_THRESHOLD_BANDWIDTH=10000  # KB/s

# Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ███╗   ██╗███████╗████████╗███╗   ███╗ ██████╗ ███╗   ██╗"
    echo " ████╗  ██║██╔════╝╚══██╔══╝████╗ ████║██╔═══██╗████╗  ██║"
    echo " ██╔██╗ ██║█████╗     ██║   ██╔████╔██║██║   ██║██╔██╗ ██║"
    echo " ██║╚██╗██║██╔══╝     ██║   ██║╚██╔╝██║██║   ██║██║╚██╗██║"
    echo " ██║ ╚████║███████╗   ██║   ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║"
    echo " ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
    echo ""
    echo "    Network Monitoring & Analysis Tool"
    echo "    Real-time Traffic Analysis & Security Monitoring"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Running with root privileges${NC}"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing network monitoring dependencies...${NC}"
    
    # Detect package manager and install tools
    if command -v apt &> /dev/null; then
        apt update
        apt install -y netstat-nat tcpdump nmap iftop nethogs ss iproute2 net-tools iptraf-ng bmon vnstat
    elif command -v yum &> /dev/null; then
        yum install -y tcpdump nmap iftop nethogs iproute2 net-tools iptraf-ng bmon vnstat
    elif command -v pacman &> /dev/null; then
        pacman -S tcpdump nmap iftop nethogs iproute2 net-tools iptraf-ng bmon vnstat --noconfirm
    elif command -v zypper &> /dev/null; then
        zypper install -y tcpdump nmap iftop nethogs iproute2 net-tools iptraf-ng bmon vnstat
    else
        echo -e "${RED}❌ Unsupported package manager${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Function to create log directory
setup_logging() {
    mkdir -p "$LOG_DIR"
    echo -e "${GREEN}✅ Log directory created: $LOG_DIR${NC}"
}

# Function to get network interfaces
get_interfaces() {
    echo -e "${CYAN}🌐 Available Network Interfaces:${NC}"
    ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | grep -v lo | sed 's/^ *//' | nl -w2 -s') '
}

# Function to select interface
select_interface() {
    local interfaces=($(ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | grep -v lo | sed 's/^ *//'))
    
    if [ ${#interfaces[@]} -eq 0 ]; then
        echo -e "${RED}❌ No network interfaces found${NC}"
        exit 1
    elif [ ${#interfaces[@]} -eq 1 ]; then
        INTERFACE="${interfaces[0]}"
        echo -e "${GREEN}✅ Auto-selected interface: $INTERFACE${NC}"
    else
        get_interfaces
        echo ""
        read -p "Select interface number: " choice
        if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -le ${#interfaces[@]} ] && [ $choice -gt 0 ]; then
            INTERFACE="${interfaces[$((choice-1))]}"
            echo -e "${GREEN}✅ Selected interface: $INTERFACE${NC}"
        else
            echo -e "${RED}❌ Invalid selection${NC}"
            exit 1
        fi
    fi
}

# Function to monitor network connections
monitor_connections() {
    echo -e "${CYAN}🔍 Network Connection Monitoring${NC}"
    echo "=================================="
    
    while true; do
        clear
        echo -e "${CYAN}🔍 Active Network Connections - $(date)${NC}"
        echo "=========================================="
        
        # Show listening ports
        echo -e "${YELLOW}📡 Listening Ports:${NC}"
        ss -tuln | head -20
        echo ""
        
        # Show established connections
        echo -e "${YELLOW}🔗 Established Connections:${NC}"
        ss -tun state established | head -15
        echo ""
        
        # Count connections
        local conn_count=$(ss -tun state established | wc -l)
        echo -e "${WHITE}Total Established Connections: $conn_count${NC}"
        
        # Alert if too many connections
        if [ $conn_count -gt $ALERT_THRESHOLD_CONNECTIONS ]; then
            echo -e "${RED}⚠️ HIGH CONNECTION COUNT ALERT: $conn_count connections${NC}"
        fi
        
        echo ""
        echo -e "${MAGENTA}Press Ctrl+C to return to menu${NC}"
        sleep $SCAN_INTERVAL
    done
}

# Function to monitor bandwidth
monitor_bandwidth() {
    echo -e "${CYAN}📊 Bandwidth Monitoring${NC}"
    echo "======================="
    
    if ! command -v iftop &> /dev/null; then
        echo -e "${RED}❌ iftop not installed${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Starting iftop for interface: $INTERFACE${NC}"
    echo -e "${MAGENTA}Press 'q' to quit iftop${NC}"
    sleep 2
    
    iftop -i "$INTERFACE" -t -s 10
}

# Function to capture packets
capture_packets() {
    echo -e "${CYAN}📦 Packet Capture${NC}"
    echo "================="
    
    if ! command -v tcpdump &> /dev/null; then
        echo -e "${RED}❌ tcpdump not installed${NC}"
        return 1
    fi
    
    local capture_file="$LOG_DIR/capture_$(date +%Y%m%d_%H%M%S).pcap"
    
    echo -e "${YELLOW}Starting packet capture on interface: $INTERFACE${NC}"
    echo -e "${YELLOW}Capture file: $capture_file${NC}"
    echo -e "${MAGENTA}Press Ctrl+C to stop capture${NC}"
    echo ""
    
    tcpdump -i "$INTERFACE" -w "$capture_file" -v
    
    echo ""
    echo -e "${GREEN}✅ Capture saved to: $capture_file${NC}"
    
    # Show basic stats
    if [ -f "$capture_file" ]; then
        local packet_count=$(tcpdump -r "$capture_file" 2>/dev/null | wc -l)
        local file_size=$(du -h "$capture_file" | cut -f1)
        echo -e "${CYAN}📈 Capture Statistics:${NC}"
        echo "Packets captured: $packet_count"
        echo "File size: $file_size"
    fi
}

# Function to analyze captured packets
analyze_packets() {
    echo -e "${CYAN}🔬 Packet Analysis${NC}"
    echo "=================="
    
    # List available capture files
    local capture_files=($(find "$LOG_DIR" -name "*.pcap" 2>/dev/null))
    
    if [ ${#capture_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No capture files found in $LOG_DIR${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Available capture files:${NC}"
    for i in "${!capture_files[@]}"; do
        local file="${capture_files[$i]}"
        local size=$(du -h "$file" | cut -f1)
        local date=$(stat -c %y "$file" | cut -d'.' -f1)
        echo "$(($i+1))) $(basename "$file") ($size) - $date"
    done
    echo ""
    
    read -p "Select file number for analysis: " choice
    if [[ $choice =~ ^[0-9]+$ ]] && [ $choice -le ${#capture_files[@]} ] && [ $choice -gt 0 ]; then
        local selected_file="${capture_files[$((choice-1))]}"
        echo -e "${GREEN}✅ Analyzing: $(basename "$selected_file")${NC}"
        echo ""
        
        # Basic analysis
        echo -e "${YELLOW}📊 Packet Statistics:${NC}"
        tcpdump -r "$selected_file" 2>/dev/null | head -20
        echo ""
        
        # Protocol distribution
        echo -e "${YELLOW}🌐 Protocol Distribution:${NC}"
        tcpdump -r "$selected_file" -n 2>/dev/null | awk '{print $3}' | cut -d'.' -f1-4 | sort | uniq -c | sort -nr | head -10
        echo ""
        
        # Top talkers
        echo -e "${YELLOW}💬 Top Source IPs:${NC}"
        tcpdump -r "$selected_file" -n 2>/dev/null | awk '{print $3}' | cut -d'.' -f1-4 | sort | uniq -c | sort -nr | head -10
        
    else
        echo -e "${RED}❌ Invalid selection${NC}"
    fi
}

# Function to scan network for devices
scan_network() {
    echo -e "${CYAN}🔍 Network Device Scan${NC}"
    echo "======================"
    
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}❌ nmap not installed${NC}"
        return 1
    fi
    
    # Get network range
    local network_range=$(ip route | grep "$INTERFACE" | grep -E '192\.168\.|10\.|172\.' | head -1 | awk '{print $1}')
    
    if [ -z "$network_range" ]; then
        echo -e "${YELLOW}⚠️ Could not determine network range, using common ranges${NC}"
        echo "Select network range to scan:"
        echo "1) 192.168.1.0/24"
        echo "2) 192.168.0.0/24"
        echo "3) 10.0.0.0/24"
        echo "4) Custom range"
        read -p "Enter choice: " range_choice
        
        case $range_choice in
            1) network_range="192.168.1.0/24" ;;
            2) network_range="192.168.0.0/24" ;;
            3) network_range="10.0.0.0/24" ;;
            4) read -p "Enter custom range (e.g., 192.168.1.0/24): " network_range ;;
            *) echo -e "${RED}❌ Invalid choice${NC}"; return 1 ;;
        esac
    fi
    
    echo -e "${YELLOW}🔍 Scanning network range: $network_range${NC}"
    echo ""
    
    # Ping sweep
    echo -e "${CYAN}📡 Ping Sweep:${NC}"
    nmap -sn "$network_range" | grep -E "Nmap scan report|MAC Address"
    echo ""
    
    # Port scan on live hosts
    echo -e "${CYAN}🔍 Quick port scan on live hosts:${NC}"
    nmap -F "$network_range" | grep -E "Nmap scan report|open"
}

# Function to monitor process network usage
monitor_process_network() {
    echo -e "${CYAN}⚙️ Process Network Usage${NC}"
    echo "========================="
    
    if command -v nethogs &> /dev/null; then
        echo -e "${YELLOW}Starting nethogs for interface: $INTERFACE${NC}"
        echo -e "${MAGENTA}Press 'q' to quit nethogs${NC}"
        sleep 2
        nethogs "$INTERFACE"
    else
        echo -e "${YELLOW}⚠️ nethogs not available, showing netstat info${NC}"
        echo ""
        echo -e "${CYAN}🔍 Network connections by process:${NC}"
        netstat -tulpn | grep -E 'tcp|udp' | head -20
    fi
}

# Function to check firewall status
check_firewall_status() {
    echo -e "${CYAN}🛡️ Firewall Status${NC}"
    echo "=================="
    
    # Check iptables
    if command -v iptables &> /dev/null; then
        echo -e "${YELLOW}📋 iptables rules:${NC}"
        iptables -L -n --line-numbers | head -30
        echo ""
    fi
    
    # Check UFW
    if command -v ufw &> /dev/null; then
        echo -e "${YELLOW}🔥 UFW Status:${NC}"
        ufw status verbose
        echo ""
    fi
    
    # Check firewalld
    if command -v firewall-cmd &> /dev/null; then
        echo -e "${YELLOW}🔥 firewalld Status:${NC}"
        firewall-cmd --state 2>/dev/null && firewall-cmd --list-all
        echo ""
    fi
}

# Function to generate network report
generate_report() {
    echo -e "${CYAN}📄 Generating Network Report${NC}"
    echo "============================="
    
    local report_file="$LOG_DIR/network_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "NETWORK MONITORING REPORT"
        echo "========================="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "Interface: $INTERFACE"
        echo ""
        
        echo "SYSTEM INFORMATION"
        echo "=================="
        uname -a
        echo ""
        
        echo "NETWORK INTERFACES"
        echo "=================="
        ip addr show
        echo ""
        
        echo "ROUTING TABLE"
        echo "============="
        ip route show
        echo ""
        
        echo "LISTENING PORTS"
        echo "==============="
        ss -tuln
        echo ""
        
        echo "ESTABLISHED CONNECTIONS"
        echo "======================="
        ss -tun state established
        echo ""
        
        echo "NETWORK STATISTICS"
        echo "=================="
        cat /proc/net/dev
        echo ""
        
        echo "FIREWALL STATUS"
        echo "==============="
        if command -v iptables &> /dev/null; then
            echo "iptables rules:"
            iptables -L -n
            echo ""
        fi
        
        if command -v ufw &> /dev/null; then
            echo "UFW status:"
            ufw status verbose
            echo ""
        fi
        
    } > "$report_file"
    
    echo -e "${GREEN}✅ Report saved to: $report_file${NC}"
    
    # Show report summary
    local lines=$(wc -l < "$report_file")
    local size=$(du -h "$report_file" | cut -f1)
    echo -e "${CYAN}📈 Report Statistics:${NC}"
    echo "Lines: $lines"
    echo "Size: $size"
}

# Function to show real-time network stats
show_network_stats() {
    echo -e "${CYAN}📊 Real-time Network Statistics${NC}"
    echo "================================"
    
    while true; do
        clear
        echo -e "${CYAN}📊 Network Statistics - $(date)${NC}"
        echo "================================"
        
        # Interface statistics
        echo -e "${YELLOW}🌐 Interface Statistics ($INTERFACE):${NC}"
        cat /proc/net/dev | grep "$INTERFACE" | awk '{printf "RX: %s bytes (%s packets)\nTX: %s bytes (%s packets)\n", $2, $3, $10, $11}'
        echo ""
        
        # Memory and CPU for network processes
        echo -e "${YELLOW}⚙️ Network-related processes:${NC}"
        ps aux | grep -E 'ssh|http|ftp|dns|network' | grep -v grep | head -5
        echo ""
        
        # Load average
        echo -e "${YELLOW}📈 System Load:${NC}"
        uptime
        echo ""
        
        # Disk usage for logs
        echo -e "${YELLOW}💾 Log Directory Usage:${NC}"
        du -sh "$LOG_DIR" 2>/dev/null || echo "Log directory not found"
        echo ""
        
        echo -e "${MAGENTA}Press Ctrl+C to return to menu${NC}"
        sleep $SCAN_INTERVAL
    done
}

# Function to show menu
show_menu() {
    echo -e "${GREEN}🎯 Network Monitoring Menu:${NC}"
    echo "============================="
    echo -e "${WHITE}[1] Monitor network connections${NC}"
    echo -e "${WHITE}[2] Monitor bandwidth usage${NC}"
    echo -e "${WHITE}[3] Capture network packets${NC}"
    echo -e "${WHITE}[4] Analyze captured packets${NC}"
    echo -e "${WHITE}[5] Scan network for devices${NC}"
    echo -e "${WHITE}[6] Monitor process network usage${NC}"
    echo -e "${WHITE}[7] Check firewall status${NC}"
    echo -e "${WHITE}[8] Show real-time network stats${NC}"
    echo -e "${WHITE}[9] Generate network report${NC}"
    echo -e "${WHITE}[10] Install dependencies${NC}"
    echo -e "${WHITE}[0] Exit${NC}"
    echo ""
}

# Main script execution
show_banner

# Check for root privileges
check_root

# Setup logging
setup_logging

# Select network interface
select_interface

echo ""

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (0-10): " choice
    
    case $choice in
        1)
            monitor_connections
            ;;
        2)
            monitor_bandwidth
            ;;
        3)
            capture_packets
            read -p "Press Enter to continue..."
            ;;
        4)
            analyze_packets
            read -p "Press Enter to continue..."
            ;;
        5)
            scan_network
            read -p "Press Enter to continue..."
            ;;
        6)
            monitor_process_network
            ;;
        7)
            check_firewall_status
            read -p "Press Enter to continue..."
            ;;
        8)
            show_network_stats
            ;;
        9)
            generate_report
            read -p "Press Enter to continue..."
            ;;
        10)
            install_dependencies
            read -p "Press Enter to continue..."
            ;;
        0)
            echo -e "${GREEN}👋 Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid choice!${NC}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
