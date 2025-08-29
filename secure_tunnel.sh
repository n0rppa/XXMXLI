#!/bin/bash

# Secure # Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗     "
    echo " ╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║     "
    echo "    ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║     "
    echo "    ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║     "
    echo "    ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗"
    echo "    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝"
    echo ""
    echo " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗"
    echo " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║"
    echo "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║"
    echo "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║"
    echo " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝"
    echo ""
    echo "    Secure Tunneling & SSH Management Tool"
    echo "    SSH Tunnels, SOCKS Proxy & VPN Management"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
} Management Tool
# SSH Tunnels, VPN Connections, and Secure Proxy Management
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

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
CONFIG_DIR="$HOME/.tunnel_manager"
TUNNEL_LOG="$CONFIG_DIR/tunnel.log"
PID_DIR="$CONFIG_DIR/pids"

# Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗     "
    echo " ╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║     "
    echo "    ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║     "
    echo "    ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║     "
    echo "    ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗"
    echo "    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝"
    echo ""
    echo "    Secure Tunneling & VPN Management Tool"
    echo "    SSH Tunnels, VPN, and Secure Proxy Management"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
}

# Function to setup configuration directory
setup_config() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$PID_DIR"
    touch "$TUNNEL_LOG"
    echo -e "${GREEN}✅ Configuration directory setup complete${NC}"
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$TUNNEL_LOG"
}

# Function to check if SSH is available
check_ssh() {
    if ! command -v ssh &> /dev/null; then
        echo -e "${RED}❌ SSH client not found. Please install openssh-client${NC}"
        return 1
    fi
    return 0
}

# Function to create SSH key pair
create_ssh_key() {
    echo -e "${CYAN}🔑 SSH Key Management${NC}"
    echo "===================="
    
    local key_name
    read -p "Enter key name (default: tunnel_key): " key_name
    key_name=${key_name:-tunnel_key}
    
    local key_path="$CONFIG_DIR/${key_name}"
    
    if [ -f "$key_path" ]; then
        echo -e "${YELLOW}⚠️ Key already exists: $key_path${NC}"
        read -p "Overwrite? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Operation cancelled${NC}"
            return
        fi
    fi
    
    echo -e "${YELLOW}🔐 Generating SSH key pair...${NC}"
    ssh-keygen -t ed25519 -f "$key_path" -C "tunnel_manager_$(date +%Y%m%d)"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SSH key generated: $key_path${NC}"
        echo -e "${CYAN}📋 Public key:${NC}"
        cat "${key_path}.pub"
        echo ""
        echo -e "${YELLOW}💡 Copy the public key to your remote server:${NC}"
        echo -e "${WHITE}ssh-copy-id -i ${key_path}.pub user@remote_host${NC}"
        
        log_message "SSH key generated: $key_path"
    else
        echo -e "${RED}❌ Failed to generate SSH key${NC}"
    fi
}

# Function to list SSH keys
list_ssh_keys() {
    echo -e "${CYAN}🔑 Available SSH Keys${NC}"
    echo "===================="
    
    local keys=($(find "$CONFIG_DIR" -name "*.pub" 2>/dev/null))
    
    if [ ${#keys[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No SSH keys found in $CONFIG_DIR${NC}"
        return
    fi
    
    for i in "${!keys[@]}"; do
        local key="${keys[$i]}"
        local keyname=$(basename "$key" .pub)
        local fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
        echo "$(($i+1))) $keyname - $fingerprint"
    done
}

# Function to create SSH tunnel
create_ssh_tunnel() {
    echo -e "${CYAN}🚇 SSH Tunnel Creator${NC}"
    echo "===================="
    
    if ! check_ssh; then
        return 1
    fi
    
    echo "Select tunnel type:"
    echo "1) Local Port Forward (access remote service locally)"
    echo "2) Remote Port Forward (expose local service remotely)"
    echo "3) Dynamic SOCKS Proxy"
    echo "4) Reverse SSH Shell"
    
    read -p "Enter choice (1-4): " tunnel_type
    
    case $tunnel_type in
        1) create_local_forward ;;
        2) create_remote_forward ;;
        3) create_socks_proxy ;;
        4) create_reverse_shell ;;
        *) echo -e "${RED}❌ Invalid choice${NC}" ;;
    esac
}

