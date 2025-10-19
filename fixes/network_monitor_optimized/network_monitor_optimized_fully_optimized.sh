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
# XXMXLI OPTIMIZED NETWORK MONITOR v2.0
# Enhanced Performance • Better Error Handling • Configuration Support
# ================================================================

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/network_monitor.conf"
CONFIG_JSON="$CONFIG_DIR/network_monitor.json"

# Performance optimization: Use faster tools when available
SEARCH_TOOL="grep"
if command -v rg >/dev/null 2>&1; then
    SEARCH_TOOL="rg"
elif command -v ag >/dev/null 2>&1; then
    SEARCH_TOOL="ag"
elif command -v awk >/dev/null 2>&1; then
    SEARCH_TOOL="awk"
fi

# Enhanced color setup with fallback detection
setup_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        PURPLE=$(tput setaf 5)
        CYAN=$(tput setaf 6)
        WHITE=$(tput setaf 7)
        MAGENTA=$(tput setaf 5)
        BOLD=$(tput bold)
        NC=$(tput sgr0)
    else
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        MAGENTA='\033[0;35m'
        BOLD='\033[1m'
        NC='\033[0m'
    fi
}

# Unicode symbols with ASCII fallbacks
setup_symbols() {
    if locale charmap 2>/dev/null | grep -qi utf; then
        CHECK="✅"
        CROSS="❌"
        WARNING="⚠️"
        ARROW="➤"
        SHIELD="🛡️"
        GEAR="⚙️"
        ROCKET="🚀"
        MAGNIFY="🔍"
        CHART="📊"
        GLOBE="🌐"
        INFO="ℹ️"
        FIRE="🔥"
        LIGHTNING="⚡"
        WAVE="🌊"
        ANTENNA="📡"
        LOCK="🔐"
        EYE="👁️"
        ALARM="🚨"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        ARROW=">"
        SHIELD="[S]"
        GEAR="[G]"
        ROCKET="[R]"
        MAGNIFY="[?]"
        CHART="[C]"
        GLOBE="[O]"
        INFO="[i]"
        FIRE="[F]"
        LIGHTNING="[L]"
        WAVE="[~]"
        ANTENNA="[A]"
        LOCK="[L]"
        EYE="[E]"
        ALARM="[!]"
    fi
}

