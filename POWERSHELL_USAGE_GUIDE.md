# PowerShell Scripts Usage Guide - XXMXLI

## 🔧 **PowerShell Script Execution Instructions**

The XXMXLI system includes several PowerShell (.ps1) scripts for Windows users. These provide advanced system configuration and security features.

---

## 📋 **Available PowerShell Scripts**

### **Main Scripts (Root Directory)**
- `disable_ipv6_geolocation.ps1` - Disable IPv6 geolocation for privacy
- `mac_ip_changer.ps1` - Advanced MAC address and IP configuration
- `automated_incident_reporter.ps1` - Security incident reporting (if available)
- `dns_security_setup.ps1` - DNS security configuration
- `encryption_tools.ps1` - File and communication encryption
- `network_monitor.ps1` - Network traffic monitoring
- `secure_tunnel.ps1` - VPN and secure tunneling setup
- `system_hardening.ps1` - Windows security hardening

### **W Folder Scripts (`/w/` directory)**
The `w` folder contains Windows-specific security and configuration utilities:
- `w/windows_defender_config.ps1` - Windows Defender configuration and optimization
- `w/firewall_rules.ps1` - Advanced Windows Firewall management
- `w/registry_security.ps1` - Registry security hardening with backup/restore
- `w/user_account_security.ps1` - User account and access control configuration
- `w/system_diagnostics.ps1` - Comprehensive system information and security analysis

### **Legacy W Folder Content**
- `w/BLKLST/` - Blacklist management utilities
- `w/BlokeD/` - Blocked content handling systems  
- `w/blacklist.txt` - Blacklist definitions and rules

---

## 🚀 **How to Run PowerShell Scripts**

### **Method 1: Right-Click Context Menu**
1. Navigate to the script location
2. Right-click on the `.ps1` file
3. Select **"Run with PowerShell"**
4. If prompted, allow execution

### **Method 2: PowerShell Terminal (Recommended)**
1. Open **PowerShell as Administrator**:
   - Press `Win + X`
   - Select **"Windows PowerShell (Admin)"** or **"Terminal (Admin)"**

2. Navigate to the script directory:
   ```powershell
   cd "C:\path\to\XXMXLI"
   ```

3. Run the script:
   ```powershell
   .\script_name.ps1
   ```

### **Method 3: From Command Prompt**
1. Open **Command Prompt as Administrator**
2. Run:
   ```cmd
   powershell -ExecutionPolicy Bypass -File "script_name.ps1"
   ```

---

## 🔒 **Execution Policy Configuration**

PowerShell may block script execution by default. Here's how to fix it:

### **Temporary Permission (Recommended)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### **Permanent Permission (Use with caution)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Check Current Policy**
```powershell
Get-ExecutionPolicy -List
```

---

## 🛠️ **Step-by-Step Examples**

### **Example 1: Disable IPv6 Geolocation**
```powershell
# Open PowerShell as Administrator
# Navigate to XXMXLI directory
cd "C:\Users\YourName\Desktop\XXMXLI"

# Run the script
.\disable_ipv6_geolocation.ps1
```

### **Example 2: Change MAC Address**
```powershell
# Ensure you're in the XXMXLI directory
cd "C:\path\to\XXMXLI"

# Run MAC changer with full path
.\mac_ip_changer.ps1
```

### **Example 3: Run W Folder Scripts**
```powershell
# Navigate to the w folder
cd "C:\path\to\XXMXLI\w"

# Run Windows Defender configuration
.\windows_defender_config.ps1

# Or run from main directory
.\w\firewall_rules.ps1
```

---

## ⚡ **Quick Start Commands**

### **One-Line Execution**
```powershell
# Run any script with full error handling
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '.\script_name.ps1'"

# Run with logging
powershell -ExecutionPolicy Bypass -File ".\script_name.ps1" | Tee-Object -FilePath "execution.log"
```

### **Batch Run Multiple Scripts**
```powershell
# Run multiple security scripts in sequence
$scripts = @(
    ".\disable_ipv6_geolocation.ps1",
    ".\system_hardening.ps1",
    ".\w\windows_defender_config.ps1"
)

foreach ($script in $scripts) {
    Write-Host "Running: $script" -ForegroundColor Green
    & $script
}
```

---

## 🔧 **Troubleshooting**

### **Common Issues and Solutions**

#### **"Execution of scripts is disabled on this system"**
**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

#### **"Cannot be loaded because running scripts is disabled"**
**Solution:**
```powershell
powershell -ExecutionPolicy Bypass -File "script_name.ps1"
```

