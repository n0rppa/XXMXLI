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
# XXMXLI OPTIMIZED INCIDENT REPORTER INSTALLATION TEST v2.0
# Enhanced Performance • Better Error Handling • Configuration Support
# ================================================================

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/installer_test.conf"
CONFIG_JSON="$CONFIG_DIR/installer_test.json"

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
        GEAR="⚙️"
        ROCKET="🚀"
        MAGNIFY="🔍"
        CHART="📊"
        INFO="ℹ️"
        SHIELD="🛡️"
        TARGET="🎯"
        HAMMER="🔨"
        WRENCH="🔧"
        LIGHTNING="⚡"
        FIRE="🔥"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        ARROW=">"
        GEAR="[G]"
        ROCKET="[R]"
        MAGNIFY="[?]"
        CHART="[C]"
        INFO="[i]"
        SHIELD="[S]"
        TARGET="[T]"
        HAMMER="[H]"
        WRENCH="[W]"
        LIGHTNING="[L]"
        FIRE="[F]"
    fi
}

# Configuration loading with validation
load_configuration() {
    # Default values
    TEST_TIMEOUT=30
    ENABLE_DEEP_SCAN=true
    ENABLE_SECURITY_CHECK=true
    ENABLE_INTEGRATION_TEST=true
    REQUIRED_FILES=()
    REQUIRED_FUNCTIONS=()
    AUTHORITY_INTEGRATIONS=()
    VERBOSE_OUTPUT=false
    
    # Try JSON configuration first
    if [[ -f "$CONFIG_JSON" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
            TEST_TIMEOUT=$(jq -r '.testing.timeout // 30' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_DEEP_SCAN=$(jq -r '.features.deep_scan // true' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_SECURITY_CHECK=$(jq -r '.features.security_check // true' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_INTEGRATION_TEST=$(jq -r '.features.integration_test // true' "$CONFIG_JSON" 2>/dev/null)
            VERBOSE_OUTPUT=$(jq -r '.output.verbose // false' "$CONFIG_JSON" 2>/dev/null)
            
            # Load required files array
            local files_json
            files_json=$(jq -r '.requirements.files[]? // empty' "$CONFIG_JSON" 2>/dev/null)
            if [[ -n "$files_json" ]]; then
                mapfile -t REQUIRED_FILES <<< "$files_json"
            fi
            
            # Load required functions array
            local functions_json
            functions_json=$(jq -r '.requirements.functions[]? // empty' "$CONFIG_JSON" 2>/dev/null)
            if [[ -n "$functions_json" ]]; then
                mapfile -t REQUIRED_FUNCTIONS <<< "$functions_json"
            fi
            
            log_debug "Configuration loaded from JSON"
        fi
    # Fallback to .conf file
    elif [[ -f "$CONFIG_FILE" ]]; then
        if source "$CONFIG_FILE" 2>/dev/null; then
            log_debug "Configuration loaded from .conf file"
        fi
    fi
    
    # Set default arrays if empty
    if [[ ${#REQUIRED_FILES[@]} -eq 0 ]]; then
        REQUIRED_FILES=(
            "install_incident_reporter.sh"
            "install_incident_reporter.bat"
            "automated_incident_reporter.sh"
            "automated_incident_reporter.ps1"
            "automated_incident_reporter.py"
        )
    fi
    
    if [[ ${#REQUIRED_FUNCTIONS[@]} -eq 0 ]]; then
        REQUIRED_FUNCTIONS=(
            "check_root"
            "install_dependencies"
            "setup_directories"
            "create_incident_report"
            "submit_to_authorities"
        )
    fi
    
    if [[ ${#AUTHORITY_INTEGRATIONS[@]} -eq 0 ]]; then
        AUTHORITY_INTEGRATIONS=(
            "FBI.*IC3"
            "CISA"
            "Europol"
            "CERT"
            "national.*cyber"
        )
    fi
}

# Enhanced logging setup
setup_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    TEST_LOG="$LOG_DIR/installer_test.log"
    ERROR_LOG="$LOG_DIR/installer_test_errors.log"
    
    # Log rotation
    for log_file in "$TEST_LOG" "$ERROR_LOG"; do
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
    [[ "${DEBUG:-false}" == "true" || "$VERBOSE_OUTPUT" == "true" ]] && {
        echo -e "${CYAN}[DEBUG $(date +'%H:%M:%S')]${NC} $1" >&2
        echo "[DEBUG $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$TEST_LOG" 2>/dev/null
    }
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    echo "[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$TEST_LOG" 2>/dev/null
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    echo "[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$TEST_LOG" 2>/dev/null
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1" >&2
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$TEST_LOG" 2>/dev/null
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1" >&2
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$ERROR_LOG" 2>/dev/null
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
    ║        ████████╗███████╗███████╗████████╗                   ║
    ║        ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝                   ║
    ║           ██║   █████╗  ███████╗   ██║                      ║
    ║           ██║   ██╔══╝  ╚════██║   ██║                      ║
    ║           ██║   ███████╗███████║   ██║                      ║
    ║           ╚═╝   ╚══════╝╚══════╝   ╚═╝                      ║
    ║                                                              ║
    ║       OPTIMIZED INCIDENT REPORTER INSTALLER TEST v2.0       ║
    ║        Enhanced Performance • Better Error Handling         ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}    ${MAGNIFY} Installation Verification • ${GEAR} Component Testing${NC}"
    echo -e "${GREEN}    ${LIGHTNING} Using: $SEARCH_TOOL • Timeout: ${TEST_TIMEOUT}s${NC}"
    echo ""
}

# Enhanced file existence check
check_installer_files() {
    local test_name="Installer Files Check"
    local passed=0
    local total=0
    
    log_info "Test 1: $test_name"
    echo "================================================================"
    
    for file in "${REQUIRED_FILES[@]}"; do
        ((total++))
        
        if [[ -f "$file" ]]; then
            # Check file size to ensure it's not empty
            local file_size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
            
            if [[ ${file_size:-0} -gt 0 ]]; then
                log_success "$(printf "%-35s" "$file") (${file_size} bytes)"
                ((passed++))
            else
                log_warning "$(printf "%-35s" "$file") (empty file)"
            fi
        else
            log_error "$(printf "%-35s" "$file") (missing)"
        fi
    done
    
    echo ""
    local percentage=$((passed * 100 / total))
    
    if [[ $percentage -ge 80 ]]; then
        log_success "File check: $passed/$total files found ($percentage%)"
    elif [[ $percentage -ge 60 ]]; then
        log_warning "File check: $passed/$total files found ($percentage%)"
    else
        log_error "File check: $passed/$total files found ($percentage%)"
    fi
    
    echo ""
    return $((total - passed))
}

# Enhanced permissions check
check_file_permissions() {
    local test_name="File Permissions Check"
    local passed=0
    local total=0
    
    log_info "Test 2: $test_name"
    echo "================================================================"
    
    # Check executable files
    local executable_files=("install_incident_reporter.sh" "automated_incident_reporter.sh")
    
    for file in "${executable_files[@]}"; do
        if [[ -f "$file" ]]; then
            ((total++))
            
            if [[ -x "$file" ]]; then
                local perms=$(stat -f "%A" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null || echo "unknown")
                log_success "$(printf "%-35s" "$file") (executable, perms: $perms)"
                ((passed++))
            else
                log_warning "$(printf "%-35s" "$file") (not executable - needs chmod +x)"
            fi
        fi
    done
    
    # Check readable files
    local readable_files=("automated_incident_reporter.py" "automated_incident_reporter.ps1" "install_incident_reporter.bat")
    
    for file in "${readable_files[@]}"; do
        if [[ -f "$file" ]]; then
            ((total++))
            
            if [[ -r "$file" ]]; then
                local perms=$(stat -f "%A" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null || echo "unknown")
                log_success "$(printf "%-35s" "$file") (readable, perms: $perms)"
                ((passed++))
            else
                log_error "$(printf "%-35s" "$file") (not readable)"
            fi
        fi
    done
    
    echo ""
    local percentage=$((passed * 100 / total))
    
    if [[ $percentage -eq 100 ]]; then
        log_success "Permissions check: $passed/$total files have correct permissions ($percentage%)"
    else
        log_warning "Permissions check: $passed/$total files have correct permissions ($percentage%)"
    fi
    
    echo ""
    return $((total - passed))
}

# Enhanced function presence check
check_script_functions() {
    local test_name="Script Function Check"
    local passed=0
    local total=0
    local script_file="automated_incident_reporter.sh"
    
    log_info "Test 3: $test_name"
    echo "================================================================"
    
    if [[ ! -f "$script_file" ]]; then
        log_error "Primary script not found: $script_file"
        echo ""
        return 1
    fi
    
    log_debug "Analyzing script: $script_file"
    
    for func in "${REQUIRED_FUNCTIONS[@]}"; do
        ((total++))
        
        # Use optimized search tool
        local found=false
        case "$SEARCH_TOOL" in
            "rg")
                if run_with_timeout "$TEST_TIMEOUT" rg -q "function.*$func|$func\(\)" "$script_file"; then
                    found=true
                fi
                ;;
            "ag")
                if run_with_timeout "$TEST_TIMEOUT" ag -l "function.*$func|$func\(\)" "$script_file" >/dev/null 2>&1; then
                    found=true
                fi
                ;;
            "awk")
                if run_with_timeout "$TEST_TIMEOUT" awk "/function.*$func|$func\(\)/ {found=1; exit} END {exit !found}" "$script_file"; then
                    found=true
                fi
                ;;
            *)
                if run_with_timeout "$TEST_TIMEOUT" grep -q "function.*$func\|$func()" "$script_file"; then
                    found=true
                fi
                ;;
        esac
        
        if [[ "$found" == "true" ]]; then
            log_success "$(printf "%-35s" "$func") function found"
            ((passed++))
        else
            log_error "$(printf "%-35s" "$func") function missing"
        fi
    done
    
    echo ""
    local percentage=$((passed * 100 / total))
    
    if [[ $percentage -ge 80 ]]; then
        log_success "Function check: $passed/$total functions found ($percentage%)"
    elif [[ $percentage -ge 60 ]]; then
        log_warning "Function check: $passed/$total functions found ($percentage%)"
    else
        log_error "Function check: $passed/$total functions found ($percentage%)"
    fi
    
    echo ""
    return $((total - passed))
}

# Enhanced authority integration check
check_authority_integration() {
    local test_name="Authority Reporting Integration"
    local passed=0
    local total=0
    local script_file="automated_incident_reporter.sh"
    
    log_info "Test 4: $test_name"
    echo "================================================================"
    
    if [[ ! -f "$script_file" ]]; then
        log_error "Primary script not found: $script_file"
        echo ""
        return 1
    fi
    
    log_debug "Checking authority integrations in: $script_file"
    
    for authority in "${AUTHORITY_INTEGRATIONS[@]}"; do
        ((total++))
        
        # Use optimized search tool for case-insensitive search
        local found=false
        case "$SEARCH_TOOL" in
            "rg")
                if run_with_timeout "$TEST_TIMEOUT" rg -qi "$authority" "$script_file"; then
                    found=true
                fi
                ;;
            "ag")
                if run_with_timeout "$TEST_TIMEOUT" ag -i "$authority" "$script_file" >/dev/null 2>&1; then
                    found=true
                fi
                ;;
            "awk")
                if run_with_timeout "$TEST_TIMEOUT" awk "tolower(\$0) ~ tolower(\"$authority\") {found=1; exit} END {exit !found}" "$script_file"; then
                    found=true
                fi
                ;;
            *)
                if run_with_timeout "$TEST_TIMEOUT" grep -qi "$authority" "$script_file"; then
                    found=true
                fi
                ;;
        esac
        
        if [[ "$found" == "true" ]]; then
            log_success "$(printf "%-35s" "$authority") integration found"
            ((passed++))
        else
            log_error "$(printf "%-35s" "$authority") integration missing"
        fi
    done
    
    echo ""
    local percentage=$((passed * 100 / total))
    
    if [[ $percentage -ge 80 ]]; then
        log_success "Authority integration: $passed/$total integrations found ($percentage%)"
    elif [[ $percentage -ge 60 ]]; then
        log_warning "Authority integration: $passed/$total integrations found ($percentage%)"
    else
        log_error "Authority integration: $passed/$total integrations found ($percentage%)"
    fi
    
    echo ""
    return $((total - passed))
}

# Deep script analysis
deep_script_analysis() {
    [[ "$ENABLE_DEEP_SCAN" != "true" ]] && return 0
    
    local test_name="Deep Script Analysis"
    local passed=0
    local total=0
    
    log_info "Test 5: $test_name"
    echo "================================================================"
    
    local script_files=("automated_incident_reporter.sh" "automated_incident_reporter.py")
    
    for script in "${script_files[@]}"; do
        if [[ -f "$script" ]]; then
            log_debug "Analyzing script: $script"
            
            # Check for error handling
            ((total++))
            case "$SEARCH_TOOL" in
                "rg")
                    if run_with_timeout "$TEST_TIMEOUT" rg -q "set -e|trap|try.*except|error.*handling" "$script"; then
                        log_success "$(printf "%-35s" "$script") has error handling"
                        ((passed++))
                    else
                        log_warning "$(printf "%-35s" "$script") lacks error handling"
                    fi
                    ;;
                *)
                    if run_with_timeout "$TEST_TIMEOUT" grep -q "set -e\|trap\|try.*except\|error.*handling" "$script"; then
                        log_success "$(printf "%-35s" "$script") has error handling"
                        ((passed++))
                    else
                        log_warning "$(printf "%-35s" "$script") lacks error handling"
                    fi
                    ;;
            esac
            
            # Check for logging
            ((total++))
            case "$SEARCH_TOOL" in
                "rg")
                    if run_with_timeout "$TEST_TIMEOUT" rg -q "log|echo.*\>|tee|logger" "$script"; then
                        log_success "$(printf "%-35s" "$script") has logging functionality"
                        ((passed++))
                    else
                        log_warning "$(printf "%-35s" "$script") lacks logging"
                    fi
                    ;;
                *)
                    if run_with_timeout "$TEST_TIMEOUT" grep -q "log\|echo.*>\|tee\|logger" "$script"; then
                        log_success "$(printf "%-35s" "$script") has logging functionality"
                        ((passed++))
                    else
                        log_warning "$(printf "%-35s" "$script") lacks logging"
                    fi
                    ;;
            esac
            
            # Check for input validation
            ((total++))
            case "$SEARCH_TOOL" in
                "rg")
                    if run_with_timeout "$TEST_TIMEOUT" rg -q "validate|check.*input|\[\[.*-n|\[\[.*-z" "$script"; then
                        log_success "$(printf "%-35s" "$script") has input validation"
                        ((passed++))
                    else
                        log_warning "$(printf "%-35s" "$script") lacks input validation"
                    fi
                    ;;
                *)
                    if run_with_timeout "$TEST_TIMEOUT" grep -q "validate\|check.*input\|\[\[.*-n\|\[\[.*-z" "$script"; then
                        log_success "$(printf "%-35s" "$script") has input validation"
                        ((passed++))
                    else
                        log_warning "$(printf "%-35s" "$script") lacks input validation"
                    fi
                    ;;
            esac
        fi
    done
    
    if [[ $total -gt 0 ]]; then
        echo ""
        local percentage=$((passed * 100 / total))
        
        if [[ $percentage -ge 80 ]]; then
            log_success "Deep analysis: $passed/$total quality checks passed ($percentage%)"
        elif [[ $percentage -ge 60 ]]; then
            log_warning "Deep analysis: $passed/$total quality checks passed ($percentage%)"
        else
            log_error "Deep analysis: $passed/$total quality checks passed ($percentage%)"
        fi
        
        echo ""
    fi
    
    return $((total - passed))
}

