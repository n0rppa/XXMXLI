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
# XXMXLI Security Health Check System v2.0
# Automated monitoring and maintenance for security scripts
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
HEALTH_LOG="$LOG_DIR/health_check.log"

# Load configuration
source "$CONFIG_DIR/security_monitor.conf" 2>/dev/null || {
    echo "Warning: Config file not found, using defaults"
    HEALTH_CHECK_INTERVAL_HOURS=24
    AUTO_CLEANUP_ENABLED=true
    CLEANUP_INTERVAL_DAYS=7
}

# Enhanced colors with fallback
setup_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        PURPLE=$(tput setaf 5)
        CYAN=$(tput setaf 6)
        WHITE=$(tput setaf 7)
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
        BOLD='\033[1m'
        NC='\033[0m'
    fi
}

# Unicode symbols with fallbacks
setup_symbols() {
    if locale charmap 2>/dev/null | grep -qi utf; then
        CHECK="✅"
        CROSS="❌" 
        WARNING="⚠️"
        INFO="ℹ️"
        GEAR="⚙️"
        SHIELD="🛡️"
        CLOCK="🕒"
        FIRE="🔥"
        ROCKET="🚀"
        HEART="💚"
        TOOL="🔧"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        INFO="[i]"
        GEAR="[G]"
        SHIELD="[S]"
        CLOCK="[T]"
        FIRE="[F]"
        ROCKET="[R]"
        HEART="[♥]"
        TOOL="[T]"
    fi
}

# Logging functions
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HEALTH_LOG"
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    log_with_timestamp "INFO: $1"
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    log_with_timestamp "SUCCESS: $1"
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1"
    log_with_timestamp "WARNING: $1"
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1"
    log_with_timestamp "ERROR: $1"
}

log_critical() { 
    echo -e "${RED}${FIRE}${NC} ${BOLD}$1${NC}"
    log_with_timestamp "CRITICAL: $1"
}

# Initialize logging
setup_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    
    # Rotate log if too large
    if [[ -f "$HEALTH_LOG" ]]; then
        local log_size=$(stat -f%z "$HEALTH_LOG" 2>/dev/null || stat -c%s "$HEALTH_LOG" 2>/dev/null || echo 0)
        if [[ $log_size -gt 10485760 ]]; then  # 10MB
            mv "$HEALTH_LOG" "${HEALTH_LOG}.$(date +%Y%m%d_%H%M%S).old"
            gzip "${HEALTH_LOG}.$(date +%Y%m%d_%H%M%S).old" 2>/dev/null || true
        fi
    fi
}

# System health banner
show_health_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                 XXMXLI SECURITY HEALTH CHECK                ║
║              Automated System Maintenance v2.0              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        ${HEART} Monitoring Security • ${TOOL} Maintaining Performance${NC}"
    echo ""
}

# Check if required tools are available
check_system_dependencies() {
    log_info "Checking system dependencies..."
    
    local required_tools=("grep" "awk" "curl" "python3" "bash")
    local optional_tools=("rg" "ag" "jq" "yq" "timeout")
    local missing_required=()
    local missing_optional=()
    
    # Check required tools
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool: available"
        else
            missing_required+=("$tool")
            log_error "$tool: MISSING (required)"
        fi
    done
    
    # Check optional tools
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "rg") version=$(rg --version | head -1 | awk '{print $2}') ;;
                "ag") version=$(ag --version | head -1 | awk '{print $3}') ;;
                "jq") version=$(jq --version | tr -d '"') ;;
                *) version="installed" ;;
            esac
            log_success "$tool: available ($version)"
        else
            missing_optional+=("$tool")
            log_warning "$tool: not available (optional, improves performance)"
        fi
    done
    
    # Report results
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_critical "Missing required tools: ${missing_required[*]}"
        return 1
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_warning "Missing optional tools: ${missing_optional[*]}"
        echo "  Install for better performance:"
        [[ " ${missing_optional[*]} " =~ " rg " ]] && echo "    - ripgrep: https://github.com/BurntSushi/ripgrep"
        [[ " ${missing_optional[*]} " =~ " ag " ]] && echo "    - the_silver_searcher: https://github.com/ggreer/the_silver_searcher"
        [[ " ${missing_optional[*]} " =~ " jq " ]] && echo "    - jq: https://stedolan.github.io/jq/"
    fi
    
    return 0
}

# Check security script health
check_security_scripts() {
    log_info "Checking security script health..."
    
    local scripts=(
        "monitor_security.sh"
        "security_monitor_optimized.sh"
        "process_w_blacklists.py"
        "blacklist_processor_optimized.py"
        "health-check.sh"
    )
    
    local healthy=0
    local total=${#scripts[@]}
    
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            # Check if script is executable
            if [[ -x "$SCRIPT_DIR/$script" ]]; then
                log_success "$script: executable and ready"
                ((healthy++))
            else
                log_warning "$script: exists but not executable"
                # Try to make it executable
                if chmod +x "$SCRIPT_DIR/$script" 2>/dev/null; then
                    log_success "$script: made executable"
                    ((healthy++))
                else
                    log_error "$script: cannot make executable"
                fi
            fi
        else
            log_warning "$script: not found"
        fi
    done
    
    local health_percentage=$((healthy * 100 / total))
    
    if [[ $health_percentage -ge 80 ]]; then
        log_success "Script health: $health_percentage% ($healthy/$total scripts healthy)"
    elif [[ $health_percentage -ge 60 ]]; then
        log_warning "Script health: $health_percentage% ($healthy/$total scripts healthy)"
    else
        log_error "Script health: $health_percentage% ($healthy/$total scripts healthy)"
    fi
    
    return $((total - healthy))
}

# Check configuration files
check_configuration_files() {
    log_info "Checking configuration files..."
    
    local config_files=(
        "config/security_monitor.conf"
        "config/security_monitor.json" 
        "config/security_monitor.yaml"
        "config/blacklist_processor.json"
    )
    
    local valid_configs=0
    
    for config_file in "${config_files[@]}"; do
        local full_path="$SCRIPT_DIR/$config_file"
        
        if [[ -f "$full_path" ]]; then
            # Validate config based on type
            case "$config_file" in
                *.json)
                    if command -v jq >/dev/null 2>&1; then
                        if jq -e . "$full_path" >/dev/null 2>&1; then
                            log_success "$config_file: valid JSON"
                            ((valid_configs++))
                        else
                            log_error "$config_file: invalid JSON syntax"
                        fi
                    else
                        log_warning "$config_file: exists but cannot validate (jq not available)"
                        ((valid_configs++))
                    fi
                    ;;
                *.yaml|*.yml)
                    if command -v yq >/dev/null 2>&1; then
                        if yq eval . "$full_path" >/dev/null 2>&1; then
                            log_success "$config_file: valid YAML"
                            ((valid_configs++))
                        else
                            log_error "$config_file: invalid YAML syntax"
                        fi
                    else
                        log_warning "$config_file: exists but cannot validate (yq not available)"
                        ((valid_configs++))
                    fi
                    ;;
                *.conf)
                    if source "$full_path" 2>/dev/null; then
                        log_success "$config_file: valid configuration"
                        ((valid_configs++))
                    else
                        log_error "$config_file: syntax errors detected"
                    fi
                    ;;
            esac
        else
            log_warning "$config_file: not found"
        fi
    done
    
    log_info "Configuration status: $valid_configs/${#config_files[@]} files valid"
    return $((${#config_files[@]} - valid_configs))
}

# Check log file health and perform rotation
check_log_health() {
    log_info "Checking log file health..."
    
    local log_files=(
        "logs/security_monitor.log"
        "logs/blacklist_processor.log"
        "logs/health_check.log"
        "logs/debug.log"
    )
    
    local max_size_mb=10
    local rotated_count=0
    
    for log_file in "${log_files[@]}"; do
        local full_path="$SCRIPT_DIR/$log_file"
        
        if [[ -f "$full_path" ]]; then
            local size_bytes=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo 0)
            local size_mb=$((size_bytes / 1024 / 1024))
            
            if [[ $size_mb -gt $max_size_mb ]]; then
                log_warning "$log_file: large size (${size_mb}MB), rotating..."
                
                # Rotate log
                local timestamp=$(date +%Y%m%d_%H%M%S)
                if mv "$full_path" "${full_path}.${timestamp}.old" 2>/dev/null; then
                    if gzip "${full_path}.${timestamp}.old" 2>/dev/null; then
                        log_success "$log_file: rotated and compressed"
                    else
                        log_success "$log_file: rotated (compression failed)"
                    fi
                    ((rotated_count++))
                else
                    log_error "$log_file: rotation failed"
                fi
            else
                log_success "$log_file: healthy (${size_mb}MB)"
            fi
        else
            log_info "$log_file: not present (will be created when needed)"
        fi
    done
    
    # Clean old log files
    if [[ $rotated_count -gt 0 ]] || [[ "$AUTO_CLEANUP_ENABLED" == "true" ]]; then
        local old_logs=$(find "$LOG_DIR" -name "*.old*" -mtime +30 2>/dev/null | wc -l)
        if [[ $old_logs -gt 0 ]]; then
            find "$LOG_DIR" -name "*.old*" -mtime +30 -delete 2>/dev/null
            log_success "Cleaned up $old_logs old log files"
        fi
    fi
    
    return 0
}

# Performance optimization check
check_performance() {
    log_info "Checking system performance..."
    
    # Test search tool performance
    local test_file=".htaccess"
    if [[ -f "$test_file" ]]; then
        local pattern="Require not ip"
        
        # Test different search tools
        for tool in grep rg ag awk; do
            if command -v "$tool" >/dev/null 2>&1; then
                local start_time=$(date +%s%N)
                
                case "$tool" in
                    "rg") rg --color=never "$pattern" "$test_file" >/dev/null 2>&1 ;;
                    "ag") ag --nocolor "$pattern" "$test_file" >/dev/null 2>&1 ;;
                    "awk") awk "/$pattern/" "$test_file" >/dev/null 2>&1 ;;
                    *) grep "$pattern" "$test_file" >/dev/null 2>&1 ;;
                esac
                
                local end_time=$(date +%s%N)
                local duration=$(( (end_time - start_time) / 1000000 ))
                
                if [[ $duration -lt 100 ]]; then
                    log_success "$tool performance: ${duration}ms (excellent)"
                elif [[ $duration -lt 500 ]]; then
                    log_success "$tool performance: ${duration}ms (good)"
                else
                    log_warning "$tool performance: ${duration}ms (slow)"
                fi
            fi
        done
    fi
    
    # Check disk space
    local disk_usage=$(df "$SCRIPT_DIR" | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $disk_usage -lt 80 ]]; then
        log_success "Disk usage: ${disk_usage}% (healthy)"
    elif [[ $disk_usage -lt 90 ]]; then
        log_warning "Disk usage: ${disk_usage}% (monitor closely)"
    else
        log_error "Disk usage: ${disk_usage}% (cleanup needed)"
    fi
    
    # Check memory usage (if available)
    if command -v free >/dev/null 2>&1; then
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [[ $mem_usage -lt 80 ]]; then
            log_success "Memory usage: ${mem_usage}% (healthy)"
        else
            log_warning "Memory usage: ${mem_usage}% (high)"
        fi
    fi
    
    return 0
}

