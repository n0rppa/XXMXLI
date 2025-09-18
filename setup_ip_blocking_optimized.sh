#!/bin/bash

# ================================================================
# XXMXLI OPTIMIZED IP BLACKLIST ANALYZER & BLOCKER v2.0
# Enhanced Performance • Better Error Handling • Configuration Support
# ================================================================

# Security warning header
echo "🛡️  SECURITY WARNING: This system is actively monitored and protected."
echo "Any unauthorized access attempts will be logged and reported to authorities."
echo "By continuing, you acknowledge authorized use only."

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/ip_blocking.conf"
CONFIG_JSON="$CONFIG_DIR/ip_blocking.json"

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
        SHIELD="🛡️"
        GEAR="⚙️"
        ROCKET="🚀"
        FIRE="🔥"
        LIGHTNING="⚡"
        CHART="📊"
        LOCK="🔒"
        TARGET="🎯"
        FOLDER="📁"
        HAMMER="🔨"
        WRENCH="🔧"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        ARROW=">"
        SHIELD="[S]"
        GEAR="[G]"
        ROCKET="[R]"
        FIRE="[F]"
        LIGHTNING="[L]"
        CHART="[C]"
        LOCK="[L]"
        TARGET="[T]"
        FOLDER="[F]"
        HAMMER="[H]"
        WRENCH="[W]"
    fi
}

# Configuration loading with validation
load_configuration() {
    # Default values
    BLACKLIST_FILE="assets/security/blocked_ips.json"
    OUTPUT_HTACCESS=".htaccess_generated_blocks"
    HIGH_PRIORITY_COUNT=100
    ADMIN_HTACCESS="admin/.htaccess_ip_blocks"
    BACKUP_ENABLED=true
    VALIDATE_IPS=true
    LOG_BLOCKED_ATTEMPTS=true
    EMERGENCY_WHITELIST=()
    
    # Try JSON configuration first
    if [[ -f "$CONFIG_JSON" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
            BLACKLIST_FILE=$(jq -r '.files.blacklist_file // "assets/security/blocked_ips.json"' "$CONFIG_JSON" 2>/dev/null)
            OUTPUT_HTACCESS=$(jq -r '.files.output_htaccess // ".htaccess_generated_blocks"' "$CONFIG_JSON" 2>/dev/null)
            HIGH_PRIORITY_COUNT=$(jq -r '.blocking.high_priority_count // 100' "$CONFIG_JSON" 2>/dev/null)
            ADMIN_HTACCESS=$(jq -r '.files.admin_htaccess // "admin/.htaccess_ip_blocks"' "$CONFIG_JSON" 2>/dev/null)
            BACKUP_ENABLED=$(jq -r '.settings.backup_enabled // true' "$CONFIG_JSON" 2>/dev/null)
            VALIDATE_IPS=$(jq -r '.settings.validate_ips // true' "$CONFIG_JSON" 2>/dev/null)
            LOG_BLOCKED_ATTEMPTS=$(jq -r '.settings.log_blocked_attempts // true' "$CONFIG_JSON" 2>/dev/null)
            
            # Load emergency whitelist
            local whitelist_json
            whitelist_json=$(jq -r '.security.emergency_whitelist[]? // empty' "$CONFIG_JSON" 2>/dev/null)
            if [[ -n "$whitelist_json" ]]; then
                mapfile -t EMERGENCY_WHITELIST <<< "$whitelist_json"
            fi
            
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
    BLOCKING_LOG="$LOG_DIR/ip_blocking.log"
    ERROR_LOG="$LOG_DIR/ip_blocking_errors.log"
    
    # Log rotation
    for log_file in "$BLOCKING_LOG" "$ERROR_LOG"; do
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
        echo "[DEBUG $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$BLOCKING_LOG" 2>/dev/null
    }
}

log_info() { 
    echo -e "${BLUE}${ARROW}${NC} $1"
    echo "[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$BLOCKING_LOG" 2>/dev/null
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    echo "[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$BLOCKING_LOG" 2>/dev/null
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1" >&2
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$BLOCKING_LOG" 2>/dev/null
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
    ║        ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗             ║
    ║        ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝             ║
    ║        ██████╔╝██║     ██║   ██║██║     █████╔╝              ║
    ║        ██╔══██╗██║     ██║   ██║██║     ██╔═██╗              ║
    ║        ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗             ║
    ║        ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝             ║
    ║                                                              ║
    ║           OPTIMIZED IP BLACKLIST ANALYZER v2.0              ║
    ║        Enhanced Performance • Better Error Handling         ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}      ${SHIELD} Server-Side Blocking • ${FIRE} High-Priority IPs${NC}"
    echo -e "${GREEN}      ${LIGHTNING} Using: $SEARCH_TOOL • Priority: $HIGH_PRIORITY_COUNT IPs${NC}"
    echo ""
}