# Security vulnerability check
security_vulnerability_check() {
    [[ "$ENABLE_SECURITY_CHECK" != "true" ]] && return 0
    
    local test_name="Security Vulnerability Check"
    local issues=0
    
    log_info "Test 6: $test_name"
    echo "================================================================"
    
    local script_files=("*.sh" "*.py" "*.ps1")
    
    for pattern in "${script_files[@]}"; do
        for script in $pattern; do
            [[ -f "$script" ]] || continue
            
            log_debug "Security scanning: $script"
            
            # Check for hardcoded passwords/keys
            case "$SEARCH_TOOL" in
                "rg")
                    if run_with_timeout "$TEST_TIMEOUT" rg -qi "password.*=|api.*key.*=|secret.*=" "$script"; then
                        log_warning "$(printf "%-35s" "$script") may contain hardcoded credentials"
                        ((issues++))
                    fi
                    
                    # Check for unsafe shell practices
                    if run_with_timeout "$TEST_TIMEOUT" rg -q "eval|exec.*\$|system\(" "$script"; then
                        log_warning "$(printf "%-35s" "$script") uses potentially unsafe shell execution"
                        ((issues++))
                    fi
                    
                    # Check for unquoted variables
                    if run_with_timeout "$TEST_TIMEOUT" rg -q "\$[A-Za-z_][A-Za-z0-9_]*[^\"']" "$script"; then
                        log_warning "$(printf "%-35s" "$script") may have unquoted variables"
                        ((issues++))
                    fi
                    ;;
                *)
                    if run_with_timeout "$TEST_TIMEOUT" grep -qi "password.*=\|api.*key.*=\|secret.*=" "$script"; then
                        log_warning "$(printf "%-35s" "$script") may contain hardcoded credentials"
                        ((issues++))
                    fi
                    
                    if run_with_timeout "$TEST_TIMEOUT" grep -q "eval\|exec.*\$\|system(" "$script"; then
                        log_warning "$(printf "%-35s" "$script") uses potentially unsafe shell execution"
                        ((issues++))
                    fi
                    ;;
            esac
        done
    done
    
    echo ""
    if [[ $issues -eq 0 ]]; then
        log_success "Security check: No obvious vulnerabilities detected"
    else
        log_warning "Security check: $issues potential security issues found"
    fi
    
    echo ""
    return $issues
}

