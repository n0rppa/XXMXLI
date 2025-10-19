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


# IPv6 & Geolocation Disable Script for Linux
# Bash Script for Privacy and Network Configuration
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ██╗██████╗ ██╗   ██╗ ██████╗      ██████╗ ███████╗ ██████╗ "
    echo " ██║██╔══██╗██║   ██║██╔════╝     ██╔════╝ ██╔════╝██╔═══██╗"
    echo " ██║██████╔╝██║   ██║███████╗     ██║  ███╗█████╗  ██║   ██║"
    echo " ██║██╔═══╝ ╚██╗ ██╔╝██╔═══██╗    ██║   ██║██╔══╝  ██║   ██║"
    echo " ██║██║      ╚████╔╝ ╚██████╔╝    ╚██████╔╝███████╗╚██████╔╝"
    echo " ╚═╝╚═╝       ╚═══╝   ╚═════╝      ╚═════╝ ╚══════╝ ╚═════╝ "
    echo ""
    echo "    IPv6 & Geolocation Disable Tool for Linux"
    echo "    Privacy Protection and Network Configuration"
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

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo -e "${CYAN}📋 Detected OS: $OS $VER${NC}"
}

# Function to backup current settings
backup_settings() {
    echo -e "${YELLOW}💾 Creating backup of current settings...${NC}"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="network_privacy_backup_${timestamp}.conf"
    
    {
        echo "# Network Privacy Settings Backup - $timestamp"
        echo "# Generated by XXMXLI IPv6 & Geolocation Disable Tool"
        echo ""
        
        echo "# IPv6 Status"
        echo "IPv6_PROC_DISABLE=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo 'unknown')"
        echo "IPv6_PROC_AUTOCONF=$(cat /proc/sys/net/ipv6/conf/all/autoconf 2>/dev/null || echo 'unknown')"
        echo "IPv6_PROC_ACCEPT_RA=$(cat /proc/sys/net/ipv6/conf/all/accept_ra 2>/dev/null || echo 'unknown')"
        
        echo ""
        echo "# Network Interfaces IPv6 Status"
        for interface in $(ls /sys/class/net/); do
            if [[ $interface != "lo" ]]; then
                echo "IPv6_${interface^^}_DISABLE=$(cat /proc/sys/net/ipv6/conf/$interface/disable_ipv6 2>/dev/null || echo 'unknown')"
            fi
        done
        
        echo ""
        echo "# Systemctl Services Status"
        systemctl is-enabled systemd-resolved 2>/dev/null && echo "SYSTEMD_RESOLVED_ENABLED=true" || echo "SYSTEMD_RESOLVED_ENABLED=false"
        systemctl is-enabled NetworkManager 2>/dev/null && echo "NETWORKMANAGER_ENABLED=true" || echo "NETWORKMANAGER_ENABLED=false"
        
        echo ""
        echo "# Geolocation Services (if any)"
        ps aux | grep -i "location\|geo" | grep -v grep | head -5
        
    } > "$backup_file"
    
    echo -e "${GREEN}✅ Backup saved to: $backup_file${NC}"
    echo -e "${CYAN}📁 Use this file to restore settings if needed${NC}"
}

# Function to disable IPv6
disable_ipv6() {
    echo -e "${YELLOW}🔄 Disabling IPv6...${NC}"
    
    # Method 1: Kernel parameters (immediate effect)
    echo -e "${CYAN}📝 Setting kernel parameters...${NC}"
    
    # Disable IPv6 for all interfaces
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    
    # Disable IPv6 autoconfig
    echo 0 > /proc/sys/net/ipv6/conf/all/autoconf
    echo 0 > /proc/sys/net/ipv6/conf/default/autoconf
    
    # Disable IPv6 router advertisements
    echo 0 > /proc/sys/net/ipv6/conf/all/accept_ra
    echo 0 > /proc/sys/net/ipv6/conf/default/accept_ra
    
    # Disable IPv6 for specific interfaces
    for interface in $(ls /sys/class/net/); do
        if [[ $interface != "lo" ]]; then
            echo 1 > /proc/sys/net/ipv6/conf/$interface/disable_ipv6 2>/dev/null
            echo -e "  ✓ Disabled IPv6 on: $interface" -e "${GREEN}"
        fi
    done
    
    # Method 2: Persistent configuration via sysctl
    echo -e "${CYAN}📝 Creating persistent sysctl configuration...${NC}"
    
    cat > /etc/sysctl.d/99-disable-ipv6.conf << EOF
# Disable IPv6 - Generated by XXMXLI Privacy Tool
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
net.ipv6.conf.all.autoconf = 0
net.ipv6.conf.default.autoconf = 0
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF
    
    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-disable-ipv6.conf >/dev/null 2>&1
    
    # Method 3: GRUB configuration (requires reboot)
    echo -e "${CYAN}📝 Updating GRUB configuration...${NC}"
    
    if [ -f /etc/default/grub ]; then
        # Backup original grub file
        cp /etc/default/grub /etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)
        
        # Add IPv6 disable parameter
        if grep -q "ipv6.disable=1" /etc/default/grub; then
            echo -e "  ✓ IPv6 disable parameter already present in GRUB"
        else
            sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /' /etc/default/grub
            echo -e "  ✓ Added IPv6 disable parameter to GRUB"
        fi
        
        # Update GRUB
        if command -v update-grub >/dev/null 2>&1; then
            update-grub >/dev/null 2>&1
        elif command -v grub2-mkconfig >/dev/null 2>&1; then
            grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
        elif command -v grub-mkconfig >/dev/null 2>&1; then
            grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
        fi
        echo -e "  ✓ GRUB configuration updated"
    fi
    
    # Method 4: NetworkManager configuration (if present)
    if command -v nmcli >/dev/null 2>&1; then
        echo -e "${CYAN}📝 Configuring NetworkManager...${NC}"
        
        # Create NetworkManager configuration
        mkdir -p /etc/NetworkManager/conf.d/
        cat > /etc/NetworkManager/conf.d/99-disable-ipv6.conf << EOF
[connection]
ipv6.method=ignore
EOF
        
        # Restart NetworkManager if it's running
        if systemctl is-active NetworkManager >/dev/null 2>&1; then
            systemctl restart NetworkManager
            echo -e "  ✓ NetworkManager restarted with IPv6 disabled"
        fi
    fi
    
    echo -e "${GREEN}✅ IPv6 disabled successfully!${NC}"
    echo -e "${YELLOW}⚠️  A system reboot is recommended for full effect.${NC}"
}

# Function to enable IPv6
enable_ipv6() {
    echo -e "${YELLOW}🔄 Enabling IPv6...${NC}"
    
    # Enable IPv6 via kernel parameters
    echo -e "${CYAN}📝 Setting kernel parameters...${NC}"
    
    echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    echo 0 > /proc/sys/net/ipv6/conf/default/disable_ipv6
    echo 1 > /proc/sys/net/ipv6/conf/all/autoconf
    echo 1 > /proc/sys/net/ipv6/conf/default/autoconf
    echo 1 > /proc/sys/net/ipv6/conf/all/accept_ra
    echo 1 > /proc/sys/net/ipv6/conf/default/accept_ra
    
    # Enable IPv6 for specific interfaces
    for interface in $(ls /sys/class/net/); do
        if [[ $interface != "lo" ]]; then
            echo 0 > /proc/sys/net/ipv6/conf/$interface/disable_ipv6 2>/dev/null
            echo -e "  ✓ Enabled IPv6 on: $interface"
        fi
    done
    
    # Remove persistent configuration
    echo -e "${CYAN}📝 Removing persistent sysctl configuration...${NC}"
    rm -f /etc/sysctl.d/99-disable-ipv6.conf
    
    # Remove GRUB parameter
    echo -e "${CYAN}📝 Updating GRUB configuration...${NC}"
    if [ -f /etc/default/grub ]; then
        sed -i 's/ipv6.disable=1 //g' /etc/default/grub
        
        # Update GRUB
        if command -v update-grub >/dev/null 2>&1; then
            update-grub >/dev/null 2>&1
        elif command -v grub2-mkconfig >/dev/null 2>&1; then
            grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
        elif command -v grub-mkconfig >/dev/null 2>&1; then
            grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
        fi
        echo -e "  ✓ GRUB configuration updated"
    fi
    
    # Remove NetworkManager configuration
    rm -f /etc/NetworkManager/conf.d/99-disable-ipv6.conf
    
    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        systemctl restart NetworkManager
        echo -e "  ✓ NetworkManager restarted with IPv6 enabled"
    fi
    
    echo -e "${GREEN}✅ IPv6 enabled successfully!${NC}"
    echo -e "${YELLOW}⚠️  A system reboot is recommended for full effect.${NC}"
}

