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


# Encryption & Privacy Tools
# File/Folder Encryption, Secure Communication, and Privacy Protection
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
# penalties. Your access is being monitored.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
ENCRYPTION_DIR="$HOME/.encryption_tools"
KEY_DIR="$ENCRYPTION_DIR/keys"
VAULT_DIR="$ENCRYPTION_DIR/vaults"

# Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ███████╗███╗   ██╗ ██████╗██████╗ ██╗   ██╗██████╗ ████████╗"
    echo " ██╔════╝████╗  ██║██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝"
    echo " █████╗  ██╔██╗ ██║██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   "
    echo " ██╔══╝  ██║╚██╗██║██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   "
    echo " ███████╗██║ ╚████║╚██████╗██║  ██║   ██║   ██║        ██║   "
    echo " ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝   "
    echo ""
    echo " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗"
    echo " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║"
    echo "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║"
    echo "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║"
    echo " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝"
    echo ""
    echo "    Encryption & Privacy Tools"
    echo "    File/Folder Encryption and Secure Communication"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
}

# Function to setup directories
setup_directories() {
    mkdir -p "$ENCRYPTION_DIR"
    mkdir -p "$KEY_DIR"
    mkdir -p "$VAULT_DIR"
    chmod 700 "$ENCRYPTION_DIR" "$KEY_DIR" "$VAULT_DIR"
    echo -e "${GREEN}✅ Encryption directories setup complete${NC}"
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    command -v openssl &> /dev/null || missing_deps+=("openssl")
    command -v gpg &> /dev/null || missing_deps+=("gnupg")
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}📦 Missing dependencies: ${missing_deps[*]}${NC}"
        echo -e "${CYAN}Installing dependencies...${NC}"
        
        if command -v apt &> /dev/null; then
            apt update && apt install -y "${missing_deps[@]}"
        elif command -v yum &> /dev/null; then
            yum install -y "${missing_deps[@]}"
        elif command -v pacman &> /dev/null; then
            pacman -S "${missing_deps[@]}" --noconfirm
        else
            echo -e "${RED}❌ Please install manually: ${missing_deps[*]}${NC}"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ All dependencies available${NC}"
}

# Function to generate secure password
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to encrypt file with AES
encrypt_file_aes() {
    echo -e "${CYAN}🔒 AES File Encryption${NC}"
    echo "======================"
    
    read -p "Enter file path to encrypt: " file_path
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi
    
    local output_file="${file_path}.encrypted"
    local key_file="$KEY_DIR/$(basename "$file_path")_$(date +%s).key"
    
    echo -e "${YELLOW}🔐 Choose encryption method:${NC}"
    echo "1) Use existing password"
    echo "2) Generate random key (recommended)"
    read -p "Choice (1-2): " method
    
    case $method in
        1)
            echo -e "${YELLOW}🔑 Enter encryption password:${NC}"
            openssl aes-256-cbc -salt -in "$file_path" -out "$output_file"
            ;;
        2)
            local random_key=$(generate_password 64)
            echo "$random_key" > "$key_file"
            chmod 600 "$key_file"
            
            echo -e "${YELLOW}🔐 Encrypting with generated key...${NC}"
            openssl aes-256-cbc -salt -k "$random_key" -in "$file_path" -out "$output_file"
            
            echo -e "${GREEN}✅ Key saved to: $key_file${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ File encrypted: $output_file${NC}"
        
        # Optionally delete original
        read -p "Delete original file? (y/N): " delete_orig
        if [[ $delete_orig =~ ^[Yy]$ ]]; then
            shred -vfz -n 3 "$file_path" 2>/dev/null || rm -f "$file_path"
            echo -e "${GREEN}✅ Original file securely deleted${NC}"
        fi
    else
        echo -e "${RED}❌ Encryption failed${NC}"
    fi
}

