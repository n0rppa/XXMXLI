#!/usr/bin/env bash
SAFE_MODE=true

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
    stack_trace >&2 || true
    exit $error_code
}
trap 'error_exit ${LINENO} $?' ERR

# Stack trace for diagnostics
stack_trace() {
    echo "--- stack trace ---"
    local i=0
    while caller $i; do
        ((i++))
    done
}

# Default PATH for cron and non-interactive sessions
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

# Cron-safe logging controls
NO_COLOR="${NO_COLOR:-}"     # Set to any value to disable ANSI colors
QUIET_MODE="${QUIET_MODE:-false}"  # Set to true to reduce stdout (cron)
SYSLOG="${SYSLOG:-false}"          # Set true to also log to syslog via logger
SAFE_MODE="${SAFE_MODE:-false}"    # Set true to simulate (no changes), use run_cmd

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
    # Optional syslog
    if [[ "$SYSLOG" == "true" ]] && command -v logger >/dev/null 2>&1; then
        logger -t "$(basename "$0")" "[$level] $message" || true
    fi
    
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
    
    for tool in awk grep rg ag; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
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

# Privilege check with explanation
require_root_or_sudo() {
    local reason="${1:-This operation requires administrative privileges.}"
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "This action needs admin privileges (root) to proceed." >&2
        echo "Why: $reason" >&2
        echo "Examples include: writing to /etc, managing firewall, installing packages, using privileged ports, or writing to /var/log." >&2
        echo "Re-run with: sudo $0 "$@"" >&2
        exit 100
    fi
}

# Safe execution wrapper obeying SAFE_MODE
run_cmd() {
    if [[ "$SAFE_MODE" == "true" ]]; then
        echo "DRY-RUN: $*"
        log_performance "INFO" "DRY-RUN: $*"
        return 0
    else
        "$@"
    fi
}

# Background helpers
declare -a __BG_PIDS=()
run_background() { "$@" & __BG_PIDS+=($!); }
wait_all() { local p; for p in "${__BG_PIDS[@]}"; do wait "$p"; done; __BG_PIDS=(); }

# AWK helpers
awk_match() { local pat="$1" file="$2"; awk "/${pat}/" "$file"; }
awk_extract_field() { local n="$1"; shift; awk -v n="$n" '{print $n}' "$@"; }

# Safe sed in-place (portable)
safe_sed_inplace() {
    local script="$1" file="$2" tmp
    tmp=$(mktemp) && sed -e "$script" "$file" > "$tmp" && mv "$tmp" "$file"
}

# IP list normalization (stdin -> stdout)
normalize_ip_list() {
    awk 'BEGIN{FS="[[:space:]]+"} {gsub(/^\s+|\s+$/, ""); if ($0 ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}(\/[0-9]{1,2})?$/ || $0 ~ /^[0-9a-fA-F:]+(\/[0-9]{1,3})?$/) print $0}' \
    | LC_ALL=C sort -u
}

# JSON helper: jq or python fallback
json_query() {
    local file="$1" filter="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r "$filter" "$file"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$file" "$filter" <<'PY'
import json,sys
fn,flt=sys.argv[1],sys.argv[2]
data=json.load(open(fn))
if flt.strip()=='.[]':
    if isinstance(data,list):
        for x in data: print(x)
    else:
        for k,v in (data or {}).items(): print(k)
else:
    # Minimal fallback: print entire json
    print(json.dumps(data))
PY
    else
        echo "ERROR: Need jq or python3 for json_query($file, $filter)" >&2; return 127
    fi
}

# Initialize logging
log_performance "INFO" "Script $(basename "$0") started with enhanced optimizations"

# Acquire lock to prevent overlap
acquire_lock
trap 'release_lock' EXIT