# Performance benchmark for search tools
run_performance_benchmark() {
    log_info "Performance Benchmark: Testing search tool efficiency"
    echo "================================================================"
    
    local test_file="automated_incident_reporter.sh"
    [[ ! -f "$test_file" ]] && test_file="/etc/passwd"  # Fallback
    
    local search_tools=("grep" "awk")
    
    # Add available tools
    command -v rg >/dev/null 2>&1 && search_tools+=("rg")
    command -v ag >/dev/null 2>&1 && search_tools+=("ag")
    
    for tool in "${search_tools[@]}"; do
        local start_time=$(date +%s.%N)
        
        case "$tool" in
            "rg")
                run_with_timeout 5 rg -q "function" "$test_file" >/dev/null 2>&1
                ;;
            "ag")
                run_with_timeout 5 ag -l "function" "$test_file" >/dev/null 2>&1
                ;;
            "awk")
                run_with_timeout 5 awk '/function/ {found=1; exit} END {exit !found}' "$test_file" >/dev/null 2>&1
                ;;
            *)
                run_with_timeout 5 grep -q "function" "$test_file" >/dev/null 2>&1
                ;;
        esac
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        printf "${GREEN}${CHECK}${NC} %-10s: %.3fs\n" "$tool" "${duration:-0}"
    done
    
    echo ""
    log_success "Benchmark completed - currently using: $SEARCH_TOOL"
    echo ""
}

