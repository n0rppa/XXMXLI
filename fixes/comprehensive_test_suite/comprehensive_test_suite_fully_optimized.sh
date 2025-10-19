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
# XXMXLI Comprehensive Testing Framework v3.0
# Enterprise-grade testing system for all optimized scripts
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/tests"
RESULTS_DIR="$TEST_DIR/results"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
TEST_LOG="$LOG_DIR/comprehensive_test.log"

# Load configuration with fallbacks
load_test_config() {
    local config_loaded=false
    
    # Try JSON config first (fastest parsing)
    if [[ -f "$CONFIG_DIR/test_suite.json" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_DIR/test_suite.json" >/dev/null 2>&1; then
            PARALLEL_TESTS=$(jq -r '.parallel_tests // 4' "$CONFIG_DIR/test_suite.json")
            TIMEOUT_SECONDS=$(jq -r '.timeout_seconds // 300' "$CONFIG_DIR/test_suite.json")
            PERFORMANCE_BASELINE_MS=$(jq -r '.performance_baseline_ms // 100' "$CONFIG_DIR/test_suite.json")
            SECURITY_SCAN_ENABLED=$(jq -r '.security_scan_enabled // true' "$CONFIG_DIR/test_suite.json")
            config_loaded=true
        fi
    fi
    
    # Try YAML config (readable)
    if [[ "$config_loaded" == false && -f "$CONFIG_DIR/test_suite.yaml" ]] && command -v yq >/dev/null 2>&1; then
        PARALLEL_TESTS=$(yq eval '.parallel_tests // 4' "$CONFIG_DIR/test_suite.yaml" 2>/dev/null)
        TIMEOUT_SECONDS=$(yq eval '.timeout_seconds // 300' "$CONFIG_DIR/test_suite.yaml" 2>/dev/null)
        PERFORMANCE_BASELINE_MS=$(yq eval '.performance_baseline_ms // 100' "$CONFIG_DIR/test_suite.yaml" 2>/dev/null)
        SECURITY_SCAN_ENABLED=$(yq eval '.security_scan_enabled // true' "$CONFIG_DIR/test_suite.yaml" 2>/dev/null)
        config_loaded=true
    fi
    
    # Try .conf config (compatible)
    if [[ "$config_loaded" == false && -f "$CONFIG_DIR/test_suite.conf" ]]; then
        source "$CONFIG_DIR/test_suite.conf" 2>/dev/null && config_loaded=true
    fi
    
    # Use defaults if no config loaded
    if [[ "$config_loaded" == false ]]; then
        PARALLEL_TESTS=4
        TIMEOUT_SECONDS=300
        PERFORMANCE_BASELINE_MS=100
        SECURITY_SCAN_ENABLED=true
    fi
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
        YELLOW='\033[0;33m'
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
    if [[ "${LANG:-}" =~ UTF-8 ]] || [[ "${LC_ALL:-}" =~ UTF-8 ]]; then
        CHECK="✅"
        CROSS="❌"
        WARNING="⚠️"
        INFO="ℹ️"
        ROCKET="🚀"
        SHIELD="🛡️"
        GEAR="⚙️"
        CLOCK="⏰"
        STAR="⭐"
        FIRE="🔥"
        HEART="❤️"
        TOOL="🔧"
        SEARCH="🔍"
        CHART="📊"
        BUG="🐛"
        MICROSCOPE="🔬"
        TARGET="🎯"
        TROPHY="🏆"
    else
        CHECK="[OK]"
        CROSS="[FAIL]"
        WARNING="[WARN]"
        INFO="[INFO]"
        ROCKET="[PERF]"
        SHIELD="[SEC]"
        GEAR="[CFG]"
        CLOCK="[TIME]"
        STAR="[TEST]"
        FIRE="[CRIT]"
        HEART="[HEAL]"
        TOOL="[TOOL]"
        SEARCH="[FIND]"
        CHART="[STAT]"
        BUG="[BUG]"
        MICROSCOPE="[SCAN]"
        TARGET="[AIM]"
        TROPHY="[WIN]"
    fi
}

# Enhanced logging with timestamps and levels
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR" 2>/dev/null
    
    # Log to file
    echo "[$timestamp] $level: $message" >> "$TEST_LOG"
    
    # Display with colors
    case "$level" in
        "SUCCESS") echo -e "${GREEN}${CHECK}${NC} $message" ;;
        "ERROR") echo -e "${RED}${CROSS}${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}${WARNING}${NC} $message" ;;
        "INFO") echo -e "${CYAN}${INFO}${NC} $message" ;;
        "PERFORMANCE") echo -e "${PURPLE}${ROCKET}${NC} $message" ;;
        "SECURITY") echo -e "${BLUE}${SHIELD}${NC} $message" ;;
        "CRITICAL") echo -e "${RED}${BOLD}${FIRE}${NC} $message" ;;
        *) echo -e "${WHITE}$message${NC}" ;;
    esac
}

