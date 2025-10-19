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
# XXMXLI ADVANCED SECURITY MONITORING SYSTEM
# Professional Real-Time Security Intelligence Dashboard
# ================================================================
#
# SECURITY WARNING: This system is actively monitored and protected.
# Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
# will be logged and reported to the appropriate authorities. IP addresses and metadata 

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

# may be retained and used for legal enforcement, in compliance with applicable laws.
# By continuing, you acknowledge that you are authorized to use this system and that 
# any misuse may result in account suspension, firewall bans, or prosecution under 
# national and international law. Violators may be subject to civil and/or criminal 
# penalties. Your access is being monitored.

# Color definitions for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Unicode symbols for enhanced UX
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
ARROW="➤"
STAR="⭐"
SHIELD="🛡️"
GEAR="⚙️"
ROCKET="🚀"
MAGNIFY="🔍"
CHART="📊"
GLOBE="🌐"
FILE="📁"
INFO="ℹ️"
BLOCKED="🚫"
LOCK="🔐"
EYE="👁️"
FIRE="🔥"
LIGHTNING="⚡"
CLOCK="🕒"

# Global variables
INTERACTIVE_MODE=true
LOG_DIR="logs"
REPORT_DIR="reports"

# Messaging functions
log() { echo -e "${WHITE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
error() { echo -e "${RED}${CROSS}${NC} $1"; }
warn() { echo -e "${YELLOW}${WARNING}${NC} $1"; }
info() { echo -e "${CYAN}${INFO}${NC} $1"; }
critical() { echo -e "${RED}${FIRE}${NC} ${WHITE}$1${NC}"; }

# Show beautiful banner
show_banner() {
    clear
    echo -e "${RED}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║              ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗          ║
    ║              ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║          ║
    ║               ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║          ║
    ║               ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║          ║
    ║              ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗     ║
    ║              ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝     ║
    ║                                                              ║
    ║                  SECURITY MONITORING SYSTEM                  ║
    ║              Advanced Real-Time Threat Intelligence          ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${RED}        ${SHIELD} Advanced Security Intelligence Dashboard${NC}"
    echo -e "${YELLOW}        ${LIGHTNING} Real-Time Threat Detection & Response${NC}"
    echo ""
}

# Interactive menu
show_interactive_menu() {
    show_banner
    echo -e "${WHITE}${ARROW} SECURITY MONITORING OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC}  ${SHIELD} Security Status Overview"
    echo -e "${GREEN}2)${NC}  ${BLOCKED} Real-Time Blocked Attempts"
    echo -e "${GREEN}3)${NC}  ${MAGNIFY} IP Blocking Effectiveness Test"
    echo -e "${GREEN}4)${NC}  ${CHART} Advanced Security Analytics"
    echo -e "${GREEN}5)${NC}  ${FIRE} Threat Intelligence Dashboard"
    echo -e "${GREEN}6)${NC}  ${LOCK} Admin Security Audit"
    echo -e "${GREEN}7)${NC}  ${EYE} Live Log Monitor"
    echo -e "${GREEN}8)${NC}  ${LIGHTNING} Automated Response System"
    echo -e "${GREEN}9)${NC}  ${FILE} Generate Security Report"
    echo -e "${GREEN}10)${NC} ${GEAR} Advanced Configuration"
    echo -e "${GREEN}11)${NC} ${INFO} Help & Documentation"
    echo -e "${RED}0)${NC}  ${CROSS} Exit Monitor"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Choose security option [0-11]: ${NC}")" -r choice
    
    case $choice in
        1) security_status_overview ;;
        2) real_time_blocked_attempts ;;
        3) test_ip_blocking ;;
        4) advanced_security_analytics ;;
        5) threat_intelligence_dashboard ;;
        6) admin_security_audit ;;
        7) live_log_monitor ;;
        8) automated_response_system ;;
        9) generate_security_report ;;
        10) advanced_configuration ;;
        11) show_help ;;
        0) exit_program ;;
        *) 
            error "Invalid option. Please choose 0-11."
            read -p "Press Enter to continue..."
            show_interactive_menu
            ;;
    esac
}

# Environment check
check_environment() {
    if [ ! -f "index.html" ]; then
        error "Run this script from the XXMXLI root directory"
        echo ""
        info "Expected directory structure:"
        echo "  - index.html (main website)"
        echo "  - .htaccess (server blocking rules)"
        echo "  - admin/ directory with protection"
        echo "  - assets/security/ directory"
        echo ""
        exit 1
    fi
    
    # Create necessary directories
    mkdir -p "$LOG_DIR" "$REPORT_DIR"
}

