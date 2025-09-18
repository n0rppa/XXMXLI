#!/bin/bash

# ================================================================
# XXMXLI OPTIMIZED SAFE IP BLOCKING DEPLOYMENT v2.0
# Enhanced Performance • Better Error Handling • Configuration Support
# ================================================================

# Security warning
echo "🛡️  SECURITY WARNING: This system is actively monitored and protected."
echo "Any unauthorized access attempts will be logged and reported to authorities."

# Script directory and configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
CONFIG_FILE="$CONFIG_DIR/ip_deployment.conf"
CONFIG_JSON="$CONFIG_DIR/ip_deployment.json"

# Performance optimization: Use faster tools when available
SEARCH_TOOL="grep"
if command -v rg >/dev/null 2>&1; then
    SEARCH_TOOL="rg"
elif command -v ag >/dev/null 2>&1; then
    SEARCH_TOOL="ag"
elif command -v awk >/dev/null 2>&1; then
    SEARCH_TOOL="awk"
fi

# Enhanced error handling
set -euo pipefail

# Trap for cleanup
cleanup() {
    local exit_code=$?
    [[ $exit_code -ne 0 ]] && log_error "Script terminated with error (code: $exit_code)"
    exit $exit_code
}
trap cleanup EXIT INT TERM

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
        STAR="⭐"
        INFO="ℹ️"
        FIRE="🔥"
        LIGHTNING="⚡"
        WRENCH="🔧"
        HAMMER="🔨"
        TARGET="🎯"
        MAGNIFY="🔍"
        CHART="📊"
        FOLDER="📁"
        LOCK="🔐"
        KEY="🔑"
        BACKUP="💾"
        DEPLOY="🚀"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        ARROW=">"
        SHIELD="[S]"
        GEAR="[G]"
        ROCKET="[R]"
        STAR="[*]"
        INFO="[i]"
        FIRE="[F]"
        LIGHTNING="[L]"
        WRENCH="[W]"
        HAMMER="[H]"
        TARGET="[T]"
        MAGNIFY="[?]"
        CHART="[C]"
        FOLDER="[F]"
        LOCK="[L]"
        KEY="[K]"
        BACKUP="[B]"
        DEPLOY="[D]"
    fi
}

# Configuration loading with validation
load_configuration() {
    # Default values
    INTERACTIVE_MODE=true
    BACKUP_ENABLED=true
    VERIFICATION_ENABLED=true
    AUTO_RESTORE_ON_FAILURE=true
    MAX_IPS_TO_DEPLOY=1000
    DEPLOYMENT_TIMEOUT=60
    BLACKLIST_FILE="assets/security/blocked_ips.json"
    MAIN_HTACCESS=".htaccess"
    ADMIN_HTACCESS="admin/.htaccess"
    ADMIN_BLOCKS="admin/.htaccess_ip_blocks"
    EMERGENCY_CONTACT=""
    NOTIFICATION_ENABLED=false
    
    # Try JSON configuration first
    if [[ -f "$CONFIG_JSON" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
            INTERACTIVE_MODE=$(jq -r '.deployment.interactive_mode // true' "$CONFIG_JSON" 2>/dev/null)
            BACKUP_ENABLED=$(jq -r '.deployment.backup_enabled // true' "$CONFIG_JSON" 2>/dev/null)
            VERIFICATION_ENABLED=$(jq -r '.deployment.verification_enabled // true' "$CONFIG_JSON" 2>/dev/null)
            AUTO_RESTORE_ON_FAILURE=$(jq -r '.deployment.auto_restore_on_failure // true' "$CONFIG_JSON" 2>/dev/null)
            MAX_IPS_TO_DEPLOY=$(jq -r '.limits.max_ips_to_deploy // 1000' "$CONFIG_JSON" 2>/dev/null)
            DEPLOYMENT_TIMEOUT=$(jq -r '.limits.deployment_timeout // 60' "$CONFIG_JSON" 2>/dev/null)
            
            BLACKLIST_FILE=$(jq -r '.files.blacklist_file // "assets/security/blocked_ips.json"' "$CONFIG_JSON" 2>/dev/null)
            MAIN_HTACCESS=$(jq -r '.files.main_htaccess // ".htaccess"' "$CONFIG_JSON" 2>/dev/null)
            ADMIN_HTACCESS=$(jq -r '.files.admin_htaccess // "admin/.htaccess"' "$CONFIG_JSON" 2>/dev/null)
            ADMIN_BLOCKS=$(jq -r '.files.admin_blocks // "admin/.htaccess_ip_blocks"' "$CONFIG_JSON" 2>/dev/null)
            
            EMERGENCY_CONTACT=$(jq -r '.notifications.emergency_contact // ""' "$CONFIG_JSON" 2>/dev/null)
            NOTIFICATION_ENABLED=$(jq -r '.notifications.enabled // false' "$CONFIG_JSON" 2>/dev/null)
            
            log_debug "Configuration loaded from JSON"
        fi
    # Fallback to .conf file
    elif [[ -f "$CONFIG_FILE" ]]; then
        if source "$CONFIG_FILE" 2>/dev/null; then
            log_debug "Configuration loaded from .conf file"
        fi
    fi
    
    # Generate timestamp for this deployment
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="backups_$TIMESTAMP"
}

# Enhanced logging setup
setup_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    DEPLOYMENT_LOG="$LOG_DIR/ip_deployment.log"
    ERROR_LOG="$LOG_DIR/ip_deployment_errors.log"
    AUDIT_LOG="$LOG_DIR/ip_deployment_audit.log"
    
    # Log rotation
    for log_file in "$DEPLOYMENT_LOG" "$ERROR_LOG" "$AUDIT_LOG"; do
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
        echo "[DEBUG $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$DEPLOYMENT_LOG" 2>/dev/null
    }
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    echo "[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$DEPLOYMENT_LOG" 2>/dev/null
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    echo "[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$DEPLOYMENT_LOG" 2>/dev/null
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1" >&2
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$DEPLOYMENT_LOG" 2>/dev/null
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1" >&2
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$ERROR_LOG" 2>/dev/null
}

