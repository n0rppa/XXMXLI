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


# System Hardening & Security Configuration Tool
# Comprehensive Linux Security Hardening Script
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization
#
# SECURITY WARNING: This system is actively monitored and protected.
# Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
# will be logged and reported to the appropriate authorities. IP addresses and metadata 
# may be retained and used for legal enforcement, in compliance with applicable laws.
# By continuing, you acknowledge that you are authorized to use this system and that 
# any misuse may result in account suspension, firewall bans, or prosecution under 
# national and international law. Violators may be subject to civil and/or criminal 
# penalties. Your access is being monitored./bash

# System Hardening & Security Configuration Tool
# Comprehensive Linux System Security Hardening
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to display banner
show_banner() {
    # Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗"
    echo " ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║"
    echo " ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║"
    echo " ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║"
    echo " ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║"
    echo " ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝"
    echo ""
    echo " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗"
    echo " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║"
    echo "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║"
    echo "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║"
    echo " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝"
    echo ""
    echo "    System Hardening & Security Configuration Tool"
    echo "    Comprehensive Linux Security Hardening"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
}
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Running with root privileges${NC}"
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        DISTRO=$ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
        DISTRO="unknown"
    fi
    
    echo -e "${CYAN}📋 Detected OS: $OS $VER${NC}"
    echo -e "${CYAN}🔧 Distribution: $DISTRO${NC}"
}

# Function to create backup
create_backup() {
    echo -e "${YELLOW}💾 Creating system configuration backup...${NC}"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="system_hardening_backup_${timestamp}"
    mkdir -p "$BACKUP_DIR"
    
    # Backup important configuration files
    [ -f /etc/ssh/sshd_config ] && cp /etc/ssh/sshd_config "$BACKUP_DIR/"
    [ -f /etc/sudoers ] && cp /etc/sudoers "$BACKUP_DIR/"
    [ -f /etc/security/limits.conf ] && cp /etc/security/limits.conf "$BACKUP_DIR/"
    [ -f /etc/sysctl.conf ] && cp /etc/sysctl.conf "$BACKUP_DIR/"
    [ -f /etc/hosts.deny ] && cp /etc/hosts.deny "$BACKUP_DIR/"
    [ -f /etc/hosts.allow ] && cp /etc/hosts.allow "$BACKUP_DIR/"
    [ -f /etc/login.defs ] && cp /etc/login.defs "$BACKUP_DIR/"
    [ -f /etc/pam.d/common-password ] && cp /etc/pam.d/common-password "$BACKUP_DIR/"
    [ -f /etc/issue ] && cp /etc/issue "$BACKUP_DIR/"
    [ -f /etc/issue.net ] && cp /etc/issue.net "$BACKUP_DIR/"
    
    # Create backup info
    cat > "$BACKUP_DIR/backup_info.txt" << EOF
System Hardening Backup
Created: $(date)
Hostname: $(hostname)
Distribution: $OS $VER
Kernel: $(uname -r)

Restore Instructions:
1. Stop relevant services before restoring
2. Copy files back to their original locations
3. Restart services and reboot if necessary
EOF
    
    echo -e "${GREEN}✅ Backup saved to: $BACKUP_DIR${NC}"
}

# Function to harden SSH configuration
harden_ssh() {
    echo -e "${YELLOW}🔄 Hardening SSH configuration...${NC}"
    
    if [ ! -f /etc/ssh/sshd_config ]; then
        echo -e "${YELLOW}⚠️ SSH not installed, skipping SSH hardening${NC}"
        return
    fi
    
    # Backup original SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    
    # Apply SSH hardening settings
    cat > /etc/ssh/sshd_config << 'EOF'
# XXMXLI SSH Hardening Configuration
# Based on security best practices

# Protocol and Encryption
Protocol 2
Port 22
AddressFamily inet

# Authentication
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Connection settings
MaxAuthTries 3
MaxSessions 3
MaxStartups 3:30:10
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2

# Security settings
PermitUserEnvironment no
AllowAgentForwarding no
AllowTcpForwarding no
X11Forwarding no
PrintMotd no
PrintLastLog yes
TCPKeepAlive no
Compression no

# Logging
LogLevel VERBOSE
SyslogFacility AUTH

# Crypto settings
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256

# Banner
Banner /etc/ssh/banner

# Restrict users (uncomment and modify as needed)
# AllowUsers yourusername
# AllowGroups ssh-users
EOF
    
    # Create SSH banner
    cat > /etc/ssh/banner << 'EOF'
***************************************************************************
                        UNAUTHORIZED ACCESS PROHIBITED
***************************************************************************
This system is for authorized users only. All activities are monitored
and recorded. Unauthorized access is strictly prohibited and will be
prosecuted to the full extent of the law.
***************************************************************************
EOF
    
    # Restart SSH service
    systemctl restart sshd || service ssh restart
    
    echo -e "${GREEN}✅ SSH hardened and restarted${NC}"
    echo -e "${YELLOW}⚠️ Remember to set up SSH keys before disconnecting!${NC}"
}