# Function to disable geolocation services
disable_geolocation() {
    echo -e "${YELLOW}🔄 Disabling Geolocation services...${NC}"
    
    # Disable GNOME location services
    if command -v gsettings >/dev/null 2>&1; then
        echo -e "${CYAN}📝 Disabling GNOME location services...${NC}"
        
        # For system-wide (requires dconf)
        sudo -u "$SUDO_USER" gsettings set org.gnome.system.location enabled false 2>/dev/null || true
        sudo -u "$SUDO_USER" gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true
        sudo -u "$SUDO_USER" gsettings set org.gnome.desktop.privacy send-software-usage-stats false 2>/dev/null || true
        
        echo -e "  ✓ GNOME location services disabled"
    fi
    
    # Disable geoclue service (if present)
    if systemctl list-unit-files | grep -q geoclue; then
        echo -e "${CYAN}🛑 Disabling geoclue service...${NC}"
        systemctl stop geoclue.service 2>/dev/null || true
        systemctl disable geoclue.service 2>/dev/null || true
        systemctl mask geoclue.service 2>/dev/null || true
        echo -e "  ✓ Geoclue service disabled and masked"
    fi
    
    # Create geoclue configuration to disable location
    if [ -d /etc/geoclue ]; then
        echo -e "${CYAN}📝 Configuring geoclue to deny location access...${NC}"
        
        mkdir -p /etc/geoclue/conf.d/
        cat > /etc/geoclue/conf.d/99-disable-location.conf << EOF
# Disable location services - Generated by XXMXLI Privacy Tool
[agent]
whitelist=

[wifi]
enable=false

[3g]
enable=false

[cdma]
enable=false

[modem-gps]
enable=false

[network-nmea]
enable=false
EOF
        echo -e "  ✓ Geoclue configuration updated"
    fi
    
    # Block common location services processes
    echo -e "${CYAN}🚫 Blocking common location services...${NC}"
    
    # Kill running location services
    pkill -f "location" 2>/dev/null || true
    pkill -f "geoclue" 2>/dev/null || true
    pkill -f "gps" 2>/dev/null || true
    
    # Block location-related network connections (optional)
    # This is commented out as it might be too aggressive
    # echo -e "${CYAN}🌐 Blocking location-related domains...${NC}"
    # Add to /etc/hosts to block location services
    # echo "127.0.0.1 location.services.mozilla.com" >> /etc/hosts
    # echo "127.0.0.1 www.googleapis.com" >> /etc/hosts
    
    echo -e "${GREEN}✅ Geolocation services disabled!${NC}"
}

# Function to enable geolocation services
enable_geolocation() {
    echo -e "${YELLOW}🔄 Enabling Geolocation services...${NC}"
    
    # Enable GNOME location services
    if command -v gsettings >/dev/null 2>&1; then
        echo -e "${CYAN}📝 Enabling GNOME location services...${NC}"
        sudo -u "$SUDO_USER" gsettings set org.gnome.system.location enabled true 2>/dev/null || true
        echo -e "  ✓ GNOME location services enabled"
    fi
    
    # Enable geoclue service
    if systemctl list-unit-files | grep -q geoclue; then
        echo -e "${CYAN}▶️ Enabling geoclue service...${NC}"
        systemctl unmask geoclue.service 2>/dev/null || true
        systemctl enable geoclue.service 2>/dev/null || true
        systemctl start geoclue.service 2>/dev/null || true
        echo -e "  ✓ Geoclue service enabled and started"
    fi
    
    # Remove geoclue restriction configuration
    rm -f /etc/geoclue/conf.d/99-disable-location.conf
    echo -e "  ✓ Geoclue restrictions removed"
    
    echo -e "${GREEN}✅ Geolocation services enabled!${NC}"
}