# Subcommands: manual and read-log
show_manual() {
        cat <<MAN
Step-by-step manual:
1) SAFE MODE: export SAFE_MODE=true to simulate changes; commands will be logged not executed.
2) Logging: file at $LOG_FILE; enable syslog with SYSLOG=true.
3) Locking: prevents concurrent runs via flock or /tmp lock.
4) Admin privileges: some actions require root (e.g., /etc edits, firewall). Use sudo.
5) IP Lists: pipe through normalize_ip_list for dedupe and validation.
6) Background work: use run_background <cmd> ... then wait_all to synchronize.
7) Text processing: prefer awk_match/awk_extract_field over grep for portability.
8) JSON: json_query <file> <filter> uses jq or a Python fallback.
MAN
}

read_log() { local n=${1:-200}; tail -n "$n" "$LOG_FILE" 2>/dev/null || echo "No logs yet."; }

# Quick CLI interceptors
case "${1:-}" in
    manual) show_manual; exit 0 ;;
    read-log) shift; read_log "${1:-200}"; exit 0 ;;
esac


# ================================================================
# XXMXLI SYSTEM HEALTH CHECK MONITOR
# Professional Interactive Health Monitoring System
# ================================================================

# Color definitions for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
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
HEART="💚"

# Messaging functions
log() { echo -e "${WHITE}[$(date +'%H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}${CHECK}${NC} $1"; }
error() { echo -e "${RED}${CROSS}${NC} $1"; }
warn() { echo -e "${YELLOW}${WARNING}${NC} $1"; }
info() { echo -e "${CYAN}${INFO}${NC} $1"; }

# Show beautiful banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║              ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗          ║
    ║              ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║          ║
    ║               ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║          ║
    ║               ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║          ║
    ║              ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗     ║
    ║              ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝     ║
    ║                                                              ║
    ║                   SYSTEM HEALTH MONITOR                      ║
    ║              Professional System Health Checker              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        ${MAGNIFY} Comprehensive System Health Analysis${NC}"
    echo -e "${YELLOW}        ${STAR} Interactive Health Monitoring Dashboard${NC}"
    echo ""
}

# Interactive menu
show_interactive_menu() {
    show_banner
    echo -e "${WHITE}${ARROW} HEALTH CHECK OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${HEART} Full System Health Check"
    echo -e "${GREEN}2)${NC} ${FILE} Directory Structure Check"
    echo -e "${GREEN}3)${NC} ${GLOBE} Server & API Status Check"
    echo -e "${GREEN}4)${NC} ${CHART} Data File Validation"
    echo -e "${GREEN}5)${NC} ${ROCKET} GitHub Pages Compatibility Check"
    echo -e "${GREEN}6)${NC} ${GEAR} Performance Analysis"
    echo -e "${GREEN}7)${NC} ${SHIELD} Security Status Check"
    echo -e "${GREEN}8)${NC} ${STAR} Generate Health Report"
    echo -e "${GREEN}9)${NC} ${INFO} Help & Documentation"
    echo -e "${RED}0)${NC} ${CROSS} Exit"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Choose option [0-9]: ${NC}")" -r choice
    
    case $choice in
        1) full_health_check ;;
        2) directory_check ;;
        3) server_api_check ;;
        4) data_validation ;;
        5) github_pages_check ;;
        6) performance_analysis ;;
        7) security_check ;;
        8) generate_health_report ;;
        9) show_help ;;
        0) exit_program ;;
        *) 
            error "Invalid option. Please choose 0-9."
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
        echo "  - status.html (status page)"
        echo "  - admin/ directory"
        echo "  - api/ directory"
        echo "  - data/ directory"
        echo ""
        exit 1
    fi
}