# Generate comprehensive test report
generate_test_report() {
    local report_file="installer_test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    log_info "Generating comprehensive test report..."
    
    cat > "$report_file" << EOF
========================================
XXMXLI INCIDENT REPORTER INSTALLER TEST REPORT
========================================
Generated: $(date)
Test Configuration:
  Search tool: $SEARCH_TOOL
  Timeout: ${TEST_TIMEOUT}s
  Deep scan: $ENABLE_DEEP_SCAN
  Security check: $ENABLE_SECURITY_CHECK
  Integration test: $ENABLE_INTEGRATION_TEST

REQUIRED FILES:
EOF

    for file in "${REQUIRED_FILES[@]}"; do
        local status="MISSING"
        local size="0"
        
        if [[ -f "$file" ]]; then
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
            [[ ${size:-0} -gt 0 ]] && status="PRESENT" || status="EMPTY"
        fi
        
        printf "  %-35s: %-8s (%s bytes)\n" "$file" "$status" "$size" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

REQUIRED FUNCTIONS:
EOF

    for func in "${REQUIRED_FUNCTIONS[@]}"; do
        local status="MISSING"
        
        if [[ -f "automated_incident_reporter.sh" ]]; then
            case "$SEARCH_TOOL" in
                "rg")
                    run_with_timeout "$TEST_TIMEOUT" rg -q "function.*$func|$func\(\)" "automated_incident_reporter.sh" && status="PRESENT"
                    ;;
                *)
                    run_with_timeout "$TEST_TIMEOUT" grep -q "function.*$func\|$func()" "automated_incident_reporter.sh" && status="PRESENT"
                    ;;
            esac
        fi
        
        printf "  %-35s: %s\n" "$func" "$status" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

AUTHORITY INTEGRATIONS:
EOF

    for authority in "${AUTHORITY_INTEGRATIONS[@]}"; do
        local status="MISSING"
        
        if [[ -f "automated_incident_reporter.sh" ]]; then
            case "$SEARCH_TOOL" in
                "rg")
                    run_with_timeout "$TEST_TIMEOUT" rg -qi "$authority" "automated_incident_reporter.sh" && status="PRESENT"
                    ;;
                *)
                    run_with_timeout "$TEST_TIMEOUT" grep -qi "$authority" "automated_incident_reporter.sh" && status="PRESENT"
                    ;;
            esac
        fi
        
        printf "  %-35s: %s\n" "$authority" "$status" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

RECOMMENDATIONS:
EOF

    # Add recommendations based on test results
    local recommendations=()
    
    [[ ! -f "automated_incident_reporter.sh" ]] && recommendations+=("Create main bash script: automated_incident_reporter.sh")
    [[ ! -x "install_incident_reporter.sh" ]] && recommendations+=("Make installer executable: chmod +x install_incident_reporter.sh")
    
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        echo "  All critical components are present and properly configured." >> "$report_file"
    else
        for rec in "${recommendations[@]}"; do
            echo "  - $rec" >> "$report_file"
        done
    fi
    
    cat >> "$report_file" << EOF