# Configuration loading
load_configuration() {
    # Default values
    SCAN_INTERVAL=5
    CAPTURE_TIMEOUT=30
    ALERT_THRESHOLD_CONNECTIONS=100
    ALERT_THRESHOLD_BANDWIDTH=10000
    LOG_RETENTION_DAYS=7
    ENABLE_PACKET_CAPTURE=false
    ENABLE_REAL_TIME_ALERTS=true
    MAX_CONNECTIONS_MONITOR=1000
    
    # Try JSON configuration first
    if [[ -f "$CONFIG_JSON" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
            SCAN_INTERVAL=$(jq -r '.monitoring.scan_interval // 5' "$CONFIG_JSON" 2>/dev/null)
            CAPTURE_TIMEOUT=$(jq -r '.monitoring.capture_timeout // 30' "$CONFIG_JSON" 2>/dev/null)
            ALERT_THRESHOLD_CONNECTIONS=$(jq -r '.alerts.max_connections // 100' "$CONFIG_JSON" 2>/dev/null)
            ALERT_THRESHOLD_BANDWIDTH=$(jq -r '.alerts.max_bandwidth_kb // 10000' "$CONFIG_JSON" 2>/dev/null)
            LOG_RETENTION_DAYS=$(jq -r '.logging.retention_days // 7' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_PACKET_CAPTURE=$(jq -r '.features.packet_capture // false' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_REAL_TIME_ALERTS=$(jq -r '.features.real_time_alerts // true' "$CONFIG_JSON" 2>/dev/null)
            log_debug "Configuration loaded from JSON"
        fi
    # Fallback to .conf file
    elif [[ -f "$CONFIG_FILE" ]]; then
        if source "$CONFIG_FILE" 2>/dev/null; then
            log_debug "Configuration loaded from .conf file"
        fi
    fi
}

# Enhanced logging setup
setup_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    MONITOR_LOG="$LOG_DIR/network_monitor.log"
    ALERT_LOG="$LOG_DIR/network_alerts.log"
    
    # Log rotation
    for log_file in "$MONITOR_LOG" "$ALERT_LOG"; do
        if [[ -f "$log_file" ]]; then
            local log_size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
            if [[ $log_size -gt 10485760 ]]; then  # 10MB
                mv "$log_file" "${log_file}.$(date +%Y%m%d_%H%M%S).old"
                gzip "${log_file}.$(date +%Y%m%d_%H%M%S).old" 2>/dev/null || true
            fi
        fi
    done
}

# Enhanced logging functions
log_debug() { 
    [[ "${DEBUG:-false}" == "true" ]] && {
        echo -e "${CYAN}[DEBUG $(date +'%H:%M:%S')]${NC} $1" >&2
        echo "[DEBUG $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG" 2>/dev/null
    }
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    echo "[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG" 2>/dev/null
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    echo "[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG" 2>/dev/null
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1" >&2
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG" 2>/dev/null
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1" >&2
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG" 2>/dev/null
}

log_alert() { 
    echo -e "${RED}${ALARM}${NC} ${BOLD}ALERT: $1${NC}" >&2
    echo "[ALERT $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$ALERT_LOG" 2>/dev/null
    echo "[ALERT $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$MONITOR_LOG" 2>/dev/null
}

# Timeout wrapper for potentially hanging commands
run_with_timeout() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${cmd[@]}" 2>/dev/null
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "${cmd[@]}" 2>/dev/null
    else
        log_warning "No timeout command available, running without timeout protection"
        "${cmd[@]}" 2>/dev/null
    fi
}

# Enhanced banner
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║             ███╗   ██╗███████╗████████╗██╗    ██╗            ║
    ║             ████╗  ██║██╔════╝╚══██╔══╝██║    ██║            ║
    ║             ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║            ║
    ║             ██║╚██╗██║██╔══╝     ██║   ██║███╗██║            ║
    ║             ██║ ╚████║███████╗   ██║   ╚███╔███╔╝            ║
    ║             ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝             ║
    ║                                                              ║
    ║               OPTIMIZED NETWORK MONITOR v2.0                ║
    ║           Enhanced Performance • Better Error Handling       ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        ${WAVE} Real-time Monitoring • ${ANTENNA} Traffic Analysis${NC}"
    echo -e "${GREEN}        ${LIGHTNING} Using: $SEARCH_TOOL • Interval: ${SCAN_INTERVAL}s${NC}"
    echo ""
}

# Enhanced network interface detection
detect_network_interfaces() {
    log_info "Detecting network interfaces..."
    
    local interfaces=()
    
    # Use multiple methods for cross-platform compatibility
    if command -v ip >/dev/null 2>&1; then
        # Linux ip command
        while IFS= read -r interface; do
            [[ -n "$interface" && "$interface" != "lo" ]] && interfaces+=("$interface")
        done < <(ip link show 2>/dev/null | awk -F': ' '/^[0-9]/ && !/lo:/ {print $2}' | sed 's/@.*$//')
    elif command -v ifconfig >/dev/null 2>&1; then
        # BSD/macOS ifconfig
        while IFS= read -r interface; do
            [[ -n "$interface" && "$interface" != "lo0" ]] && interfaces+=("$interface")
        done < <(ifconfig -l 2>/dev/null | tr ' ' '\n' | grep -v '^lo' || ifconfig 2>/dev/null | awk '/^[a-zA-Z]/ && !/^lo/ {print $1}' | tr -d ':')
    fi
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        log_error "No network interfaces detected"
        return 1
    fi
    
    log_success "Detected ${#interfaces[@]} network interfaces:"
    local i=1
    for interface in "${interfaces[@]}"; do
        echo "  $i) $interface"
        ((i++))
    done
    
    echo "${interfaces[@]}"
    return 0
}

# Enhanced connection monitoring with performance optimization
monitor_connections() {
    log_info "Monitoring network connections..."
    
    local connection_count=0
    local suspicious_connections=0
    
    # Use netstat or ss (faster) for connection monitoring
    if command -v ss >/dev/null 2>&1; then
        # ss is faster than netstat
        local connections
        connections=$(run_with_timeout "$CAPTURE_TIMEOUT" ss -tuln 2>/dev/null | wc -l)
        connection_count=$((connections - 1))  # Remove header line
        
        # Check for suspicious patterns
        local foreign_connections
        foreign_connections=$(run_with_timeout "$CAPTURE_TIMEOUT" ss -tun 2>/dev/null | awk '$5 !~ /^127\./ && $5 !~ /^::1/ && $5 !~ /^$/ {print $5}' | sort | uniq -c | sort -nr)
        
        if [[ -n "$foreign_connections" ]]; then
            while read -r count ip; do
                if [[ ${count:-0} -gt 10 ]]; then
                    log_warning "Suspicious activity: $count connections from $ip"
                    ((suspicious_connections++))
                fi
            done <<< "$foreign_connections"
        fi
        
    elif command -v netstat >/dev/null 2>&1; then
        # Fallback to netstat
        connection_count=$(run_with_timeout "$CAPTURE_TIMEOUT" netstat -an 2>/dev/null | grep -c '^tcp\|^udp' || echo 0)
        
        # Check for suspicious patterns with netstat
        local foreign_ips
        foreign_ips=$(run_with_timeout "$CAPTURE_TIMEOUT" netstat -an 2>/dev/null | awk '/^tcp/ && $5 !~ /127\.0\.0\.1/ && $5 !~ /::1/ {print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr)
        
        if [[ -n "$foreign_ips" ]]; then
            while read -r count ip; do
                if [[ ${count:-0} -gt 10 ]]; then
                    log_warning "Suspicious activity: $count connections from $ip"
                    ((suspicious_connections++))
                fi
            done <<< "$foreign_ips"
        fi
    else
        log_error "No network monitoring tools available (ss/netstat)"
        return 1
    fi
    
    # Alert on threshold breach
    if [[ ${connection_count:-0} -gt $ALERT_THRESHOLD_CONNECTIONS ]]; then
        log_alert "High connection count: $connection_count (threshold: $ALERT_THRESHOLD_CONNECTIONS)"
    else
        log_success "Active connections: $connection_count"
    fi
    
    if [[ $suspicious_connections -gt 0 ]]; then
        log_alert "Detected $suspicious_connections suspicious connection patterns"
    fi
    
    return 0
}

# Enhanced bandwidth monitoring
monitor_bandwidth() {
    log_info "Monitoring network bandwidth..."
    
    local interfaces
    IFS=' ' read -ra interfaces <<< "$(detect_network_interfaces)"
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        return 1
    fi
    
    # Monitor primary interface (first non-loopback)
    local primary_interface="${interfaces[0]}"
    log_debug "Monitoring bandwidth on interface: $primary_interface"
    
    # Cross-platform bandwidth monitoring
    local rx_bytes_before tx_bytes_before rx_bytes_after tx_bytes_after
    
    if [[ -f "/sys/class/net/$primary_interface/statistics/rx_bytes" ]]; then
        # Linux sysfs method (fastest)
        rx_bytes_before=$(cat "/sys/class/net/$primary_interface/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_bytes_before=$(cat "/sys/class/net/$primary_interface/statistics/tx_bytes" 2>/dev/null || echo 0)
        
        sleep "$SCAN_INTERVAL"
        
        rx_bytes_after=$(cat "/sys/class/net/$primary_interface/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_bytes_after=$(cat "/sys/class/net/$primary_interface/statistics/tx_bytes" 2>/dev/null || echo 0)
        
    elif command -v ifconfig >/dev/null 2>&1; then
        # BSD/macOS ifconfig method
        local ifconfig_before ifconfig_after
        ifconfig_before=$(ifconfig "$primary_interface" 2>/dev/null)
        
        # Extract bytes (different format on different systems)
        if echo "$ifconfig_before" | grep -q "RX bytes"; then
            # Linux ifconfig format
            rx_bytes_before=$(echo "$ifconfig_before" | grep "RX bytes" | awk '{print $2}' | cut -d: -f2 || echo 0)
            tx_bytes_before=$(echo "$ifconfig_before" | grep "TX bytes" | awk '{print $6}' | cut -d: -f2 || echo 0)
        else
            # BSD/macOS format
            rx_bytes_before=$(echo "$ifconfig_before" | grep "input" | awk '{print $5}' || echo 0)
            tx_bytes_before=$(echo "$ifconfig_before" | grep "output" | awk '{print $5}' || echo 0)
        fi
        
        sleep "$SCAN_INTERVAL"
        
        ifconfig_after=$(ifconfig "$primary_interface" 2>/dev/null)
        
        if echo "$ifconfig_after" | grep -q "RX bytes"; then
            rx_bytes_after=$(echo "$ifconfig_after" | grep "RX bytes" | awk '{print $2}' | cut -d: -f2 || echo 0)
            tx_bytes_after=$(echo "$ifconfig_after" | grep "TX bytes" | awk '{print $6}' | cut -d: -f2 || echo 0)
        else
            rx_bytes_after=$(echo "$ifconfig_after" | grep "input" | awk '{print $5}' || echo 0)
            tx_bytes_after=$(echo "$ifconfig_after" | grep "output" | awk '{print $5}' || echo 0)
        fi
    else
        log_error "No bandwidth monitoring tools available"
        return 1
    fi
    
    # Calculate bandwidth
    local rx_diff=$((rx_bytes_after - rx_bytes_before))
    local tx_diff=$((tx_bytes_after - tx_bytes_before))
    local rx_kbps=$((rx_diff / SCAN_INTERVAL / 1024))
    local tx_kbps=$((tx_diff / SCAN_INTERVAL / 1024))
    local total_kbps=$((rx_kbps + tx_kbps))
    
    # Display results
    log_success "Bandwidth on $primary_interface: ↓${rx_kbps}KB/s ↑${tx_kbps}KB/s (Total: ${total_kbps}KB/s)"
    
    # Check thresholds
    if [[ $total_kbps -gt $ALERT_THRESHOLD_BANDWIDTH ]]; then
        log_alert "High bandwidth usage: ${total_kbps}KB/s (threshold: ${ALERT_THRESHOLD_BANDWIDTH}KB/s)"
    fi
    
    return 0
}

# Enhanced port scanning detection
detect_port_scans() {
    log_info "Scanning for port scan attempts..."
    
    # Check system logs for potential port scans
    local log_files=("/var/log/messages" "/var/log/syslog" "/var/log/secure" "/var/log/auth.log")
    local scan_indicators=0
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" && -r "$log_file" ]]; then
            # Look for connection attempts patterns in the last hour
            local recent_scans
            recent_scans=$(run_with_timeout 10 tail -1000 "$log_file" | \
                grep "$(date '+%b %d %H:')" | \
                grep -iE "(connection.*refused|port.*unreachable|syn.*flood)" | \
                wc -l 2>/dev/null || echo 0)
            
            if [[ ${recent_scans:-0} -gt 5 ]]; then
                log_warning "Potential port scan detected in $log_file: $recent_scans suspicious entries"
                ((scan_indicators++))
            fi
        fi
    done
    
    # Check netstat for half-open connections (potential SYN flood)
    if command -v ss >/dev/null 2>&1; then
        local syn_recv_count
        syn_recv_count=$(run_with_timeout 10 ss -ant | grep -c "SYN-RECV" 2>/dev/null || echo 0)
        
        if [[ ${syn_recv_count:-0} -gt 20 ]]; then
            log_alert "Potential SYN flood attack: $syn_recv_count SYN-RECV connections"
            ((scan_indicators++))
        fi
    fi
    
    if [[ $scan_indicators -eq 0 ]]; then
        log_success "No port scan activity detected"
    else
        log_alert "Port scan indicators detected: $scan_indicators"
    fi
    
    return $scan_indicators
}

# Real-time monitoring mode
start_real_time_monitoring() {
    echo -e "${PURPLE}${BOLD}${WAVE} REAL-TIME NETWORK MONITORING${NC}"
    echo "================================================================"
    echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
    echo ""
    
    local iteration=0
    while true; do
        ((iteration++))
        
        echo -e "${CYAN}${ARROW} Monitoring cycle $iteration ($(date))${NC}"
        echo "----------------------------------------------------------------"
        
        # Monitor connections
        monitor_connections
        echo ""
        
        # Monitor bandwidth
        monitor_bandwidth
        echo ""
        
        # Check for port scans every 5 iterations
        if [[ $((iteration % 5)) -eq 0 ]]; then
            detect_port_scans
            echo ""
        fi
        
        echo -e "${BLUE}Waiting ${SCAN_INTERVAL}s for next scan...${NC}"
        echo ""
        
        sleep "$SCAN_INTERVAL"
    done
}

# Network security assessment
network_security_assessment() {
    echo -e "${PURPLE}${BOLD}${SHIELD} NETWORK SECURITY ASSESSMENT${NC}"
    echo "================================================================"
    echo ""
    
    local security_score=0
    local max_score=0
    
    # Check for open ports
    log_info "Checking for open ports..."
    ((max_score++))
    
    if command -v ss >/dev/null 2>&1; then
        local listening_ports
        listening_ports=$(run_with_timeout 15 ss -tuln | grep LISTEN | wc -l)
        
        if [[ ${listening_ports:-0} -lt 10 ]]; then
            log_success "Listening ports: $listening_ports (reasonable)"
            ((security_score++))
        else
            log_warning "Listening ports: $listening_ports (review needed)"
        fi
        
        # Show specific listening ports
        log_info "Listening ports:"
        run_with_timeout 10 ss -tuln | grep LISTEN | awk '{print "  " $1 " " $5}' | head -10
    fi
    
    echo ""
    
    # Check firewall status
    log_info "Checking firewall status..."
    ((max_score++))
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            log_success "UFW firewall: active"
            ((security_score++))
        else
            log_warning "UFW firewall: inactive"
        fi
    elif command -v iptables >/dev/null 2>&1; then
        local iptables_rules
        iptables_rules=$(iptables -L | wc -l)
        if [[ ${iptables_rules:-0} -gt 10 ]]; then
            log_success "iptables: configured ($iptables_rules rules)"
            ((security_score++))
        else
            log_warning "iptables: minimal configuration"
        fi
    elif command -v pfctl >/dev/null 2>&1; then
        if pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then
            log_success "PF firewall: active"
            ((security_score++))
        else
            log_warning "PF firewall: inactive"
        fi
    else
        log_warning "No firewall tools detected"
    fi
    
    echo ""
    
    # Network interface security
    log_info "Checking network interface security..."
    ((max_score++))
    
    local promiscuous_interfaces=0
    local interfaces
    IFS=' ' read -ra interfaces <<< "$(detect_network_interfaces)"
    
    for interface in "${interfaces[@]}"; do
        if command -v ip >/dev/null 2>&1; then
            if ip link show "$interface" | grep -q "PROMISC"; then
                log_warning "Interface $interface is in promiscuous mode"
                ((promiscuous_interfaces++))
            fi
        fi
    done
    
    if [[ $promiscuous_interfaces -eq 0 ]]; then
        log_success "No interfaces in promiscuous mode"
        ((security_score++))
    fi
    
    # Calculate and display security score
    local percentage=$((security_score * 100 / max_score))
    echo ""
    echo "================================================================"
    echo -e "${WHITE}${SHIELD} NETWORK SECURITY SCORE: ${NC}"
    
    if [[ $percentage -ge 80 ]]; then
        echo -e "${GREEN}${CHECK} GOOD ($percentage%) - $security_score/$max_score checks passed${NC}"
    elif [[ $percentage -ge 60 ]]; then
        echo -e "${YELLOW}${WARNING} FAIR ($percentage%) - $security_score/$max_score checks passed${NC}"
    else
        echo -e "${RED}${CROSS} POOR ($percentage%) - $security_score/$max_score checks passed${NC}"
    fi
}

# Interactive menu
show_interactive_menu() {
    show_banner
    
    echo -e "${WHITE}${GEAR} OPTIMIZED NETWORK MONITORING OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${WAVE} Real-time Network Monitoring"
    echo -e "${GREEN}2)${NC} ${CHART} Connection Analysis"
    echo -e "${GREEN}3)${NC} ${ANTENNA} Bandwidth Monitoring"
    echo -e "${GREEN}4)${NC} ${MAGNIFY} Port Scan Detection"
    echo -e "${GREEN}5)${NC} ${SHIELD} Network Security Assessment"
    echo -e "${GREEN}6)${NC} ${GLOBE} Network Interface Information"
    echo -e "${GREEN}7)${NC} ${GEAR} Configuration Status"
    echo -e "${GREEN}8)${NC} ${LIGHTNING} Debug Mode Toggle"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "$(echo -e "${CYAN}Choose option [0-8]:${NC} ")" choice
    
    case "$choice" in
        1) start_real_time_monitoring ;;
        2) monitor_connections; read -p "Press Enter to continue..." ;;
        3) monitor_bandwidth; read -p "Press Enter to continue..." ;;
        4) detect_port_scans; read -p "Press Enter to continue..." ;;
        5) network_security_assessment; read -p "Press Enter to continue..." ;;
        6) show_network_info; read -p "Press Enter to continue..." ;;
        7) show_configuration_status; read -p "Press Enter to continue..." ;;
        8) toggle_debug_mode; show_interactive_menu ;;
        0) log_info "Exiting network monitor"; exit 0 ;;
        *) log_error "Invalid option: $choice"; sleep 1 ;;
    esac
    
    show_interactive_menu
}