#### **"Access is denied" or "Administrator privileges required"**
**Solution:**
- Always run PowerShell as Administrator
- Right-click PowerShell → "Run as administrator"

#### **"Path not found" errors**
**Solution:**
```powershell
# Always use full paths or navigate to script directory first
cd "C:\full\path\to\XXMXLI"
.\script_name.ps1
```

---

## 📁 **Directory Structure Reference**

```
XXMXLI/
├── disable_ipv6_geolocation.ps1
├── mac_ip_changer.ps1
├── dns_security_setup.ps1
├── encryption_tools.ps1
├── network_monitor.ps1
├── secure_tunnel.ps1
├── system_hardening.ps1
└── w/
    ├── windows_defender_config.ps1
    ├── registry_security.ps1
    ├── firewall_rules.ps1
    ├── user_account_security.ps1
    ├── service_management.ps1
## 📁 **W Folder Structure Details**

The `w` folder is specifically designed for Windows-centric security operations:

```
w/
├── windows_defender_config.ps1    # Windows Defender security configuration
├── firewall_rules.ps1             # Advanced firewall management
├── registry_security.ps1          # Registry hardening with backup
├── user_account_security.ps1      # User account and access control
├── system_diagnostics.ps1         # System analysis and reporting
├── BLKLST/                        # Blacklist management utilities
├── BlokeD/                        # Blocked content handling
└── blacklist.txt                  # Blacklist definitions
```

### **Script Functionality Overview:**

**windows_defender_config.ps1:**
- Enable/disable real-time protection
- Configure exclusions and scan settings
- Update signature databases
- Performance optimization

**firewall_rules.ps1:**
- Block/allow specific ports and applications
- Configure network profiles (Domain, Private, Public)
- Create custom security rules
- Monitor active connections

**registry_security.ps1:**
- Harden Windows registry settings
- Create automatic backups before changes
- Disable dangerous Windows features
- Configure privacy and security policies

**user_account_security.ps1:**
- Audit user accounts and permissions
- Configure password policies
- Manage administrator accounts
- Set up account lockout policies

**system_diagnostics.ps1:**
- Comprehensive system security analysis
- Generate detailed security reports
- Monitor system events and processes
- Export findings for review

---

## 🛡️ **Security Best Practices**

### **Before Running Scripts:**
1. **Review the script content** - Always check what scripts do before running
2. **Run as Administrator** - Most system scripts require elevated privileges
3. **Backup your system** - Create restore points before major changes
4. **Test in VM first** - If possible, test scripts in a virtual machine

### **Script Verification:**
```powershell
# Check script signature (if available)
Get-AuthenticodeSignature .\script_name.ps1

# View script content before running
Get-Content .\script_name.ps1 | more
```

---

## 📝 **Logging and Monitoring**

### **Enable Script Logging:**
```powershell
# Run with transcript logging
Start-Transcript -Path "C:\XXMXLI\logs\powershell_session.log"
.\script_name.ps1
Stop-Transcript
```

### **Create Execution Log:**
```powershell
# Log all output to file
.\script_name.ps1 2>&1 | Tee-Object -FilePath "execution_log.txt"
```

---

## 🔄 **Automation Options**

### **Create Batch File Launcher:**
Create `run_powershell_script.bat`:
```batch
@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "script_name.ps1"
pause
```

### **Task Scheduler Integration:**
1. Open Task Scheduler
2. Create Basic Task
3. Set Action: "Start a program"
4. Program: `powershell.exe`
5. Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\script.ps1"`

---

## 📞 **Support and Help**

### **Get Script Help:**
```powershell
# Most XXMXLI scripts support help
.\script_name.ps1 -Help

# Or check for built-in help
Get-Help .\script_name.ps1
```

### **PowerShell Built-in Help:**
```powershell
# General PowerShell help
Get-Help about_Execution_Policies
Get-Help about_Scripts
```

---

## 🎯 **Quick Reference Commands**

```powershell
# Navigate to XXMXLI
cd "C:\path\to\XXMXLI"

# List all PowerShell scripts
Get-ChildItem -Recurse -Filter "*.ps1"

# Run with bypass policy
Set-ExecutionPolicy Bypass -Scope Process; .\script.ps1

# Run with administrator check
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Batch run all scripts in w folder
Get-ChildItem ".\w\*.ps1" | ForEach-Object { & $_.FullName }
```

---

**Note:** Always ensure you understand what each script does before execution. Some scripts make significant system changes that may require reboot or could affect system behavior.

For additional support, check the individual script help documentation or consult the XXMXLI main documentation.