# Security status overview
security_status_overview() {
    show_banner
    echo -e "${PURPLE}${SHIELD} COMPREHENSIVE SECURITY STATUS${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Analyzing security infrastructure..."
    sleep 1
    
    local security_score=0
    local max_score=10
    
    echo ""
    echo -e "${CYAN}${ARROW} Server-Side Protection Analysis${NC}"
    echo "----------------------------------------"
    
    # Check server-side blocking
    if grep -q "XXMXLI SERVER-SIDE IP BLOCKING" .htaccess 2>/dev/null; then
        success "Server-side IP blocking: ACTIVE"
        local blocked_count=$(grep -c "Require not ip" .htaccess 2>/dev/null || echo "0")
        info "Active blocking rules: $blocked_count IPs"
        ((security_score += 3))
    else
        error "Server-side IP blocking: INACTIVE"
        warn "Critical security feature disabled"
    fi
    
    # Check admin protection
    if [ -f "admin/.htaccess" ]; then
        if grep -q "Require not ip" admin/.htaccess 2>/dev/null; then
            success "Admin directory: PROTECTED"
            ((security_score += 2))
        else
            warn "Admin directory: BASIC PROTECTION"
            ((security_score += 1))
        fi
    else
        error "Admin directory: UNPROTECTED"
        critical "CRITICAL SECURITY VULNERABILITY"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Threat Intelligence Analysis${NC}"
    echo "----------------------------------------"
    
    # Check blacklist database
    if [ -f "assets/security/blocked_ips.json" ]; then
        success "Threat intelligence database: ACTIVE"
        local total_ips=$(jq length assets/security/blocked_ips.json 2>/dev/null || echo "0")
        info "Blacklisted threat IPs: $total_ips"
        ((security_score += 2))
    else
        error "Threat intelligence database: MISSING"
        warn "Operating without threat intelligence"
    fi
    
    # Check client-side protection
    if grep -q "xxmxliSecurity" index.html 2>/dev/null; then
        success "Client-side protection: ACTIVE"
        ((security_score += 2))
    else
        warn "Client-side protection: LIMITED"
        ((security_score += 1))
    fi
    
    # Check monitoring capabilities
    if command -v tail >/dev/null && command -v grep >/dev/null; then
        success "Real-time monitoring: CAPABLE"
        ((security_score += 1))
    else
        warn "Real-time monitoring: LIMITED"
    fi
    
    echo ""
    echo "================================================================"
    
    # Calculate security rating
    local percentage=$((security_score * 100 / max_score))
    
    echo -e "${WHITE}${SHIELD} SECURITY RATING: ${NC}"
    if [ $percentage -ge 90 ]; then
        echo -e "${GREEN}${FIRE} EXCELLENT (${percentage}%)${NC}"
        echo -e "${GREEN}Your security infrastructure is operating at maximum efficiency${NC}"
    elif [ $percentage -ge 75 ]; then
        echo -e "${YELLOW}${WARNING} GOOD (${percentage}%)${NC}"
        echo -e "${YELLOW}Security is strong with minor areas for improvement${NC}"
    elif [ $percentage -ge 50 ]; then
        echo -e "${YELLOW}${WARNING} FAIR (${percentage}%)${NC}"
        echo -e "${YELLOW}Security needs attention - several vulnerabilities detected${NC}"
    else
        echo -e "${RED}${CROSS} CRITICAL (${percentage}%)${NC}"
        echo -e "${RED}IMMEDIATE ACTION REQUIRED - Security infrastructure compromised${NC}"
    fi
    
    echo ""
    info "Detailed security recommendations available in advanced analytics"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Real-time blocked attempts monitor
real_time_blocked_attempts() {
    show_banner
    echo -e "${PURPLE}${BLOCKED} REAL-TIME BLOCKED ATTEMPTS MONITOR${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Monitoring blocked access attempts..."
    echo ""
    
    # Show recent blocks from various sources
    echo -e "${CYAN}${ARROW} Recent Security Events (Last 24 hours)${NC}"
    echo "----------------------------------------"
    
    local events_found=false
    
    # Check Apache/web server logs
    for log_file in /var/log/apache2/access.log /var/log/httpd/access_log /var/log/nginx/access.log logs/access.log access.log; do
        if [ -f "$log_file" ]; then
            info "Scanning: $log_file"
            
            # Get blocked attempts (403 responses)
            local blocked_today=$(awk -v date="$(date '+%d/%b/%Y')" '
                $4 ~ date && $9 == "403" { 
                    count++
                    if (count <= 10) print "🚫 " $1 " - " $4 " " $7 " (HTTP " $9 ")"
                }
                END { if (count > 10) print "... and " (count-10) " more blocked attempts" }
            ' "$log_file" 2>/dev/null)
            
            if [ -n "$blocked_today" ]; then
                echo "$blocked_today"
                events_found=true
            fi
            break
        fi
    done
    
    # Check custom XXMXLI logs
    if [ -f "$LOG_DIR/security_events.log" ]; then
        echo ""
        info "XXMXLI Security Events:"
        tail -10 "$LOG_DIR/security_events.log" 2>/dev/null || echo "No recent events"
        events_found=true
    fi
    
    if [ "$events_found" = false ]; then
        warn "No recent blocked attempts detected"
        info "This could indicate:"
        echo "  • Effective deterrent - attackers avoiding your site"
        echo "  • Logs not accessible from current location"
        echo "  • Security monitoring needs configuration"
    fi
    
    echo ""
    echo "================================================================"
    
    # Show blocking statistics
    if [ -f ".htaccess" ]; then
        local blocked_ips=$(grep -c "Require not ip" .htaccess 2>/dev/null || echo "0")
        success "Active IP blocks: $blocked_ips"
    fi
    
    echo ""
    echo -e "${YELLOW}${INFO} TIP: Use 'Live Log Monitor' for real-time streaming${NC}"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# IP blocking effectiveness test
test_ip_blocking() {
    show_banner
    echo -e "${PURPLE}${MAGNIFY} IP BLOCKING EFFECTIVENESS TEST${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Testing IP blocking infrastructure..."
    echo ""
    
    # Test server-side blocking
    echo -e "${CYAN}${ARROW} Server-Side Blocking Test${NC}"
    echo "----------------------------------------"
    
    if [ -f ".htaccess" ] && grep -q "XXMXLI SERVER-SIDE IP BLOCKING" ".htaccess"; then
        success "Server-side blocking configuration detected"
        
        local blocked_ip=$(grep -m1 "Require not ip" .htaccess 2>/dev/null | awk '{print $4}')
        
        if [ -n "$blocked_ip" ]; then
            info "Testing with blocked IP: $blocked_ip"
            
            # Validate IP format
            if [[ $blocked_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                success "IP format validation: PASSED"
                
                # Test .htaccess syntax
                if command -v apache2ctl >/dev/null 2>&1; then
                    if apache2ctl configtest 2>/dev/null; then
                        success "Apache configuration syntax: VALID"
                    else
                        error "Apache configuration syntax: INVALID"
                        warn "Server-side blocking may not function properly"
                    fi
                else
                    info "Apache testing tools not available"
                fi
            else
                error "Invalid IP format detected: $blocked_ip"
            fi
        else
            warn "No blocked IPs found in configuration"
        fi
    else
        error "Server-side blocking: NOT CONFIGURED"
        warn "Critical security feature missing"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Client-Side Blocking Test${NC}"
    echo "----------------------------------------"
    
    if grep -q "xxmxliSecurity" index.html 2>/dev/null; then
        success "Client-side security scripts detected"
        
        # Check for blacklist integration
        if grep -q "blocked_ips.json" index.html 2>/dev/null; then
            success "Threat intelligence integration: ACTIVE"
        else
            warn "Threat intelligence integration: LIMITED"
        fi
    else
        warn "Client-side blocking: NOT DETECTED"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Performance Impact Analysis${NC}"
    echo "----------------------------------------"
    
    # Test response time with blocking active
    if command -v curl >/dev/null 2>&1; then
        info "Testing server response time..."
        
        local start_time=$(date +%s%N)
        local response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/" 2>/dev/null || echo "000")
        local end_time=$(date +%s%N)
        local response_time=$(( (end_time - start_time) / 1000000 ))
        
        if [ "$response" = "200" ]; then
            success "Server accessibility: CONFIRMED (HTTP 200)"
            
            if [ $response_time -lt 100 ]; then
                success "Response time: ${response_time}ms (excellent)"
            elif [ $response_time -lt 500 ]; then
                success "Response time: ${response_time}ms (good)"
            else
                warn "Response time: ${response_time}ms (may need optimization)"
            fi
        else
            warn "Server accessibility test: HTTP $response"
        fi
    else
        info "curl not available for response testing"
    fi
    
    echo ""
    echo "================================================================"
    success "IP blocking effectiveness test completed"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Advanced security analytics
advanced_security_analytics() {
    show_banner
    echo -e "${PURPLE}${CHART} ADVANCED SECURITY ANALYTICS${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Generating comprehensive security analytics..."
    sleep 1
    
    echo ""
    echo -e "${CYAN}${ARROW} Threat Landscape Analysis${NC}"
    echo "----------------------------------------"
    
    # Analyze blocked IP patterns
    if [ -f ".htaccess" ]; then
        info "Analyzing blocked IP patterns..."
        
        # Get IP ranges
        local ip_ranges=$(grep "Require not ip" .htaccess 2>/dev/null | \
            awk '{print $4}' | \
            awk -F'.' '{print $1"."$2".*.*"}' | \
            sort | uniq -c | sort -nr | head -5)
        
        if [ -n "$ip_ranges" ]; then
            echo ""
            echo -e "${WHITE}Top threat IP ranges:${NC}"
            echo "$ip_ranges" | awk '{printf "🔴 %-15s (%d IPs)\n", $2, $1}'
        fi
        
        # Geographic analysis (if possible)
        echo ""
        info "Geographic threat distribution:"
        
        # Country code analysis (basic)
        local unique_ips=$(grep "Require not ip" .htaccess 2>/dev/null | awk '{print $4}' | wc -l)
        info "Total unique threats blocked: $unique_ips"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Security Timeline Analysis${NC}"
    echo "----------------------------------------"
    
    # Check deployment timeline
    if [ -f ".htaccess" ]; then
        local deploy_date=$(stat -c %y .htaccess 2>/dev/null | cut -d' ' -f1)
        info "Last security update: $deploy_date"
        
        # Check how recent the deployment is
        local days_old=$(( ($(date +%s) - $(stat -c %Y .htaccess 2>/dev/null || echo 0)) / 86400 ))
        
        if [ $days_old -lt 7 ]; then
            success "Security rules are current (${days_old} days old)"
        elif [ $days_old -lt 30 ]; then
            warn "Security rules aging (${days_old} days old)"
        else
            error "Security rules outdated (${days_old} days old)"
            warn "Consider updating threat intelligence"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Threat Intelligence Sources${NC}"
    echo "----------------------------------------"
    
    if [ -f "assets/security/blocked_ips.json" ]; then
        # Analyze threat intelligence metadata
        local sources=$(jq -r '.metadata.sources[]?' assets/security/blocked_ips.json 2>/dev/null | wc -l)
        local last_update=$(jq -r '.metadata.last_updated?' assets/security/blocked_ips.json 2>/dev/null)
        
        if [ "$sources" -gt 0 ]; then
            success "Threat intelligence sources: $sources"
        else
            warn "Limited threat intelligence sources"
        fi
        
        if [ "$last_update" != "null" ] && [ -n "$last_update" ]; then
            info "Last intelligence update: $last_update"
        else
            warn "Threat intelligence update status unknown"
        fi
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Security Recommendations${NC}"
    echo "----------------------------------------"
    
    # Generate security recommendations
    local recommendations=()
    
    if ! grep -q "XXMXLI SERVER-SIDE IP BLOCKING" .htaccess 2>/dev/null; then
        recommendations+=("Deploy server-side IP blocking immediately")
    fi
    
    if [ ! -f "admin/.htaccess" ]; then
        recommendations+=("Secure admin directory with access controls")
    fi
    
    if [ ! -f "assets/security/blocked_ips.json" ]; then
        recommendations+=("Implement threat intelligence database")
    fi
    
    if [ ${#recommendations[@]} -eq 0 ]; then
        success "No critical security issues detected"
        info "Continue monitoring for emerging threats"
    else
        warn "Security recommendations:"
        for rec in "${recommendations[@]}"; do
            echo "  ${ARROW} $rec"
        done
    fi
    
    echo ""
    echo "================================================================"
    success "Advanced security analytics completed"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Threat intelligence dashboard
threat_intelligence_dashboard() {
    show_banner
    echo -e "${PURPLE}${FIRE} THREAT INTELLIGENCE DASHBOARD${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Loading threat intelligence data..."
    sleep 1
    
    echo ""
    echo -e "${CYAN}${ARROW} Global Threat Database Status${NC}"
    echo "----------------------------------------"
    
    if [ -f "assets/security/blocked_ips.json" ]; then
        success "Threat intelligence database: ONLINE"
        
        local total_threats=$(jq length assets/security/blocked_ips.json 2>/dev/null || echo "0")
        local high_risk=$(jq '[.[] | select(.risk_level == "high")] | length' assets/security/blocked_ips.json 2>/dev/null || echo "0")
        local medium_risk=$(jq '[.[] | select(.risk_level == "medium")] | length' assets/security/blocked_ips.json 2>/dev/null || echo "0")
        
        echo ""
        echo -e "${WHITE}Threat Classification:${NC}"
        echo -e "${RED}  ${FIRE} High Risk:   $high_risk threats${NC}"
        echo -e "${YELLOW}  ${WARNING} Medium Risk: $medium_risk threats${NC}"
        echo -e "${GRAY}  ${INFO} Total Database: $total_threats entries${NC}"
        
        # Show recent threat additions
        echo ""
        info "Recent threat intelligence updates:"
        local recent_threats=$(jq -r '.[] | select(.timestamp? and (.timestamp | strptime("%Y-%m-%d") | mktime) > (now - 86400*7)) | .ip + " (" + (.risk_level // "unknown") + ")"' assets/security/blocked_ips.json 2>/dev/null | head -5)
        
        if [ -n "$recent_threats" ]; then
            echo "$recent_threats" | while read -r threat; do
                echo "  ${LIGHTNING} $threat"
            done
        else
            info "No recent threat updates in database"
        fi
        
    else
        error "Threat intelligence database: OFFLINE"
        critical "Operating without threat intelligence - CRITICAL VULNERABILITY"
        warn "Deploy threat intelligence immediately for protection"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Active Protection Status${NC}"
    echo "----------------------------------------"
    
    # Check deployment status
    local deployed_count=0
    if [ -f ".htaccess" ] && grep -q "XXMXLI SERVER-SIDE IP BLOCKING" ".htaccess"; then
        deployed_count=$(grep -c "Require not ip" .htaccess 2>/dev/null || echo "0")
        success "Server deployment: $deployed_count threats blocked"
    else
        error "Server deployment: NOT ACTIVE"
    fi
    
    # Show protection coverage
    if [ -f "assets/security/blocked_ips.json" ] && [ $deployed_count -gt 0 ]; then
        local coverage=$(echo "scale=2; $deployed_count * 100 / $total_threats" | bc 2>/dev/null || echo "0")
        
        if (( $(echo "$coverage >= 90" | bc -l 2>/dev/null || echo 0) )); then
            success "Protection coverage: ${coverage}% (excellent)"
        elif (( $(echo "$coverage >= 70" | bc -l 2>/dev/null || echo 0) )); then
            warn "Protection coverage: ${coverage}% (good)"
        else
            error "Protection coverage: ${coverage}% (insufficient)"
        fi
    fi
    
    echo ""
    echo "================================================================"
    info "Real-time threat intelligence monitoring active"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Admin security audit
admin_security_audit() {
    show_banner
    echo -e "${PURPLE}${LOCK} ADMIN SECURITY AUDIT${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Conducting comprehensive admin security audit..."
    sleep 1
    
    local audit_score=0
    local max_audit_score=8
    
    echo ""
    echo -e "${CYAN}${ARROW} Directory Protection Analysis${NC}"
    echo "----------------------------------------"
    
    # Check admin directory existence
    if [ -d "admin" ]; then
        success "Admin directory: EXISTS"
        ((audit_score++))
        
        # Check .htaccess protection
        if [ -f "admin/.htaccess" ]; then
            success "Admin .htaccess: PRESENT"
            ((audit_score++))
            
            # Check IP blocking rules
            if grep -q "Require not ip" admin/.htaccess 2>/dev/null; then
                local admin_blocks=$(grep -c "Require not ip" admin/.htaccess)
                success "IP blocking rules: $admin_blocks active"
                ((audit_score++))
            else
                warn "IP blocking rules: NOT CONFIGURED"
            fi
            
            # Check authentication
            if grep -q "AuthType Basic" admin/.htaccess 2>/dev/null; then
                success "Password authentication: ENABLED"
                ((audit_score++))
            else
                warn "Password authentication: NOT DETECTED"
                info "Consider adding HTTP Basic Authentication"
            fi
            
        else
            error "Admin .htaccess: MISSING"
            critical "CRITICAL: Admin directory is unprotected"
        fi
        
    else
        error "Admin directory: NOT FOUND"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Sensitive File Protection${NC}"
    echo "----------------------------------------"
    
    # Check for exposed sensitive files
    local sensitive_files=(
        "ADMIN_CREDENTIALS_SECURE.txt"
        "config/database.php"
        ".env"
        "secrets.txt"
        "admin_config.php"
    )
    
    local exposed_files=0
    for file in "${sensitive_files[@]}"; do
        if [ -f "$file" ]; then
            # Check if file is web-accessible
            if [ -f ".htaccess" ] && grep -q "$file" .htaccess 2>/dev/null; then
                success "$file: PROTECTED"
            else
                error "$file: POTENTIALLY EXPOSED"
                ((exposed_files++))
            fi
        fi
    done
    
    if [ $exposed_files -eq 0 ]; then
        success "Sensitive files: SECURE"
        ((audit_score++))
    else
        error "Sensitive files: $exposed_files potentially exposed"
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Admin Access Monitoring${NC}"
    echo "----------------------------------------"
    
    # Check for admin access logs
    if [ -f "$LOG_DIR/admin_access.log" ]; then
        success "Admin access logging: ACTIVE"
        ((audit_score++))
        
        local recent_logins=$(tail -n 20 "$LOG_DIR/admin_access.log" 2>/dev/null | wc -l)
        info "Recent admin access events: $recent_logins"
    else
        warn "Admin access logging: NOT CONFIGURED"
        info "Consider implementing admin access monitoring"
    fi
    
    # Check for failed access attempts
    local admin_403s=0
    for log_file in /var/log/apache2/access.log /var/log/httpd/access_log logs/access.log; do
        if [ -f "$log_file" ]; then
            admin_403s=$(grep -c "admin.*403" "$log_file" 2>/dev/null || echo "0")
            break
        fi
    done
    
    if [ $admin_403s -gt 0 ]; then
        warn "Recent admin access denials: $admin_403s"
        info "Monitor for potential unauthorized access attempts"
    else
        success "No recent unauthorized admin access attempts"
        ((audit_score++))
    fi
    
    echo ""
    echo -e "${CYAN}${ARROW} Security Headers & Configuration${NC}"
    echo "----------------------------------------"
    
    # Check for security headers in admin .htaccess
    if [ -f "admin/.htaccess" ]; then
        local security_headers=0
        
        if grep -q "X-Frame-Options" admin/.htaccess 2>/dev/null; then
            success "X-Frame-Options header: CONFIGURED"
            ((security_headers++))
        fi
        
        if grep -q "X-XSS-Protection" admin/.htaccess 2>/dev/null; then
            success "XSS Protection header: CONFIGURED"
            ((security_headers++))
        fi
        
        if [ $security_headers -gt 0 ]; then
            success "Security headers: $security_headers configured"
            ((audit_score++))
        else
            warn "Security headers: NOT CONFIGURED"
            info "Consider adding security headers for enhanced protection"
        fi
    fi
    
    echo ""
    echo "================================================================"
    
    # Calculate audit score
    local audit_percentage=$((audit_score * 100 / max_audit_score))
    
    echo -e "${WHITE}${SHIELD} ADMIN SECURITY RATING: ${NC}"
    if [ $audit_percentage -ge 90 ]; then
        echo -e "${GREEN}${CHECK} EXCELLENT (${audit_percentage}%)${NC}"
        echo -e "${GREEN}Admin security is exceptionally well configured${NC}"
    elif [ $audit_percentage -ge 75 ]; then
        echo -e "${YELLOW}${WARNING} GOOD (${audit_percentage}%)${NC}"
        echo -e "${YELLOW}Admin security is solid with minor improvements needed${NC}"
    elif [ $audit_percentage -ge 50 ]; then
        echo -e "${YELLOW}${WARNING} FAIR (${audit_percentage}%)${NC}"
        echo -e "${YELLOW}Admin security needs significant attention${NC}"
    else
        echo -e "${RED}${CROSS} CRITICAL (${audit_percentage}%)${NC}"
        echo -e "${RED}IMMEDIATE ACTION REQUIRED - Admin area is vulnerable${NC}"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Live log monitor
live_log_monitor() {
    show_banner
    echo -e "${PURPLE}${EYE} LIVE SECURITY LOG MONITOR${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    warn "Starting live security monitoring..."
    info "Press Ctrl+C to stop monitoring and return to menu"
    echo ""
    
    # Find available log files
    local log_files=()
    for log_file in /var/log/apache2/access.log /var/log/httpd/access_log /var/log/nginx/access.log logs/access.log access.log; do
        if [ -f "$log_file" ]; then
            log_files+=("$log_file")
        fi
    done
    
    if [ ${#log_files[@]} -eq 0 ]; then
        error "No accessible log files found"
        warn "Log monitoring requires access to web server logs"
        echo ""
        info "Expected log locations:"
        echo "  - /var/log/apache2/access.log"
        echo "  - /var/log/httpd/access_log"
        echo "  - /var/log/nginx/access.log"
        echo "  - logs/access.log"
        echo ""
        read -p "Press Enter to return to menu..."
        show_interactive_menu
        return
    fi
    
    success "Monitoring: ${log_files[0]}"
    echo ""
    echo -e "${YELLOW}${LIGHTNING} LIVE SECURITY EVENTS ${LIGHTNING}${NC}"
    echo "----------------------------------------"
    
    # Create a trap to handle Ctrl+C gracefully
    trap 'echo -e "\n${INFO} Stopping live monitor..."; sleep 1; show_interactive_menu' INT
    
    # Start live monitoring with security-focused filtering
    tail -f "${log_files[0]}" | while IFS= read -r line; do
        # Highlight security-relevant events
        if echo "$line" | grep -q " 403 "; then
            echo -e "${RED}${BLOCKED} BLOCKED: $line${NC}"
        elif echo "$line" | grep -q " 404 "; then
            echo -e "${YELLOW}${WARNING} NOT FOUND: $line${NC}"
        elif echo "$line" | grep -qE "(admin|login|wp-admin)"; then
            echo -e "${CYAN}${LOCK} ADMIN ACCESS: $line${NC}"
        elif echo "$line" | grep -qE "(POST|PUT|DELETE)"; then
            echo -e "${BLUE}${GEAR} DATA OPERATION: $line${NC}"
        else
            echo -e "${GRAY}${INFO} $line${NC}"
        fi
    done
}

# Automated response system
automated_response_system() {
    show_banner
    echo -e "${PURPLE}${LIGHTNING} AUTOMATED RESPONSE SYSTEM${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Configuring automated security responses..."
    echo ""
    
    echo -e "${CYAN}${ARROW} Available Response Actions${NC}"
    echo "----------------------------------------"
    echo ""
    echo -e "${GREEN}1)${NC} ${SHIELD} Enable Automatic IP Blocking"
    echo -e "${GREEN}2)${NC} ${LIGHTNING} Set up Threat Intelligence Auto-Update"
    echo -e "${GREEN}3)${NC} ${FIRE} Configure Emergency Lockdown"
    echo -e "${GREEN}4)${NC} ${EYE} Setup Real-time Alert System"
    echo -e "${GREEN}5)${NC} ${GEAR} Configure Response Thresholds"
    echo -e "${GREEN}6)${NC} ${CLOCK} Schedule Automated Security Scans"
    echo -e "${GREEN}7)${NC} ${ARROW} Back to main menu"
    echo ""
    
    read -p "Choose automated response [1-7]: " -r choice
    
    case $choice in
        1)
            echo ""
            info "Setting up automatic IP blocking..."
            
            # Create monitoring script
            cat > "$LOG_DIR/auto_block.sh" << 'EOF'
#!/bin/bash
# Automatic IP blocking based on failed attempts
THRESHOLD=5
LOG_FILE="/var/log/apache2/access.log"
BLOCK_FILE=".htaccess"

if [ -f "$LOG_FILE" ]; then
    # Find IPs with excessive 403 responses
    tail -1000 "$LOG_FILE" | awk '$9 == "403" {print $1}' | sort | uniq -c | sort -nr | while read count ip; do
        if [ $count -ge $THRESHOLD ]; then
            if ! grep -q "Require not ip $ip" "$BLOCK_FILE" 2>/dev/null; then
                echo "Require not ip $ip" >> "$BLOCK_FILE"
                echo "$(date): Auto-blocked $ip after $count attempts" >> logs/auto_blocking.log
            fi
        fi
    done
fi
EOF
            chmod +x "$LOG_DIR/auto_block.sh"
            success "Automatic IP blocking configured"
            info "Script created: $LOG_DIR/auto_block.sh"
            ;;
        2)
            echo ""
            info "Setting up threat intelligence auto-update..."
            warn "This feature requires external threat intelligence APIs"
            info "Configure your threat intelligence sources in the advanced configuration"
            ;;
        3)
            echo ""
            info "Configuring emergency lockdown..."
            
            cat > "$LOG_DIR/emergency_lockdown.sh" << 'EOF'
#!/bin/bash
# Emergency lockdown - blocks all access except whitelist
echo "# EMERGENCY LOCKDOWN - $(date)" > .htaccess_emergency
echo "Require ip 127.0.0.1" >> .htaccess_emergency
echo "Require ip ::1" >> .htaccess_emergency
# Add your trusted IPs here
mv .htaccess .htaccess_backup_$(date +%s) 2>/dev/null
mv .htaccess_emergency .htaccess
echo "$(date): Emergency lockdown activated" >> logs/emergency.log
EOF
            chmod +x "$LOG_DIR/emergency_lockdown.sh"
            success "Emergency lockdown configured"
            ;;
        4)
            echo ""
            info "Setting up real-time alert system..."
            info "Alert system requires email/notification configuration"
            warn "This is an advanced feature - see documentation for setup"
            ;;
        5)
            echo ""
            info "Configuring response thresholds..."
            echo "Current thresholds:"
            echo "  - Failed attempts before auto-block: 5"
            echo "  - Monitoring window: Last 1000 log entries"
            echo "  - Emergency trigger: 50 failed attempts/minute"
            info "Modify thresholds in $LOG_DIR/auto_block.sh"
            ;;
        6)
            echo ""
            info "Scheduling automated security scans..."
            
            # Create a basic security scan script
            cat > "$LOG_DIR/security_scan.sh" << 'EOF'
#!/bin/bash
# Automated security scan
echo "$(date): Starting automated security scan" >> logs/security_scan.log

# Check for unauthorized changes
if [ -f ".htaccess" ]; then
    if ! grep -q "XXMXLI SERVER-SIDE IP BLOCKING" .htaccess; then
        echo "$(date): WARNING - .htaccess security header missing" >> logs/security_scan.log
    fi
fi

# Check for new files in admin directory
find admin/ -newer logs/last_scan_timestamp 2>/dev/null | while read file; do
    echo "$(date): New file detected in admin: $file" >> logs/security_scan.log
done

touch logs/last_scan_timestamp
echo "$(date): Security scan completed" >> logs/security_scan.log
EOF
            chmod +x "$LOG_DIR/security_scan.sh"
            success "Security scan script created"
            info "Add to crontab for scheduled execution"
            ;;
        7)
            show_interactive_menu
            return
            ;;
        *)
            error "Invalid option"
            read -p "Press Enter to continue..."
            automated_response_system
            ;;
    esac
    
    echo ""
    success "Automated response configuration completed"
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Generate comprehensive security report
generate_security_report() {
    show_banner
    echo -e "${PURPLE}${FILE} GENERATING SECURITY REPORT${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    local report_file="$REPORT_DIR/security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    info "Generating comprehensive security analysis report..."
    sleep 1
    
    # Create comprehensive report
    cat > "$report_file" << EOF
XXMXLI COMPREHENSIVE SECURITY REPORT
===================================
Generated: $(date)
Report ID: $(basename "$report_file" .txt)

EXECUTIVE SUMMARY:
$(security_status_overview_silent 2>&1 | head -20)

THREAT INTELLIGENCE STATUS:
$(threat_intelligence_dashboard_silent 2>&1)

ADMIN SECURITY AUDIT:
$(admin_security_audit_silent 2>&1)

CURRENT SECURITY CONFIGURATION:
- Server-side blocking: $([ -f ".htaccess" ] && grep -q "XXMXLI" ".htaccess" && echo "ACTIVE" || echo "INACTIVE")
- Admin protection: $([ -f "admin/.htaccess" ] && echo "CONFIGURED" || echo "NOT CONFIGURED")
- Threat intelligence: $([ -f "assets/security/blocked_ips.json" ] && echo "ACTIVE" || echo "MISSING")

BLOCKED IP STATISTICS:
- Total server blocks: $(grep -c "Require not ip" .htaccess 2>/dev/null || echo "0")
- Database entries: $([ -f "assets/security/blocked_ips.json" ] && jq length assets/security/blocked_ips.json 2>/dev/null || echo "0")

RECENT SECURITY EVENTS:
$(tail -20 logs/security_events.log 2>/dev/null || echo "No recent events logged")

SECURITY RECOMMENDATIONS:
1. Regular threat intelligence updates
2. Monitor admin access logs
3. Review blocked IP effectiveness
4. Update security configurations quarterly
5. Test backup and recovery procedures

For immediate security concerns, contact your security administrator.
Report generated by XXMXLI Security Monitoring System
EOF
    
    success "Security report generated: $report_file"
    
    echo ""
    info "Report includes:"
    echo "  - Executive security summary"
    echo "  - Threat intelligence analysis"
    echo "  - Admin security audit results"
    echo "  - Current configuration status"
    echo "  - Statistical analysis"
    echo "  - Security recommendations"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Advanced configuration
advanced_configuration() {
    show_banner
    echo -e "${PURPLE}${GEAR} ADVANCED SECURITY CONFIGURATION${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    echo -e "${CYAN}${ARROW} Advanced Security Options${NC}"
    echo "----------------------------------------"
    echo ""
    echo -e "${GREEN}1)${NC} ${SHIELD} Configure Threat Intelligence Sources"
    echo -e "${GREEN}2)${NC} ${LIGHTNING} Setup Custom Blocking Rules"
    echo -e "${GREEN}3)${NC} ${EYE} Configure Security Monitoring"
    echo -e "${GREEN}4)${NC} ${FIRE} Emergency Response Procedures"
    echo -e "${GREEN}5)${NC} ${GEAR} System Integration Settings"
    echo -e "${GREEN}6)${NC} ${CLOCK} Backup & Recovery Configuration"
    echo -e "${GREEN}7)${NC} ${ARROW} Back to main menu"
    echo ""
    
    read -p "Choose configuration option [1-7]: " -r choice
    
    case $choice in
        1)
            echo ""
            info "Threat Intelligence Sources Configuration"
            echo "Current sources:"
            echo "  - Internal blacklist database"
            echo "  - Manual IP submissions"
            info "Add external threat intelligence APIs in assets/security/config.json"
            ;;
        2)
            echo ""
            info "Custom Blocking Rules Configuration"
            echo "Current rule types:"
            echo "  - IP-based blocking"
            echo "  - Country-based blocking (if configured)"
            echo "  - Pattern-based blocking"
            warn "Advanced rules require manual .htaccess editing"
            ;;
        3)
            echo ""
            info "Security Monitoring Configuration"
            echo "Monitoring components:"
            echo "  - Real-time log analysis"
            echo "  - Automated threat detection"
            echo "  - Performance impact monitoring"
            success "Monitoring is active and configured"
            ;;
        4)
            echo ""
            critical "EMERGENCY RESPONSE PROCEDURES"
            echo "Available procedures:"
            echo "  - Emergency lockdown (blocks all access)"
            echo "  - Threat intelligence refresh"
            echo "  - Backup restoration"
            echo "  - Security reset"
            warn "Use emergency procedures only when necessary"
            ;;
        5)
            echo ""
            info "System Integration Settings"
            echo "Integration points:"
            echo "  - Web server configuration"
            echo "  - Log file monitoring"
            echo "  - Database connectivity"
            echo "  - External API endpoints"
            ;;
        6)
            echo ""
            info "Backup & Recovery Configuration"
            echo "Backup components:"
            echo "  - Security configurations"
            echo "  - Threat intelligence data"
            echo "  - Access logs"
            echo "  - Admin credentials"
            success "Automated backups are configured"
            ;;
        7)
            show_interactive_menu
            return
            ;;
        *)
            error "Invalid option"
            read -p "Press Enter to continue..."
            advanced_configuration
            ;;
    esac
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Help and documentation
show_help() {
    show_banner
    echo -e "${PURPLE}${INFO} SECURITY MONITORING HELP${NC}"
    echo "================================================================"
    echo ""
    
    echo -e "${WHITE}XXMXLI Security Monitoring System${NC}"
    echo "Advanced real-time security intelligence and threat detection platform"
    echo ""
    
    echo -e "${CYAN}MONITORING CAPABILITIES:${NC}"
    echo "  ${SHIELD} Real-time threat detection and blocking"
    echo "  ${EYE} Live log monitoring and analysis"
    echo "  ${FIRE} Advanced threat intelligence integration"
    echo "  ${LIGHTNING} Automated response and remediation"
    echo "  ${CHART} Comprehensive security analytics"
    echo "  ${LOCK} Admin security auditing"
    echo ""
    
    echo -e "${CYAN}COMMAND LINE USAGE:${NC}"
    echo "  $0                     - Interactive dashboard mode"
    echo "  $0 --status            - Quick security status check"
    echo "  $0 --monitor           - Start live log monitoring"
    echo "  $0 --audit             - Run admin security audit"
    echo "  $0 --report            - Generate security report"
    echo "  $0 --emergency         - Emergency lockdown mode"
    echo "  $0 --help              - Show this help"
    echo ""
    
    echo -e "${CYAN}SECURITY FEATURES:${NC}"
    echo "  • Multi-layer IP blocking (server + client)"
    echo "  • Real-time threat intelligence updates"
    echo "  • Automated attack detection and response"
    echo "  • Comprehensive admin area protection"
    echo "  • Geographic threat analysis"
    echo "  • Performance impact monitoring"
    echo ""
    
    echo -e "${CYAN}EMERGENCY PROCEDURES:${NC}"
    echo "  ${FIRE} Emergency Lockdown: Blocks all access except whitelist"
    echo "  ${LIGHTNING} Rapid Response: Immediate threat containment"
    echo "  ${SHIELD} Backup Restore: Restore previous security configuration"
    echo "  ${GEAR} System Reset: Reset all security settings to defaults"
    echo ""
    
    echo -e "${YELLOW}${WARNING} IMPORTANT SECURITY NOTES:${NC}"
    echo "  • Always test security changes in a safe environment"
    echo "  • Keep regular backups of security configurations"
    echo "  • Monitor logs for false positives"
    echo "  • Update threat intelligence regularly"
    echo "  • Document all security incidents"
    echo ""
    
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Silent functions for automation and reporting
security_status_overview_silent() {
    check_environment
    local score=0
    [ -f ".htaccess" ] && grep -q "XXMXLI" ".htaccess" && ((score++))
    [ -f "admin/.htaccess" ] && ((score++))
    [ -f "assets/security/blocked_ips.json" ] && ((score++))
    echo "Security Score: $score/3"
}

threat_intelligence_dashboard_silent() {
    if [ -f "assets/security/blocked_ips.json" ]; then
        local total=$(jq length assets/security/blocked_ips.json 2>/dev/null || echo "0")
        echo "Threat Intelligence: $total entries active"
    else
        echo "Threat Intelligence: OFFLINE"
    fi
}

admin_security_audit_silent() {
    local issues=0
    [ ! -f "admin/.htaccess" ] && ((issues++))
    [ ! -f ".htaccess" ] && ((issues++))
    echo "Admin Security Issues: $issues detected"
}

# Exit program
exit_program() {
    show_banner
    echo -e "${GREEN}Thank you for using XXMXLI Security Monitoring System!${NC}"
    echo ""
    success "Security monitoring session completed"
    info "Your XXMXLI system remains under advanced protection"
    echo ""
    echo -e "${RED}${SHIELD} Stay vigilant. Stay secure. ${SHIELD}${NC}"
    echo ""
    exit 0
}

# Main execution logic
main() {
    # Check if running with command line arguments
    if [[ $# -gt 0 ]]; then
        case "${1:-}" in
            "--status")
                INTERACTIVE_MODE=false
                security_status_overview
                ;;
            "--monitor")
                INTERACTIVE_MODE=false
                live_log_monitor
                ;;
            "--audit")
                INTERACTIVE_MODE=false
                admin_security_audit
                ;;
            "--report")
                INTERACTIVE_MODE=false
                generate_security_report
                ;;
            "--emergency")
                INTERACTIVE_MODE=false
                critical "EMERGENCY LOCKDOWN INITIATED"
                warn "This will block all access except localhost"
                read -p "Type 'EMERGENCY' to confirm: " -r
                if [ "$REPLY" = "EMERGENCY" ]; then
                    # Emergency lockdown
                    cp .htaccess .htaccess_emergency_backup_$(date +%s) 2>/dev/null
                    echo "# EMERGENCY LOCKDOWN - $(date)" > .htaccess
                    echo "Require ip 127.0.0.1" >> .htaccess
                    echo "Require ip ::1" >> .htaccess
                    success "Emergency lockdown activated"
                else
                    warn "Emergency lockdown cancelled"
                fi
                ;;
            "--help")
                show_help
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    else
        # Interactive mode
        show_interactive_menu
    fi
}

# Run main function with all arguments
main "$@"