# Function to decrypt file with AES
decrypt_file_aes() {
    echo -e "${CYAN}🔓 AES File Decryption${NC}"
    echo "======================"
    
    read -p "Enter encrypted file path: " encrypted_file
    
    if [ ! -f "$encrypted_file" ]; then
        echo -e "${RED}❌ File not found: $encrypted_file${NC}"
        return 1
    fi
    
    local output_file="${encrypted_file%.encrypted}"
    
    echo -e "${YELLOW}🔐 Choose decryption method:${NC}"
    echo "1) Enter password manually"
    echo "2) Use key file"
    read -p "Choice (1-2): " method
    
    case $method in
        1)
            echo -e "${YELLOW}🔑 Enter decryption password:${NC}"
            openssl aes-256-cbc -d -in "$encrypted_file" -out "$output_file"
            ;;
        2)
            echo -e "${CYAN}Available key files:${NC}"
            local key_files=($(find "$KEY_DIR" -name "*.key" 2>/dev/null))
            
            if [ ${#key_files[@]} -eq 0 ]; then
                echo -e "${YELLOW}⚠️ No key files found${NC}"
                return 1
            fi
            
            for i in "${!key_files[@]}"; do
                echo "$(($i+1))) $(basename "${key_files[$i]}")"
            done
            
            read -p "Select key file: " key_choice
            if [[ $key_choice =~ ^[0-9]+$ ]] && [ $key_choice -le ${#key_files[@]} ] && [ $key_choice -gt 0 ]; then
                local selected_key="${key_files[$((key_choice-1))]}"
                local key_content=$(cat "$selected_key")
                
                openssl aes-256-cbc -d -k "$key_content" -in "$encrypted_file" -out "$output_file"
            else
                echo -e "${RED}❌ Invalid selection${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ File decrypted: $output_file${NC}"
    else
        echo -e "${RED}❌ Decryption failed${NC}"
    fi
}

# Function to encrypt folder
encrypt_folder() {
    echo -e "${CYAN}📁 Folder Encryption${NC}"
    echo "==================="
    
    read -p "Enter folder path to encrypt: " folder_path
    
    if [ ! -d "$folder_path" ]; then
        echo -e "${RED}❌ Folder not found: $folder_path${NC}"
        return 1
    fi
    
    local archive_name="$(basename "$folder_path")_$(date +%s)"
    local archive_file="$VAULT_DIR/${archive_name}.tar.gz"
    local encrypted_file="$VAULT_DIR/${archive_name}.tar.gz.encrypted"
    local key_file="$KEY_DIR/${archive_name}.key"
    
    echo -e "${YELLOW}📦 Creating archive...${NC}"
    tar -czf "$archive_file" -C "$(dirname "$folder_path")" "$(basename "$folder_path")"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Failed to create archive${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔐 Encrypting archive...${NC}"
    local random_key=$(generate_password 64)
    echo "$random_key" > "$key_file"
    chmod 600 "$key_file"
    
    openssl aes-256-cbc -salt -k "$random_key" -in "$archive_file" -out "$encrypted_file"
    
    if [ $? -eq 0 ]; then
        rm -f "$archive_file"
        echo -e "${GREEN}✅ Folder encrypted: $encrypted_file${NC}"
        echo -e "${GREEN}✅ Key saved to: $key_file${NC}"
        
        # Optionally delete original folder
        read -p "Delete original folder? (y/N): " delete_orig
        if [[ $delete_orig =~ ^[Yy]$ ]]; then
            rm -rf "$folder_path"
            echo -e "${GREEN}✅ Original folder deleted${NC}"
        fi
    else
        echo -e "${RED}❌ Encryption failed${NC}"
        rm -f "$archive_file"
    fi
}

# Function to decrypt folder
decrypt_folder() {
    echo -e "${CYAN}📂 Folder Decryption${NC}"
    echo "==================="
    
    echo -e "${CYAN}Available encrypted archives:${NC}"
    local encrypted_files=($(find "$VAULT_DIR" -name "*.encrypted" 2>/dev/null))
    
    if [ ${#encrypted_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No encrypted archives found${NC}"
        return 1
    fi
    
    for i in "${!encrypted_files[@]}"; do
        local file="${encrypted_files[$i]}"
        local size=$(du -h "$file" | cut -f1)
        local date=$(stat -c %y "$file" | cut -d'.' -f1)
        echo "$(($i+1))) $(basename "$file") ($size) - $date"
    done
    
    read -p "Select archive to decrypt: " choice
    if [[ ! $choice =~ ^[0-9]+$ ]] || [ $choice -gt ${#encrypted_files[@]} ] || [ $choice -lt 1 ]; then
        echo -e "${RED}❌ Invalid selection${NC}"
        return 1
    fi
    
    local selected_file="${encrypted_files[$((choice-1))]}"
    local archive_name=$(basename "$selected_file" .tar.gz.encrypted)
    local key_file="$KEY_DIR/${archive_name}.key"
    local temp_archive="/tmp/${archive_name}.tar.gz"
    
    if [ ! -f "$key_file" ]; then
        echo -e "${RED}❌ Key file not found: $key_file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🔓 Decrypting archive...${NC}"
    local key_content=$(cat "$key_file")
    openssl aes-256-cbc -d -k "$key_content" -in "$selected_file" -out "$temp_archive"
    
    if [ $? -eq 0 ]; then
        read -p "Extract to current directory? (Y/n): " extract_here
        local extract_dir="."
        
        if [[ $extract_here =~ ^[Nn]$ ]]; then
            read -p "Enter extraction directory: " extract_dir
            mkdir -p "$extract_dir"
        fi
        
        echo -e "${YELLOW}📦 Extracting archive...${NC}"
        tar -xzf "$temp_archive" -C "$extract_dir"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Folder decrypted and extracted to: $extract_dir${NC}"
        else
            echo -e "${RED}❌ Extraction failed${NC}"
        fi
        
        rm -f "$temp_archive"
    else
        echo -e "${RED}❌ Decryption failed${NC}"
    fi
}

# Function for GPG operations
gpg_operations() {
    echo -e "${CYAN}🔐 GPG Operations${NC}"
    echo "================="
    
    echo "1) Generate GPG key pair"
    echo "2) List GPG keys"
    echo "3) Encrypt file with GPG"
    echo "4) Decrypt file with GPG"
    echo "5) Sign file"
    echo "6) Verify signature"
    echo "7) Back to main menu"
    echo ""
    
    read -p "Enter choice (1-7): " gpg_choice
    
    case $gpg_choice in
        1) gpg_generate_key ;;
        2) gpg_list_keys ;;
        3) gpg_encrypt_file ;;
        4) gpg_decrypt_file ;;
        5) gpg_sign_file ;;
        6) gpg_verify_signature ;;
        7) return ;;
        *) echo -e "${RED}❌ Invalid choice${NC}" ;;
    esac
}