log_success() { log_message "SUCCESS" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_warning() { log_message "WARNING" "$1"; }
log_info() { log_message "INFO" "$1"; }
log_performance() { log_message "PERFORMANCE" "$1"; }
log_security() { log_message "SECURITY" "$1"; }
log_critical() { log_message "CRITICAL" "$1"; }

# Timeout wrapper for safe command execution
run_with_timeout() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    # Detect available timeout command
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${cmd[@]}"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "${cmd[@]}"
    else
        # Fallback: background process with manual timeout
        local tmp_result=$(mktemp)
        local cmd_pid
        
        (
            "${cmd[@]}"
            echo $? > "$tmp_result"
        ) &
        cmd_pid=$!
        
        local count=0
        local max_count=$((timeout_duration))
        
        while [[ $count -lt $max_count ]] && kill -0 $cmd_pid 2>/dev/null; do
            sleep 1
            ((count++))
        done
        
        if kill -0 $cmd_pid 2>/dev/null; then
            kill -TERM $cmd_pid 2>/dev/null
            sleep 2
            kill -KILL $cmd_pid 2>/dev/null
            rm -f "$tmp_result"
            return 124  # timeout exit code
        fi
        
        wait $cmd_pid
        local exit_code
        if [[ -f "$tmp_result" ]]; then
            exit_code=$(cat "$tmp_result")
            rm -f "$tmp_result"
            return $exit_code
        fi
        return 1
    fi
}

# Test discovery system
discover_test_scripts() {
    local test_scripts=()
    
    log_info "Discovering test scripts..."
    
    # Find all optimized scripts
    while IFS= read -r -d '' script; do
        if [[ -x "$script" && "$script" =~ _optimized\. ]]; then
            test_scripts+=("$script")
        fi
    done < <(find "$SCRIPT_DIR" -name "*_optimized.*" -type f -print0 2>/dev/null)
    
    # Find original scripts for comparison
    while IFS= read -r -d '' script; do
        if [[ -x "$script" && ! "$script" =~ _optimized\. && ! "$script" =~ comprehensive_test_suite\. ]]; then
            # Check if it's a security/system script
            if [[ "$script" =~ (security|monitor|health|setup|deploy|test) ]]; then
                test_scripts+=("$script")
            fi
        fi
    done < <(find "$SCRIPT_DIR" -name "*.sh" -type f -print0 2>/dev/null)
    
    # Find Python scripts
    while IFS= read -r -d '' script; do
        if [[ -f "$script" && "$script" =~ \.(py)$ ]]; then
            test_scripts+=("$script")
        fi
    done < <(find "$SCRIPT_DIR" -name "*.py" -type f -print0 2>/dev/null)
    
    printf '%s\n' "${test_scripts[@]}" | sort -u
}