# Security infrastructure check
check_security_infrastructure() {
    log_info "Checking security infrastructure..."
    
    local issues=0
    
    # Check .htaccess files
    if [[ -f ".htaccess" ]]; then
        if grep -q "XXMXLI" ".htaccess" 2>/dev/null; then
            local blocked_count=$(grep -c "Require not ip" ".htaccess" 2>/dev/null || echo 0)
            log_success "Main .htaccess: active with $blocked_count blocked IPs"
        else
            log_error "Main .htaccess: missing XXMXLI security rules"
            ((issues++))
        fi
    else
        log_error "Main .htaccess: file not found"
        ((issues++))
    fi
    
    # Check admin protection
    if [[ -f "admin/.htaccess" ]]; then
        log_success "Admin .htaccess: protection configured"
    else
        log_warning "Admin .htaccess: not configured"
        ((issues++))
    fi
    
    # Check security assets
    if [[ -f "assets/security/blocked_ips.js" ]]; then
        local file_age=$(( ($(date +%s) - $(stat -f%m "assets/security/blocked_ips.js" 2>/dev/null || stat -c%Y "assets/security/blocked_ips.js" 2>/dev/null || echo 0)) / 3600 ))
        if [[ $file_age -lt 24 ]]; then
            log_success "Blocked IPs database: fresh (${file_age}h old)"
        else
            log_warning "Blocked IPs database: outdated (${file_age}h old)"
        fi
    else
        log_warning "Blocked IPs database: not found"
    fi
    
    return $issues
}

# Generate health report
generate_health_report() {
    local report_file="$SCRIPT_DIR/reports/health_report_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$(dirname "$report_file")" 2>/dev/null
    
    {
        echo "XXMXLI SECURITY HEALTH REPORT"
        echo "=============================="
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo ""
        
        echo "DEPENDENCY CHECK:"
        check_system_dependencies 2>&1 | grep -E "(available|MISSING|not available)"
        echo ""
        
        echo "SCRIPT HEALTH:"
        check_security_scripts 2>&1 | grep -E "(executable|not found|health:)"
        echo ""
        
        echo "CONFIGURATION STATUS:"
        check_configuration_files 2>&1 | grep -E "(valid|invalid|not found|status:)"
        echo ""
        
        echo "PERFORMANCE METRICS:"
        check_performance 2>&1 | grep -E "(performance:|usage:)"
        echo ""
        
        echo "SECURITY INFRASTRUCTURE:"
        check_security_infrastructure 2>&1 | grep -E "(htaccess:|database:)"
        echo ""
        
    } > "$report_file"
    
    log_success "Health report generated: $report_file"
}

# Interactive health check menu
show_health_menu() {
    show_health_banner
    
    echo -e "${WHITE}${GEAR} SECURITY HEALTH CHECK OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${CHECK} Full System Health Check"
    echo -e "${GREEN}2)${NC} ${GEAR} Check Dependencies"
    echo -e "${GREEN}3)${NC} ${SHIELD} Check Security Scripts"
    echo -e "${GREEN}4)${NC} ${INFO} Check Configuration Files"
    echo -e "${GREEN}5)${NC} ${CLOCK} Check Log Health"
    echo -e "${GREEN}6)${NC} ${ROCKET} Performance Check"
    echo -e "${GREEN}7)${NC} ${FIRE} Security Infrastructure Check"
    echo -e "${GREEN}8)${NC} ${TOOL} Generate Health Report"
    echo -e "${GREEN}9)${NC} ${HEART} Schedule Automatic Checks"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "$(echo -e "${CYAN}Choose option [0-9]:${NC} ")" choice
    
    case "$choice" in
        1) run_full_health_check ;;
        2) check_system_dependencies ;;
        3) check_security_scripts ;;
        4) check_configuration_files ;;
        5) check_log_health ;;
        6) check_performance ;;
        7) check_security_infrastructure ;;
        8) generate_health_report ;;
        9) schedule_automatic_checks ;;
        0) log_info "Exiting health check system"; exit 0 ;;
        *) log_error "Invalid option: $choice"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_health_menu
}

# Run full health check
run_full_health_check() {
    echo -e "${PURPLE}${BOLD}🏥 FULL SYSTEM HEALTH CHECK${NC}"
    echo "================================================================"
    echo ""
    
    local start_time=$(date +%s)
    local total_issues=0
    
    # Run all checks
    check_system_dependencies || ((total_issues += $?))
    echo ""
    
    check_security_scripts || ((total_issues += $?))
    echo ""
    
    check_configuration_files || ((total_issues += $?))
    echo ""
    
    check_log_health || ((total_issues += $?))
    echo ""
    
    check_performance || ((total_issues += $?))
    echo ""
    
    check_security_infrastructure || ((total_issues += $?))
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "================================================================"
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "Health check completed in ${duration}s - System is healthy! ${HEART}"
    elif [[ $total_issues -lt 5 ]]; then
        log_warning "Health check completed in ${duration}s - Minor issues detected ($total_issues)"
    else
        log_error "Health check completed in ${duration}s - Multiple issues found ($total_issues)"
    fi
}

# Schedule automatic checks
schedule_automatic_checks() {
    echo -e "${PURPLE}${CLOCK} AUTOMATIC HEALTH CHECK SCHEDULING${NC}"
    echo "================================================================"
    echo ""
    
    local cron_entry="0 */6 * * * $SCRIPT_DIR/security_health_check.sh --auto 2>&1 | logger -t xxmxli-health"
    
    log_info "Current schedule: Every 6 hours"
    log_info "Log location: System journal (use journalctl -t xxmxli-health)"
    echo ""
    
    if crontab -l 2>/dev/null | grep -q "security_health_check.sh"; then
        log_success "Automatic health checks are already scheduled"
    else
        echo "Would you like to schedule automatic health checks?"
        read -p "Enter 'yes' to confirm: " confirm
        
        if [[ "$confirm" == "yes" ]]; then
            (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
            log_success "Automatic health checks scheduled"
        else
            log_info "Automatic scheduling cancelled"
        fi
    fi
}

# Main execution
main() {
    # Handle command line arguments
    case "${1:-}" in
        "--auto"|"-a")
            # Automated mode (for cron)
            setup_colors
            setup_symbols  
            setup_logging
            run_full_health_check
            generate_health_report
            ;;
        "--report"|"-r")
            # Report only mode
            setup_colors
            setup_symbols
            setup_logging
            generate_health_report
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--auto|--report|--help]"
            echo "  --auto     Run automated health check (for cron)"
            echo "  --report   Generate health report only"
            echo "  --help     Show this help"
            exit 0
            ;;
        *)
            # Interactive mode
            setup_colors
            setup_symbols
            setup_logging
            show_health_menu
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "Health check system terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