# Function to show current status
show_status() {
    echo -e "${GREEN}📊 Current Privacy Settings Status:${NC}"
    echo -e "${GREEN}===================================${NC}"
    
    # IPv6 Status
    echo -e "${CYAN}🌐 IPv6 Status:${NC}"
    
    local ipv6_disabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo "unknown")
    if [ "$ipv6_disabled" = "1" ]; then
        echo -e "  Status: ${RED}DISABLED${NC}"
    elif [ "$ipv6_disabled" = "0" ]; then
        echo -e "  Status: ${GREEN}ENABLED${NC}"
    else
        echo -e "  Status: ${YELLOW}UNKNOWN${NC}"
    fi
    
    # Check individual interfaces
    for interface in $(ls /sys/class/net/); do
        if [[ $interface != "lo" ]]; then
            local if_ipv6_disabled=$(cat /proc/sys/net/ipv6/conf/$interface/disable_ipv6 2>/dev/null || echo "unknown")
            if [ "$if_ipv6_disabled" = "1" ]; then
                echo -e "  $interface: ${RED}DISABLED${NC}"
            elif [ "$if_ipv6_disabled" = "0" ]; then
                echo -e "  $interface: ${GREEN}ENABLED${NC}"
            fi
        fi
    done
    
    # Check GRUB configuration
    if grep -q "ipv6.disable=1" /etc/default/grub 2>/dev/null; then
        echo -e "  GRUB Parameter: ${RED}IPv6 DISABLED${NC}"
    else
        echo -e "  GRUB Parameter: ${GREEN}IPv6 ENABLED${NC}"
    fi
    
    echo ""
    
    # Geolocation Status
    echo -e "${CYAN}📍 Geolocation Services Status:${NC}"
    
    # Check geoclue service
    if systemctl is-active geoclue.service >/dev/null 2>&1; then
        echo -e "  Geoclue Service: ${GREEN}RUNNING${NC}"
    elif systemctl list-unit-files | grep -q geoclue; then
        if systemctl is-enabled geoclue.service >/dev/null 2>&1; then
            echo -e "  Geoclue Service: ${YELLOW}ENABLED (not running)${NC}"
        else
            echo -e "  Geoclue Service: ${RED}DISABLED${NC}"
        fi
    else
        echo -e "  Geoclue Service: ${YELLOW}NOT INSTALLED${NC}"
    fi
    
    # Check GNOME location settings
    if command -v gsettings >/dev/null 2>&1; then
        local gnome_location=$(sudo -u "$SUDO_USER" gsettings get org.gnome.system.location enabled 2>/dev/null || echo "unknown")
        if [ "$gnome_location" = "true" ]; then
            echo -e "  GNOME Location: ${GREEN}ENABLED${NC}"
        elif [ "$gnome_location" = "false" ]; then
            echo -e "  GNOME Location: ${RED}DISABLED${NC}"
        else
            echo -e "  GNOME Location: ${YELLOW}UNKNOWN/NOT AVAILABLE${NC}"
        fi
    fi
    
    echo ""
}

