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


# ========================================
# XXMXLI IP BLACKLIST ANALYZER & BLOCKER
# ========================================
# This script analyzes your blacklist and creates server-side blocking rules
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

echo "🛡️  XXMXLI IP Blacklist Analysis & Server-Side Blocking Setup"
echo "=============================================================="

# Configuration
BLACKLIST_FILE="assets/security/blocked_ips.json"
OUTPUT_HTACCESS=".htaccess_generated_blocks"
HIGH_PRIORITY_COUNT=100
ADMIN_HTACCESS="admin/.htaccess_ip_blocks"

# Check if blacklist file exists
if [ ! -f "$BLACKLIST_FILE" ]; then
    echo "❌ Error: Blacklist file not found at $BLACKLIST_FILE"
    exit 1
fi

echo "📊 Analyzing blacklist data..."

# Extract total IP count
TOTAL_IPS=$(grep -o '"total_ips": [0-9]*' "$BLACKLIST_FILE" | grep -o '[0-9]*')
echo "📈 Total IPs in blacklist: $TOTAL_IPS"

# Create high-priority server-side blocking rules
echo "🔥 Creating high-priority server-side blocking rules..."

cat > "$OUTPUT_HTACCESS" << 'EOF'
# ========================================
# XXMXLI AUTO-GENERATED IP BLOCKING RULES
# ========================================
# Generated on: $(date)
# High-priority IPs that are blocked at server level

RewriteEngine On

# Block high-priority threat IPs
<RequireAll>
    Require all granted
    
EOF

# Extract first 100 IPs for server-side blocking
echo "⚡ Extracting top $HIGH_PRIORITY_COUNT IPs for server-side blocking..."

# Parse JSON and extract first N IPs
python3 << EOF
import json
import sys

try:
    with open('$BLACKLIST_FILE', 'r') as f:
        data = json.load(f)
    
    ips = data.get('blocked_ips', [])[:$HIGH_PRIORITY_COUNT]
    
    for ip in ips:
        print(f"    Require not ip {ip}")
        
except Exception as e:
    print(f"Error processing JSON: {e}", file=sys.stderr)
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    # Append the extracted IPs to htaccess file
    python3 << EOF >> "$OUTPUT_HTACCESS"
import json

try:
    with open('$BLACKLIST_FILE', 'r') as f:
        data = json.load(f)
    
    ips = data.get('blocked_ips', [])[:$HIGH_PRIORITY_COUNT]
    
    for ip in ips:
        print(f"    Require not ip {ip}")
        
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
EOF

    # Complete the htaccess file
    cat >> "$OUTPUT_HTACCESS" << 'EOF'
    
</RequireAll>

# Block suspicious user agents
RewriteCond %{HTTP_USER_AGENT} (bot|crawler|spider|scraper|hack|scan|vuln) [NC]
RewriteRule .* /blocked.html [R=403,L]

# Block empty user agents
RewriteCond %{HTTP_USER_AGENT} ^-?$
RewriteRule .* /blocked.html [R=403,L]

# Block IP ranges known for attacks
RewriteCond %{REMOTE_ADDR} ^1\.0\.248\.
RewriteRule .* /blocked.html [R=403,L]

RewriteCond %{REMOTE_ADDR} ^185\.220\.
RewriteRule .* /blocked.html [R=403,L]

# Log blocked attempts
RewriteCond %{REQUEST_URI} !^/blocked\.html$
RewriteCond %{REMOTE_ADDR} ^(1\.0\.0\.1|1\.1\.1\.1)$
RewriteRule .* - [E=blocked_ip:1]
CustomLog logs/xxmxli_blocked.log "%h %t \"%r\" %>s %b [BLOCKED]" env=blocked_ip

EOF

    echo "✅ Generated $OUTPUT_HTACCESS with $HIGH_PRIORITY_COUNT high-priority IPs"
else
    echo "❌ Failed to process blacklist JSON"
    exit 1
fi

# Create admin-specific blocking
echo "🔒 Creating admin area protection..."
mkdir -p admin
cat > "$ADMIN_HTACCESS" << 'EOF'
# ========================================
# XXMXLI ADMIN AREA IP PROTECTION
# ========================================
# Extra security for admin directory

AuthType Basic
AuthName "XXMXLI Admin Access"
AuthUserFile /path/to/.htpasswd

<RequireAll>
    Require valid-user
    
    # Block broader IP ranges from admin access
    Require not ip 1.0.0.0/8
    Require not ip 2.0.0.0/8
    Require not ip 46.0.0.0/8
    Require not ip 185.0.0.0/8
    Require not ip 194.0.0.0/8
    
    # Add your trusted admin IPs here:
    # Require ip YOUR.ADMIN.IP.HERE
</RequireAll>

# Additional admin security
<Files "*.php">
    Require all denied
    # Require ip YOUR.ADMIN.IP.HERE
</Files>

EOF

echo "✅ Generated $ADMIN_HTACCESS for admin protection"

# Generate installation instructions
cat > "INSTALLATION_INSTRUCTIONS.txt" << EOF
========================================
XXMXLI SERVER-SIDE IP BLOCKING SETUP
========================================

🚀 INSTALLATION STEPS:

1. BACKUP YOUR CURRENT .htaccess:
   cp .htaccess .htaccess.backup

2. ADD BLOCKING RULES TO YOUR MAIN .htaccess:
   cat $OUTPUT_HTACCESS >> .htaccess

3. INSTALL ADMIN PROTECTION:
   cp $ADMIN_HTACCESS admin/.htaccess

4. CREATE BLOCKED PAGE:
   Create a file called 'blocked.html' in your root directory

5. TEST THE SETUP:
   - Check that your site still loads normally
   - Verify blocked IPs get 403 errors
   - Test admin access works

⚠️  IMPORTANT NOTES:
- This blocks $HIGH_PRIORITY_COUNT of your highest-priority IPs at server level
- Remaining IPs are still handled by your client-side system
- Monitor your server logs for blocked attempts
- Adjust IP ranges based on your legitimate user base

📊 MONITORING:
- Blocked attempts logged to: logs/xxmxli_blocked.log
- Check regularly: tail -f logs/xxmxli_blocked.log

🆘 EMERGENCY DISABLE:
If you get locked out, remove the blocking rules from .htaccess
or add your IP to the trusted list.

EOF

echo ""
echo "🎯 SUMMARY:"
echo "==========="
echo "✅ Generated server-side blocking for $HIGH_PRIORITY_COUNT high-priority IPs"
echo "✅ Created admin area protection rules"
echo "✅ Generated installation instructions"
echo ""
echo "📁 FILES CREATED:"
echo "- $OUTPUT_HTACCESS (main blocking rules)"
echo "- $ADMIN_HTACCESS (admin protection)"
echo "- INSTALLATION_INSTRUCTIONS.txt (setup guide)"
echo ""
echo "⚡ NEXT STEPS:"
echo "1. Review the generated files"
echo "2. Follow INSTALLATION_INSTRUCTIONS.txt"
echo "3. Test thoroughly before deploying"
echo ""
echo "🛡️  Your site will have REAL server-side IP blocking after installation!"