# Function to generate GPG key
gpg_generate_key() {
    echo -e "${YELLOW}🔑 GPG Key Generation${NC}"
    echo "===================="
    
    echo -e "${CYAN}This will generate a new GPG key pair.${NC}"
    echo "You will be prompted for:"
    echo "- Real name"
    echo "- Email address"
    echo "- Passphrase"
    echo ""
    
    read -p "Continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi
    
    gpg --full-generate-key
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ GPG key pair generated successfully${NC}"
    else
        echo -e "${RED}❌ Key generation failed${NC}"
    fi
}

# Function to list GPG keys
gpg_list_keys() {
    echo -e "${CYAN}🔑 GPG Keys${NC}"
    echo "==========="
    
    echo -e "${YELLOW}Public keys:${NC}"
    gpg --list-keys
    echo ""
    
    echo -e "${YELLOW}Private keys:${NC}"
    gpg --list-secret-keys
}

# Function to encrypt file with GPG
gpg_encrypt_file() {
    echo -e "${YELLOW}🔒 GPG File Encryption${NC}"
    
    read -p "Enter file path to encrypt: " file_path
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Available recipients:${NC}"
    gpg --list-keys --with-colons | grep '^uid' | cut -d: -f10
    echo ""
    
    read -p "Enter recipient email/ID: " recipient
    local output_file="${file_path}.gpg"
    
    gpg --encrypt --armor --recipient "$recipient" --output "$output_file" "$file_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ File encrypted: $output_file${NC}"
    else
        echo -e "${RED}❌ Encryption failed${NC}"
    fi
}

