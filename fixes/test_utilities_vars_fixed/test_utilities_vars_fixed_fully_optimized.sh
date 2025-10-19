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
# XXMXLI Advanced Test Utilities
# Supporting functions for comprehensive testing
# ================================================================

# Test data generator for performance testing
generate_test_data() {
    local test_file="$1"
    local size="${2:-1000}"
    
    echo "# XXMXLI Test Data - Generated $(date)" > "$test_file"
    echo "# This file is used for performance testing" >> "$test_file"
    echo "" >> "$test_file"
    
    for ((i=1; i<=size; i++)); do
        echo "TestEntry$i=Value$i" >> "$test_file"
        echo "XXMXLI_CONFIG_$i=test_value_$i" >> "$test_file"
        if (( i % 10 == 0 )); then
            echo "# Section $((i/10))" >> "$test_file"
        fi
    done
    
    echo "# End of test data" >> "$test_file"
}

# Mock dependency checker
check_mock_environment() {
    local missing_tools=()
    local optional_tools=("rg" "ag" "jq" "yq" "timeout")
    
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Missing optional tools for full testing: ${missing_tools[*]}"
        echo "Installing these tools will improve test coverage:"
        for tool in "${missing_tools[@]}"; do
            case "$tool" in
                "rg") echo "  - ripgrep: sudo apt install ripgrep" ;;
                "ag") echo "  - the_silver_searcher: sudo apt install silversearcher-ag" ;;
                "jq") echo "  - jq: sudo apt install jq" ;;
                "yq") echo "  - yq: wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq" ;;
                "timeout") echo "  - timeout: Usually part of coreutils" ;;
            esac
        done
        return 1
    fi
    
    return 0
}

# Performance baseline calibration
calibrate_performance_baseline() {
    local test_file="test_performance.tmp"
    generate_test_data "$test_file" 500
    
    echo "Calibrating performance baseline..."
    
    local total_time=0
    local iterations=5
    
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(date +%s%N)
        grep "XXMXLI" "$test_file" >/dev/null 2>&1
        local end_time=$(date +%s%N)
        local duration=$(( (end_time - start_time) / 1000000 ))
        total_time=$((total_time + duration))
    done
    
    local baseline=$((total_time / iterations))
    echo "Recommended performance baseline: ${baseline}ms"
    
    rm -f "$test_file"
    return $baseline
}

# Security test patterns
get_security_patterns() {
    cat << 'EOF'
# Common security anti-patterns to detect
password\s*=\s*["'][^"']+["']
secret\s*=\s*["'][^"']+["']
api_key\s*=\s*["'][^"']+["']
token\s*=\s*["'][^"']+["']
\$\{[^}]*\}.*\$[^}]*
eval\s+\$
exec\s+\$[^}]*
rm\s+-rf\s+\$
chmod\s+777
EOF
}

# Generate test certificates for security testing
generate_test_certificates() {
    local cert_dir="tests/security/certs"
    mkdir -p "$cert_dir" 2>/dev/null
    
    # Generate test private key (for testing only)
    openssl genrsa -out "$cert_dir/test.key" 2048 2>/dev/null
    
    # Generate test certificate
    openssl req -new -x509 -key "$cert_dir/test.key" -out "$cert_dir/test.crt" -days 1 \
        -subj "/C=XX/ST=Test/L=Test/O=XXMXLI/OU=Testing/CN=test.local" 2>/dev/null
    
    echo "Test certificates generated in $cert_dir"
}

# Clean up test artifacts
cleanup_test_environment() {
    echo "Cleaning up test environment..."
    
    # Remove temporary test files
    find . -name "*.tmp" -type f -delete 2>/dev/null
    find . -name "test_*.backup" -type f -delete 2>/dev/null
    
    # Clean up test certificates
    rm -rf tests/security/certs 2>/dev/null
    
    # Clean up old test results (keep last 5)
    if [[ -d "tests/results" ]]; then
        cd "tests/results" && ls -t *.html 2>/dev/null | tail -n +6 | xargs rm -f
        cd "tests/results" && ls -t *.txt 2>/dev/null | tail -n +6 | xargs rm -f
        cd - >/dev/null
    fi
    
    echo "Test environment cleaned"
}

# Validate test configuration
validate_test_config() {
    local config_file="$1"
    local config_valid=true
    
    if [[ ! -f "$config_file" ]]; then
        echo "Configuration file not found: $config_file"
        return 1
    fi
    
    case "$config_file" in
        *.json)
            if command -v jq >/dev/null 2>&1; then
                if ! jq -e . "$config_file" >/dev/null 2>&1; then
                    echo "Invalid JSON in $config_file"
                    config_valid=false
                fi
            fi
            ;;
        *.yaml|*.yml)
            if command -v yq >/dev/null 2>&1; then
                if ! yq eval . "$config_file" >/dev/null 2>&1; then
                    echo "Invalid YAML in $config_file"
                    config_valid=false
                fi
            fi
            ;;
        *.conf)
            if ! source "$config_file" 2>/dev/null; then
                echo "Invalid configuration syntax in $config_file"
                config_valid=false
            fi
            ;;
    esac
    
    if [[ "$config_valid" == true ]]; then
        echo "Configuration file $config_file is valid"
        return 0
    else
        return 1
    fi
}

# Main utility function
main() {
    case "${1:-}" in
        "generate-data")
            generate_test_data "${2:-test_data.tmp}" "${3:-1000}"
            ;;
        "check-env")
            check_mock_environment
            ;;
        "calibrate")
            calibrate_performance_baseline
            ;;
        "cleanup")
            cleanup_test_environment
            ;;
        "validate-config")
            validate_test_config "${2:-config/test_suite.json}"
            ;;
        "security-patterns")
            get_security_patterns
            ;;
        "generate-certs")
            generate_test_certificates
            ;;
        *)
            echo "XXMXLI Advanced Test Utilities"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  generate-data [file] [size]  Generate test data file"
            echo "  check-env                    Check testing environment"
            echo "  calibrate                    Calibrate performance baseline"
            echo "  cleanup                      Clean up test artifacts"
            echo "  validate-config [file]       Validate configuration file"
            echo "  security-patterns            Show security test patterns"
            echo "  generate-certs               Generate test certificates"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