# Network interface information
show_network_info() {
    echo -e "${PURPLE}${GLOBE} NETWORK INTERFACE INFORMATION${NC}"
    echo "================================================================"
    echo ""
    
    local interfaces
    IFS=' ' read -ra interfaces <<< "$(detect_network_interfaces)"
    
    for interface in "${interfaces[@]}"; do
        echo -e "${CYAN}Interface: $interface${NC}"
        
        if command -v ip >/dev/null 2>&1; then
            # Linux ip command - more detailed info
            local ip_info
            ip_info=$(ip addr show "$interface" 2>/dev/null)
            
            # Extract IP addresses
            local ipv4_addrs
            ipv4_addrs=$(echo "$ip_info" | grep "inet " | awk '{print $2}')
            [[ -n "$ipv4_addrs" ]] && echo "  IPv4: $ipv4_addrs"
            
            local ipv6_addrs
            ipv6_addrs=$(echo "$ip_info" | grep "inet6" | awk '{print $2}')
            [[ -n "$ipv6_addrs" ]] && echo "  IPv6: $ipv6_addrs"
            
            # Interface status
            if echo "$ip_info" | grep -q "state UP"; then
                echo -e "  Status: ${GREEN}UP${NC}"
            else
                echo -e "  Status: ${RED}DOWN${NC}"
            fi
            
        elif command -v ifconfig >/dev/null 2>&1; then
            # BSD/macOS ifconfig
            local ifconfig_info
            ifconfig_info=$(ifconfig "$interface" 2>/dev/null)
            
            local ipv4_addr
            ipv4_addr=$(echo "$ifconfig_info" | grep "inet " | awk '{print $2}')
            [[ -n "$ipv4_addr" ]] && echo "  IPv4: $ipv4_addr"
            
            if echo "$ifconfig_info" | grep -q "status: active\|flags.*UP"; then
                echo -e "  Status: ${GREEN}UP${NC}"
            else
                echo -e "  Status: ${RED}DOWN${NC}"
            fi
        fi
        
        echo ""
    done
}