# Function to configure firewall
configure_firewall() {
    echo -e "${YELLOW}🔄 Configuring firewall...${NC}"
    
    # Install UFW if not present
    if ! command -v ufw &> /dev/null; then
        echo -e "${CYAN}📦 Installing UFW firewall...${NC}"
        if command -v apt &> /dev/null; then
            apt update && apt install -y ufw
        elif command -v yum &> /dev/null; then
            yum install -y epel-release && yum install -y ufw
        elif command -v pacman &> /dev/null; then
            pacman -S ufw --noconfirm
        fi
    fi
    
    if command -v ufw &> /dev/null; then
        # Reset UFW to defaults
        ufw --force reset
        
        # Set default policies
        ufw default deny incoming
        ufw default allow outgoing
        
        # Allow essential services
        ufw allow ssh
        ufw allow 80/tcp    # HTTP
        ufw allow 443/tcp   # HTTPS
        
        # Rate limiting for SSH
        ufw limit ssh
        
        # Enable UFW
        ufw --force enable
        
        echo -e "${GREEN}✅ UFW firewall configured and enabled${NC}"
    else
        echo -e "${RED}❌ Failed to install UFW${NC}"
    fi
}

# Function to harden kernel parameters
harden_kernel() {
    echo -e "${YELLOW}🔄 Hardening kernel parameters...${NC}"
    
    cat > /etc/sysctl.d/99-security-hardening.conf << 'EOF'
# XXMXLI Kernel Security Hardening
# Network security
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# ICMP settings
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# SYN flood protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# IP spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Log suspicious packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Memory protection
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1

# Process restrictions
fs.suid_dumpable = 0
kernel.core_uses_pid = 1

# Address space layout randomization
kernel.randomize_va_space = 2

# Restrict access to kernel logs
kernel.dmesg_restrict = 1

# Restrict perf events
kernel.perf_event_paranoid = 2
EOF
    
    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-security-hardening.conf
    
    echo -e "${GREEN}✅ Kernel parameters hardened${NC}"
}

# Function to configure secure file permissions
secure_file_permissions() {
    echo -e "${YELLOW}🔄 Securing file permissions...${NC}"
    
    # Set proper permissions on sensitive files
    chmod 600 /etc/ssh/sshd_config 2>/dev/null
    chmod 600 /etc/shadow 2>/dev/null
    chmod 600 /etc/gshadow 2>/dev/null
    chmod 644 /etc/passwd 2>/dev/null
    chmod 644 /etc/group 2>/dev/null
    chmod 600 /boot/grub/grub.cfg 2>/dev/null
    chmod 600 /boot/grub2/grub.cfg 2>/dev/null
    
    # Remove world-writable permissions from critical directories
    find /etc -type f -perm -o+w -exec chmod o-w {} \; 2>/dev/null
    find /bin -type f -perm -o+w -exec chmod o-w {} \; 2>/dev/null
    find /sbin -type f -perm -o+w -exec chmod o-w {} \; 2>/dev/null
    
    # Set proper umask
    echo "umask 027" >> /etc/profile
    echo "umask 027" >> /etc/bash.bashrc 2>/dev/null
    
    echo -e "${GREEN}✅ File permissions secured${NC}"
}

# Function to disable unnecessary services
disable_services() {
    echo -e "${YELLOW}🔄 Disabling unnecessary services...${NC}"
    
    # List of potentially unnecessary services
    SERVICES_TO_DISABLE=(
        "telnet"
        "rsh"
        "rlogin"
        "vsftpd"
        "httpd"
        "apache2"
        "nginx"
        "sendmail"
        "postfix"
        "dovecot"
        "cups"
        "avahi-daemon"
        "bluetooth"
        "nfs-server"
        "rpcbind"
        "ypbind"
    )
    
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            echo -e "${CYAN}Disabling service: $service${NC}"
            systemctl disable "$service" 2>/dev/null
            systemctl stop "$service" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✅ Unnecessary services disabled${NC}"
}