# Function to decrypt file with GPG
gpg_decrypt_file() {
    echo -e "${YELLOW}🔓 GPG File Decryption${NC}"
    
    read -p "Enter encrypted file path (.gpg): " encrypted_file
    
    if [ ! -f "$encrypted_file" ]; then
        echo -e "${RED}❌ File not found: $encrypted_file${NC}"
        return 1
    fi
    
    local output_file="${encrypted_file%.gpg}"
    
    gpg --decrypt --output "$output_file" "$encrypted_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ File decrypted: $output_file${NC}"
    else
        echo -e "${RED}❌ Decryption failed${NC}"
    fi
}

# Function to sign file with GPG
gpg_sign_file() {
    echo -e "${YELLOW}✍️ GPG File Signing${NC}"
    
    read -p "Enter file path to sign: " file_path
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}❌ File not found: $file_path${NC}"
        return 1
    fi
    
    local signature_file="${file_path}.sig"
    
    gpg --detach-sign --armor --output "$signature_file" "$file_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ File signed: $signature_file${NC}"
    else
        echo -e "${RED}❌ Signing failed${NC}"
    fi
}

# Function to verify GPG signature
gpg_verify_signature() {
    echo -e "${YELLOW}✅ GPG Signature Verification${NC}"
    
    read -p "Enter signature file path (.sig): " sig_file
    
    if [ ! -f "$sig_file" ]; then
        echo -e "${RED}❌ Signature file not found: $sig_file${NC}"
        return 1
    fi
    
    local original_file="${sig_file%.sig}"
    
    if [ ! -f "$original_file" ]; then
        echo -e "${RED}❌ Original file not found: $original_file${NC}"
        return 1
    fi
    
    gpg --verify "$sig_file" "$original_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Signature verified successfully${NC}"
    else
        echo -e "${RED}❌ Signature verification failed${NC}"
    fi
}

# Function to secure delete files
secure_delete() {
    echo -e "${CYAN}🗑️ Secure File Deletion${NC}"
    echo "======================="
    
    read -p "Enter file/folder path to securely delete: " target_path
    
    if [ ! -e "$target_path" ]; then
        echo -e "${RED}❌ Path not found: $target_path${NC}"
        return 1
    fi
    
    echo -e "${RED}⚠️ WARNING: This will permanently destroy the data!${NC}"
    echo -e "${YELLOW}Target: $target_path${NC}"
    read -p "Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return
    fi
    
    echo -e "${YELLOW}🔄 Securely deleting...${NC}"
    
    if [ -f "$target_path" ]; then
        # Use shred for files
        if command -v shred &> /dev/null; then
            shred -vfz -n 5 "$target_path"
        else
            # Fallback method
            dd if=/dev/urandom of="$target_path" bs=1M count=$(du -m "$target_path" | cut -f1) 2>/dev/null
            rm -f "$target_path"
        fi
    elif [ -d "$target_path" ]; then
        # For directories, overwrite all files first
        find "$target_path" -type f -exec shred -vfz -n 3 {} \; 2>/dev/null
        rm -rf "$target_path"
    fi
    
    echo -e "${GREEN}✅ Secure deletion completed${NC}"
}

# Function to create encrypted vault
create_vault() {
    echo -e "${CYAN}🏦 Create Encrypted Vault${NC}"
    echo "========================="
    
    read -p "Enter vault name: " vault_name
    local vault_path="$VAULT_DIR/${vault_name}"
    
    if [ -d "$vault_path" ]; then
        echo -e "${RED}❌ Vault already exists: $vault_name${NC}"
        return 1
    fi
    
    mkdir -p "$vault_path"
    chmod 700 "$vault_path"
    
    # Create vault info file
    cat > "$vault_path/.vault_info" << EOF
Vault Name: $vault_name
Created: $(date)
Description: Encrypted file vault
Warning: Do not modify this file
EOF
    
    echo -e "${GREEN}✅ Vault created: $vault_path${NC}"
    echo -e "${CYAN}💡 You can now add files to encrypt in this vault${NC}"
}