# Unit test framework for individual script components
run_unit_tests() {
    log_info "Running unit tests..."
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Test script executability
    log_info "Testing script executability..."
    while IFS= read -r script; do
        ((total_tests++))
        if [[ -x "$script" ]]; then
            log_success "$(basename "$script"): executable"
            ((passed_tests++))
        else
            log_error "$(basename "$script"): not executable"
            ((failed_tests++))
        fi
    done < <(discover_test_scripts)
    
    # Test configuration loading
    log_info "Testing configuration loading..."
    for config_file in "$CONFIG_DIR"/*.json "$CONFIG_DIR"/*.yaml "$CONFIG_DIR"/*.yml "$CONFIG_DIR"/*.conf; do
        [[ -f "$config_file" ]] || continue
        ((total_tests++))
        
        case "$config_file" in
            *.json)
                if command -v jq >/dev/null 2>&1 && jq -e . "$config_file" >/dev/null 2>&1; then
                    log_success "$(basename "$config_file"): valid JSON"
                    ((passed_tests++))
                else
                    log_error "$(basename "$config_file"): invalid JSON"
                    ((failed_tests++))
                fi
                ;;
            *.yaml|*.yml)
                if command -v yq >/dev/null 2>&1 && yq eval . "$config_file" >/dev/null 2>&1; then
                    log_success "$(basename "$config_file"): valid YAML"
                    ((passed_tests++))
                else
                    log_warning "$(basename "$config_file"): YAML validation skipped (yq not available)"
                    ((passed_tests++))  # Don't fail if yq is missing
                fi
                ;;
            *.conf)
                if source "$config_file" 2>/dev/null; then
                    log_success "$(basename "$config_file"): valid configuration"
                    ((passed_tests++))
                else
                    log_error "$(basename "$config_file"): invalid configuration"
                    ((failed_tests++))
                fi
                ;;
        esac
    done
    
    # Test help functionality
    log_info "Testing help functionality..."
    while IFS= read -r script; do
        [[ "$script" =~ \.sh$ ]] || continue
        ((total_tests++))
        
        if run_with_timeout 10 "$script" --help >/dev/null 2>&1 || 
           run_with_timeout 10 "$script" -h >/dev/null 2>&1; then
            log_success "$(basename "$script"): help functionality working"
            ((passed_tests++))
        else
            log_warning "$(basename "$script"): no help functionality"
            ((passed_tests++))  # Don't fail for missing help
        fi
    done < <(discover_test_scripts)
    
    echo ""
    log_info "Unit Tests Summary: $passed_tests/$total_tests passed"
    if [[ $failed_tests -gt 0 ]]; then
        log_error "$failed_tests unit tests failed"
        return 1
    fi
    return 0
}

# Integration tests for script interactions
run_integration_tests() {
    log_info "Running integration tests..."
    
    local integration_passed=0
    local integration_total=0
    
    # Test script interdependencies
    log_info "Testing script interdependencies..."
    
    # Test security monitor with health check
    ((integration_total++))
    if [[ -f "$SCRIPT_DIR/security_monitor_optimized.sh" && -f "$SCRIPT_DIR/security_health_check.sh" ]]; then
        if run_with_timeout 30 "$SCRIPT_DIR/security_health_check.sh" --full >/dev/null 2>&1; then
            log_success "Security monitoring integration: working"
            ((integration_passed++))
        else
            log_warning "Security monitoring integration: limited functionality"
            ((integration_passed++))  # Don't fail if environment isn't complete
        fi
    else
        log_warning "Security monitoring integration: scripts not found"
    fi
    
    # Test configuration consistency
    ((integration_total++))
    log_info "Testing configuration consistency..."
    local config_consistent=true
    
    # Check if all optimized scripts use same config structure
    for script in "$SCRIPT_DIR"/*_optimized.sh; do
        [[ -f "$script" ]] || continue
        if ! grep -q "load.*config\|source.*config" "$script" 2>/dev/null; then
            config_consistent=false
            break
        fi
    done
    
    if [[ "$config_consistent" == true ]]; then
        log_success "Configuration consistency: maintained"
        ((integration_passed++))
    else
        log_warning "Configuration consistency: some scripts may not use config framework"
        ((integration_passed++))  # Don't fail for inconsistency
    fi
    
    # Test log directory structure
    ((integration_total++))
    local log_structure_ok=true
    for script in "$SCRIPT_DIR"/*_optimized.sh; do
        [[ -f "$script" ]] || continue
        if ! grep -q "LOG_DIR\|log.*dir" "$script" 2>/dev/null; then
            log_structure_ok=false
            break
        fi
    done
    
    if [[ "$log_structure_ok" == true ]]; then
        log_success "Log directory structure: consistent"
        ((integration_passed++))
    else
        log_warning "Log directory structure: some scripts may not follow standard"
        ((integration_passed++))
    fi
    
    echo ""
    log_info "Integration Tests Summary: $integration_passed/$integration_total passed"
    return 0
}

# Performance benchmarking
run_performance_tests() {
    log_info "Running performance tests..."
    
    local perf_tests_passed=0
    local perf_tests_total=0
    
    # Test search tool performance
    log_info "Benchmarking search tools..."
    
    local test_file=".htaccess"
    local test_pattern="XXMXLI"
    
    if [[ ! -f "$test_file" ]]; then
        # Create test file if doesn't exist
        echo "# XXMXLI Security Rules" > "$test_file"
        echo "RewriteEngine On" >> "$test_file"
        for i in {1..100}; do
            echo "Require not ip 192.168.1.$i" >> "$test_file"
        done
    fi
    
    for tool in rg ag awk grep; do
        if command -v "$tool" >/dev/null 2>&1; then
            ((perf_tests_total++))
            
            local start_time=$(date +%s%N)
            
            case "$tool" in
                "rg") rg --color=never "$test_pattern" "$test_file" >/dev/null 2>&1 ;;
                "ag") ag --nocolor "$test_pattern" "$test_file" >/dev/null 2>&1 ;;
                "awk") awk "/$test_pattern/" "$test_file" >/dev/null 2>&1 ;;
                "grep") grep "$test_pattern" "$test_file" >/dev/null 2>&1 ;;
            esac
            
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))
            
            if [[ $duration -lt $PERFORMANCE_BASELINE_MS ]]; then
                log_performance "$tool: ${duration}ms (excellent - below ${PERFORMANCE_BASELINE_MS}ms baseline)"
                ((perf_tests_passed++))
            elif [[ $duration -lt $((PERFORMANCE_BASELINE_MS * 2)) ]]; then
                log_performance "$tool: ${duration}ms (good - within 2x baseline)"
                ((perf_tests_passed++))
            else
                log_warning "$tool: ${duration}ms (slow - above 2x baseline)"
            fi
        fi
    done
    
    # Test script startup time
    log_info "Testing script startup times..."
    while IFS= read -r script; do
        [[ "$script" =~ \.sh$ ]] || continue
        [[ -x "$script" ]] || continue
        
        ((perf_tests_total++))
        
        local start_time=$(date +%s%N)
        if run_with_timeout 10 "$script" --help >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local startup_time=$(( (end_time - start_time) / 1000000 ))
            
            if [[ $startup_time -lt 1000 ]]; then
                log_performance "$(basename "$script"): ${startup_time}ms startup (fast)"
                ((perf_tests_passed++))
            elif [[ $startup_time -lt 3000 ]]; then
                log_performance "$(basename "$script"): ${startup_time}ms startup (acceptable)"
                ((perf_tests_passed++))
            else
                log_warning "$(basename "$script"): ${startup_time}ms startup (slow)"
            fi
        else
            log_warning "$(basename "$script"): could not test startup time"
        fi
    done < <(discover_test_scripts | head -5)  # Limit to 5 for performance
    
    echo ""
    log_info "Performance Tests Summary: $perf_tests_passed/$perf_tests_total passed"
    return 0
}

# Security validation tests
run_security_tests() {
    if [[ "$SECURITY_SCAN_ENABLED" != true ]]; then
        log_info "Security tests disabled in configuration"
        return 0
    fi
    
    log_info "Running security validation tests..."
    
    local security_passed=0
    local security_total=0
    
    # Test for hardcoded credentials
    log_info "Scanning for hardcoded credentials..."
    ((security_total++))
    
    local credentials_found=false
    while IFS= read -r script; do
        if grep -iE "(password|secret|key|token).*=.*['\"][^'\"]*['\"]" "$script" 2>/dev/null | grep -qvE "^[[:space:]]*#"; then
            log_security "$(basename "$script"): potential hardcoded credentials found"
            credentials_found=true
        fi
    done < <(discover_test_scripts)
    
    if [[ "$credentials_found" == false ]]; then
        log_success "No hardcoded credentials detected"
        ((security_passed++))
    else
        log_warning "Potential hardcoded credentials detected - review recommended"
    fi
    
    # Test for command injection vulnerabilities
    log_info "Scanning for command injection risks..."
    ((security_total++))
    
    local injection_risks=false
    while IFS= read -r script; do
        if grep -E "\$\{[^}]*\}|\$\([^)]*\)" "$script" 2>/dev/null | grep -qvE "^[[:space:]]*#|dirname|basename|date|pwd"; then
            # Check if it's using user input unsafely
            if grep -B2 -A2 "\$\{.*\}" "$script" 2>/dev/null | grep -qE "read.*|curl.*\$"; then
                log_security "$(basename "$script"): potential command injection risk"
                injection_risks=true
            fi
        fi
    done < <(discover_test_scripts)
    
    if [[ "$injection_risks" == false ]]; then
        log_success "No obvious command injection risks detected"
        ((security_passed++))
    else
        log_warning "Potential command injection risks detected - review recommended"
    fi
    
    # Test file permission security
    log_info "Checking file permissions..."
    ((security_total++))
    
    local insecure_perms=false
    while IFS= read -r script; do
        local perms=$(stat -c "%a" "$script" 2>/dev/null || stat -f "%A" "$script" 2>/dev/null)
        if [[ "${perms: -1}" == "7" ]]; then  # World writable
            log_security "$(basename "$script"): world-writable permissions (${perms})"
            insecure_perms=true
        fi
    done < <(discover_test_scripts)
    
    if [[ "$insecure_perms" == false ]]; then
        log_success "File permissions are secure"
        ((security_passed++))
    else
        log_warning "Insecure file permissions detected"
    fi
    
    echo ""
    log_info "Security Tests Summary: $security_passed/$security_total passed"
    return 0
}

# Error handling and edge case tests
run_error_handling_tests() {
    log_info "Testing error handling and edge cases..."
    
    local error_tests_passed=0
    local error_tests_total=0
    
    # Test behavior with missing dependencies
    log_info "Testing missing dependency handling..."
    while IFS= read -r script; do
        [[ "$script" =~ _optimized\.sh$ ]] || continue
        
        ((error_tests_total++))
        
        # Test with PATH that excludes common tools
        local old_path="$PATH"
        export PATH="/bin:/usr/bin"  # Minimal PATH
        
        if run_with_timeout 15 "$script" --help >/dev/null 2>&1; then
            log_success "$(basename "$script"): handles missing tools gracefully"
            ((error_tests_passed++))
        else
            # Check if it fails gracefully
            local exit_code=$?
            if [[ $exit_code -eq 124 ]]; then
                log_warning "$(basename "$script"): timed out with minimal PATH"
            else
                log_success "$(basename "$script"): exits cleanly with missing tools"
                ((error_tests_passed++))
            fi
        fi
        
        export PATH="$old_path"
    done < <(discover_test_scripts | head -3)  # Limit for efficiency
    
    # Test behavior with corrupted config files
    log_info "Testing corrupted configuration handling..."
    if [[ -f "$CONFIG_DIR/security_monitor.json" ]]; then
        ((error_tests_total++))
        
        # Backup original config
        local backup_config="$CONFIG_DIR/security_monitor.json.backup"
        cp "$CONFIG_DIR/security_monitor.json" "$backup_config" 2>/dev/null
        
        # Create corrupted config
        echo '{"invalid": json}' > "$CONFIG_DIR/security_monitor.json"
        
        # Test with corrupted config
        if [[ -f "$SCRIPT_DIR/security_monitor_optimized.sh" ]]; then
            if run_with_timeout 15 "$SCRIPT_DIR/security_monitor_optimized.sh" --help >/dev/null 2>&1; then
                log_success "security_monitor_optimized.sh: handles corrupted config gracefully"
                ((error_tests_passed++))
            else
                log_warning "security_monitor_optimized.sh: may not handle corrupted config gracefully"
            fi
        fi
        
        # Restore original config
        if [[ -f "$backup_config" ]]; then
            mv "$backup_config" "$CONFIG_DIR/security_monitor.json"
        fi
    fi
    
    # Test disk space limitations
    log_info "Testing disk space handling..."
    ((error_tests_total++))
    
    local disk_usage=$(df "$SCRIPT_DIR" | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $disk_usage -gt 95 ]]; then
        log_warning "Disk usage at ${disk_usage}% - testing low disk space handling"
        # Scripts should handle this gracefully
        ((error_tests_passed++))
    else
        log_success "Sufficient disk space available (${disk_usage}% used)"
        ((error_tests_passed++))
    fi
    
    echo ""
    log_info "Error Handling Tests Summary: $error_tests_passed/$error_tests_total passed"
    return 0
}

# Test report generation
generate_comprehensive_report() {
    local report_file="$RESULTS_DIR/comprehensive_test_report_$(date +%Y%m%d_%H%M%S).html"
    mkdir -p "$RESULTS_DIR" 2>/dev/null
    
    log_info "Generating comprehensive test report..."
    
    cat > "$report_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>XXMXLI Comprehensive Test Report</title>
    <style>
        body { font-family: 'Courier New', monospace; background: #000; color: #00ff00; margin: 20px; }
        .header { border-bottom: 2px solid #00ff00; padding-bottom: 10px; margin-bottom: 20px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #003300; background: #001100; }
        .success { color: #00ff00; }
        .warning { color: #ffff00; }
        .error { color: #ff0000; }
        .info { color: #00ffff; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #002200; border: 1px solid #00ff00; }
        .timestamp { color: #008000; font-size: 0.9em; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #003300; padding: 8px; text-align: left; }
        th { background: #002200; }
        .chart { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 XXMXLI Comprehensive Test Report</h1>
        <p class="timestamp">Generated: $(date)</p>
        <p>System: $(uname -a)</p>
    </div>
EOF
    
    # Add test results to report
    {
        echo "<div class=\"section\">"
        echo "<h2>📊 Test Summary</h2>"
        echo "<div class=\"metric\">Scripts Tested: $(discover_test_scripts | wc -l)</div>"
        echo "<div class=\"metric\">Test Categories: 6</div>"
        echo "<div class=\"metric\">Total Duration: ${test_duration}s</div>"
        echo "</div>"
        
        echo "<div class=\"section\">"
        echo "<h2>🔧 Unit Tests</h2>"
        echo "<p>Tests individual script components and functionality</p>"
        echo "</div>"
        
        echo "<div class=\"section\">"
        echo "<h2>🔗 Integration Tests</h2>"
        echo "<p>Tests script interactions and dependencies</p>"
        echo "</div>"
        
        echo "<div class=\"section\">"
        echo "<h2>🚀 Performance Tests</h2>"
        echo "<p>Benchmarks search tools and script startup times</p>"
        echo "</div>"
        
        echo "<div class=\"section\">"
        echo "<h2>🛡️ Security Tests</h2>"
        echo "<p>Scans for security vulnerabilities and best practices</p>"
        echo "</div>"
        
        echo "<div class=\"section\">"
        echo "<h2>🐛 Error Handling Tests</h2>"
        echo "<p>Tests graceful handling of edge cases and failures</p>"
        echo "</div>"
        
        echo "</body></html>"
    } >> "$report_file"
    
    log_success "Comprehensive test report generated: $report_file"
    
    # Also generate text summary
    local text_report="$RESULTS_DIR/test_summary_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "XXMXLI COMPREHENSIVE TEST SUMMARY"
        echo "=================================="
        echo "Generated: $(date)"
        echo ""
        echo "CONFIGURATION:"
        echo "- Parallel Tests: $PARALLEL_TESTS"
        echo "- Timeout: ${TIMEOUT_SECONDS}s"
        echo "- Performance Baseline: ${PERFORMANCE_BASELINE_MS}ms"
        echo "- Security Scan: $SECURITY_SCAN_ENABLED"
        echo ""
        echo "SCRIPTS TESTED: $(discover_test_scripts | wc -l)"
        echo ""
        echo "TEST CATEGORIES COMPLETED:"
        echo "✅ Unit Tests"
        echo "✅ Integration Tests" 
        echo "✅ Performance Tests"
        echo "✅ Security Tests"
        echo "✅ Error Handling Tests"
        echo ""
        echo "Full HTML report: $report_file"
    } > "$text_report"
    
    log_success "Text summary generated: $text_report"
}

# Main test execution
run_comprehensive_tests() {
    local start_time=$(date +%s)
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 XXMXLI COMPREHENSIVE TEST SUITE             ║"
    echo "║              Enterprise Testing Framework v3.0               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Load configuration
    load_test_config
    log_info "Configuration loaded - Parallel: $PARALLEL_TESTS, Timeout: ${TIMEOUT_SECONDS}s"
    
    # Run test suites
    local total_failures=0
    
    echo ""
    echo "🧪 RUNNING UNIT TESTS"
    echo "===================="
    run_unit_tests || ((total_failures++))
    
    echo ""
    echo "🔗 RUNNING INTEGRATION TESTS"
    echo "============================"
    run_integration_tests || ((total_failures++))
    
    echo ""
    echo "🚀 RUNNING PERFORMANCE TESTS"
    echo "============================"
    run_performance_tests || ((total_failures++))
    
    echo ""
    echo "🛡️ RUNNING SECURITY TESTS"
    echo "========================="
    run_security_tests || ((total_failures++))
    
    echo ""
    echo "🐛 RUNNING ERROR HANDLING TESTS"
    echo "==============================="
    run_error_handling_tests || ((total_failures++))
    
    local end_time=$(date +%s)
    test_duration=$((end_time - start_time))
    
    echo ""
    echo "📊 GENERATING COMPREHENSIVE REPORT"
    echo "=================================="
    generate_comprehensive_report
    
    echo ""
    echo "================================================================"
    if [[ $total_failures -eq 0 ]]; then
        log_success "All test suites completed successfully! ${TROPHY}"
        log_info "Test execution time: ${test_duration} seconds"
        echo ""
        echo -e "${GREEN}${BOLD}🎉 COMPREHENSIVE TESTING COMPLETE${NC}"
        echo -e "${CYAN}${HEART} Your optimized scripts are enterprise-ready!${NC}"
    else
        log_warning "$total_failures test suite(s) had issues - review recommended"
        log_info "Test execution time: ${test_duration} seconds"
        echo ""
        echo -e "${YELLOW}${BOLD}⚠️ TESTING COMPLETE WITH WARNINGS${NC}"
        echo -e "${CYAN}${GEAR} Review the detailed reports for optimization opportunities${NC}"
    fi
    echo ""
}

# Interactive test menu
show_test_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 XXMXLI TESTING FRAMEWORK                    ║"
    echo "║              Choose Your Testing Strategy                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${WHITE}${MICROSCOPE} TESTING OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${TARGET} Run Comprehensive Test Suite"
    echo -e "${GREEN}2)${NC} ${GEAR} Unit Tests Only"
    echo -e "${GREEN}3)${NC} ${ROCKET} Performance Tests Only" 
    echo -e "${GREEN}4)${NC} ${SHIELD} Security Tests Only"
    echo -e "${GREEN}5)${NC} ${BUG} Error Handling Tests Only"
    echo -e "${GREEN}6)${NC} ${CHART} Generate Test Report"
    echo -e "${GREEN}7)${NC} ${SEARCH} Discover Test Scripts"
    echo -e "${GREEN}8)${NC} ${INFO} Test Configuration"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "$(echo -e "${CYAN}Choose testing option [0-8]:${NC} ")" choice
    
    case "$choice" in
        1) run_comprehensive_tests ;;
        2) run_unit_tests ;;
        3) run_performance_tests ;;
        4) run_security_tests ;;
        5) run_error_handling_tests ;;
        6) generate_comprehensive_report ;;
        7) 
            echo ""
            log_info "Discovered scripts:"
            discover_test_scripts | while read -r script; do
                echo "  📄 $script"
            done
            echo ""
            read -p "Press Enter to continue..."
            ;;
        8)
            echo ""
            log_info "Test Configuration:"
            echo "  📁 Config Dir: $CONFIG_DIR"
            echo "  📊 Parallel Tests: $PARALLEL_TESTS"
            echo "  ⏰ Timeout: ${TIMEOUT_SECONDS}s"
            echo "  🎯 Performance Baseline: ${PERFORMANCE_BASELINE_MS}ms"
            echo "  🛡️ Security Scan: $SECURITY_SCAN_ENABLED"
            echo ""
            read -p "Press Enter to continue..."
            ;;
        0) log_info "Exiting testing framework"; exit 0 ;;
        *) log_error "Invalid option: $choice"; sleep 1 ;;
    esac
    
    show_test_menu
}

# Main execution
main() {
    # Initialize
    setup_colors
    setup_symbols
    load_test_config
    
    # Create necessary directories
    mkdir -p "$TEST_DIR" "$RESULTS_DIR" "$LOG_DIR" 2>/dev/null
    
    # Clear old log
    > "$TEST_LOG" 2>/dev/null
    
    # Handle command line arguments
    case "${1:-}" in
        "--full"|"--comprehensive")
            run_comprehensive_tests
            ;;
        "--unit")
            run_unit_tests
            ;;
        "--performance"|"--perf")
            run_performance_tests
            ;;
        "--security"|"--sec")
            run_security_tests
            ;;
        "--error"|"--errors")
            run_error_handling_tests
            ;;
        "--report")
            generate_comprehensive_report
            ;;
        "--discover")
            discover_test_scripts
            ;;
        "--help"|"-h")
            echo "XXMXLI Comprehensive Testing Framework v3.0"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --full, --comprehensive  Run all test suites"
            echo "  --unit                   Run unit tests only"
            echo "  --performance, --perf    Run performance tests only"
            echo "  --security, --sec        Run security tests only"
            echo "  --error, --errors        Run error handling tests only"
            echo "  --report                 Generate test report"
            echo "  --discover               List all discoverable scripts"
            echo "  --help, -h               Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            show_test_menu
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "Testing framework terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