# Function to configure password policies
configure_password_policy() {
    echo -e "${YELLOW}🔄 Configuring password policies...${NC}"
    
    # Install libpam-pwquality if not present
    if command -v apt &> /dev/null; then
        apt install -y libpam-pwquality 2>/dev/null
    elif command -v yum &> /dev/null; then
        yum install -y libpwquality 2>/dev/null
    fi
    
    # Configure password quality requirements
    cat > /etc/security/pwquality.conf << 'EOF'
# XXMXLI Password Quality Configuration
minlen = 12
minclass = 3
maxrepeat = 2
maxsequence = 3
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
difok = 8
retry = 3
EOF
    
    # Configure login.defs for password aging
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs 2>/dev/null
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs 2>/dev/null
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs 2>/dev/null
    
    echo -e "${GREEN}✅ Password policies configured${NC}"
}

# Function to configure audit logging
configure_audit() {
    echo -e "${YELLOW}🔄 Configuring audit logging...${NC}"
    
    # Install auditd if not present
    if ! command -v auditd &> /dev/null; then
        if command -v apt &> /dev/null; then
            apt install -y auditd audispd-plugins
        elif command -v yum &> /dev/null; then
            yum install -y audit
        elif command -v pacman &> /dev/null; then
            pacman -S audit --noconfirm
        fi
    fi
    
    if command -v auditd &> /dev/null; then
        # Configure audit rules
        cat > /etc/audit/rules.d/audit.rules << 'EOF'
# XXMXLI Audit Rules
# Delete all previous rules
-D

# Buffer size
-b 8192

# Failure mode (0=silent, 1=printk, 2=panic)
-f 1

# Monitor authentication events
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Monitor login/logout events
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p wa -k logins

# Monitor network configuration
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/network/ -p wa -k system-locale

# Monitor system calls
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change

# Monitor file access
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod

# Make the configuration immutable
-e 2
EOF
        
        # Restart auditd
        systemctl enable auditd
        systemctl restart auditd
        
        echo -e "${GREEN}✅ Audit logging configured${NC}"
    else
        echo -e "${YELLOW}⚠️ Failed to install auditd${NC}"
    fi
}

# Function to secure shared memory
secure_shared_memory() {
    echo -e "${YELLOW}🔄 Securing shared memory...${NC}"
    
    # Add nodev,nosuid,noexec options to /dev/shm
    if ! grep -q "/dev/shm" /etc/fstab; then
        echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" >> /etc/fstab
        echo -e "${GREEN}✅ Shared memory secured in /etc/fstab${NC}"
    else
        echo -e "${YELLOW}⚠️ /dev/shm already configured in /etc/fstab${NC}"
    fi
}

# Function to configure system banners
configure_banners() {
    echo -e "${YELLOW}🔄 Configuring system banners...${NC}"
    
    # Create login banner
    cat > /etc/issue << 'EOF'
***************************************************************************
                        UNAUTHORIZED ACCESS PROHIBITED
***************************************************************************
This system is for authorized users only. All activities are monitored
and recorded. Unauthorized access is strictly prohibited and will be
prosecuted to the full extent of the law.
***************************************************************************

EOF
    
    cp /etc/issue /etc/issue.net
    
    # Create MOTD
    cat > /etc/motd << 'EOF'
***************************************************************************
                        SYSTEM SECURITY NOTICE
***************************************************************************
This system has been hardened for security. All activities are logged.
Ensure you follow security policies and report any suspicious activity.
***************************************************************************

EOF
    
    echo -e "${GREEN}✅ System banners configured${NC}"
}