# Function to create local port forward
create_local_forward() {
    echo -e "${YELLOW}🔄 Local Port Forward Configuration${NC}"
    
    read -p "Local port (e.g., 8080): " local_port
    read -p "Remote host (e.g., example.com): " remote_host
    read -p "SSH user: " ssh_user
    read -p "SSH server: " ssh_server
    read -p "Remote service host (default: localhost): " service_host
    service_host=${service_host:-localhost}
    read -p "Remote service port (e.g., 80): " service_port
    
    # Optional SSH key
    echo -e "${CYAN}Available SSH keys:${NC}"
    list_ssh_keys
    read -p "SSH key number (press Enter for default): " key_choice
    
    local ssh_options="-L ${local_port}:${service_host}:${service_port}"
    local ssh_key=""
    
    if [[ $key_choice =~ ^[0-9]+$ ]]; then
        local keys=($(find "$CONFIG_DIR" -name "*.pub" 2>/dev/null))
        if [ $key_choice -le ${#keys[@]} ] && [ $key_choice -gt 0 ]; then
            local selected_key="${keys[$((key_choice-1))]}"
            ssh_key="-i ${selected_key%.pub}"
        fi
    fi
    
    local tunnel_name="local_${local_port}_${service_port}_$(date +%s)"
    local pid_file="$PID_DIR/${tunnel_name}.pid"
    
    echo -e "${YELLOW}🚇 Starting local port forward tunnel...${NC}"
    echo "Local port $local_port -> $ssh_server -> $service_host:$service_port"
    
    # Start tunnel in background
    nohup ssh $ssh_key $ssh_options -N -f "$ssh_user@$ssh_server" > /dev/null 2>&1 &
    local ssh_pid=$!
    echo $ssh_pid > "$pid_file"
    
    # Verify tunnel
    sleep 2
    if kill -0 $ssh_pid 2>/dev/null; then
        echo -e "${GREEN}✅ Tunnel started successfully${NC}"
        echo -e "${CYAN}📋 Tunnel Details:${NC}"
        echo "Name: $tunnel_name"
        echo "PID: $ssh_pid"
        echo "Local access: http://localhost:$local_port"
        echo "PID file: $pid_file"
        
        log_message "Local forward tunnel started: $tunnel_name (PID: $ssh_pid)"
    else
        echo -e "${RED}❌ Failed to start tunnel${NC}"
        rm -f "$pid_file"
    fi
}

# Function to create remote port forward
create_remote_forward() {
    echo -e "${YELLOW}🔄 Remote Port Forward Configuration${NC}"
    
    read -p "Remote port: " remote_port
    read -p "Local service host (default: localhost): " local_host
    local_host=${local_host:-localhost}
    read -p "Local service port: " local_port
    read -p "SSH user: " ssh_user
    read -p "SSH server: " ssh_server
    
    # Optional SSH key
    echo -e "${CYAN}Available SSH keys:${NC}"
    list_ssh_keys
    read -p "SSH key number (press Enter for default): " key_choice
    
    local ssh_options="-R ${remote_port}:${local_host}:${local_port}"
    local ssh_key=""
    
    if [[ $key_choice =~ ^[0-9]+$ ]]; then
        local keys=($(find "$CONFIG_DIR" -name "*.pub" 2>/dev/null))
        if [ $key_choice -le ${#keys[@]} ] && [ $key_choice -gt 0 ]; then
            local selected_key="${keys[$((key_choice-1))]}"
            ssh_key="-i ${selected_key%.pub}"
        fi
    fi
    
    local tunnel_name="remote_${remote_port}_${local_port}_$(date +%s)"
    local pid_file="$PID_DIR/${tunnel_name}.pid"
    
    echo -e "${YELLOW}🚇 Starting remote port forward tunnel...${NC}"
    echo "Remote port $remote_port -> $ssh_server -> $local_host:$local_port"
    
    # Start tunnel in background
    nohup ssh $ssh_key $ssh_options -N -f "$ssh_user@$ssh_server" > /dev/null 2>&1 &
    local ssh_pid=$!
    echo $ssh_pid > "$pid_file"
    
    # Verify tunnel
    sleep 2
    if kill -0 $ssh_pid 2>/dev/null; then
        echo -e "${GREEN}✅ Tunnel started successfully${NC}"
        echo -e "${CYAN}📋 Tunnel Details:${NC}"
        echo "Name: $tunnel_name"
        echo "PID: $ssh_pid"
        echo "Remote access: $ssh_server:$remote_port"
        echo "PID file: $pid_file"
        
        log_message "Remote forward tunnel started: $tunnel_name (PID: $ssh_pid)"
    else
        echo -e "${RED}❌ Failed to start tunnel${NC}"
        rm -f "$pid_file"
    fi
}

# Function to create SOCKS proxy
create_socks_proxy() {
    echo -e "${YELLOW}🔄 SOCKS Proxy Configuration${NC}"
    
    read -p "Local SOCKS port (default: 1080): " socks_port
    socks_port=${socks_port:-1080}
    read -p "SSH user: " ssh_user
    read -p "SSH server: " ssh_server
    
    # Optional SSH key
    echo -e "${CYAN}Available SSH keys:${NC}"
    list_ssh_keys
    read -p "SSH key number (press Enter for default): " key_choice
    
    local ssh_options="-D $socks_port"
    local ssh_key=""
    
    if [[ $key_choice =~ ^[0-9]+$ ]]; then
        local keys=($(find "$CONFIG_DIR" -name "*.pub" 2>/dev/null))
        if [ $key_choice -le ${#keys[@]} ] && [ $key_choice -gt 0 ]; then
            local selected_key="${keys[$((key_choice-1))]}"
            ssh_key="-i ${selected_key%.pub}"
        fi
    fi
    
    local tunnel_name="socks_${socks_port}_$(date +%s)"
    local pid_file="$PID_DIR/${tunnel_name}.pid"
    
    echo -e "${YELLOW}🚇 Starting SOCKS proxy tunnel...${NC}"
    echo "SOCKS proxy on localhost:$socks_port -> $ssh_server"
    
    # Start tunnel in background
    nohup ssh $ssh_key $ssh_options -N -f "$ssh_user@$ssh_server" > /dev/null 2>&1 &
    local ssh_pid=$!
    echo $ssh_pid > "$pid_file"
    
    # Verify tunnel
    sleep 2
    if kill -0 $ssh_pid 2>/dev/null; then
        echo -e "${GREEN}✅ SOCKS proxy started successfully${NC}"
        echo -e "${CYAN}📋 Proxy Details:${NC}"
        echo "Name: $tunnel_name"
        echo "PID: $ssh_pid"
        echo "SOCKS proxy: localhost:$socks_port"
        echo "PID file: $pid_file"
        echo ""
        echo -e "${YELLOW}💡 Configure your browser/application to use:${NC}"
        echo "SOCKS5 proxy: 127.0.0.1:$socks_port"
        
        log_message "SOCKS proxy started: $tunnel_name (PID: $ssh_pid)"
    else
        echo -e "${RED}❌ Failed to start SOCKS proxy${NC}"
        rm -f "$pid_file"
    fi
}

# Function to create reverse shell
create_reverse_shell() {
    echo -e "${YELLOW}🔄 Reverse SSH Shell Configuration${NC}"
    echo -e "${RED}⚠️ WARNING: Use only for authorized penetration testing!${NC}"
    
    read -p "Continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return
    fi
    
    read -p "Local listening port: " listen_port
    read -p "Target SSH user: " ssh_user
    read -p "Target SSH server: " ssh_server
    
    # Optional SSH key
    echo -e "${CYAN}Available SSH keys:${NC}"
    list_ssh_keys
    read -p "SSH key number (press Enter for default): " key_choice
    
    local ssh_options="-R ${listen_port}:localhost:22"
    local ssh_key=""
    
    if [[ $key_choice =~ ^[0-9]+$ ]]; then
        local keys=($(find "$CONFIG_DIR" -name "*.pub" 2>/dev/null))
        if [ $key_choice -le ${#keys[@]} ] && [ $key_choice -gt 0 ]; then
            local selected_key="${keys[$((key_choice-1))]}"
            ssh_key="-i ${selected_key%.pub}"
        fi
    fi
    
    local tunnel_name="reverse_${listen_port}_$(date +%s)"
    local pid_file="$PID_DIR/${tunnel_name}.pid"
    
    echo -e "${YELLOW}🚇 Starting reverse shell tunnel...${NC}"
    echo "Reverse shell: $ssh_server:$listen_port -> localhost:22"
    
    # Start tunnel in background
    nohup ssh $ssh_key $ssh_options -N -f "$ssh_user@$ssh_server" > /dev/null 2>&1 &
    local ssh_pid=$!
    echo $ssh_pid > "$pid_file"
    
    # Verify tunnel
    sleep 2
    if kill -0 $ssh_pid 2>/dev/null; then
        echo -e "${GREEN}✅ Reverse shell tunnel started${NC}"
        echo -e "${CYAN}📋 Tunnel Details:${NC}"
        echo "Name: $tunnel_name"
        echo "PID: $ssh_pid"
        echo "Access from target: ssh -p $listen_port user@localhost"
        echo "PID file: $pid_file"
        
        log_message "Reverse shell tunnel started: $tunnel_name (PID: $ssh_pid)"
    else
        echo -e "${RED}❌ Failed to start reverse shell tunnel${NC}"
        rm -f "$pid_file"
    fi
}

# Function to list active tunnels
list_tunnels() {
    echo -e "${CYAN}🚇 Active Tunnels${NC}"
    echo "================"
    
    local pid_files=($(find "$PID_DIR" -name "*.pid" 2>/dev/null))
    
    if [ ${#pid_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No active tunnels found${NC}"
        return
    fi
    
    for pid_file in "${pid_files[@]}"; do
        local tunnel_name=$(basename "$pid_file" .pid)
        local pid=$(cat "$pid_file" 2>/dev/null)
        
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}✅ $tunnel_name (PID: $pid) - ACTIVE${NC}"
            
            # Show process details
            local process_info=$(ps -p "$pid" -o pid,cmd --no-headers 2>/dev/null)
            if [ -n "$process_info" ]; then
                echo "   Command: ${process_info#*ssh}"
            fi
        else
            echo -e "${RED}❌ $tunnel_name (PID: $pid) - DEAD${NC}"
            rm -f "$pid_file"
        fi
        echo ""
    done
}

# Function to kill tunnel
kill_tunnel() {
    echo -e "${CYAN}⚰️ Kill Tunnel${NC}"
    echo "=============="
    
    local pid_files=($(find "$PID_DIR" -name "*.pid" 2>/dev/null))
    
    if [ ${#pid_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ No active tunnels found${NC}"
        return
    fi
    
    echo "Active tunnels:"
    for i in "${!pid_files[@]}"; do
        local pid_file="${pid_files[$i]}"
        local tunnel_name=$(basename "$pid_file" .pid)
        local pid=$(cat "$pid_file" 2>/dev/null)
        
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            echo "$(($i+1))) $tunnel_name (PID: $pid)"
        fi
    done
    echo "$(($i+2))) Kill all tunnels"
    echo ""
    
    read -p "Select tunnel to kill: " choice
    
    if [[ $choice =~ ^[0-9]+$ ]]; then
        if [ $choice -eq $((${#pid_files[@]}+1)) ]; then
            # Kill all tunnels
            echo -e "${YELLOW}🔄 Killing all tunnels...${NC}"
            for pid_file in "${pid_files[@]}"; do
                local pid=$(cat "$pid_file" 2>/dev/null)
                if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                    kill "$pid" 2>/dev/null
                    echo -e "${GREEN}✅ Killed tunnel: $(basename "$pid_file" .pid)${NC}"
                    log_message "Tunnel killed: $(basename "$pid_file" .pid) (PID: $pid)"
                fi
                rm -f "$pid_file"
            done
        elif [ $choice -le ${#pid_files[@]} ] && [ $choice -gt 0 ]; then
            local selected_file="${pid_files[$((choice-1))]}"
            local tunnel_name=$(basename "$selected_file" .pid)
            local pid=$(cat "$selected_file" 2>/dev/null)
            
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null
                echo -e "${GREEN}✅ Killed tunnel: $tunnel_name${NC}"
                log_message "Tunnel killed: $tunnel_name (PID: $pid)"
            else
                echo -e "${YELLOW}⚠️ Tunnel already dead: $tunnel_name${NC}"
            fi
            rm -f "$selected_file"
        else
            echo -e "${RED}❌ Invalid selection${NC}"
        fi
    else
        echo -e "${RED}❌ Invalid selection${NC}"
    fi
}

# Function to monitor tunnels
monitor_tunnels() {
    echo -e "${CYAN}📊 Tunnel Monitoring${NC}"
    echo "==================="
    
    while true; do
        clear
        echo -e "${CYAN}📊 Tunnel Status - $(date)${NC}"
        echo "==============================="
        
        local active_count=0
        local pid_files=($(find "$PID_DIR" -name "*.pid" 2>/dev/null))
        
        for pid_file in "${pid_files[@]}"; do
            local tunnel_name=$(basename "$pid_file" .pid)
            local pid=$(cat "$pid_file" 2>/dev/null)
            
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
                echo -e "${GREEN}✅ $tunnel_name (PID: $pid)${NC}"
                ((active_count++))
            else
                echo -e "${RED}❌ $tunnel_name (DEAD)${NC}"
                rm -f "$pid_file"
            fi
        done
        
        echo ""
        echo -e "${WHITE}Total Active Tunnels: $active_count${NC}"
        echo ""
        echo -e "${MAGENTA}Press Ctrl+C to return to menu${NC}"
        
        sleep 5
    done
}

# Function to show logs
show_logs() {
    echo -e "${CYAN}📜 Tunnel Logs${NC}"
    echo "=============="
    
    if [ ! -f "$TUNNEL_LOG" ]; then
        echo -e "${YELLOW}⚠️ No log file found${NC}"
        return
    fi
    
    echo "Recent log entries:"
    tail -20 "$TUNNEL_LOG"
    echo ""
    echo -e "${CYAN}Full log file: $TUNNEL_LOG${NC}"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    
    if command -v apt &> /dev/null; then
        apt update
        apt install -y openssh-client openssh-server sshpass autossh
    elif command -v yum &> /dev/null; then
        yum install -y openssh-clients openssh-server sshpass autossh
    elif command -v pacman &> /dev/null; then
        pacman -S openssh sshpass autossh --noconfirm
    else
        echo -e "${RED}❌ Unsupported package manager${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Function to show menu
show_menu() {
    echo -e "${GREEN}🎯 Secure Tunneling Menu:${NC}"
    echo "=========================="
    echo -e "${WHITE}[1] Create SSH tunnel${NC}"
    echo -e "${WHITE}[2] List active tunnels${NC}"
    echo -e "${WHITE}[3] Kill tunnel${NC}"
    echo -e "${WHITE}[4] Monitor tunnels${NC}"
    echo -e "${WHITE}[5] SSH Key management${NC}"
    echo -e "${WHITE}[6] Show logs${NC}"
    echo -e "${WHITE}[7] Install dependencies${NC}"
    echo -e "${WHITE}[0] Exit${NC}"
    echo ""
}

# Function for SSH key management menu
ssh_key_menu() {
    while true; do
        echo -e "${GREEN}🔑 SSH Key Management:${NC}"
        echo "====================="
        echo -e "${WHITE}[1] Create new SSH key${NC}"
        echo -e "${WHITE}[2] List SSH keys${NC}"
        echo -e "${WHITE}[3] Back to main menu${NC}"
        echo ""
        
        read -p "Enter your choice (1-3): " key_choice
        
        case $key_choice in
            1)
                create_ssh_key
                read -p "Press Enter to continue..."
                ;;
            2)
                list_ssh_keys
                read -p "Press Enter to continue..."
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}❌ Invalid choice!${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Main script execution
show_banner

# Setup configuration
setup_config

echo ""

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1)
            create_ssh_tunnel
            read -p "Press Enter to continue..."
            ;;
        2)
            list_tunnels
            read -p "Press Enter to continue..."
            ;;
        3)
            kill_tunnel
            read -p "Press Enter to continue..."
            ;;
        4)
            monitor_tunnels
            ;;
        5)
            ssh_key_menu
            ;;
        6)
            show_logs
            read -p "Press Enter to continue..."
            ;;
        7)
            install_dependencies
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