NEXT STEPS:
1. Review any missing components listed above
2. Test installation in a controlled environment
3. Verify authority reporting endpoints are accessible
4. Conduct end-to-end incident reporting test
5. Deploy to production environment

Report generated by XXMXLI Optimized Installer Test v2.0
EOF

    log_success "Test report generated: $report_file"
}

# Interactive test runner
interactive_test_runner() {
    echo -e "${PURPLE}${GEAR} INTERACTIVE TEST RUNNER${NC}"
    echo "================================================================"
    echo ""
    
    echo "Available test suites:"
    echo "1) Quick Test (essential checks only)"
    echo "2) Standard Test (all standard checks)"
    echo "3) Comprehensive Test (includes deep scan and security)"
    echo "4) Custom Test (choose specific tests)"
    echo ""
    
    read -p "Select test suite [1-4]: " suite_choice
    
    case "$suite_choice" in
        1)
            ENABLE_DEEP_SCAN=false
            ENABLE_SECURITY_CHECK=false
            ;;
        2)
            ENABLE_DEEP_SCAN=false
            ENABLE_SECURITY_CHECK=true
            ;;
        3)
            ENABLE_DEEP_SCAN=true
            ENABLE_SECURITY_CHECK=true
            ;;
        4)
            read -p "Enable deep scan? (y/n): " deep_scan
            [[ "$deep_scan" =~ ^[Yy] ]] && ENABLE_DEEP_SCAN=true || ENABLE_DEEP_SCAN=false
            
            read -p "Enable security check? (y/n): " security_check
            [[ "$security_check" =~ ^[Yy] ]] && ENABLE_SECURITY_CHECK=true || ENABLE_SECURITY_CHECK=false
            ;;
    esac
    
    echo ""
    log_success "Test configuration updated"
}