# Configuration status display
show_configuration_status() {
    echo -e "${PURPLE}${GEAR} CONFIGURATION STATUS${NC}"
    echo "================================================================"
    echo ""
    
    echo "Current configuration:"
    echo "  Search tool: $SEARCH_TOOL"
    echo "  Scan interval: ${SCAN_INTERVAL}s"
    echo "  Capture timeout: ${CAPTURE_TIMEOUT}s"
    echo "  Connection threshold: $ALERT_THRESHOLD_CONNECTIONS"
    echo "  Bandwidth threshold: ${ALERT_THRESHOLD_BANDWIDTH}KB/s"
    echo "  Log retention: ${LOG_RETENTION_DAYS} days"
    echo "  Packet capture: $ENABLE_PACKET_CAPTURE"
    echo "  Real-time alerts: $ENABLE_REAL_TIME_ALERTS"
    echo ""
    
    echo "Configuration files:"
    [[ -f "$CONFIG_JSON" ]] && echo -e "${GREEN}  ✓ JSON: $CONFIG_JSON${NC}" || echo -e "${YELLOW}  - JSON: $CONFIG_JSON (not found)${NC}"
    [[ -f "$CONFIG_FILE" ]] && echo -e "${GREEN}  ✓ CONF: $CONFIG_FILE${NC}" || echo -e "${YELLOW}  - CONF: $CONFIG_FILE (not found)${NC}"
    echo ""
    
    echo "Log files:"
    [[ -f "$MONITOR_LOG" ]] && echo "  Monitor log: $MONITOR_LOG ($(du -h "$MONITOR_LOG" 2>/dev/null | cut -f1))"
    [[ -f "$ALERT_LOG" ]] && echo "  Alert log: $ALERT_LOG ($(du -h "$ALERT_LOG" 2>/dev/null | cut -f1))"
}

# Debug mode toggle
toggle_debug_mode() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        DEBUG=false
        log_info "Debug mode disabled"
    else
        DEBUG=true
        log_info "Debug mode enabled"
    fi
}

# Initialize system
init_system() {
    setup_colors
    setup_symbols
    setup_logging
    load_configuration
    
    log_debug "XXMXLI Network Monitor v2.0 initialized"
    log_debug "Using search tool: $SEARCH_TOOL"
    log_debug "Configuration: interval=${SCAN_INTERVAL}s, timeout=${CAPTURE_TIMEOUT}s"
}

# Main execution
main() {
    # Handle command line arguments
    case "${1:-}" in
        "--monitor"|"-m")
            init_system
            start_real_time_monitoring
            ;;
        "--assess"|"-a")
            init_system
            network_security_assessment
            ;;
        "--debug"|"-d")
            DEBUG=true
            init_system
            show_interactive_menu
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--monitor|--assess|--debug|--help]"
            echo "  --monitor    Start real-time monitoring"
            echo "  --assess     Run network security assessment"
            echo "  --debug      Enable debug mode and run interactively"
            echo "  --help       Show this help"
            exit 0
            ;;
        *)
            init_system
            show_interactive_menu
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "Network monitor terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
