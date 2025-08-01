# XXMXLI IP Blacklist Tools for Windows

## Overview
This package contains Windows-compatible tools for processing IP blacklists and implementing network-level protection on Windows systems.

## Files Included

### Core Scripts
- **`process_w_blacklists.ps1`** - PowerShell script (recommended)
- **`process_w_blacklists.bat`** - Batch file (legacy support)
- **`process_w_blacklists.py`** - Python script (cross-platform)

### Generated Output Files
- **`blocked_ips.js`** - JavaScript array of blocked IPs
- **`blocked_ips.json`** - JSON format IP list with statistics
- **`blocked_ips.txt`** - Plain text IP list
- **`blacklist_stats.json`** - Processing statistics and metadata
- **`apply_firewall_rules.ps1`** - Windows Firewall rules (PowerShell)
- **`apply_ip_blocks.bat`** - Windows Firewall rules (Batch)
- **`hosts_entries.txt`** - Hosts file entries

## Quick Start

### Method 1: PowerShell (Recommended)
```powershell
# Run with default settings
.\process_w_blacklists.ps1

# Run with firewall rules generation
.\process_w_blacklists.ps1 -GenerateFirewallRules

# Run with hosts file entries
.\process_w_blacklists.ps1 -GenerateHostsFile

# Run with verbose output
.\process_w_blacklists.ps1 -Verbose

# Full featured run
.\process_w_blacklists.ps1 -GenerateFirewallRules -GenerateHostsFile -Verbose
```

### Method 2: Batch File
```cmd
# Double-click the file or run from command prompt
process_w_blacklists.bat
```

### Method 3: Python (if installed)
```cmd
python process_w_blacklists.py
```

## Prerequisites

### For PowerShell Script
- Windows PowerShell 5.1 or PowerShell Core 6+
- Administrator privileges (for firewall rules)

### For Batch Script
- Windows Command Prompt
- Administrator privileges (for firewall rules)

### For Python Script
- Python 3.6+
- No additional packages required

## Directory Structure

```
XXMXLI/
├── w/                          # Source blacklist files
│   ├── blacklist.txt
│   ├── BLKLST/
│   └── BlokeD/
├── assets/
│   └── security/               # Generated output files
├── process_w_blacklists.ps1    # PowerShell processor
├── process_w_blacklists.bat    # Batch processor
├── process_w_blacklists.py     # Python processor
└── README_Windows.md           # This file
```

## Usage Instructions

### 1. Prepare Blacklist Files
- Create a folder named `w` in the same directory as the scripts
- Add your IP blacklist files to the `w` folder
- Supported formats: `.txt`, `.list`, `.ipset`, `.csv`, `.dat`, `.conf`
- Files can contain comments (lines starting with #)

### 2. Run the Processor
Choose your preferred method from the Quick Start section above.

### 3. Apply Generated Rules

#### Windows Firewall (Recommended)
```powershell
# Run as Administrator
.\apply_firewall_rules.ps1
```

#### Hosts File Method
1. Run Notepad as Administrator
2. Open `C:\Windows\System32\drivers\etc\hosts`
3. Append contents of `hosts_entries.txt`
4. Save the file

#### Web Application Integration
```javascript
// Include the generated JavaScript file
<script src="assets/security/blocked_ips.js"></script>

// Use in your application
if (isIPBlocked(userIP)) {
    console.log('IP is blocked');
}
```

## Security Features

### Firewall Integration
- Blocks IPs at the network level
- Creates inbound and outbound rules
- Organizes rules in manageable batches
- Easy removal of all XXMXLI rules

### Hosts File Integration
- Redirects blocked IPs to localhost
- Works with all applications
- No additional software required
- Immediate effect after saving

### Web Protection
- JavaScript integration for web apps
- JSON data for server-side processing
- Statistics and metadata included
- Cross-platform compatibility

## Performance Considerations

### Large Blacklists
- PowerShell: Handles 100,000+ IPs efficiently
- Batch: May be slower with very large lists
- Firewall rules: Limited to ~1000 rules per batch

### Memory Usage
- PowerShell: Moderate memory usage
- Batch: Low memory usage
- Generated files: Compressed when possible

## Troubleshooting

### Common Issues

**PowerShell Execution Policy Error**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Access Denied for Firewall Rules**
- Run PowerShell/Command Prompt as Administrator
- Ensure Windows Firewall service is running

**Large File Processing**
- Split large blacklists into smaller files
- Use PowerShell for better performance
- Monitor system resources during processing

### Error Messages

**"Source directory not found"**
- Create the `w` folder in the script directory
- Add your blacklist files to the `w` folder

**"PowerShell not found"**
- Install PowerShell from Microsoft Store
- Or use the batch file alternative

**"Access denied to hosts file"**
- Run Notepad as Administrator
- Check file permissions on hosts file

## Advanced Configuration

### PowerShell Parameters
```powershell
# Custom source directory
.\process_w_blacklists.ps1 -SourceDir "C:\Blacklists"

# Custom output directory
.\process_w_blacklists.ps1 -OutputDir "C:\Security"

# Combine parameters
.\process_w_blacklists.ps1 -SourceDir "custom" -OutputDir "output" -Verbose
```

### Batch File Customization
Edit the configuration section at the top of the batch file:
```batch
set "SOURCE_DIR=your_custom_directory"
set "OUTPUT_DIR=your_output_directory"
```

## Automation

### Scheduled Tasks
Create a Windows scheduled task to run the processor automatically:

```powershell
# Create daily task
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\path\to\process_w_blacklists.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "XXMXLI-Blacklist-Update" -Action $Action -Trigger $Trigger -Settings $Settings
```

### Continuous Monitoring
For real-time protection, consider:
- Windows Defender integration
- Third-party firewall solutions
- Network-level blocking (router/gateway)

## Security Warnings

⚠️ **Important Security Notes:**
- Always review blacklists before applying
- Test firewall rules in a safe environment
- Keep backups of original configurations
- Monitor system performance after applying rules
- Regularly update blacklist sources

## Support and Updates

For the latest version and support:
- Website: https://xxmxli.com/security.html
- Download latest tools from the security section
- Report issues through the website contact form

## License

These tools are provided for educational and legitimate security purposes only. Use responsibly and in accordance with applicable laws and regulations.

---

**XXMXLI Security Toolkit - Windows Edition**
*Protecting your digital world, one IP at a time.*