# Function to show menu
show_menu() {
    echo -e "${GREEN}🎯 Select an option:${NC}"
    echo -e "${GREEN}===================${NC}"
    echo -e "${WHITE}[1] Show current status${NC}"
    echo -e "${WHITE}[2] Disable IPv6 only${NC}"
    echo -e "${WHITE}[3] Disable Geolocation only${NC}"
    echo -e "${WHITE}[4] Disable both IPv6 & Geolocation${NC}"
    echo -e "${WHITE}[5] Enable IPv6 only${NC}"
    echo -e "${WHITE}[6] Enable Geolocation only${NC}"
    echo -e "${WHITE}[7] Enable both IPv6 & Geolocation${NC}"
    echo -e "${WHITE}[8] Create backup of current settings${NC}"
    echo -e "${WHITE}[9] Network troubleshooting${NC}"
    echo -e "${WHITE}[0] Exit${NC}"
    echo ""
}

# Function for network troubleshooting
network_troubleshooting() {
    echo -e "${CYAN}🔧 Network Troubleshooting:${NC}"
    echo -e "${CYAN}===========================${NC}"
    
    echo -e "${YELLOW}📡 Network Interfaces:${NC}"
    ip link show
    
    echo -e "\n${YELLOW}🌐 IPv4 Addresses:${NC}"
    ip -4 addr show
    
    echo -e "\n${YELLOW}🌐 IPv6 Addresses:${NC}"
    ip -6 addr show
    
    echo -e "\n${YELLOW}🛣️ Routing Table:${NC}"
    ip route show
    
    echo -e "\n${YELLOW}📶 DNS Configuration:${NC}"
    cat /etc/resolv.conf
    
    echo -e "\n${YELLOW}🔍 Active Network Services:${NC}"
    ss -tulpn | head -10
}

# Main script execution
show_banner

# Check for root privileges
check_root

# Detect Linux distribution
detect_distro

echo ""

# Handle command line arguments
case "${1:-menu}" in
    "disable-ipv6")
        backup_settings
        disable_ipv6
        ;;
    "disable-geo")
        backup_settings
        disable_geolocation
        ;;
    "disable-all")
        backup_settings
        echo -e "${YELLOW}🔄 Disabling both IPv6 and Geolocation...${NC}"
        disable_ipv6
        echo ""
        disable_geolocation
        echo ""
        echo -e "${GREEN}✅ Both IPv6 and Geolocation disabled!${NC}"
        ;;
    "enable-ipv6")
        enable_ipv6
        ;;
    "enable-geo")
        enable_geolocation
        ;;
    "enable-all")
        echo -e "${YELLOW}🔄 Enabling both IPv6 and Geolocation...${NC}"
        enable_ipv6
        echo ""
        enable_geolocation
        echo ""
        echo -e "${GREEN}✅ Both IPv6 and Geolocation enabled!${NC}"
        ;;
    "status")
        show_status
        ;;
    "menu"|*)
        while true; do
            show_menu
            read -p "Enter your choice (0-9): " choice
            
            case $choice in
                1)
                    show_status
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    backup_settings
                    disable_ipv6
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    backup_settings
                    disable_geolocation
                    read -p "Press Enter to continue..."
                    ;;
                4)
                    backup_settings
                    echo -e "${YELLOW}🔄 Disabling both IPv6 and Geolocation...${NC}"
                    disable_ipv6
                    echo ""
                    disable_geolocation
                    echo ""
                    echo -e "${GREEN}✅ Both IPv6 and Geolocation disabled!${NC}"
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    enable_ipv6
                    read -p "Press Enter to continue..."
                    ;;
                6)
                    enable_geolocation
                    read -p "Press Enter to continue..."
                    ;;
                7)
                    echo -e "${YELLOW}🔄 Enabling both IPv6 and Geolocation...${NC}"
                    enable_ipv6
                    echo ""
                    enable_geolocation
                    echo ""
                    echo -e "${GREEN}✅ Both IPv6 and Geolocation enabled!${NC}"
                    read -p "Press Enter to continue..."
                    ;;
                8)
                    backup_settings
                    read -p "Press Enter to continue..."
                    ;;
                9)
                    network_troubleshooting
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
        ;;
esac

echo ""
echo -e "${GREEN}📋 Script completed. Remember to use these tools responsibly!${NC}"
echo -e "${YELLOW}⚠️  Some changes may require a system restart to take full effect.${NC}"