# Main test execution
run_installation_test() {
    show_banner
    
    log_info "Starting XXMXLI Incident Reporter Installation Test"
    echo ""
    
    local total_errors=0
    
    # Test 1: File existence
    check_installer_files
    total_errors=$((total_errors + $?))
    
    # Test 2: File permissions
    check_file_permissions
    total_errors=$((total_errors + $?))
    
    # Test 3: Script functions
    check_script_functions
    total_errors=$((total_errors + $?))
    
    # Test 4: Authority integration
    check_authority_integration
    total_errors=$((total_errors + $?))
    
    # Test 5: Deep analysis (optional)
    deep_script_analysis
    total_errors=$((total_errors + $?))
    
    # Test 6: Security check (optional)
    security_vulnerability_check
    total_errors=$((total_errors + $?))
    
    # Performance benchmark
    run_performance_benchmark
    
    # Generate report
    generate_test_report
    
    # Final summary
    echo ""
    echo -e "${WHITE}${TARGET} INSTALLATION TEST COMPLETE${NC}"
    echo "================================================================"
    
    if [[ $total_errors -eq 0 ]]; then
        echo -e "${GREEN}${CHECK} ${BOLD}ALL TESTS PASSED${NC}"
        echo -e "${GREEN}Installation package is ready for deployment!${NC}"
    elif [[ $total_errors -le 3 ]]; then
        echo -e "${YELLOW}${WARNING} ${BOLD}MINOR ISSUES DETECTED${NC}"
        echo -e "${YELLOW}$total_errors issues found - review recommendations${NC}"
    else
        echo -e "${RED}${CROSS} ${BOLD}SIGNIFICANT ISSUES DETECTED${NC}"
        echo -e "${RED}$total_errors issues found - requires attention${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}${INFO} Test report available in: installer_test_report_*.txt${NC}"
    echo -e "${CYAN}${INFO} Detailed logs available in: $LOG_DIR${NC}"
    
    return $total_errors
}

# Initialize system
init_system() {
    setup_colors
    setup_symbols
    setup_logging
    load_configuration
    
    log_debug "XXMXLI Installer Test v2.0 initialized"
    log_debug "Using search tool: $SEARCH_TOOL"
    log_debug "Configuration: timeout=${TEST_TIMEOUT}s, deep_scan=$ENABLE_DEEP_SCAN, security=$ENABLE_SECURITY_CHECK"
}

# Main execution
main() {
    case "${1:-}" in
        "--interactive"|"-i")
            init_system
            interactive_test_runner
            run_installation_test
            ;;
        "--quick"|"-q")
            init_system
            ENABLE_DEEP_SCAN=false
            ENABLE_SECURITY_CHECK=false
            run_installation_test
            ;;
        "--comprehensive"|"-c")
            init_system
            ENABLE_DEEP_SCAN=true
            ENABLE_SECURITY_CHECK=true
            run_installation_test
            ;;
        "--benchmark"|"-b")
            init_system
            run_performance_benchmark
            ;;
        "--report"|"-r")
            init_system
            generate_test_report
            ;;
        "--debug"|"-d")
            DEBUG=true
            init_system
            run_installation_test
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--interactive|--quick|--comprehensive|--benchmark|--report|--debug|--help]"
            echo "  --interactive      Run with interactive test selection"
            echo "  --quick           Run quick tests only (essential checks)"
            echo "  --comprehensive   Run all tests including deep scan and security"
            echo "  --benchmark       Run performance benchmark only"
            echo "  --report          Generate test report only"
            echo "  --debug           Enable debug mode"
            echo "  --help            Show this help"
            exit 0
            ;;
        *)
            init_system
            run_installation_test
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "Installation test terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
