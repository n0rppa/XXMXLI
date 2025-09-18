#!/bin/bash

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