# Function to check system security status
check_security_status() {
    echo -e "${GREEN}📊 System Security Status:${NC}"
    echo "=========================="
    
    # SSH status
    echo -e "${CYAN}🔒 SSH Security:${NC}"
    if systemctl is-active sshd >/dev/null 2>&1 || systemctl is-active ssh >/dev/null 2>&1; then
        echo -e "SSH Service: ${GREEN}ACTIVE${NC}"
        if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
            echo -e "Root Login: ${GREEN}DISABLED${NC}"
        else
            echo -e "Root Login: ${RED}ENABLED${NC} (Security Risk)"
        fi
        if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
            echo -e "Password Auth: ${GREEN}DISABLED${NC}"
        else
            echo -e "Password Auth: ${YELLOW}ENABLED${NC}"
        fi
    else
        echo -e "SSH Service: ${YELLOW}INACTIVE${NC}"
    fi
    
    # Firewall status
    echo -e "${CYAN}🛡️ Firewall Status:${NC}"
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            echo -e "UFW Firewall: ${GREEN}ACTIVE${NC}"
        else
            echo -e "UFW Firewall: ${RED}INACTIVE${NC}"
        fi
    else
        echo -e "UFW Firewall: ${YELLOW}NOT INSTALLED${NC}"
    fi
    
    # Audit status
    echo -e "${CYAN}📋 Audit Logging:${NC}"
    if systemctl is-active auditd >/dev/null 2>&1; then
        echo -e "Auditd: ${GREEN}ACTIVE${NC}"
    else
        echo -e "Auditd: ${YELLOW}INACTIVE${NC}"
    fi
    
    # Kernel hardening
    echo -e "${CYAN}🔧 Kernel Hardening:${NC}"
    if [ -f /etc/sysctl.d/99-security-hardening.conf ]; then
        echo -e "Kernel Hardening: ${GREEN}CONFIGURED${NC}"
    else
        echo -e "Kernel Hardening: ${YELLOW}NOT CONFIGURED${NC}"
    fi
    
    # File permissions
    echo -e "${CYAN}📁 Critical File Permissions:${NC}"
    if [ "$(stat -c %a /etc/shadow 2>/dev/null)" = "600" ]; then
        echo -e "/etc/shadow: ${GREEN}SECURE (600)${NC}"
    else
        echo -e "/etc/shadow: ${RED}INSECURE${NC}"
    fi
    
    echo ""
}

# Function to show menu
show_menu() {
    echo -e "${GREEN}🎯 System Hardening Menu:${NC}"
    echo "========================"
    echo -e "${WHITE}[1] Show security status${NC}"
    echo -e "${WHITE}[2] Full system hardening (recommended)${NC}"
    echo -e "${WHITE}[3] Harden SSH configuration${NC}"
    echo -e "${WHITE}[4] Configure firewall (UFW)${NC}"
    echo -e "${WHITE}[5] Harden kernel parameters${NC}"
    echo -e "${WHITE}[6] Secure file permissions${NC}"
    echo -e "${WHITE}[7] Configure password policies${NC}"
    echo -e "${WHITE}[8] Setup audit logging${NC}"
    echo -e "${WHITE}[9] Disable unnecessary services${NC}"
    echo -e "${WHITE}[10] Create system backup${NC}"
    echo -e "${WHITE}[0] Exit${NC}"
    echo ""
}

# Main script execution
show_banner

# Check for root privileges
check_root

# Detect distribution
detect_distro

echo ""

# Handle command line arguments
case "${1:-menu}" in
    "full-harden")
        create_backup
        harden_ssh
        configure_firewall
        harden_kernel
        secure_file_permissions
        configure_password_policy
        configure_audit
        disable_services
        secure_shared_memory
        configure_banners
        check_security_status
        ;;
    "ssh")
        create_backup
        harden_ssh
        ;;
    "firewall")
        configure_firewall
        ;;
    "kernel")
        harden_kernel
        ;;
    "status")
        check_security_status
        ;;
    "menu"|*)
        while true; do
            show_menu
            read -p "Enter your choice (0-10): " choice
            
            case $choice in
                1)
                    check_security_status
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    echo -e "${YELLOW}🚨 Full system hardening will modify many settings!${NC}"
                    read -p "Continue? (y/N): " confirm
                    if [[ $confirm =~ ^[Yy]$ ]]; then
                        create_backup
                        harden_ssh
                        configure_firewall
                        harden_kernel
                        secure_file_permissions
                        configure_password_policy
                        configure_audit
                        disable_services
                        secure_shared_memory
                        configure_banners
                        check_security_status
                    fi
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    create_backup
                    harden_ssh
                    read -p "Press Enter to continue..."
                    ;;
                4)
                    configure_firewall
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    harden_kernel
                    read -p "Press Enter to continue..."
                    ;;
                6)
                    secure_file_permissions
                    read -p "Press Enter to continue..."
                    ;;
                7)
                    configure_password_policy
                    read -p "Press Enter to continue..."
                    ;;
                8)
                    configure_audit
                    read -p "Press Enter to continue..."
                    ;;
                9)
                    disable_services
                    read -p "Press Enter to continue..."
                    ;;
                10)
                    create_backup
                    read -p "Press Enter to continue..."
                    ;;
                0)
                    echo -e "${GREEN}👋 Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}❌ Invalid choice!${NC}"
                    read -p "Press Enter to continue..."
                    ;;
            esac
        done
        ;;
esac

echo ""
echo -e "${GREEN}📋 System hardening completed!${NC}"
echo -e "${YELLOW}⚠️  Reboot the system to ensure all changes take effect.${NC}"
echo -e "${CYAN}💡 Test system functionality and connectivity after hardening.${NC}"
