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
# XXMXLI OPTIMIZED HEALTH CHECK MONITOR v2.0
# Enhanced Performance • Better Error Handling • Configuration Support
# ================================================================

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/health_check.conf"
CONFIG_JSON="$CONFIG_DIR/health_check.json"

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

# Unicode symbols with ASCII fallbacks
setup_symbols() {
    if locale charmap 2>/dev/null | grep -qi utf; then
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
        CLOCK="🕒"
        FIRE="🔥"
        LIGHTNING="⚡"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        ARROW=">"
        STAR="[*]"
        SHIELD="[S]"
        GEAR="[G]"
        ROCKET="[R]"
        MAGNIFY="[?]"
        CHART="[C]"
        GLOBE="[O]"
        FILE="[F]"
        INFO="[i]"
        HEART="[♥]"
        CLOCK="[T]"
        FIRE="[F]"
        LIGHTNING="[L]"
    fi
}

# Configuration loading
load_configuration() {
    # Default values
    CHECK_TIMEOUT=30
    LOG_RETENTION_DAYS=7
    ENABLE_DETAILED_LOGGING=true
    AUTO_CLEANUP=true
    PERFORMANCE_MONITORING=true
    
    # Try JSON configuration first
    if [[ -f "$CONFIG_JSON" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
            CHECK_TIMEOUT=$(jq -r '.monitoring.check_timeout // 30' "$CONFIG_JSON" 2>/dev/null)
            LOG_RETENTION_DAYS=$(jq -r '.logging.retention_days // 7' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_DETAILED_LOGGING=$(jq -r '.logging.detailed // true' "$CONFIG_JSON" 2>/dev/null)
            AUTO_CLEANUP=$(jq -r '.maintenance.auto_cleanup // true' "$CONFIG_JSON" 2>/dev/null)
            PERFORMANCE_MONITORING=$(jq -r '.monitoring.performance // true' "$CONFIG_JSON" 2>/dev/null)
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
    HEALTH_LOG="$LOG_DIR/health_check.log"
    
    # Log rotation
    if [[ -f "$HEALTH_LOG" ]]; then
        local log_size=$(stat -f%z "$HEALTH_LOG" 2>/dev/null || stat -c%s "$HEALTH_LOG" 2>/dev/null || echo 0)
        if [[ $log_size -gt 10485760 ]]; then  # 10MB
            mv "$HEALTH_LOG" "${HEALTH_LOG}.$(date +%Y%m%d_%H%M%S).old"
            gzip "${HEALTH_LOG}.$(date +%Y%m%d_%H%M%S).old" 2>/dev/null || true
        fi
    fi
}

# Enhanced logging functions with file output
log_debug() { 
    [[ "${DEBUG:-false}" == "true" ]] && {
        echo -e "${CYAN}[DEBUG $(date +'%H:%M:%S')]${NC} $1" >&2
        echo "[DEBUG $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG" 2>/dev/null
    }
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    [[ "$ENABLE_DETAILED_LOGGING" == "true" ]] && echo "[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG" 2>/dev/null
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    [[ "$ENABLE_DETAILED_LOGGING" == "true" ]] && echo "[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG" 2>/dev/null
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1" >&2
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG" 2>/dev/null
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1" >&2
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG" 2>/dev/null
}

log_critical() { 
    echo -e "${RED}${FIRE}${NC} ${BOLD}$1${NC}" >&2
    echo "[CRITICAL $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$HEALTH_LOG" 2>/dev/null
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

# Optimized search function
optimized_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-$CHECK_TIMEOUT}"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    case "$SEARCH_TOOL" in
        "rg")
            run_with_timeout "$timeout" rg --color=never "$pattern" "$file"
            ;;
        "ag")
            run_with_timeout "$timeout" ag --nocolor "$pattern" "$file"
            ;;
        "awk")
            run_with_timeout "$timeout" awk "/$pattern/" "$file"
            ;;
        *)
            run_with_timeout "$timeout" grep "$pattern" "$file"
            ;;
    esac
}

# Enhanced banner with system info
show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║              ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗          ║
    ║              ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║          ║
    ║               ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║          ║
    ║               ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║          ║
    ║              ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗     ║
    ║              ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝     ║
    ║                                                              ║
    ║               OPTIMIZED HEALTH CHECK MONITOR v2.0           ║
    ║           Enhanced Performance • Better Error Handling       ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        ${ROCKET} Performance Optimized • ${GEAR} Configuration Driven${NC}"
    echo -e "${GREEN}        ${LIGHTNING} Using: $SEARCH_TOOL • Timeout: ${CHECK_TIMEOUT}s${NC}"
    echo ""
}

# System resource monitoring with performance optimization
check_system_resources() {
    log_info "Checking system resources..."
    local issues=0
    
    # CPU usage check with timeout
    local cpu_usage=0
    if command -v top >/dev/null 2>&1; then
        cpu_usage=$(run_with_timeout 5 top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo 0)
        cpu_usage=${cpu_usage%.*}  # Remove decimal part
        
        if [[ ${cpu_usage:-0} -lt 70 ]]; then
            log_success "CPU usage: ${cpu_usage}% (healthy)"
        elif [[ ${cpu_usage:-0} -lt 90 ]]; then
            log_warning "CPU usage: ${cpu_usage}% (high)"
            ((issues++))
        else
            log_error "CPU usage: ${cpu_usage}% (critical)"
            ((issues++))
        fi
    fi
    
    # Memory usage check
    if command -v free >/dev/null 2>&1; then
        local mem_info
        mem_info=$(run_with_timeout 5 free -m)
        if [[ -n "$mem_info" ]]; then
            local mem_usage=$(echo "$mem_info" | awk 'NR==2{printf "%.0f", $3*100/$2}')
            local mem_total=$(echo "$mem_info" | awk 'NR==2{print $2}')
            local mem_used=$(echo "$mem_info" | awk 'NR==2{print $3}')
            
            if [[ ${mem_usage:-0} -lt 80 ]]; then
                log_success "Memory usage: ${mem_usage}% (${mem_used}MB/${mem_total}MB)"
            elif [[ ${mem_usage:-0} -lt 95 ]]; then
                log_warning "Memory usage: ${mem_usage}% (${mem_used}MB/${mem_total}MB)"
                ((issues++))
            else
                log_error "Memory usage: ${mem_usage}% (${mem_used}MB/${mem_total}MB)"
                ((issues++))
            fi
        fi
    fi
    
    # Disk usage check with optimization
    local disk_usage
    disk_usage=$(df "$SCRIPT_DIR" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%' || echo 0)
    
    if [[ ${disk_usage:-0} -lt 80 ]]; then
        log_success "Disk usage: ${disk_usage}% (healthy)"
    elif [[ ${disk_usage:-0} -lt 95 ]]; then
        log_warning "Disk usage: ${disk_usage}% (monitor closely)"
        ((issues++))
    else
        log_error "Disk usage: ${disk_usage}% (cleanup needed urgently)"
        ((issues++))
    fi
    
    # Load average check (Linux/macOS)
    if command -v uptime >/dev/null 2>&1; then
        local load_avg
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',' || echo "0")
        local cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")
        
        if command -v bc >/dev/null 2>&1; then
            local load_percentage=$(echo "scale=0; $load_avg * 100 / $cpu_cores" | bc 2>/dev/null || echo 0)
            
            if [[ ${load_percentage:-0} -lt 70 ]]; then
                log_success "System load: ${load_avg} (${load_percentage}% of ${cpu_cores} cores)"
            elif [[ ${load_percentage:-0} -lt 100 ]]; then
                log_warning "System load: ${load_avg} (${load_percentage}% of ${cpu_cores} cores)"
                ((issues++))
            else
                log_error "System load: ${load_avg} (${load_percentage}% of ${cpu_cores} cores - overloaded)"
                ((issues++))
            fi
        else
            log_info "System load: ${load_avg} (${cpu_cores} cores available)"
        fi
    fi
    
    return $issues
}

# Enhanced security infrastructure check
check_security_infrastructure() {
    log_info "Checking security infrastructure..."
    local issues=0
    
    # Check .htaccess with optimized search
    if [[ -f ".htaccess" ]]; then
        if optimized_search "XXMXLI" ".htaccess" >/dev/null; then
            local blocked_count
            blocked_count=$(optimized_search "Require not ip" ".htaccess" | wc -l 2>/dev/null || echo 0)
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
    
    # Check security assets with file age
    local security_files=("assets/security/blocked_ips.js" "assets/security/blocked_ips.json")
    for security_file in "${security_files[@]}"; do
        if [[ -f "$security_file" ]]; then
            local file_age=$(( ($(date +%s) - $(stat -f%m "$security_file" 2>/dev/null || stat -c%Y "$security_file" 2>/dev/null || echo 0)) / 3600 ))
            if [[ $file_age -lt 24 ]]; then
                log_success "$(basename "$security_file"): fresh (${file_age}h old)"
            else
                log_warning "$(basename "$security_file"): outdated (${file_age}h old)"
            fi
        else
            log_warning "$(basename "$security_file"): not found"
        fi
    done
    
    return $issues
}

# Performance benchmarking
run_performance_benchmark() {
    if [[ "$PERFORMANCE_MONITORING" != "true" ]]; then
        return 0
    fi
    
    log_info "Running performance benchmark..."
    
    local test_file=".htaccess"
    if [[ ! -f "$test_file" ]]; then
        log_warning "Cannot run performance test - .htaccess not found"
        return 0
    fi
    
    local pattern="Require not ip"
    
    # Test available search tools
    for tool in grep rg ag awk; do
        if command -v "$tool" >/dev/null 2>&1; then
            local start_time end_time duration
            start_time=$(date +%s%N)
            
            case "$tool" in
                "rg") rg --color=never "$pattern" "$test_file" >/dev/null 2>&1 ;;
                "ag") ag --nocolor "$pattern" "$test_file" >/dev/null 2>&1 ;;
                "awk") awk "/$pattern/" "$test_file" >/dev/null 2>&1 ;;
                *) grep "$pattern" "$test_file" >/dev/null 2>&1 ;;
            esac
            
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            
            if [[ "$tool" == "$SEARCH_TOOL" ]]; then
                if [[ $duration -lt 50 ]]; then
                    log_success "$tool: ${duration}ms (CURRENT - excellent)"
                elif [[ $duration -lt 200 ]]; then
                    log_success "$tool: ${duration}ms (CURRENT - good)"
                else
                    log_warning "$tool: ${duration}ms (CURRENT - slow)"
                fi
            else
                if [[ $duration -lt 50 ]]; then
                    log_info "$tool: ${duration}ms (excellent)"
                elif [[ $duration -lt 200 ]]; then
                    log_info "$tool: ${duration}ms (good)"
                else
                    log_info "$tool: ${duration}ms (slow)"
                fi
            fi
        fi
    done
}

# Enhanced dependency check
check_dependencies() {
    log_info "Checking system dependencies..."
    
    local required_tools=("bash" "grep" "awk" "curl" "python3")
    local optional_tools=("rg" "ag" "jq" "timeout" "bc")
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
            log_success "$tool: available (performance enhanced)"
        else
            missing_optional+=("$tool")
            log_info "$tool: not available (optional)"
        fi
    done
    
    # Provide installation suggestions
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        echo ""
        log_info "Install optional tools for better performance:"
        [[ " ${missing_optional[*]} " =~ " rg " ]] && echo "  - ripgrep: apt install ripgrep / brew install ripgrep"
        [[ " ${missing_optional[*]} " =~ " ag " ]] && echo "  - ag: apt install silversearcher-ag / brew install the_silver_searcher"
        [[ " ${missing_optional[*]} " =~ " jq " ]] && echo "  - jq: apt install jq / brew install jq"
    fi
    
    return ${#missing_required[@]}
}

# Automated cleanup with safeguards
perform_cleanup() {
    if [[ "$AUTO_CLEANUP" != "true" ]]; then
        return 0
    fi
    
    log_info "Performing automated cleanup..."
    
    # Clean old log files
    local cleaned_files=0
    if [[ -d "$LOG_DIR" ]]; then
        # Find and remove log files older than retention period
        while IFS= read -r -d '' file; do
            if rm "$file" 2>/dev/null; then
                ((cleaned_files++))
            fi
        done < <(find "$LOG_DIR" -name "*.old*" -mtime +${LOG_RETENTION_DAYS} -print0 2>/dev/null)
        
        if [[ $cleaned_files -gt 0 ]]; then
            log_success "Cleaned up $cleaned_files old log files"
        fi
    fi
    
    # Clean temporary files
    local temp_files=0
    if [[ -d "/tmp" ]]; then
        while IFS= read -r -d '' file; do
            if [[ "$file" =~ xxmxli ]] && rm "$file" 2>/dev/null; then
                ((temp_files++))
            fi
        done < <(find /tmp -name "*xxmxli*" -mtime +1 -print0 2>/dev/null)
        
        if [[ $temp_files -gt 0 ]]; then
            log_success "Cleaned up $temp_files temporary files"
        fi
    fi
}

# Comprehensive health check
run_comprehensive_check() {
    local start_time=$(date +%s)
    local total_issues=0
    
    echo -e "${PURPLE}${BOLD}🏥 COMPREHENSIVE HEALTH CHECK${NC}"
    echo "================================================================"
    echo ""
    
    # System dependencies
    check_dependencies || ((total_issues += $?))
    echo ""
    
    # System resources
    check_system_resources || ((total_issues += $?))
    echo ""
    
    # Security infrastructure
    check_security_infrastructure || ((total_issues += $?))
    echo ""
    
    # Performance benchmark
    run_performance_benchmark
    echo ""
    
    # Cleanup
    perform_cleanup
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "================================================================"
    
    # Health score calculation
    local max_checks=15  # Approximate number of checks
    local health_score=$((100 - (total_issues * 100 / max_checks)))
    health_score=$((health_score < 0 ? 0 : health_score))
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "Health check completed in ${duration}s - System is healthy! ${HEART} (Score: ${health_score}%)"
    elif [[ $total_issues -lt 3 ]]; then
        log_warning "Health check completed in ${duration}s - Minor issues detected ($total_issues) (Score: ${health_score}%)"
    else
        log_error "Health check completed in ${duration}s - Multiple issues found ($total_issues) (Score: ${health_score}%)"
    fi
    
    return $total_issues
}

# Interactive menu system
show_interactive_menu() {
    show_banner
    
    echo -e "${WHITE}${GEAR} OPTIMIZED HEALTH CHECK OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${HEART} Comprehensive Health Check"
    echo -e "${GREEN}2)${NC} ${CHART} System Resource Monitoring"
    echo -e "${GREEN}3)${NC} ${SHIELD} Security Infrastructure Check"
    echo -e "${GREEN}4)${NC} ${ROCKET} Performance Benchmark"
    echo -e "${GREEN}5)${NC} ${GEAR} Dependency Check"
    echo -e "${GREEN}6)${NC} ${FILE} Configuration Status"
    echo -e "${GREEN}7)${NC} ${LIGHTNING} Debug Mode Toggle"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "$(echo -e "${CYAN}Choose option [0-7]:${NC} ")" choice
    
    case "$choice" in
        1) run_comprehensive_check; read -p "Press Enter to continue..." ;;
        2) check_system_resources; read -p "Press Enter to continue..." ;;
        3) check_security_infrastructure; read -p "Press Enter to continue..." ;;
        4) run_performance_benchmark; read -p "Press Enter to continue..." ;;
        5) check_dependencies; read -p "Press Enter to continue..." ;;
        6) show_configuration_status; read -p "Press Enter to continue..." ;;
        7) toggle_debug_mode; show_interactive_menu ;;
        0) log_info "Exiting health check monitor"; exit 0 ;;
        *) log_error "Invalid option: $choice"; sleep 1 ;;
    esac
    
    show_interactive_menu
}