# Full comprehensive health check
full_health_check() {
    show_banner
    echo -e "${PURPLE}${HEART} COMPREHENSIVE SYSTEM HEALTH CHECK${NC}"
    echo "================================================================"
    echo ""
    
    info "Starting comprehensive system analysis..."
    sleep 1
    
    check_environment
    
    echo ""
    echo -e "${CYAN}${ARROW} Running all health checks...${NC}"
    echo ""
    
    # Run all check components
    local checks_passed=0
    local total_checks=7
    
    # Directory check
    info "1/7 - Directory structure validation..."
    if directory_check_silent; then
        success "Directory structure: PASSED"
        ((checks_passed++))
    else
        error "Directory structure: FAILED"
    fi
    
    # Server check
    info "2/7 - Server status validation..."
    if server_check_silent; then
        success "Server status: PASSED"
        ((checks_passed++))
    else
        warn "Server status: WARNING (not running)"
    fi
    
    # API check
    info "3/7 - API endpoints validation..."
    if api_check_silent; then
        success "API endpoints: PASSED"
        ((checks_passed++))
    else
        error "API endpoints: FAILED"
    fi
    
    # Data validation
    info "4/7 - Data files validation..."
    if data_validation_silent; then
        success "Data files: PASSED"
        ((checks_passed++))
    else
        error "Data files: FAILED"
    fi
    
    # GitHub Pages
    info "5/7 - GitHub Pages compatibility..."
    if github_pages_check_silent; then
        success "GitHub Pages: PASSED"
        ((checks_passed++))
    else
        warn "GitHub Pages: WARNING"
    fi
    
    # Performance
    info "6/7 - Performance analysis..."
    if performance_check_silent; then
        success "Performance: PASSED"
        ((checks_passed++))
    else
        warn "Performance: WARNING"
    fi
    
    # Security
    info "7/7 - Security status..."
    if security_check_silent; then
        success "Security: PASSED"
        ((checks_passed++))
    else
        warn "Security: WARNING"
    fi
    
    echo ""
    echo "================================================================"
    
    # Show results
    local percentage=$((checks_passed * 100 / total_checks))
    
    if [ $checks_passed -eq $total_checks ]; then
        echo -e "${GREEN}${HEART} SYSTEM STATUS: EXCELLENT${NC}"
        echo -e "${GREEN}All $total_checks checks passed! Your system is running optimally.${NC}"
    elif [ $percentage -ge 80 ]; then
        echo -e "${YELLOW}${WARNING} SYSTEM STATUS: GOOD${NC}"
        echo -e "${YELLOW}$checks_passed/$total_checks checks passed ($percentage%). Minor issues detected.${NC}"
    elif [ $percentage -ge 60 ]; then
        echo -e "${YELLOW}${WARNING} SYSTEM STATUS: FAIR${NC}"
        echo -e "${YELLOW}$checks_passed/$total_checks checks passed ($percentage%). Some attention needed.${NC}"
    else
        echo -e "${RED}${CROSS} SYSTEM STATUS: NEEDS ATTENTION${NC}"
        echo -e "${RED}$checks_passed/$total_checks checks passed ($percentage%). Multiple issues detected.${NC}"
    fi
    
    echo ""
    info "For detailed analysis, run individual check options from the menu"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Directory structure check
directory_check() {
    show_banner
    echo -e "${PURPLE}${FILE} DIRECTORY STRUCTURE CHECK${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Checking required files and directories..."
    echo ""
    
    local required_files=(
        "index.html"
        "status.html"
        "admin/visitor-dashboard.html"
        "api/get-visitor-stats.php"
        "api/visitor-logger.php"
        "api/check-blacklist.php"
        "assets/js/static-visitor-tracker.js"
        "data/visitors.json"
        "data/daily_stats.json"
        "_config.yml"
        ".nojekyll"
    )
    
    local found=0
    local total=${#required_files[@]}
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            success "$file"
            ((found++))
        else
            error "$file (missing)"
        fi
    done
    
    echo ""
    echo "================================================================"
    
    local percentage=$((found * 100 / total))
    
    if [ $found -eq $total ]; then
        success "Directory structure is complete! ($found/$total files found)"
    elif [ $percentage -ge 90 ]; then
        warn "Directory structure is mostly complete ($found/$total files, $percentage%)"
    else
        error "Directory structure has missing files ($found/$total files, $percentage%)"
        echo ""
        info "Run 'git status' to check for uncommitted files"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Server and API status check
server_api_check() {
    show_banner
    echo -e "${PURPLE}${GLOBE} SERVER & API STATUS CHECK${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    # Check PHP availability
    info "Checking PHP availability..."
    if command -v php &> /dev/null; then
        success "PHP is available"
        info "Version: $(php --version | head -n 1)"
    else
        error "PHP not found"
        warn "Install PHP to run local development server"
    fi
    
    echo ""
    
    # Check server status
    info "Checking local server status..."
    if curl -s http://localhost:8000 &> /dev/null; then
        success "Local server is running on port 8000"
        
        echo ""
        info "Testing API endpoints..."
        
        # Test visitor stats API
        if curl -s http://localhost:8000/api/get-visitor-stats.php?action=overview | grep -q "totalVisitors"; then
            success "Visitor Stats API is working"
        else
            error "Visitor Stats API error"
        fi
        
        # Test visitor logger API
        if curl -s -f http://localhost:8000/api/visitor-logger.php &> /dev/null; then
            success "Visitor Logger API is accessible"
        else
            error "Visitor Logger API error"
        fi
        
        # Test blacklist API
        if curl -s -f http://localhost:8000/api/check-blacklist.php &> /dev/null; then
            success "Blacklist API is accessible"
        else
            error "Blacklist API error"
        fi
        
    else
        warn "Local server not running on port 8000"
        info "Start with: php -S localhost:8000 -t ."
        warn "Cannot test APIs without running server"
    fi
    
    echo ""
    echo "================================================================"
    info "Quick Test URLs:"
    echo "   ${GLOBE} Main Site: http://localhost:8000/"
    echo "   ${CHART} Status Page: http://localhost:8000/status.html"
    echo "   ${SHIELD} Admin Dashboard: http://localhost:8000/admin/visitor-dashboard.html"
    echo "   ${GEAR} API Test: http://localhost:8000/api/get-visitor-stats.php?action=overview"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Data file validation
data_validation() {
    show_banner
    echo -e "${PURPLE}${CHART} DATA FILE VALIDATION${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Validating JSON data files..."
    echo ""
    
    local files_ok=0
    local total_files=2
    
    # Check daily_stats.json
    if [ -f "data/daily_stats.json" ]; then
        if python3 -m json.tool data/daily_stats.json &> /dev/null; then
            success "daily_stats.json is valid JSON"
            local entries=$(jq length data/daily_stats.json 2>/dev/null || echo "unknown")
            info "Contains $entries entries"
            ((files_ok++))
        else
            error "daily_stats.json has invalid JSON"
            warn "Run: echo '{}' > data/daily_stats.json to reset"
        fi
    else
        error "daily_stats.json missing"
        info "Creating empty file..."
        mkdir -p data
        echo '{}' > data/daily_stats.json
        success "Created empty daily_stats.json"
        ((files_ok++))
    fi
    
    echo ""
    
    # Check visitors.json
    if [ -f "data/visitors.json" ]; then
        if python3 -m json.tool data/visitors.json &> /dev/null; then
            success "visitors.json is valid JSON"
            local entries=$(jq length data/visitors.json 2>/dev/null || echo "unknown")
            info "Contains $entries visitor records"
            ((files_ok++))
        else
            error "visitors.json has invalid JSON"
            warn "Run: echo '[]' > data/visitors.json to reset"
        fi
    else
        error "visitors.json missing"
        info "Creating empty file..."
        mkdir -p data
        echo '[]' > data/visitors.json
        success "Created empty visitors.json"
        ((files_ok++))
    fi
    
    echo ""
    echo "================================================================"
    
    if [ $files_ok -eq $total_files ]; then
        success "All data files are valid and ready!"
    else
        warn "Some data files need attention"
        info "The system will automatically recreate missing files"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# GitHub Pages compatibility check
github_pages_check() {
    show_banner
    echo -e "${PURPLE}${ROCKET} GITHUB PAGES COMPATIBILITY${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Checking GitHub Pages configuration..."
    echo ""
    
    local config_ok=0
    local total_configs=2
    
    # Check _config.yml
    if [ -f "_config.yml" ]; then
        success "_config.yml is present"
        info "GitHub Pages Jekyll configuration found"
        ((config_ok++))
    else
        error "_config.yml missing"
        warn "GitHub Pages may not work correctly without Jekyll config"
    fi
    
    # Check .nojekyll
    if [ -f ".nojekyll" ]; then
        success ".nojekyll is present"
        info "GitHub Pages will serve files directly"
        ((config_ok++))
    else
        error ".nojekyll missing"
        warn "Creating .nojekyll file..."
        touch .nojekyll
        success "Created .nojekyll file"
        ((config_ok++))
    fi
    
    echo ""
    
    # Check for GitHub Pages specific requirements
    info "Checking static mode compatibility..."
    
    if [ -f "assets/js/static-visitor-tracker.js" ]; then
        success "Static visitor tracker is available"
        info "System will work in static mode on GitHub Pages"
    else
        warn "Static visitor tracker not found"
        warn "Dynamic features may not work on GitHub Pages"
    fi
    
    echo ""
    echo "================================================================"
    
    if [ $config_ok -eq $total_configs ]; then
        success "GitHub Pages configuration is complete!"
        info "Your site is ready for GitHub Pages deployment"
        echo ""
        info "The system will automatically switch to static mode when hosted on GitHub Pages"
    else
        warn "GitHub Pages configuration needs attention"
        info "Some features may not work correctly when deployed"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Performance analysis
performance_analysis() {
    show_banner
    echo -e "${PURPLE}${ROCKET} PERFORMANCE ANALYSIS${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Analyzing system performance..."
    echo ""
    
    # File size analysis
    info "File size analysis:"
    if [ -f "data/visitors.json" ]; then
        local size=$(du -h data/visitors.json | cut -f1)
        info "visitors.json: $size"
        
        local records=$(jq length data/visitors.json 2>/dev/null || echo "0")
        if [ "$records" -gt 1000 ]; then
            warn "Large visitor database ($records records) - consider archiving old data"
        else
            success "Visitor database size is optimal ($records records)"
        fi
    fi
    
    if [ -f "data/daily_stats.json" ]; then
        local size=$(du -h data/daily_stats.json | cut -f1)
        info "daily_stats.json: $size"
    fi
    
    echo ""
    
    # Server performance test
    if curl -s http://localhost:8000 &> /dev/null; then
        info "Server response time test..."
        local start_time=$(date +%s%N)
        curl -s http://localhost:8000 > /dev/null
        local end_time=$(date +%s%N)
        local response_time=$(( (end_time - start_time) / 1000000 ))
        
        if [ $response_time -lt 100 ]; then
            success "Server response time: ${response_time}ms (excellent)"
        elif [ $response_time -lt 500 ]; then
            success "Server response time: ${response_time}ms (good)"
        else
            warn "Server response time: ${response_time}ms (slow)"
        fi
    else
        warn "Cannot test server performance - server not running"
    fi
    
    echo ""
    echo "================================================================"
    success "Performance analysis completed"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Security status check
security_check() {
    show_banner
    echo -e "${PURPLE}${SHIELD} SECURITY STATUS CHECK${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    info "Checking security configurations..."
    echo ""
    
    # Check for .htaccess files
    if [ -f ".htaccess" ]; then
        success ".htaccess file is present"
        if grep -q "XXMXLI" ".htaccess"; then
            success "XXMXLI security rules are active"
        else
            warn "Generic .htaccess found - XXMXLI rules may not be active"
        fi
    else
        warn ".htaccess file not found"
        info "IP blocking may not be active"
    fi
    
    # Check admin protection
    if [ -f "admin/.htaccess" ]; then
        success "Admin directory is protected"
    else
        warn "Admin directory protection not found"
        warn "Admin area may be publicly accessible"
    fi
    
    # Check for sensitive files
    echo ""
    info "Checking for exposed sensitive files..."
    
    local sensitive_files=(
        "ADMIN_CREDENTIALS_SECURE.txt"
        "config/database.php"
        ".env"
        "secrets.txt"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [ -f "$file" ]; then
            warn "Sensitive file found: $file"
            warn "Ensure this file is not accessible via web"
        fi
    done
    
    # Check blacklist
    if [ -f "assets/security/blocked_ips.json" ]; then
        success "IP blacklist is present"
        local blocked_count=$(jq length assets/security/blocked_ips.json 2>/dev/null || echo "0")
        info "$blocked_count IPs are blocked"
    else
        warn "IP blacklist not found"
    fi
    
    echo ""
    echo "================================================================"
    info "Security recommendations:"
    echo "  1. Keep IP blacklist updated"
    echo "  2. Regularly check server logs"
    echo "  3. Use HTTPS in production"
    echo "  4. Keep software updated"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Generate comprehensive health report
generate_health_report() {
    show_banner
    echo -e "${PURPLE}${STAR} GENERATING HEALTH REPORT${NC}"
    echo "================================================================"
    echo ""
    
    check_environment
    
    local report_file="health_report_$(date +%Y%m%d_%H%M%S).txt"
    
    info "Generating comprehensive health report..."
    
    cat > "$report_file" << EOF
XXMXLI SYSTEM HEALTH REPORT
===========================
Generated: $(date)
Report ID: $(date +%Y%m%d_%H%M%S)

SYSTEM OVERVIEW:
- Script Location: $(pwd)
- User: $(whoami)
- Hostname: $(hostname)
- PHP Available: $(command -v php &> /dev/null && echo "Yes" || echo "No")
- Server Running: $(curl -s http://localhost:8000 &> /dev/null && echo "Yes" || echo "No")

DIRECTORY STRUCTURE:
$(directory_check_silent 2>&1)

SERVER STATUS:
$(server_check_silent 2>&1)

DATA VALIDATION:
$(data_validation_silent 2>&1)

SECURITY STATUS:
$(security_check_silent 2>&1)

PERFORMANCE METRICS:
- Visitor Records: $([ -f "data/visitors.json" ] && jq length data/visitors.json 2>/dev/null || echo "0")
- Daily Stats Size: $([ -f "data/daily_stats.json" ] && du -h data/daily_stats.json | cut -f1 || echo "N/A")
- Blocked IPs: $([ -f "assets/security/blocked_ips.json" ] && jq length assets/security/blocked_ips.json 2>/dev/null || echo "0")

RECOMMENDATIONS:
- Regularly update IP blacklist
- Monitor server logs for security threats
- Keep all software components updated
- Test APIs after each deployment

For technical support, refer to SYSTEM_STATUS_REPORT.md
EOF
    
    success "Health report generated: $report_file"
    
    echo ""
    info "Report contents:"
    echo "  - System overview and configuration"
    echo "  - Complete directory structure analysis"
    echo "  - Server and API status"
    echo "  - Data file validation results"
    echo "  - Security configuration check"
    echo "  - Performance metrics"
    echo "  - System recommendations"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Help and documentation
show_help() {
    show_banner
    echo -e "${PURPLE}${INFO} HELP & DOCUMENTATION${NC}"
    echo "================================================================"
    echo ""
    
    echo -e "${WHITE}XXMXLI Health Check Monitor${NC}"
    echo "This tool provides comprehensive health monitoring for your XXMXLI system."
    echo ""
    
    echo -e "${CYAN}AVAILABLE CHECKS:${NC}"
    echo "  ${HEART} Full Health Check    - Complete system analysis"
    echo "  ${FILE} Directory Check      - Verify all required files"
    echo "  ${GLOBE} Server/API Check     - Test server and endpoints"
    echo "  ${CHART} Data Validation      - Check JSON file integrity"
    echo "  ${ROCKET} GitHub Pages Check  - Verify deployment readiness"
    echo "  ${GEAR} Performance Analysis - System performance metrics"
    echo "  ${SHIELD} Security Check      - Security configuration audit"
    echo "  ${STAR} Health Report       - Generate detailed report"
    echo ""
    
    echo -e "${CYAN}COMMAND LINE USAGE:${NC}"
    echo "  $0                    - Interactive mode (this menu)"
    echo "  $0 --full             - Run full health check"
    echo "  $0 --directory        - Check directory structure"
    echo "  $0 --server           - Check server status"
    echo "  $0 --data             - Validate data files"
    echo "  $0 --github           - Check GitHub Pages compatibility"
    echo "  $0 --security         - Security audit"
    echo "  $0 --report           - Generate report"
    echo "  $0 --help             - Show this help"
    echo ""
    
    echo -e "${CYAN}SYSTEM REQUIREMENTS:${NC}"
    echo "  - PHP (for local development server)"
    echo "  - curl (for API testing)"
    echo "  - jq (for JSON validation)"
    echo "  - Python 3 (for JSON validation)"
    echo ""
    
    echo -e "${CYAN}TROUBLESHOOTING:${NC}"
    echo "  ${CROSS} Server not running    → php -S localhost:8000 -t ."
    echo "  ${CROSS} JSON validation fails → Check file syntax"
    echo "  ${CROSS} Missing files         → Run git status"
    echo "  ${CROSS} API errors           → Check server logs"
    echo ""
    
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Silent check functions for automation
directory_check_silent() {
    local required_files=(
        "index.html" "status.html" "admin/visitor-dashboard.html"
        "api/get-visitor-stats.php" "api/visitor-logger.php" "api/check-blacklist.php"
        "assets/js/static-visitor-tracker.js" "data/visitors.json" "data/daily_stats.json"
        "_config.yml" ".nojekyll"
    )
    
    for file in "${required_files[@]}"; do
        [ -f "$file" ] || return 1
    done
    return 0
}

server_check_silent() {
    curl -s http://localhost:8000 &> /dev/null
}

api_check_silent() {
    curl -s http://localhost:8000/api/get-visitor-stats.php?action=overview | grep -q "totalVisitors"
}

data_validation_silent() {
    [ -f "data/daily_stats.json" ] && python3 -m json.tool data/daily_stats.json &> /dev/null &&
    [ -f "data/visitors.json" ] && python3 -m json.tool data/visitors.json &> /dev/null
}

github_pages_check_silent() {
    [ -f "_config.yml" ] && [ -f ".nojekyll" ]
}

performance_check_silent() {
    # Basic performance check - just verify files exist and are reasonable size
    [ -f "data/visitors.json" ] && [ $(stat -f%z data/visitors.json 2>/dev/null || stat -c%s data/visitors.json 2>/dev/null || echo 0) -lt 10485760 ]
}

security_check_silent() {
    [ -f ".htaccess" ] || [ -f "admin/.htaccess" ] || [ -f "assets/security/blocked_ips.json" ]
}

# Exit program
exit_program() {
    show_banner
    echo -e "${GREEN}Thank you for using XXMXLI Health Check Monitor!${NC}"
    echo ""
    success "System health monitoring completed"
    info "Your XXMXLI system is under professional monitoring"
    echo ""
    echo -e "${CYAN}${HEART} Keep your system healthy and secure!${NC}"
    echo ""
    exit 0
}

# Main execution logic
main() {
    # Check if running with command line arguments
    if [[ $# -gt 0 ]]; then
        case "${1:-}" in
            "--full")
                check_environment
                full_health_check
                ;;
            "--directory")
                check_environment
                directory_check
                ;;
            "--server")
                check_environment
                server_api_check
                ;;
            "--data")
                check_environment
                data_validation
                ;;
            "--github")
                check_environment
                github_pages_check
                ;;
            "--security")
                check_environment
                security_check
                ;;
            "--report")
                check_environment
                generate_health_report
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