# Function to list vaults
list_vaults() {
    echo -e "${CYAN}🏦 Available Vaults${NC}"
    echo "=================="
    
    local vaults=($(find "$VAULT_DIR" -maxdepth 1 -type d -name "*" 2>/dev/null))
    
    if [ ${#vaults[@]} -le 1 ]; then  # Only the vault_dir itself
        echo -e "${YELLOW}⚠️ No vaults found${NC}"
        return
    fi
    
    for vault in "${vaults[@]}"; do
        if [ "$vault" != "$VAULT_DIR" ]; then
            local vault_name=$(basename "$vault")
            local file_count=$(find "$vault" -type f | wc -l)
            local size=$(du -sh "$vault" 2>/dev/null | cut -f1)
            echo -e "${GREEN}📁 $vault_name${NC} - $file_count files ($size)"
        fi
    done
}

# Function to show menu
show_menu() {
    echo -e "${GREEN}🎯 Encryption Tools Menu:${NC}"
    echo "=========================="
    echo -e "${WHITE}[1] Encrypt file (AES)${NC}"
    echo -e "${WHITE}[2] Decrypt file (AES)${NC}"
    echo -e "${WHITE}[3] Encrypt folder${NC}"
    echo -e "${WHITE}[4] Decrypt folder${NC}"
    echo -e "${WHITE}[5] GPG operations${NC}"
    echo -e "${WHITE}[6] Create encrypted vault${NC}"
    echo -e "${WHITE}[7] List vaults${NC}"
    echo -e "${WHITE}[8] Secure delete${NC}"
    echo -e "${WHITE}[9] Generate password${NC}"
    echo -e "${WHITE}[0] Exit${NC}"
    echo ""
}

# Function to generate and display password
show_generated_password() {
    echo -e "${CYAN}🔑 Password Generator${NC}"
    echo "===================="
    
    read -p "Enter password length (default: 32): " length
    length=${length:-32}
    
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 8 ] || [ "$length" -gt 128 ]; then
        echo -e "${RED}❌ Invalid length. Use 8-128${NC}"
        return 1
    fi
    
    local password=$(generate_password "$length")
    echo ""
    echo -e "${GREEN}Generated password:${NC}"
    echo -e "${WHITE}$password${NC}"
    echo ""
    echo -e "${YELLOW}💡 Password strength: ${length} characters${NC}"
    
    # Optional save to file
    read -p "Save password to file? (y/N): " save_pass
    if [[ $save_pass =~ ^[Yy]$ ]]; then
        local pass_file="$KEY_DIR/password_$(date +%s).txt"
        echo "$password" > "$pass_file"
        chmod 600 "$pass_file"
        echo -e "${GREEN}✅ Password saved to: $pass_file${NC}"
    fi
}

# Main script execution
show_banner

# Setup directories
setup_directories

# Check dependencies
check_dependencies

echo ""

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (0-9): " choice
    
    case $choice in
        1)
            encrypt_file_aes
            read -p "Press Enter to continue..."
            ;;
        2)
            decrypt_file_aes
            read -p "Press Enter to continue..."
            ;;
        3)
            encrypt_folder
            read -p "Press Enter to continue..."
            ;;
        4)
            decrypt_folder
            read -p "Press Enter to continue..."
            ;;
        5)
            gpg_operations
            read -p "Press Enter to continue..."
            ;;
        6)
            create_vault
            read -p "Press Enter to continue..."
            ;;
        7)
            list_vaults
            read -p "Press Enter to continue..."
            ;;
        8)
            secure_delete
            read -p "Press Enter to continue..."
            ;;
        9)
            show_generated_password
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