# Configuration status display
show_configuration_status() {
    echo -e "${PURPLE}${GEAR} CONFIGURATION STATUS${NC}"
    echo "================================================================"
    echo ""
    
    echo "Current configuration:"
    echo "  Search tool: $SEARCH_TOOL"
    echo "  Check timeout: ${CHECK_TIMEOUT}s"
    echo "  Log retention: ${LOG_RETENTION_DAYS} days"
    echo "  Detailed logging: $ENABLE_DETAILED_LOGGING"
    echo "  Auto cleanup: $AUTO_CLEANUP"
    echo "  Performance monitoring: $PERFORMANCE_MONITORING"
    echo ""
    
    echo "Configuration files:"
    [[ -f "$CONFIG_JSON" ]] && echo -e "${GREEN}  ✓ JSON: $CONFIG_JSON${NC}" || echo -e "${YELLOW}  - JSON: $CONFIG_JSON (not found)${NC}"
    [[ -f "$CONFIG_FILE" ]] && echo -e "${GREEN}  ✓ CONF: $CONFIG_FILE${NC}" || echo -e "${YELLOW}  - CONF: $CONFIG_FILE (not found)${NC}"
    echo ""
    
    echo "Log files:"
    [[ -f "$HEALTH_LOG" ]] && echo "  Health log: $HEALTH_LOG ($(du -h "$HEALTH_LOG" 2>/dev/null | cut -f1))"
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
    
    log_debug "XXMXLI Health Check Monitor v2.0 initialized"
    log_debug "Using search tool: $SEARCH_TOOL"
    log_debug "Configuration: timeout=${CHECK_TIMEOUT}s, retention=${LOG_RETENTION_DAYS}d"
}

# Main execution
main() {
    # Handle command line arguments
    case "${1:-}" in
        "--auto"|"-a")
            # Automated mode
            init_system
            run_comprehensive_check
            ;;
        "--debug"|"-d")
            DEBUG=true
            init_system
            show_interactive_menu
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--auto|--debug|--help]"
            echo "  --auto     Run automated comprehensive check"
            echo "  --debug    Enable debug mode and run interactively"
            echo "  --help     Show this help"
            exit 0
            ;;
        *)
            # Interactive mode
            init_system
            show_interactive_menu
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "Health check monitor terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