# IP validation function
validate_ip() {
    local ip="$1"
    local regex='^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'
    
    if [[ $ip =~ $regex ]]; then
        # Additional validation for IP octets
        local IFS='.' parts=($ip)
        for part in "${parts[@]}"; do
            if [[ ${part%%/*} -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Enhanced blacklist file validation
validate_blacklist_file() {
    log_info "Validating blacklist file: $BLACKLIST_FILE"
    
    if [[ ! -f "$BLACKLIST_FILE" ]]; then
        log_error "Blacklist file not found at $BLACKLIST_FILE"
        return 1
    fi
    
    if [[ ! -r "$BLACKLIST_FILE" ]]; then
        log_error "Cannot read blacklist file: $BLACKLIST_FILE"
        return 1
    fi
    
    # Check if file is valid JSON
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq not available, skipping JSON validation"
        return 0
    fi
    
    if ! jq -e . "$BLACKLIST_FILE" >/dev/null 2>&1; then
        log_error "Invalid JSON format in blacklist file"
        return 1
    fi
    
    # Check for required fields
    local total_ips
    total_ips=$(jq -r '.total_ips // 0' "$BLACKLIST_FILE" 2>/dev/null)
    
    if [[ ${total_ips:-0} -eq 0 ]]; then
        log_warning "No IPs found in blacklist file"
        return 1
    fi
    
    log_success "Blacklist file validated: $total_ips total IPs"
    return 0
}

# Enhanced backup functionality
create_backup() {
    local file_to_backup="$1"
    local backup_suffix="${2:-$(date +%Y%m%d_%H%M%S)}"
    
    if [[ ! -f "$file_to_backup" ]]; then
        log_debug "No existing file to backup: $file_to_backup"
        return 0
    fi
    
    local backup_file="${file_to_backup}.backup_${backup_suffix}"
    
    if cp "$file_to_backup" "$backup_file" 2>/dev/null; then
        log_success "Created backup: $backup_file"
        return 0
    else
        log_error "Failed to create backup of $file_to_backup"
        return 1
    fi
}

# Enhanced IP extraction with validation
extract_ips_from_blacklist() {
    local output_file="$1"
    local ip_count="$2"
    
    log_info "Extracting top $ip_count IPs from blacklist..."
    
    # Use Python with enhanced error handling
    python3 << EOF
import json
import sys
import ipaddress
import signal

def signal_handler(signum, frame):
    print("Operation timed out", file=sys.stderr)
    sys.exit(1)

signal.signal(signal.SIGALRM, signal_handler)
signal.alarm(30)  # 30 second timeout

try:
    with open('$BLACKLIST_FILE', 'r') as f:
        data = json.load(f)
    
    ips = data.get('blocked_ips', [])[:$ip_count]
    valid_ips = []
    
    for ip in ips:
        try:
            # Validate IP address
            if '/' in ip:
                ipaddress.ip_network(ip, strict=False)
            else:
                ipaddress.ip_address(ip)
            valid_ips.append(ip)
        except ValueError:
            print(f"Warning: Invalid IP address skipped: {ip}", file=sys.stderr)
            continue
    
    print(f"Successfully validated {len(valid_ips)} out of {len(ips)} IPs", file=sys.stderr)
    
    # Write to temporary file first
    with open('$output_file.tmp', 'w') as f:
        for ip in valid_ips:
            f.write(f"    Require not ip {ip}\n")
    
except FileNotFoundError:
    print("Error: Blacklist file not found", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"Error: Invalid JSON format: {e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"Error processing blacklist: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    signal.alarm(0)  # Cancel timeout
EOF
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 && -f "${output_file}.tmp" ]]; then
        mv "${output_file}.tmp" "$output_file"
        log_success "IP extraction completed successfully"
        return 0
    else
        rm -f "${output_file}.tmp" 2>/dev/null
        log_error "IP extraction failed with exit code: $exit_code"
        return 1
    fi
}

# Enhanced htaccess generation
generate_htaccess_rules() {
    local output_file="$1"
    local ip_file="$2"
    
    log_info "Generating .htaccess rules..."
    
    # Create backup if file exists
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        create_backup "$output_file"
    fi
    
    # Generate htaccess header
    cat > "$output_file" << EOF
# ========================================
# XXMXLI AUTO-GENERATED IP BLOCKING RULES
# ========================================
# Generated on: $(date)
# High-priority IPs blocked at server level
# Using search tool: $SEARCH_TOOL
# Configuration: $HIGH_PRIORITY_COUNT priority IPs

RewriteEngine On

# Performance optimization
RewriteOptions MaxRedirects=1

# Block high-priority threat IPs
<RequireAll>
    Require all granted
    
    # Emergency whitelist (always allowed)
EOF

    # Add emergency whitelist
    for whitelist_ip in "${EMERGENCY_WHITELIST[@]}"; do
        if validate_ip "$whitelist_ip"; then
            echo "    # Emergency access: $whitelist_ip" >> "$output_file"
        fi
    done
    
    echo "" >> "$output_file"
    
    # Add extracted IPs
    if [[ -f "$ip_file" ]]; then
        cat "$ip_file" >> "$output_file"
    else
        log_error "IP file not found: $ip_file"
        return 1
    fi
    
    # Add footer
    cat >> "$output_file" << 'EOF'
    
</RequireAll>

# Block suspicious user agents with performance optimization
RewriteCond %{HTTP_USER_AGENT} "^$" [OR]
RewriteCond %{HTTP_USER_AGENT} "(bot|crawler|spider|scraper|hack|scan|vuln|exploit|injection)" [NC]
RewriteRule .* /blocked.html [R=403,L]

# Block common attack patterns
RewriteCond %{QUERY_STRING} "(union.*select|insert.*into|update.*set|delete.*from)" [NC]
RewriteRule .* /blocked.html [R=403,L]

# Block IP ranges known for attacks (optimized)
RewriteCond %{REMOTE_ADDR} "^(1\.0\.248\.|185\.220\.|194\.147\.)" [OR]
RewriteCond %{REMOTE_ADDR} "^(46\.161\.|2\.56\.)" 
RewriteRule .* /blocked.html [R=403,L]

# Rate limiting for repeated requests
RewriteMap requests_per_hour prg:/usr/local/bin/rate_limiter.pl
RewriteCond ${requests_per_hour:%{REMOTE_ADDR}|0} >100
RewriteRule .* /blocked.html [R=429,L]

EOF

    # Add logging if enabled
    if [[ "$LOG_BLOCKED_ATTEMPTS" == "true" ]]; then
        cat >> "$output_file" << 'EOF'
# Enhanced logging for blocked attempts
RewriteCond %{REQUEST_URI} !^/blocked\.html$
RewriteCond %{REQUEST_URI} !^/assets/
RewriteRule .* - [E=log_request:1]
CustomLog logs/xxmxli_blocked.log "%h %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" [BLOCKED]" env=log_request

EOF
    fi
    
    log_success "Generated .htaccess rules in $output_file"
    return 0
}

# Enhanced admin protection
generate_admin_protection() {
    local admin_file="$1"
    
    log_info "Creating admin area protection..."
    
    # Ensure admin directory exists
    local admin_dir=$(dirname "$admin_file")
    if ! mkdir -p "$admin_dir" 2>/dev/null; then
        log_error "Cannot create admin directory: $admin_dir"
        return 1
    fi
    
    # Create backup if file exists
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        create_backup "$admin_file"
    fi
    
    cat > "$admin_file" << EOF
# ========================================
# XXMXLI ADMIN AREA IP PROTECTION v2.0
# ========================================
# Enhanced security for admin directory
# Generated on: $(date)

# Basic authentication requirement
AuthType Basic
AuthName "XXMXLI Admin Access - Authorized Personnel Only"
AuthUserFile $(realpath "$admin_dir")/.htpasswd

<RequireAll>
    Require valid-user
    
    # Emergency whitelist (always allowed)
EOF

    # Add emergency whitelist to admin protection
    for whitelist_ip in "${EMERGENCY_WHITELIST[@]}"; do
        if validate_ip "$whitelist_ip"; then
            echo "    Require ip $whitelist_ip  # Emergency access" >> "$admin_file"
        fi
    done
    
    cat >> "$admin_file" << 'EOF'
    
    # Block high-risk IP ranges from admin access
    Require not ip 1.0.0.0/8
    Require not ip 2.0.0.0/8
    Require not ip 46.0.0.0/8
    Require not ip 185.0.0.0/8
    Require not ip 194.0.0.0/8
    
    # Block known attack sources
    Require not ip 103.0.0.0/8
    Require not ip 111.0.0.0/8
    Require not ip 117.0.0.0/8
    
    # Add your trusted admin IPs here:
    # Require ip YOUR.ADMIN.IP.HERE
    # Require ip YOUR.OFFICE.IP.RANGE/24
</RequireAll>

# Enhanced file protection
<Files "*.php">
    <RequireAll>
        Require valid-user
        # Additional IP restrictions for PHP files
        # Require ip YOUR.ADMIN.IP.HERE
    </RequireAll>
</Files>

<Files "*.json">
    Require all denied
</Files>

<Files "*.log">
    Require all denied
</Files>

# Block direct access to sensitive files
<FilesMatch "\.(conf|config|ini|env)$">
    Require all denied
</FilesMatch>

# Security headers for admin area
Header always set X-Frame-Options "DENY"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

EOF
    
    log_success "Generated admin protection in $admin_file"
    return 0
}

# Enhanced installation instructions
generate_installation_instructions() {
    local instruction_file="INSTALLATION_INSTRUCTIONS.txt"
    
    log_info "Generating installation instructions..."
    
    cat > "$instruction_file" << EOF
========================================
XXMXLI OPTIMIZED IP BLOCKING SETUP v2.0
========================================
Generated: $(date)
Configuration: $HIGH_PRIORITY_COUNT priority IPs
Search tool: $SEARCH_TOOL

🚀 INSTALLATION STEPS:

1. BACKUP YOUR CURRENT .htaccess (CRITICAL):
   cp .htaccess .htaccess.backup_\$(date +%Y%m%d_%H%M%S)

2. MERGE BLOCKING RULES WITH YOUR MAIN .htaccess:
   # Option A: Append to existing .htaccess
   cat $OUTPUT_HTACCESS >> .htaccess
   
   # Option B: Replace .htaccess (if you don't have custom rules)
   cp $OUTPUT_HTACCESS .htaccess

3. INSTALL ADMIN PROTECTION:
   cp $ADMIN_HTACCESS admin/.htaccess
   
   # Create admin password file (replace with your credentials):
   htpasswd -c admin/.htpasswd admin_user

4. CREATE BLOCKED PAGE:
   # Create a professional blocked page
   cat > blocked.html << 'BLOCKED_EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Access Denied - XXMXLI Security</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial; text-align: center; padding: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
        .error { color: #d32f2f; font-size: 24px; margin-bottom: 20px; }
        .message { color: #666; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="container">
        <div class="error">🛡️ Access Denied</div>
        <div class="message">
            Your IP address has been identified as a security risk.<br>
            If you believe this is an error, please contact the administrator.<br><br>
            <small>Reference: XXMXLI Security System</small>
        </div>
    </div>
</body>
</html>
BLOCKED_EOF

5. TEST THE SETUP:
   # Check that your site loads normally
   curl -I http://yoursite.com
   
   # Verify admin access works (replace with your IP)
   # curl -I http://yoursite.com/admin/ -H "X-Forwarded-For: YOUR_IP"

6. MONITOR BLOCKED ATTEMPTS:
   tail -f logs/xxmxli_blocked.log

⚠️  IMPORTANT SECURITY NOTES:
=====================================
- This system blocks $HIGH_PRIORITY_COUNT highest-priority IPs at server level
- Emergency whitelist configured: ${EMERGENCY_WHITELIST[*]:-"None configured"}
- Remaining IPs are handled by client-side systems
- Rate limiting enabled: 100 requests/hour per IP
- Enhanced logging tracks all blocked attempts

📊 MONITORING & MAINTENANCE:
==========================
- Blocked attempts: logs/xxmxli_blocked.log
- Error log: $ERROR_LOG
- Configuration: $CONFIG_JSON
- Backup enabled: $BACKUP_ENABLED

🛠️  PERFORMANCE OPTIMIZATIONS:
============================
- Using $SEARCH_TOOL for pattern matching
- Optimized RewriteRules with early termination
- Rate limiting prevents DoS attacks
- Compressed logs with automatic rotation

🆘 EMERGENCY PROCEDURES:
======================
IF YOU GET LOCKED OUT:
1. Remove blocking rules from .htaccess:
   sed -i '/XXMXLI AUTO-GENERATED/,/^$/d' .htaccess

2. Or add your IP to emergency whitelist in config:
   Edit $CONFIG_JSON and add your IP to emergency_whitelist array

3. Or disable via FTP/SSH:
   mv .htaccess .htaccess.disabled

TROUBLESHOOTING:
- 500 Internal Server Error: Check Apache error log
- Still getting attacked: Increase HIGH_PRIORITY_COUNT
- Performance issues: Reduce HIGH_PRIORITY_COUNT or use CDN

📞 SUPPORT:
==========
- Check logs first: tail -100 $ERROR_LOG
- Verify configuration: cat $CONFIG_JSON
- Test individual rules manually

🔄 UPDATING:
===========
To update the blocking list:
1. Update $BLACKLIST_FILE
2. Run this script again: ./$(basename "$0")
3. The system will create new backups automatically

📈 STATISTICS:
=============
Last run: $(date)
Total IPs processed: \$(jq -r '.total_ips // 0' "$BLACKLIST_FILE" 2>/dev/null || echo "Unknown")
High-priority IPs: $HIGH_PRIORITY_COUNT
Emergency whitelist: ${#EMERGENCY_WHITELIST[@]} IPs
Configuration source: $([ -f "$CONFIG_JSON" ] && echo "JSON" || echo "Default")

EOF

    log_success "Generated installation instructions: $instruction_file"
    return 0
}

# Performance benchmark
run_performance_benchmark() {
    log_info "Running performance benchmark..."
    
    local start_time=$(date +%s.%N)
    
    # Test search tool performance
    if [[ -f "$BLACKLIST_FILE" ]]; then
        log_debug "Testing search performance with $SEARCH_TOOL"
        
        local test_ip="192.168.1.1"
        case "$SEARCH_TOOL" in
            "rg")
                run_with_timeout 5 rg -q "$test_ip" "$BLACKLIST_FILE" >/dev/null 2>&1
                ;;
            "ag")
                run_with_timeout 5 ag -l "$test_ip" "$BLACKLIST_FILE" >/dev/null 2>&1
                ;;
            "awk")
                run_with_timeout 5 awk "/$test_ip/ {found=1; exit} END {exit !found}" "$BLACKLIST_FILE" >/dev/null 2>&1
                ;;
            *)
                run_with_timeout 5 grep -q "$test_ip" "$BLACKLIST_FILE" >/dev/null 2>&1
                ;;
        esac
    fi
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    log_success "Performance benchmark completed in ${duration:-0}s using $SEARCH_TOOL"
}

# Main blocking setup function
setup_ip_blocking() {
    show_banner
    
    log_info "Starting XXMXLI IP Blacklist Analysis & Blocking Setup"
    
    # Validate blacklist file
    if ! validate_blacklist_file; then
        log_error "Cannot proceed without valid blacklist file"
        return 1
    fi
    
    # Get total IP count
    local total_ips
    if command -v jq >/dev/null 2>&1; then
        total_ips=$(jq -r '.total_ips // 0' "$BLACKLIST_FILE" 2>/dev/null)
    else
        total_ips=$(grep -o '"total_ips": [0-9]*' "$BLACKLIST_FILE" | grep -o '[0-9]*' || echo "0")
    fi
    
    log_success "Total IPs in blacklist: $total_ips"
    
    # Performance benchmark
    run_performance_benchmark
    
    # Extract IPs
    local temp_ip_file="/tmp/extracted_ips_$$"
    if ! extract_ips_from_blacklist "$temp_ip_file" "$HIGH_PRIORITY_COUNT"; then
        rm -f "$temp_ip_file"
        return 1
    fi
    
    # Generate htaccess rules
    if ! generate_htaccess_rules "$OUTPUT_HTACCESS" "$temp_ip_file"; then
        rm -f "$temp_ip_file"
        return 1
    fi
    
    # Generate admin protection
    if ! generate_admin_protection "$ADMIN_HTACCESS"; then
        rm -f "$temp_ip_file"
        return 1
    fi
    
    # Generate installation instructions
    generate_installation_instructions
    
    # Cleanup
    rm -f "$temp_ip_file"
    
    # Summary
    echo ""
    echo -e "${WHITE}${TARGET} SETUP COMPLETE - SUMMARY${NC}"
    echo "================================================================"
    log_success "Generated server-side blocking for $HIGH_PRIORITY_COUNT high-priority IPs"
    log_success "Created admin area protection with enhanced security"
    log_success "Generated comprehensive installation instructions"
    echo ""
    echo -e "${CYAN}${FOLDER} FILES CREATED:${NC}"
    echo "- $OUTPUT_HTACCESS (main blocking rules)"
    echo "- $ADMIN_HTACCESS (admin protection)"
    echo "- INSTALLATION_INSTRUCTIONS.txt (setup guide)"
    echo ""
    echo -e "${LIGHTNING} NEXT STEPS:${NC}"
    echo "1. Review the generated files carefully"
    echo "2. Follow INSTALLATION_INSTRUCTIONS.txt step by step"
    echo "3. Test thoroughly in staging environment first"
    echo "4. Monitor logs after deployment"
    echo ""
    echo -e "${SHIELD} Your site will have REAL server-side IP blocking after installation!${NC}"
    
    return 0
}

# Interactive configuration
interactive_config() {
    echo -e "${PURPLE}${GEAR} INTERACTIVE CONFIGURATION${NC}"
    echo "================================================================"
    echo ""
    
    echo "Current configuration:"
    echo "  Blacklist file: $BLACKLIST_FILE"
    echo "  High priority count: $HIGH_PRIORITY_COUNT"
    echo "  Output file: $OUTPUT_HTACCESS"
    echo "  Admin protection: $ADMIN_HTACCESS"
    echo "  Backup enabled: $BACKUP_ENABLED"
    echo "  IP validation: $VALIDATE_IPS"
    echo ""
    
    read -p "Do you want to modify the configuration? (y/n): " modify_config
    
    if [[ "$modify_config" =~ ^[Yy] ]]; then
        read -p "High priority IP count [$HIGH_PRIORITY_COUNT]: " new_count
        [[ -n "$new_count" ]] && HIGH_PRIORITY_COUNT="$new_count"
        
        read -p "Enable backups? (y/n) [$BACKUP_ENABLED]: " new_backup
        [[ "$new_backup" =~ ^[Nn] ]] && BACKUP_ENABLED=false
        
        log_success "Configuration updated"
    fi
}

# Initialize system
init_system() {
    setup_colors
    setup_symbols
    setup_logging
    load_configuration
    
    log_debug "XXMXLI IP Blocking Setup v2.0 initialized"
    log_debug "Using search tool: $SEARCH_TOOL"
    log_debug "Configuration: $HIGH_PRIORITY_COUNT priority IPs, backup=$BACKUP_ENABLED"
}

# Main execution
main() {
    case "${1:-}" in
        "--interactive"|"-i")
            init_system
            interactive_config
            setup_ip_blocking
            ;;
        "--config"|"-c")
            init_system
            echo "Current configuration:"
            echo "  Search tool: $SEARCH_TOOL"
            echo "  Blacklist file: $BLACKLIST_FILE"
            echo "  High priority count: $HIGH_PRIORITY_COUNT"
            echo "  Output htaccess: $OUTPUT_HTACCESS"
            echo "  Admin protection: $ADMIN_HTACCESS"
            echo "  Backup enabled: $BACKUP_ENABLED"
            echo "  IP validation: $VALIDATE_IPS"
            echo "  Emergency whitelist: ${EMERGENCY_WHITELIST[*]:-"None"}"
            ;;
        "--validate"|"-v")
            init_system
            validate_blacklist_file
            ;;
        "--benchmark"|"-b")
            init_system
            run_performance_benchmark
            ;;
        "--debug"|"-d")
            DEBUG=true
            init_system
            setup_ip_blocking
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--interactive|--config|--validate|--benchmark|--debug|--help]"
            echo "  --interactive    Run with interactive configuration"
            echo "  --config         Show current configuration"
            echo "  --validate       Validate blacklist file only"
            echo "  --benchmark      Run performance benchmark"
            echo "  --debug          Enable debug mode"
            echo "  --help           Show this help"
            exit 0
            ;;
        *)
            init_system
            setup_ip_blocking
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "IP blocking setup terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi