# Windows Firewall Rules Configuration
# XXMXLI Advanced Firewall Security Configuration

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI Windows Firewall Rules Configuration" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "ERROR: This script requires administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Running with administrator privileges" -ForegroundColor Green
Write-Host ""

function Show-Menu {
    Write-Host "Firewall Configuration Options:" -ForegroundColor Cyan
    Write-Host "  1. Enable Windows Firewall (all profiles)"
    Write-Host "  2. Configure security rules"
    Write-Host "  3. Block suspicious ports"
    Write-Host "  4. Allow essential applications"
    Write-Host "  5. Show current firewall status"
    Write-Host "  6. Reset to default rules"
    Write-Host "  7. Exit"
    Write-Host ""
}

function Enable-FirewallProfiles {
    Write-Host "Enabling Windows Firewall for all profiles..." -ForegroundColor Yellow
    
    try {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block
        Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
        
        Write-Host "✓ Windows Firewall enabled for all profiles" -ForegroundColor Green
        Write-Host "✓ Default inbound: Block, Default outbound: Allow" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error enabling firewall: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Configure-SecurityRules {
    Write-Host "Configuring security firewall rules..." -ForegroundColor Yellow
    
    try {
        # Block common attack ports
        $attackPorts = @(135, 139, 445, 1433, 1434, 3389, 5985, 5986)
        foreach ($port in $attackPorts) {
            $ruleName = "XXMXLI_Block_Port_$port"
            if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $port -Action Block
                Write-Host "  ✓ Blocked inbound TCP port $port" -ForegroundColor Green
            }
        }
        
        # Allow essential Windows services
        $essentialRules = @(
            @{Name="XXMXLI_Allow_HTTP"; Protocol="TCP"; Port=80; Direction="Outbound"},
            @{Name="XXMXLI_Allow_HTTPS"; Protocol="TCP"; Port=443; Direction="Outbound"},
            @{Name="XXMXLI_Allow_DNS"; Protocol="UDP"; Port=53; Direction="Outbound"}
        )
        
        foreach ($rule in $essentialRules) {
            if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $rule.Name -Direction $rule.Direction -Protocol $rule.Protocol -LocalPort $rule.Port -Action Allow
                Write-Host "  ✓ Allowed $($rule.Direction) $($rule.Protocol) port $($rule.Port)" -ForegroundColor Green
            }
        }
        
        Write-Host "✓ Security rules configured successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error configuring security rules: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Block-SuspiciousPorts {
    Write-Host "Blocking suspicious and unnecessary ports..." -ForegroundColor Yellow
    
    $suspiciousPorts = @(
        @{Port=23; Protocol="TCP"; Description="Telnet"},
        @{Port=69; Protocol="UDP"; Description="TFTP"},
        @{Port=135; Protocol="TCP"; Description="RPC Endpoint Mapper"},
        @{Port=139; Protocol="TCP"; Description="NetBIOS Session"},
        @{Port=445; Protocol="TCP"; Description="SMB"},
        @{Port=1433; Protocol="TCP"; Description="SQL Server"},
        @{Port=1434; Protocol="UDP"; Description="SQL Browser"},
        @{Port=3389; Protocol="TCP"; Description="RDP (block external)"},
        @{Port=5985; Protocol="TCP"; Description="WinRM HTTP"},
        @{Port=5986; Protocol="TCP"; Description="WinRM HTTPS"}
    )
    
    try {
        foreach ($portInfo in $suspiciousPorts) {
            $ruleName = "XXMXLI_Block_$($portInfo.Description)_$($portInfo.Port)"
            if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol $portInfo.Protocol -LocalPort $portInfo.Port -Action Block
                Write-Host "  ✓ Blocked $($portInfo.Description) (port $($portInfo.Port)/$($portInfo.Protocol))" -ForegroundColor Green
            }
        }
        
        Write-Host "✓ Suspicious ports blocked successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error blocking suspicious ports: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-FirewallStatus {
    Write-Host "Current Windows Firewall Status:" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    $profiles = Get-NetFirewallProfile
    foreach ($profile in $profiles) {
        $status = if ($profile.Enabled) { "ENABLED" } else { "DISABLED" }
        $color = if ($profile.Enabled) { "Green" } else { "Red" }
        Write-Host "$($profile.Name) Profile: $status" -ForegroundColor $color
        Write-Host "  Default Inbound Action: $($profile.DefaultInboundAction)"
        Write-Host "  Default Outbound Action: $($profile.DefaultOutboundAction)"
        Write-Host ""
    }
    
    # Show XXMXLI custom rules
    $xxmxliRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" }
    if ($xxmxliRules) {
        Write-Host "XXMXLI Custom Rules:" -ForegroundColor Yellow
        $xxmxliRules | Select-Object DisplayName, Direction, Action, Enabled | Format-Table -AutoSize
    }
}

function Reset-FirewallRules {
    Write-Host "Resetting firewall to default rules..." -ForegroundColor Yellow
    
    $confirm = Read-Host "This will remove all XXMXLI custom rules. Continue? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            # Remove XXMXLI custom rules
            Get-NetFirewallRule | Where-Object { $_.DisplayName -like "XXMXLI_*" } | Remove-NetFirewallRule
            
            # Reset to default settings
            netsh advfirewall reset
            
            Write-Host "✓ Firewall reset to default configuration" -ForegroundColor Green
            
        } catch {
            Write-Host "✗ Error resetting firewall: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (1-7)"
    
    switch ($choice) {
        "1" { Enable-FirewallProfiles }
        "2" { Configure-SecurityRules }
        "3" { Block-SuspiciousPorts }
        "4" { 
            Write-Host "Allow essential applications feature coming soon..." -ForegroundColor Yellow
            Write-Host "Currently allowing HTTP, HTTPS, and DNS automatically" -ForegroundColor Green
        }
        "5" { Show-FirewallStatus }
        "6" { Reset-FirewallRules }
        "7" { 
            Write-Host "Thank you for using XXMXLI Firewall Configuration" -ForegroundColor Blue
            break 
        }
        default { 
            Write-Host "Invalid choice. Please select 1-7." -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "7") {
        Write-Host ""
        Read-Host "Press Enter to continue"
        Clear-Host
    }
    
} while ($choice -ne "7")

# Log the session
$LogEntry = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Action = "Firewall Configuration Session"
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
}

$LogFile = Join-Path $ScriptDir "firewall_changes.log"
$LogEntry | ConvertTo-Json | Add-Content $LogFile