log_audit() {
    echo "[AUDIT $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$AUDIT_LOG" 2>/dev/null
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
    ║    ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗       ║
    ║    ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝       ║
    ║    ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝        ║
    ║    ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝         ║
    ║    ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║          ║
    ║    ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝          ║
    ║                                                              ║
    ║         OPTIMIZED SAFE IP BLOCKING DEPLOYMENT v2.0          ║
    ║        Enhanced Performance • Better Error Handling         ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}    ${SHIELD} Professional Security • ${DEPLOY} Automated Deployment${NC}"
    echo -e "${GREEN}    ${LIGHTNING} Using: $SEARCH_TOOL • Backup: $BACKUP_ENABLED${NC}"
    echo ""
}

# Enhanced environment check
check_environment() {
    log_info "Running comprehensive environment check..."
    
    local issues=0
    
    # Check if we're in the correct directory
    if [[ ! -f "index.html" ]] && [[ ! -f "CNAME" ]]; then
        log_error "Not in XXMXLI root directory (no index.html or CNAME found)"
        ((issues++))
    fi
    
    # Check for blacklist file
    if [[ ! -f "$BLACKLIST_FILE" ]]; then
        log_error "Blacklist file not found: $BLACKLIST_FILE"
        ((issues++))
    else
        # Validate JSON format
        if command -v jq >/dev/null 2>&1; then
            if ! jq -e . "$BLACKLIST_FILE" >/dev/null 2>&1; then
                log_error "Invalid JSON format in blacklist file"
                ((issues++))
            else
                local ip_count
                ip_count=$(jq -r '. | length' "$BLACKLIST_FILE" 2>/dev/null || echo 0)
                
                if [[ ${ip_count:-0} -eq 0 ]]; then
                    log_warning "Blacklist file is empty"
                elif [[ ${ip_count:-0} -gt $MAX_IPS_TO_DEPLOY ]]; then
                    log_warning "IP count ($ip_count) exceeds maximum ($MAX_IPS_TO_DEPLOY)"
                else
                    log_success "Found $ip_count IPs in blacklist"
                fi
            fi
        fi
    fi
    
    # Check admin directory
    if [[ ! -d "admin" ]]; then
        log_warning "Admin directory not found - admin protection will be skipped"
    else
        log_success "Admin directory found"
    fi
    
    # Check write permissions
    if [[ ! -w "." ]]; then
        log_error "No write permissions in current directory"
        ((issues++))
    fi
    
    # Check backup directory creation
    if ! mkdir -p "$BACKUP_DIR" 2>/dev/null; then
        log_error "Cannot create backup directory: $BACKUP_DIR"
        ((issues++))
    else
        log_success "Backup directory ready: $BACKUP_DIR"
    fi
    
    # Check dependencies
    local required_tools=("jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_warning "Optional tool not found: $tool"
        fi
    done
    
    if [[ $issues -gt 0 ]]; then
        log_error "Environment check failed with $issues issues"
        return 1
    fi
    
    log_success "Environment check passed"
    return 0
}

# Enhanced IP validation
validate_ip() {
    local ip="$1"
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$'
    
    if [[ $ip =~ $ip_regex ]]; then
        # Check for valid octets
        local IFS='.' parts=($ip)
        for part in "${parts[@]}"; do
            local octet=${part%%/*}  # Remove CIDR notation if present
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Enhanced backup creation with validation
create_backup() {
    log_info "Creating comprehensive backup..."
    
    local backup_files=0
    local backup_size=0
    
    # Create backup directory structure
    mkdir -p "$BACKUP_DIR"/{htaccess,config,logs}
    
    # Backup existing .htaccess files
    if [[ -f "$MAIN_HTACCESS" ]]; then
        cp "$MAIN_HTACCESS" "$BACKUP_DIR/htaccess/"
        local size=$(stat -f%z "$MAIN_HTACCESS" 2>/dev/null || stat -c%s "$MAIN_HTACCESS" 2>/dev/null || echo 0)
        backup_size=$((backup_size + size))
        ((backup_files++))
        log_success "Backed up main .htaccess (${size} bytes)"
    fi
    
    if [[ -f "$ADMIN_HTACCESS" ]]; then
        cp "$ADMIN_HTACCESS" "$BACKUP_DIR/htaccess/"
        local size=$(stat -f%z "$ADMIN_HTACCESS" 2>/dev/null || stat -c%s "$ADMIN_HTACCESS" 2>/dev/null || echo 0)
        backup_size=$((backup_size + size))
        ((backup_files++))
        log_success "Backed up admin .htaccess (${size} bytes)"
    fi
    
    if [[ -f "$ADMIN_BLOCKS" ]]; then
        cp "$ADMIN_BLOCKS" "$BACKUP_DIR/htaccess/"
        local size=$(stat -f%z "$ADMIN_BLOCKS" 2>/dev/null || stat -c%s "$ADMIN_BLOCKS" 2>/dev/null || echo 0)
        backup_size=$((backup_size + size))
        ((backup_files++))
        log_success "Backed up admin IP blocks (${size} bytes)"
    fi
    
    # Backup current configuration
    [[ -f "$CONFIG_JSON" ]] && cp "$CONFIG_JSON" "$BACKUP_DIR/config/"
    [[ -f "$CONFIG_FILE" ]] && cp "$CONFIG_FILE" "$BACKUP_DIR/config/"
    
    # Create comprehensive backup metadata
    cat > "$BACKUP_DIR/backup_info.json" << EOF
{
    "backup_info": {
        "created": "$(date -Iseconds)",
        "timestamp": "$TIMESTAMP",
        "directory": "$BACKUP_DIR",
        "script_version": "XXMXLI Optimized IP Deployment v2.0",
        "search_tool": "$SEARCH_TOOL",
        "configuration": {
            "interactive_mode": $INTERACTIVE_MODE,
            "backup_enabled": $BACKUP_ENABLED,
            "verification_enabled": $VERIFICATION_ENABLED,
            "max_ips_to_deploy": $MAX_IPS_TO_DEPLOY
        }
    },
    "backed_up_files": {
        "count": $backup_files,
        "total_size_bytes": $backup_size,
        "files": [
EOF

    # Add file list
    local first=true
    for file in "$BACKUP_DIR/htaccess"/*; do
        [[ -f "$file" ]] || continue
        [[ "$first" == "true" ]] && first=false || echo "," >> "$BACKUP_DIR/backup_info.json"
        local filename=$(basename "$file")
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        echo -n "            {\"name\": \"$filename\", \"size\": $size}" >> "$BACKUP_DIR/backup_info.json"
    done
    
    cat >> "$BACKUP_DIR/backup_info.json" << EOF

        ]
    },
    "restore_command": "./$(basename "$0") --restore $BACKUP_DIR"
}
EOF

    # Create simple restore script
    cat > "$BACKUP_DIR/restore.sh" << EOF
#!/bin/bash
# XXMXLI Backup Restore Script
# Created: $(date)

set -euo pipefail

echo "Restoring XXMXLI IP deployment backup from $BACKUP_DIR"
echo "========================================================"

EOF

    if [[ -f "$BACKUP_DIR/htaccess/.htaccess" ]]; then
        echo "cp \"$BACKUP_DIR/htaccess/.htaccess\" \"$MAIN_HTACCESS\"" >> "$BACKUP_DIR/restore.sh"
    fi
    
    if [[ -f "$BACKUP_DIR/htaccess/admin/.htaccess" ]]; then
        echo "cp \"$BACKUP_DIR/htaccess/admin/.htaccess\" \"$ADMIN_HTACCESS\"" >> "$BACKUP_DIR/restore.sh"
    fi
    
    echo "echo \"Backup restored successfully!\"" >> "$BACKUP_DIR/restore.sh"
    chmod +x "$BACKUP_DIR/restore.sh"
    
    log_audit "Backup created: $backup_files files, $backup_size bytes, directory: $BACKUP_DIR"
    log_success "Backup created: $backup_files files ($((backup_size / 1024))KB) in $BACKUP_DIR"
    
    return 0
}

# Enhanced IP deployment with validation
deploy_ip_blocks() {
    log_info "Deploying IP blocking rules with validation..."
    
    if [[ ! -f "$BLACKLIST_FILE" ]]; then
        log_error "Blacklist file not found: $BLACKLIST_FILE"
        return 1
    fi
    
    local deployed_ips=0
    local invalid_ips=0
    
    # Deploy main site blocking
    log_debug "Generating main site .htaccess"
    
    {
        echo "# ================================================================"
        echo "# XXMXLI OPTIMIZED SERVER-SIDE IP BLOCKING"
        echo "# ================================================================"
        echo "# Generated: $(date -Iseconds)"
        echo "# Backup: $BACKUP_DIR"
        echo "# Search tool: $SEARCH_TOOL"
        echo "# Configuration: $(basename "$CONFIG_JSON")"
        echo ""
        echo "RewriteEngine On"
        echo ""
        echo "# Performance optimization"
        echo "RewriteOptions MaxRedirects=1"
        echo ""
        echo "# IP blocking section"
        echo "<RequireAll>"
        echo "    Require all granted"
        echo ""
    } > "$MAIN_HTACCESS"
    
    # Process IPs with validation
    if command -v jq >/dev/null 2>&1; then
        # Use jq for JSON processing
        while IFS= read -r ip; do
            if validate_ip "$ip"; then
                echo "    Require not ip $ip" >> "$MAIN_HTACCESS"
                ((deployed_ips++))
                
                # Log every 100 IPs for progress
                if [[ $((deployed_ips % 100)) -eq 0 ]]; then
                    log_debug "Processed $deployed_ips IPs..."
                fi
                
                # Safety limit
                if [[ $deployed_ips -ge $MAX_IPS_TO_DEPLOY ]]; then
                    log_warning "Reached maximum IP limit ($MAX_IPS_TO_DEPLOY)"
                    break
                fi
            else
                log_warning "Invalid IP format skipped: $ip"
                ((invalid_ips++))
            fi
        done < <(jq -r '.[] // empty' "$BLACKLIST_FILE" 2>/dev/null)
    else
        # Fallback to grep/awk for IP extraction
        log_warning "jq not available, using fallback IP extraction"
        case "$SEARCH_TOOL" in
            "rg")
                while IFS= read -r line; do
                    local ip=$(echo "$line" | rg -o '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
                    [[ -n "$ip" ]] && validate_ip "$ip" && {
                        echo "    Require not ip $ip" >> "$MAIN_HTACCESS"
                        ((deployed_ips++))
                    }
                done < "$BLACKLIST_FILE"
                ;;
            *)
                while IFS= read -r line; do
                    local ip=$(echo "$line" | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | head -1)
                    [[ -n "$ip" ]] && validate_ip "$ip" && {
                        echo "    Require not ip $ip" >> "$MAIN_HTACCESS"
                        ((deployed_ips++))
                    }
                done < "$BLACKLIST_FILE"
                ;;
        esac
    fi
    
    # Complete .htaccess file
    {
        echo ""
        echo "</RequireAll>"
        echo ""
        echo "# Enhanced security rules"
        echo "RewriteCond %{HTTP_USER_AGENT} \"^$\" [OR]"
        echo "RewriteCond %{HTTP_USER_AGENT} \"(bot|crawler|spider|scraper|hack|scan|vuln)\" [NC]"
        echo "RewriteRule .* /blocked.html [R=403,L]"
        echo ""
        echo "# Performance and security footer"
        echo "Header always set X-Frame-Options \"DENY\""
        echo "Header always set X-Content-Type-Options \"nosniff\""
        echo ""
        echo "# Deployment stats:"
        echo "# Deployed IPs: $deployed_ips"
        echo "# Invalid IPs skipped: $invalid_ips"
        echo "# Generated by: XXMXLI Optimized Deployment v2.0"
    } >> "$MAIN_HTACCESS"
    
    log_success "Main site deployment: $deployed_ips IPs deployed"
    
    # Deploy admin protection if directory exists
    if [[ -d "admin" ]]; then
        log_debug "Generating admin protection"
        
        {
            echo "# ================================================================"
            echo "# XXMXLI OPTIMIZED ADMIN IP PROTECTION"
            echo "# ================================================================"
            echo "# Generated: $(date -Iseconds)"
            echo ""
            echo "AuthType Basic"
            echo "AuthName \"XXMXLI Admin Access - Authorized Personnel Only\""
            echo "AuthUserFile $(realpath admin)/.htpasswd"
            echo ""
            echo "<RequireAll>"
            echo "    Require valid-user"
            echo ""
        } > "$ADMIN_HTACCESS"
        
        # Copy IP blocks to admin (first 500 for performance)
        local admin_ips=0
        if command -v jq >/dev/null 2>&1; then
            while IFS= read -r ip && [[ $admin_ips -lt 500 ]]; do
                if validate_ip "$ip"; then
                    echo "    Require not ip $ip" >> "$ADMIN_HTACCESS"
                    ((admin_ips++))
                fi
            done < <(jq -r '.[] // empty' "$BLACKLIST_FILE" 2>/dev/null)
        fi
        
        {
            echo ""
            echo "</RequireAll>"
            echo ""
            echo "# Enhanced admin security"
            echo "<Files \"*.php\">"
            echo "    <RequireAll>"
            echo "        Require valid-user"
            echo "    </RequireAll>"
            echo "</Files>"
            echo ""
            echo "# Admin deployment stats: $admin_ips IPs"
        } >> "$ADMIN_HTACCESS"
        
        log_success "Admin protection deployed: $admin_ips IPs"
    fi
    
    log_audit "Deployment completed: $deployed_ips main IPs, $invalid_ips invalid IPs skipped"
    return 0
}

# Enhanced verification with detailed checks
verify_deployment() {
    [[ "$VERIFICATION_ENABLED" != "true" ]] && return 0
    
    log_info "Running comprehensive deployment verification..."
    
    local issues=0
    
    # Check main .htaccess
    if [[ -f "$MAIN_HTACCESS" ]]; then
        if grep -q "XXMXLI OPTIMIZED SERVER-SIDE IP BLOCKING" "$MAIN_HTACCESS"; then
            local ip_count
            ip_count=$(grep -c "Require not ip" "$MAIN_HTACCESS" || echo 0)
            log_success "Main .htaccess verified: $ip_count IPs deployed"
            
            # Check for syntax errors (basic)
            if grep -q "RewriteEngine On" "$MAIN_HTACCESS" && grep -q "</RequireAll>" "$MAIN_HTACCESS"; then
                log_success "Main .htaccess syntax appears valid"
            else
                log_error "Main .htaccess syntax issues detected"
                ((issues++))
            fi
        else
            log_error "Main .htaccess deployment signature not found"
            ((issues++))
        fi
    else
        log_error "Main .htaccess file not found after deployment"
        ((issues++))
    fi
    
    # Check admin .htaccess if admin directory exists
    if [[ -d "admin" ]]; then
        if [[ -f "$ADMIN_HTACCESS" ]]; then
            if grep -q "XXMXLI OPTIMIZED ADMIN IP PROTECTION" "$ADMIN_HTACCESS"; then
                local admin_ip_count
                admin_ip_count=$(grep -c "Require not ip" "$ADMIN_HTACCESS" || echo 0)
                log_success "Admin .htaccess verified: $admin_ip_count IPs deployed"
            else
                log_error "Admin .htaccess deployment signature not found"
                ((issues++))
            fi
        else
            log_error "Admin .htaccess file not found after deployment"
            ((issues++))
        fi
    fi
    
    # Check backup integrity
    if [[ -f "$BACKUP_DIR/backup_info.json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq -e . "$BACKUP_DIR/backup_info.json" >/dev/null 2>&1; then
                log_success "Backup metadata verified"
            else
                log_warning "Backup metadata corrupted"
            fi
        fi
        
        if [[ -x "$BACKUP_DIR/restore.sh" ]]; then
            log_success "Backup restore script ready"
        else
            log_warning "Backup restore script not executable"
        fi
    else
        log_warning "Backup metadata not found"
    fi
    
    if [[ $issues -eq 0 ]]; then
        log_success "Deployment verification passed"
        return 0
    else
        log_error "Deployment verification failed with $issues issues"
        
        if [[ "$AUTO_RESTORE_ON_FAILURE" == "true" ]]; then
            log_warning "Auto-restore enabled, attempting rollback..."
            restore_from_backup_auto
        fi
        
        return 1
    fi
}

# Auto-restore function
restore_from_backup_auto() {
    log_info "Performing automatic restore from backup..."
    
    if [[ -x "$BACKUP_DIR/restore.sh" ]]; then
        if "$BACKUP_DIR/restore.sh"; then
            log_success "Automatic restore completed"
            return 0
        else
            log_error "Automatic restore failed"
            return 1
        fi
    else
        log_error "No restore script found in backup"
        return 1
    fi
}

# Interactive menu system
show_interactive_menu() {
    show_banner
    
    echo -e "${WHITE}${GEAR} OPTIMIZED DEPLOYMENT OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${SHIELD} Safe Deploy (Recommended - with backups)"
    echo -e "${GREEN}2)${NC} ${CHART} Check Current Status"
    echo -e "${GREEN}3)${NC} ${ROCKET} Quick Deploy (Automated)"
    echo -e "${GREEN}4)${NC} ${BACKUP} Restore from Backup"
    echo -e "${GREEN}5)${NC} ${MAGNIFY} View Deployment Log"
    echo -e "${GREEN}6)${NC} ${WARNING} Emergency Rollback"
    echo -e "${GREEN}7)${NC} ${WRENCH} Advanced Options"
    echo -e "${GREEN}8)${NC} ${GEAR} Configuration Status"
    echo -e "${GREEN}9)${NC} ${LIGHTNING} Performance Benchmark"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    echo "================================================================"
    
    local choice
    read -p "$(echo -e "${CYAN}Choose option [0-9]:${NC} ")" choice
    
    case "$choice" in
        1) safe_deploy_blocking ;;
        2) check_deployment_status ;;
        3) quick_deploy ;;
        4) restore_from_backup_interactive ;;
        5) view_deployment_log ;;
        6) emergency_rollback ;;
        7) advanced_options ;;
        8) show_configuration_status ;;
        9) run_performance_benchmark ;;
        0) exit_program ;;
        *) 
            log_error "Invalid option: $choice"
            sleep 1
            show_interactive_menu
            ;;
    esac
}

# Safe deployment with user interaction
safe_deploy_blocking() {
    show_banner
    echo -e "${PURPLE}${SHIELD} SAFE IP BLOCKING DEPLOYMENT${NC}"
    echo "================================================================"
    echo ""
    
    # Pre-deployment checks
    if ! check_environment; then
        echo ""
        read -p "Environment check failed. Continue anyway? (y/N): " continue_anyway
        [[ ! "$continue_anyway" =~ ^[Yy]$ ]] && {
            show_interactive_menu
            return
        }
    fi
    
    # Show deployment preview
    if [[ -f "$BLACKLIST_FILE" ]] && command -v jq >/dev/null 2>&1; then
        local ip_count
        ip_count=$(jq -r '. | length' "$BLACKLIST_FILE" 2>/dev/null || echo "unknown")
        
        echo "Deployment preview:"
        echo "  Blacklist file: $BLACKLIST_FILE"
        echo "  IPs to deploy: $ip_count"
        echo "  Max IPs allowed: $MAX_IPS_TO_DEPLOY"
        echo "  Search tool: $SEARCH_TOOL"
        echo "  Backup enabled: $BACKUP_ENABLED"
        echo "  Verification enabled: $VERIFICATION_ENABLED"
        echo ""
    fi
    
    echo -e "${YELLOW}${WARNING} This will modify your web server configuration${NC}"
    echo "Files that will be modified:"
    echo "  - $MAIN_HTACCESS (main site blocking)"
    [[ -d "admin" ]] && echo "  - $ADMIN_HTACCESS (admin protection)"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Do you want to continue? [y/N]:${NC} ")" confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && {
        log_info "Deployment cancelled by user"
        show_interactive_menu
        return
    }
    
    # Execute deployment
    local start_time=$(date +%s)
    
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        create_backup || {
            log_error "Backup creation failed"
            read -p "Continue without backup? (y/N): " no_backup
            [[ ! "$no_backup" =~ ^[Yy]$ ]] && {
                show_interactive_menu
                return
            }
        }
    fi
    
    if deploy_ip_blocks; then
        if verify_deployment; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            echo ""
            log_success "IP blocking deployment completed successfully!"
            log_info "Deployment took ${duration}s"
            log_audit "Safe deployment completed successfully in ${duration}s"
        else
            log_error "Deployment verification failed"
        fi
    else
        log_error "IP deployment failed"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Quick automated deployment
quick_deploy() {
    show_banner
    echo -e "${ROCKET}${DEPLOY} QUICK DEPLOYMENT MODE${NC}"
    echo "================================================================"
    echo ""
    
    log_info "Running automated deployment..."
    
    local start_time=$(date +%s)
    
    if check_environment && create_backup && deploy_ip_blocks && verify_deployment; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        log_success "Quick deployment completed in ${duration}s!"
        log_audit "Quick deployment completed successfully in ${duration}s"
    else
        log_error "Quick deployment failed"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Check deployment status
check_deployment_status() {
    echo -e "${PURPLE}${CHART} DEPLOYMENT STATUS CHECK${NC}"
    echo "================================================================"
    echo ""
    
    log_info "Checking current deployment status..."
    
    # Check main .htaccess
    if [[ -f "$MAIN_HTACCESS" ]]; then
        if grep -q "XXMXLI" "$MAIN_HTACCESS"; then
            local ip_count
            ip_count=$(grep -c "Require not ip" "$MAIN_HTACCESS" || echo 0)
            local file_size=$(stat -f%z "$MAIN_HTACCESS" 2>/dev/null || stat -c%s "$MAIN_HTACCESS" 2>/dev/null || echo 0)
            
            log_success "Main .htaccess: DEPLOYED ($ip_count IPs, ${file_size} bytes)"
            
            # Check last modification
            local mod_time
            mod_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$MAIN_HTACCESS" 2>/dev/null || stat -c "%y" "$MAIN_HTACCESS" 2>/dev/null || echo "unknown")
            echo "  Last modified: $mod_time"
        else
            log_warning "Main .htaccess: EXISTS but not XXMXLI deployment"
        fi
    else
        log_warning "Main .htaccess: NOT FOUND"
    fi
    
    # Check admin .htaccess
    if [[ -d "admin" ]]; then
        if [[ -f "$ADMIN_HTACCESS" ]]; then
            if grep -q "XXMXLI" "$ADMIN_HTACCESS"; then
                local admin_ip_count
                admin_ip_count=$(grep -c "Require not ip" "$ADMIN_HTACCESS" || echo 0)
                log_success "Admin .htaccess: DEPLOYED ($admin_ip_count IPs)"
            else
                log_warning "Admin .htaccess: EXISTS but not XXMXLI deployment"
            fi
        else
            log_warning "Admin .htaccess: NOT FOUND"
        fi
    else
        log_info "Admin directory: NOT FOUND"
    fi
    
    # Check blacklist file status
    if [[ -f "$BLACKLIST_FILE" ]]; then
        if command -v jq >/dev/null 2>&1; then
            local total_ips
            total_ips=$(jq -r '. | length' "$BLACKLIST_FILE" 2>/dev/null || echo "unknown")
            log_success "Blacklist file: $total_ips IPs available"
        else
            log_info "Blacklist file: EXISTS (jq not available for count)"
        fi
    else
        log_error "Blacklist file: NOT FOUND ($BLACKLIST_FILE)"
    fi
    
    # Check recent backups
    local backup_count
    backup_count=$(find . -maxdepth 1 -name "backups_*" -type d | wc -l)
    if [[ ${backup_count:-0} -gt 0 ]]; then
        log_success "Available backups: $backup_count"
        find . -maxdepth 1 -name "backups_*" -type d | head -5 | while read -r backup_dir; do
            local backup_date=$(echo "$backup_dir" | sed 's/.*backups_//')
            echo "  - $backup_dir ($backup_date)"
        done
    else
        log_warning "No backups found"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Interactive backup restore
restore_from_backup_interactive() {
    echo -e "${PURPLE}${BACKUP} RESTORE FROM BACKUP${NC}"
    echo "================================================================"
    echo ""
    
    # Find available backups
    local backups=()
    while IFS= read -r -d '' backup_dir; do
        backups+=("$backup_dir")
    done < <(find . -maxdepth 1 -name "backups_*" -type d -print0 | sort -z)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_error "No backups found"
        read -p "Press Enter to return to menu..."
        show_interactive_menu
        return
    fi
    
    echo "Available backups:"
    local i=1
    for backup in "${backups[@]}"; do
        local backup_date=$(echo "$backup" | sed 's/.*backups_//')
        local backup_info=""
        
        if [[ -f "$backup/backup_info.json" ]] && command -v jq >/dev/null 2>&1; then
            local file_count
            file_count=$(jq -r '.backed_up_files.count // "unknown"' "$backup/backup_info.json" 2>/dev/null)
            backup_info=" ($file_count files)"
        fi
        
        echo "  $i) $backup ($backup_date)$backup_info"
        ((i++))
    done
    
    echo ""
    read -p "Select backup to restore [1-${#backups[@]}]: " backup_choice
    
    if [[ "$backup_choice" =~ ^[0-9]+$ ]] && [[ $backup_choice -ge 1 ]] && [[ $backup_choice -le ${#backups[@]} ]]; then
        local selected_backup="${backups[$((backup_choice - 1))]}"
        
        echo ""
        log_warning "This will overwrite current .htaccess files"
        read -p "Are you sure you want to restore from $selected_backup? (y/N): " confirm_restore
        
        if [[ "$confirm_restore" =~ ^[Yy]$ ]]; then
            if [[ -x "$selected_backup/restore.sh" ]]; then
                log_info "Restoring from $selected_backup..."
                
                if "$selected_backup/restore.sh"; then
                    log_success "Restore completed successfully!"
                    log_audit "Manual restore completed from $selected_backup"
                else
                    log_error "Restore failed"
                fi
            else
                log_error "Restore script not found or not executable"
            fi
        else
            log_info "Restore cancelled"
        fi
    else
        log_error "Invalid backup selection"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# View deployment logs
view_deployment_log() {
    echo -e "${PURPLE}${MAGNIFY} DEPLOYMENT LOGS${NC}"
    echo "================================================================"
    echo ""
    
    local log_files=("$DEPLOYMENT_LOG" "$ERROR_LOG" "$AUDIT_LOG")
    local log_names=("Deployment" "Errors" "Audit")
    
    echo "Available logs:"
    local i=1
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            local size=$(stat -f%z "$log_file" 2>/dev/null || stat -c%s "$log_file" 2>/dev/null || echo 0)
            local lines=$(wc -l < "$log_file" 2>/dev/null || echo 0)
            echo "  $i) ${log_names[$((i-1))]} log ($lines lines, $((size / 1024))KB)"
        else
            echo "  $i) ${log_names[$((i-1))]} log (not found)"
        fi
        ((i++))
    done
    
    echo ""
    read -p "Select log to view [1-3], or Enter to return: " log_choice
    
    if [[ "$log_choice" =~ ^[1-3]$ ]]; then
        local selected_log="${log_files[$((log_choice - 1))]}"
        
        if [[ -f "$selected_log" ]]; then
            echo ""
            echo "=== ${log_names[$((log_choice - 1))]} Log ==="
            tail -50 "$selected_log"
            echo ""
            read -p "Press Enter to continue..."
        else
            log_error "Log file not found: $selected_log"
            read -p "Press Enter to continue..."
        fi
    fi
    
    show_interactive_menu
}

# Emergency rollback
emergency_rollback() {
    echo -e "${RED}${WARNING} EMERGENCY ROLLBACK${NC}"
    echo "================================================================"
    echo ""
    
    log_warning "This will attempt to restore the most recent backup"
    echo ""
    
    # Find most recent backup
    local latest_backup
    latest_backup=$(find . -maxdepth 1 -name "backups_*" -type d | sort | tail -1)
    
    if [[ -n "$latest_backup" ]]; then
        echo "Latest backup found: $latest_backup"
        
        if [[ -f "$latest_backup/backup_info.json" ]] && command -v jq >/dev/null 2>&1; then
            local backup_date
            backup_date=$(jq -r '.backup_info.created // "unknown"' "$latest_backup/backup_info.json" 2>/dev/null)
            echo "Backup created: $backup_date"
        fi
        
        echo ""
        read -p "$(echo -e "${RED}Proceed with emergency rollback? (y/N):${NC} ")" emergency_confirm
        
        if [[ "$emergency_confirm" =~ ^[Yy]$ ]]; then
            if [[ -x "$latest_backup/restore.sh" ]]; then
                log_info "Executing emergency rollback..."
                
                if "$latest_backup/restore.sh"; then
                    log_success "Emergency rollback completed!"
                    log_audit "Emergency rollback completed from $latest_backup"
                else
                    log_error "Emergency rollback failed"
                fi
            else
                log_error "Restore script not found in backup"
            fi
        else
            log_info "Emergency rollback cancelled"
        fi
    else
        log_error "No backups found for emergency rollback"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Advanced options menu
advanced_options() {
    echo -e "${PURPLE}${WRENCH} ADVANCED OPTIONS${NC}"
    echo "================================================================"
    echo ""
    
    echo "1) Force deploy without validation"
    echo "2) Deploy specific IP count only"
    echo "3) Clean old backups"
    echo "4) Validate configuration"
    echo "5) Export deployment report"
    echo "6) Return to main menu"
    echo ""
    
    read -p "Select advanced option [1-6]: " advanced_choice
    
    case "$advanced_choice" in
        1)
            log_warning "Force deployment mode - validation disabled"
            VERIFICATION_ENABLED=false
            safe_deploy_blocking
            ;;
        2)
            read -p "Enter maximum IPs to deploy: " custom_ip_count
            if [[ "$custom_ip_count" =~ ^[0-9]+$ ]]; then
                MAX_IPS_TO_DEPLOY="$custom_ip_count"
                log_info "IP limit set to $MAX_IPS_TO_DEPLOY"
                safe_deploy_blocking
            else
                log_error "Invalid IP count"
            fi
            ;;
        3)
            clean_old_backups
            ;;
        4)
            validate_configuration
            ;;
        5)
            export_deployment_report
            ;;
        6)
            show_interactive_menu
            ;;
        *)
            log_error "Invalid advanced option"
            advanced_options
            ;;
    esac
}

# Clean old backups
clean_old_backups() {
    echo ""
    log_info "Cleaning old backups..."
    
    local backup_count
    backup_count=$(find . -maxdepth 1 -name "backups_*" -type d | wc -l)
    
    if [[ ${backup_count:-0} -le 5 ]]; then
        log_info "Only $backup_count backups found, no cleanup needed"
    else
        echo "Found $backup_count backups, keeping newest 5..."
        
        # Remove oldest backups, keep 5 newest
        find . -maxdepth 1 -name "backups_*" -type d | sort | head -n -5 | while read -r old_backup; do
            log_info "Removing old backup: $old_backup"
            rm -rf "$old_backup"
        done
        
        log_success "Backup cleanup completed"
    fi
    
    read -p "Press Enter to continue..."
    advanced_options
}

# Validate configuration
validate_configuration() {
    echo ""
    log_info "Validating configuration..."
    
    local config_issues=0
    
    # Check configuration file
    if [[ -f "$CONFIG_JSON" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
                log_success "Configuration JSON is valid"
            else
                log_error "Configuration JSON is invalid"
                ((config_issues++))
            fi
        else
            log_warning "Cannot validate JSON (jq not available)"
        fi
    else
        log_info "No JSON configuration found (using defaults)"
    fi
    
    # Check blacklist file
    if [[ -f "$BLACKLIST_FILE" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq -e . "$BLACKLIST_FILE" >/dev/null 2>&1; then
                local ip_count
                ip_count=$(jq -r '. | length' "$BLACKLIST_FILE" 2>/dev/null || echo 0)
                log_success "Blacklist file valid: $ip_count IPs"
            else
                log_error "Blacklist file is invalid JSON"
                ((config_issues++))
            fi
        fi
    else
        log_error "Blacklist file not found: $BLACKLIST_FILE"
        ((config_issues++))
    fi
    
    # Check file permissions
    if [[ ! -w "." ]]; then
        log_error "No write permissions in current directory"
        ((config_issues++))
    else
        log_success "Directory is writable"
    fi
    
    echo ""
    if [[ $config_issues -eq 0 ]]; then
        log_success "Configuration validation passed"
    else
        log_error "Configuration validation failed: $config_issues issues"
    fi
    
    read -p "Press Enter to continue..."
    advanced_options
}

# Export deployment report
export_deployment_report() {
    echo ""
    log_info "Generating deployment report..."
    
    local report_file="deployment_report_$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$report_file" << EOF
{
    "deployment_report": {
        "generated": "$(date -Iseconds)",
        "script_version": "XXMXLI Optimized IP Deployment v2.0",
        "search_tool": "$SEARCH_TOOL",
        "configuration": {
            "interactive_mode": $INTERACTIVE_MODE,
            "backup_enabled": $BACKUP_ENABLED,
            "verification_enabled": $VERIFICATION_ENABLED,
            "max_ips_to_deploy": $MAX_IPS_TO_DEPLOY,
            "deployment_timeout": $DEPLOYMENT_TIMEOUT
        },
        "environment": {
            "working_directory": "$(pwd)",
            "blacklist_file": "$BLACKLIST_FILE",
            "main_htaccess": "$MAIN_HTACCESS",
            "admin_htaccess": "$ADMIN_HTACCESS"
        },
        "status": {
EOF

    # Add current status
    if [[ -f "$MAIN_HTACCESS" ]] && grep -q "XXMXLI" "$MAIN_HTACCESS"; then
        local ip_count
        ip_count=$(grep -c "Require not ip" "$MAIN_HTACCESS" || echo 0)
        echo "            \"main_deployment\": \"active\"," >> "$report_file"
        echo "            \"deployed_ips\": $ip_count," >> "$report_file"
    else
        echo "            \"main_deployment\": \"inactive\"," >> "$report_file"
        echo "            \"deployed_ips\": 0," >> "$report_file"
    fi
    
    local backup_count
    backup_count=$(find . -maxdepth 1 -name "backups_*" -type d | wc -l)
    echo "            \"available_backups\": $backup_count" >> "$report_file"
    
    cat >> "$report_file" << EOF
        }
    }
}
EOF

    log_success "Deployment report exported: $report_file"
    read -p "Press Enter to continue..."
    advanced_options
}

# Show configuration status
show_configuration_status() {
    echo -e "${PURPLE}${GEAR} CONFIGURATION STATUS${NC}"
    echo "================================================================"
    echo ""
    
    echo "Current configuration:"
    echo "  Search tool: $SEARCH_TOOL"
    echo "  Interactive mode: $INTERACTIVE_MODE"
    echo "  Backup enabled: $BACKUP_ENABLED"
    echo "  Verification enabled: $VERIFICATION_ENABLED"
    echo "  Auto-restore on failure: $AUTO_RESTORE_ON_FAILURE"
    echo "  Max IPs to deploy: $MAX_IPS_TO_DEPLOY"
    echo "  Deployment timeout: ${DEPLOYMENT_TIMEOUT}s"
    echo ""
    
    echo "File paths:"
    echo "  Blacklist file: $BLACKLIST_FILE"
    echo "  Main .htaccess: $MAIN_HTACCESS"
    echo "  Admin .htaccess: $ADMIN_HTACCESS"
    echo "  Admin blocks: $ADMIN_BLOCKS"
    echo ""
    
    echo "Configuration files:"
    [[ -f "$CONFIG_JSON" ]] && echo -e "${GREEN}  ✓ JSON: $CONFIG_JSON${NC}" || echo -e "${YELLOW}  - JSON: $CONFIG_JSON (not found)${NC}"
    [[ -f "$CONFIG_FILE" ]] && echo -e "${GREEN}  ✓ CONF: $CONFIG_FILE${NC}" || echo -e "${YELLOW}  - CONF: $CONFIG_FILE (not found)${NC}"
    echo ""
    
    echo "Log files:"
    [[ -f "$DEPLOYMENT_LOG" ]] && echo "  Deployment log: $DEPLOYMENT_LOG"
    [[ -f "$ERROR_LOG" ]] && echo "  Error log: $ERROR_LOG"
    [[ -f "$AUDIT_LOG" ]] && echo "  Audit log: $AUDIT_LOG"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Performance benchmark
run_performance_benchmark() {
    echo -e "${PURPLE}${LIGHTNING} PERFORMANCE BENCHMARK${NC}"
    echo "================================================================"
    echo ""
    
    log_info "Testing search tool performance..."
    
    local test_file="$BLACKLIST_FILE"
    [[ ! -f "$test_file" ]] && test_file="/etc/passwd"  # Fallback
    
    local search_tools=("grep" "awk")
    command -v rg >/dev/null 2>&1 && search_tools+=("rg")
    command -v ag >/dev/null 2>&1 && search_tools+=("ag")
    
    for tool in "${search_tools[@]}"; do
        local start_time=$(date +%s.%N)
        
        case "$tool" in
            "rg")
                run_with_timeout 5 rg -q "192.168" "$test_file" >/dev/null 2>&1
                ;;
            "ag")
                run_with_timeout 5 ag -l "192.168" "$test_file" >/dev/null 2>&1
                ;;
            "awk")
                run_with_timeout 5 awk '/192.168/ {found=1; exit} END {exit !found}' "$test_file" >/dev/null 2>&1
                ;;
            *)
                run_with_timeout 5 grep -q "192.168" "$test_file" >/dev/null 2>&1
                ;;
        esac
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        printf "${GREEN}${CHECK}${NC} %-10s: %.3fs\n" "$tool" "${duration:-0}"
    done
    
    echo ""
    log_success "Benchmark completed - currently using: $SEARCH_TOOL"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Exit program
exit_program() {
    echo -e "${CYAN}${INFO} Thank you for using XXMXLI Optimized IP Deployment${NC}"
    log_audit "User exited deployment system"
    exit 0
}

# Initialize system
init_system() {
    setup_colors
    setup_symbols
    setup_logging
    load_configuration
    
    log_debug "XXMXLI IP Deployment v2.0 initialized"
    log_debug "Using search tool: $SEARCH_TOOL"
    log_debug "Configuration: interactive=$INTERACTIVE_MODE, backup=$BACKUP_ENABLED, verification=$VERIFICATION_ENABLED"
}

# Main execution
main() {
    case "${1:-}" in
        "--deploy"|"-d")
            init_system
            INTERACTIVE_MODE=false
            check_environment && create_backup && deploy_ip_blocks && verify_deployment
            ;;
        "--quick"|"-q")
            init_system
            INTERACTIVE_MODE=false
            quick_deploy
            ;;
        "--status"|"-s")
            init_system
            check_deployment_status
            ;;
        "--restore")
            init_system
            if [[ -n "${2:-}" && -d "$2" ]]; then
                log_info "Restoring from specified backup: $2"
                if [[ -x "$2/restore.sh" ]]; then
                    "$2/restore.sh"
                else
                    log_error "Restore script not found in $2"
                fi
            else
                restore_from_backup_interactive
            fi
            ;;
        "--config"|"-c")
            init_system
            show_configuration_status
            ;;
        "--benchmark"|"-b")
            init_system
            run_performance_benchmark
            ;;
        "--debug")
            DEBUG=true
            init_system
            show_interactive_menu
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--deploy|--quick|--status|--restore [DIR]|--config|--benchmark|--debug|--help]"
            echo "  --deploy       Non-interactive deployment"
            echo "  --quick        Quick automated deployment"
            echo "  --status       Check deployment status"
            echo "  --restore DIR  Restore from specific backup directory"
            echo "  --config       Show configuration status"
            echo "  --benchmark    Run performance benchmark"
            echo "  --debug        Enable debug mode and run interactively"
            echo "  --help         Show this help"
            exit 0
            ;;
        *)
            init_system
            if [[ "$INTERACTIVE_MODE" == "true" ]]; then
                show_interactive_menu
            else
                check_environment && create_backup && deploy_ip_blocks && verify_deployment
            fi
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi