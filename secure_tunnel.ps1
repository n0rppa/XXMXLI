# Secure Tunnel - Windows PowerShell Version
# SSH Tunneling and Secure Connection Tools
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization

param(
    [switch]$Help,
    [string]$CreateTunnel,
    [switch]$ListTunnels,
    [switch]$KillTunnels
)

# Configuration
$ConfigDir = "$env:USERPROFILE\.secure_tunnel"
$TunnelDir = "$ConfigDir\tunnels"
$KeyDir = "$ConfigDir\keys"
$LogFile = "$ConfigDir\tunnel.log"
$ActiveTunnelsFile = "$ConfigDir\active_tunnels.json"

# Create directories
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
if (!(Test-Path $TunnelDir)) { New-Item -ItemType Directory -Path $TunnelDir -Force | Out-Null }
if (!(Test-Path $KeyDir)) { New-Item -ItemType Directory -Path $KeyDir -Force | Out-Null }

# Set secure permissions
$acl = Get-Acl $ConfigDir
$acl.SetAccessRuleProtection($true, $false)
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $ConfigDir -AclObject $acl

# Active tunnels tracking
$Global:ActiveTunnels = @()
if (Test-Path $ActiveTunnelsFile) {
    try {
        $Global:ActiveTunnels = Get-Content $ActiveTunnelsFile | ConvertFrom-Json
    } catch {
        $Global:ActiveTunnels = @()
    }
}

# Logging function
function Write-Log {
    param($Message, $Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $logEntry
}

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host " ████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗     " -ForegroundColor Cyan
    Write-Host " ╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║     " -ForegroundColor Cyan
    Write-Host "    ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║     " -ForegroundColor Cyan
    Write-Host "    ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║     " -ForegroundColor Cyan
    Write-Host "    ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗" -ForegroundColor Cyan
    Write-Host "    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗" -ForegroundColor Cyan
    Write-Host " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║" -ForegroundColor Cyan
    Write-Host "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║" -ForegroundColor Cyan
    Write-Host " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Secure Tunnel - Windows PowerShell" -ForegroundColor Green
    Write-Host "    SSH Tunneling and Secure Connection Tools" -ForegroundColor Green
    Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
    Write-Host ""
}

# Save active tunnels
function Save-ActiveTunnels {
    $Global:ActiveTunnels | ConvertTo-Json | Out-File $ActiveTunnelsFile
}

# Create SSH key pair
function New-SSHKeyPair {
    param([string]$KeyName = "tunnel_key")
    
    $keyPath = "$KeyDir\$KeyName"
    
    if (Test-Path "$keyPath.pub") {
        Write-Log "Key pair already exists: $KeyName" "Yellow"
        return $keyPath
    }
    
    Write-Log "Generating SSH key pair..." "Yellow"
    
    try {
        # Check if ssh-keygen is available
        $sshKeygen = Get-Command ssh-keygen -ErrorAction SilentlyContinue
        
        if ($sshKeygen) {
            # Use OpenSSH ssh-keygen
            $process = Start-Process -FilePath "ssh-keygen" -ArgumentList @(
                "-t", "rsa",
                "-b", "4096",
                "-f", $keyPath,
                "-N", "",
                "-C", "tunnel-key-$env:COMPUTERNAME"
            ) -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-Log "SSH key pair generated: $keyPath" "Green"
                Write-Log "Public key: $keyPath.pub" "Green"
                return $keyPath
            } else {
                Write-Log "ssh-keygen failed with exit code: $($process.ExitCode)" "Red"
            }
        } else {
            Write-Log "OpenSSH not found. Please install OpenSSH or use PuTTY tools." "Red"
            Write-Log "You can install OpenSSH with: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" "Yellow"
        }
    }
    catch {
        Write-Log "Key generation failed: $($_.Exception.Message)" "Red"
    }
    
    return $null
}

# Port forwarding using netsh
function New-PortForward {
    param(
        [int]$LocalPort,
        [string]$RemoteHost,
        [int]$RemotePort,
        [string]$Interface = "127.0.0.1"
    )
    
    try {
        Write-Log "Creating port forward: $Interface`:$LocalPort -> $RemoteHost`:$RemotePort" "Yellow"
        
        # Create netsh port forwarding rule
        $command = "netsh interface portproxy add v4tov4 listenport=$LocalPort listenaddress=$Interface connectport=$RemotePort connectaddress=$RemoteHost"
        
        $result = Invoke-Expression $command
        
        if ($LASTEXITCODE -eq 0) {
            $tunnel = @{
                Id = [System.Guid]::NewGuid().ToString()
                Type = "PortForward"
                LocalPort = $LocalPort
                RemoteHost = $RemoteHost
                RemotePort = $RemotePort
                Interface = $Interface
                Created = Get-Date
                Command = $command
            }
            
            $Global:ActiveTunnels += $tunnel
            Save-ActiveTunnels
            
            Write-Log "Port forward created successfully" "Green"
            return $tunnel.Id
        } else {
            Write-Log "Failed to create port forward" "Red"
            return $null
        }
    }
    catch {
        Write-Log "Port forward failed: $($_.Exception.Message)" "Red"
        return $null
    }
}

# Remove port forwarding
function Remove-PortForward {
    param(
        [int]$LocalPort,
        [string]$Interface = "127.0.0.1"
    )
    
    try {
        Write-Log "Removing port forward on $Interface`:$LocalPort" "Yellow"
        
        $command = "netsh interface portproxy delete v4tov4 listenport=$LocalPort listenaddress=$Interface"
        $result = Invoke-Expression $command
        
        if ($LASTEXITCODE -eq 0) {
            # Remove from active tunnels
            $Global:ActiveTunnels = $Global:ActiveTunnels | Where-Object { 
                -not ($_.Type -eq "PortForward" -and $_.LocalPort -eq $LocalPort -and $_.Interface -eq $Interface)
            }
            Save-ActiveTunnels
            
            Write-Log "Port forward removed successfully" "Green"
        } else {
            Write-Log "Failed to remove port forward" "Red"
        }
    }
    catch {
        Write-Log "Port forward removal failed: $($_.Exception.Message)" "Red"
    }
}

# SSH tunnel using OpenSSH client
function New-SSHTunnel {
    param(
        [string]$RemoteHost,
        [string]$Username,
        [int]$LocalPort,
        [int]$RemotePort,
        [string]$KeyFile = $null,
        [string]$TunnelType = "Local" # Local, Remote, Dynamic
    )
    
    try {
        # Check if ssh is available
        $ssh = Get-Command ssh -ErrorAction SilentlyContinue
        
        if (-not $ssh) {
            Write-Log "OpenSSH client not found. Please install OpenSSH." "Red"
            Write-Log "Install with: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" "Yellow"
            return $null
        }
        
        $sshArgs = @()
        
        # Configure tunnel type
        switch ($TunnelType) {
            "Local" {
                $sshArgs += "-L", "$LocalPort`:127.0.0.1:$RemotePort"
                Write-Log "Creating local SSH tunnel: localhost:$LocalPort -> $RemoteHost`:$RemotePort" "Yellow"
            }
            "Remote" {
                $sshArgs += "-R", "$RemotePort`:127.0.0.1:$LocalPort"
                Write-Log "Creating remote SSH tunnel: $RemoteHost`:$RemotePort -> localhost:$LocalPort" "Yellow"
            }
            "Dynamic" {
                $sshArgs += "-D", "$LocalPort"
                Write-Log "Creating dynamic SSH tunnel (SOCKS proxy) on port $LocalPort" "Yellow"
            }
        }
        
        # Add common SSH options
        $sshArgs += "-N", "-f" # No command, background
        $sshArgs += "-o", "StrictHostKeyChecking=no"
        $sshArgs += "-o", "UserKnownHostsFile=NUL"
        
        # Add key file if specified
        if ($KeyFile -and (Test-Path $KeyFile)) {
            $sshArgs += "-i", $KeyFile
        }
        
        # Add user@host
        $sshArgs += "$Username@$RemoteHost"
        
        Write-Log "Starting SSH tunnel..." "Yellow"
        Write-Log "Command: ssh $($sshArgs -join ' ')" "Cyan"
        
        # Start SSH tunnel
        $process = Start-Process -FilePath "ssh" -ArgumentList $sshArgs -PassThru -WindowStyle Hidden
        
        if ($process) {
            Start-Sleep 2 # Give SSH time to establish connection
            
            if (-not $process.HasExited) {
                $tunnel = @{
                    Id = [System.Guid]::NewGuid().ToString()
                    Type = "SSH"
                    TunnelType = $TunnelType
                    ProcessId = $process.Id
                    LocalPort = $LocalPort
                    RemoteHost = $RemoteHost
                    RemotePort = $RemotePort
                    Username = $Username
                    KeyFile = $KeyFile
                    Created = Get-Date
                    Command = "ssh $($sshArgs -join ' ')"
                }
                
                $Global:ActiveTunnels += $tunnel
                Save-ActiveTunnels
                
                Write-Log "SSH tunnel created successfully (PID: $($process.Id))" "Green"
                return $tunnel.Id
            } else {
                Write-Log "SSH tunnel failed to start" "Red"
                return $null
            }
        }
    }
    catch {
        Write-Log "SSH tunnel failed: $($_.Exception.Message)" "Red"
        return $null
    }
}

# Kill SSH tunnel
function Stop-SSHTunnel {
    param([string]$TunnelId)
    
    $tunnel = $Global:ActiveTunnels | Where-Object { $_.Id -eq $TunnelId }
    
    if (-not $tunnel) {
        Write-Log "Tunnel not found: $TunnelId" "Red"
        return
    }
    
    try {
        if ($tunnel.Type -eq "SSH" -and $tunnel.ProcessId) {
            $process = Get-Process -Id $tunnel.ProcessId -ErrorAction SilentlyContinue
            if ($process) {
                Stop-Process -Id $tunnel.ProcessId -Force
                Write-Log "SSH tunnel stopped (PID: $($tunnel.ProcessId))" "Green"
            }
        }
        elseif ($tunnel.Type -eq "PortForward") {
            Remove-PortForward -LocalPort $tunnel.LocalPort -Interface $tunnel.Interface
        }
        
        # Remove from active tunnels
        $Global:ActiveTunnels = $Global:ActiveTunnels | Where-Object { $_.Id -ne $TunnelId }
        Save-ActiveTunnels
    }
    catch {
        Write-Log "Failed to stop tunnel: $($_.Exception.Message)" "Red"
    }
}

# Test port connectivity
function Test-PortConnection {
    param(
        [string]$Host,
        [int]$Port,
        [int]$Timeout = 5
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($Host, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($Timeout * 1000, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            return $true
        } else {
            $tcpClient.Close()
            return $false
        }
    }
    catch {
        return $false
    }
}

# Show active tunnels
function Show-ActiveTunnels {
    Write-Host "`nActive Tunnels:" -ForegroundColor Green
    Write-Host "===============" -ForegroundColor Green
    
    if ($Global:ActiveTunnels.Count -eq 0) {
        Write-Host "No active tunnels" -ForegroundColor Yellow
        return
    }
    
    foreach ($tunnel in $Global:ActiveTunnels) {
        $status = "Unknown"
        
        if ($tunnel.Type -eq "SSH" -and $tunnel.ProcessId) {
            $process = Get-Process -Id $tunnel.ProcessId -ErrorAction SilentlyContinue
            $status = if ($process) { "Running" } else { "Stopped" }
        }
        elseif ($tunnel.Type -eq "PortForward") {
            $portForwards = netsh interface portproxy show v4tov4 2>$null
            $status = if ($portForwards -match "$($tunnel.LocalPort)") { "Active" } else { "Inactive" }
        }
        
        Write-Host "🔗 [$($tunnel.Id.Substring(0,8))] $($tunnel.Type)" -ForegroundColor Cyan
        Write-Host "   Type: $($tunnel.TunnelType)" -ForegroundColor White
        Write-Host "   Local: $($tunnel.LocalPort), Remote: $($tunnel.RemoteHost):$($tunnel.RemotePort)" -ForegroundColor White
        Write-Host "   Status: $status" -ForegroundColor $(if ($status -match "Running|Active") { "Green" } else { "Red" })
        Write-Host "   Created: $($tunnel.Created)" -ForegroundColor Gray
        Write-Host ""
    }
}

# Kill all tunnels
function Stop-AllTunnels {
    Write-Host "WARNING: This will stop all active tunnels!" -ForegroundColor Red
    $confirm = Read-Host "Type 'STOP' to confirm"
    
    if ($confirm -eq "STOP") {
        foreach ($tunnel in $Global:ActiveTunnels) {
            Stop-SSHTunnel -TunnelId $tunnel.Id
        }
        
        # Clean up any remaining port forwards
        try {
            netsh interface portproxy reset
            Write-Log "All port forwards cleared" "Green"
        }
        catch {
            Write-Log "Failed to clear port forwards: $($_.Exception.Message)" "Red"
        }
        
        $Global:ActiveTunnels = @()
        Save-ActiveTunnels
        Write-Log "All tunnels stopped" "Green"
    }
}

# Show menu
function Show-Menu {
    Write-Host "`nSecure Tunnel Menu:" -ForegroundColor Green
    Write-Host "===================" -ForegroundColor Green
    Write-Host "[1] Create SSH tunnel (Local)" -ForegroundColor White
    Write-Host "[2] Create SSH tunnel (Remote)" -ForegroundColor White
    Write-Host "[3] Create SSH tunnel (Dynamic/SOCKS)" -ForegroundColor White
    Write-Host "[4] Create port forward" -ForegroundColor White
    Write-Host "[5] Generate SSH key pair" -ForegroundColor White
    Write-Host "[6] Show active tunnels" -ForegroundColor White
    Write-Host "[7] Stop specific tunnel" -ForegroundColor White
    Write-Host "[8] Stop all tunnels" -ForegroundColor White
    Write-Host "[9] Test port connectivity" -ForegroundColor White
    Write-Host "[0] Exit" -ForegroundColor White
    Write-Host ""
}

# Help function
function Show-Help {
    Write-Host @"
Secure Tunnel - Windows PowerShell

SYNOPSIS
    SSH tunneling and secure connection tools for Windows

DESCRIPTION
    This tool provides comprehensive tunneling capabilities including:
    - SSH local/remote/dynamic tunnels
    - Port forwarding using netsh
    - SSH key generation
    - Tunnel management
    - Connectivity testing

PARAMETERS
    -Help          Show this help message
    -CreateTunnel  Create a specific tunnel type
    -ListTunnels   List all active tunnels
    -KillTunnels   Stop all tunnels

EXAMPLES
    .\secure_tunnel.ps1
    .\secure_tunnel.ps1 -ListTunnels
    .\secure_tunnel.ps1 -KillTunnels

REQUIREMENTS
    - Windows 10/11 or Windows Server
    - PowerShell 5.0 or later
    - OpenSSH Client (optional but recommended)
    - Administrator privileges for some features

TUNNEL TYPES
    - Local SSH Tunnel: Forward local port to remote service
    - Remote SSH Tunnel: Forward remote port to local service
    - Dynamic SSH Tunnel: SOCKS proxy for browsing
    - Port Forward: Simple port forwarding using netsh

SECURITY NOTES
    - SSH keys are stored with restricted permissions
    - Tunnels run in background processes
    - All connections are logged
    - Use strong authentication methods

INSTALLATION
    Install OpenSSH Client:
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

"@
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Show-Banner

if ($ListTunnels) {
    Show-ActiveTunnels
    exit 0
}

if ($KillTunnels) {
    Stop-AllTunnels
    exit 0
}

if ($CreateTunnel) {
    # Command line tunnel creation (basic implementation)
    Write-Log "Interactive tunnel creation not implemented in command line mode" "Yellow"
    Write-Log "Run without parameters for interactive mode" "Yellow"
    exit 0
}

# Main interactive loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (0-9)"
    
    switch ($choice) {
        "1" {
            # Local SSH tunnel
            $remoteHost = Read-Host "Enter remote host"
            $username = Read-Host "Enter username"
            $localPort = Read-Host "Enter local port"
            $remotePort = Read-Host "Enter remote port"
            $keyFile = Read-Host "Enter key file path (optional)"
            
            if ([string]::IsNullOrWhiteSpace($keyFile)) {
                $keyFile = $null
            }
            
            $tunnelId = New-SSHTunnel -RemoteHost $remoteHost -Username $username -LocalPort $localPort -RemotePort $remotePort -KeyFile $keyFile -TunnelType "Local"
            
            if ($tunnelId) {
                Write-Log "Tunnel created with ID: $($tunnelId.Substring(0,8))" "Green"
            }
            
            Read-Host "Press Enter to continue"
        }
        "2" {
            # Remote SSH tunnel
            $remoteHost = Read-Host "Enter remote host"
            $username = Read-Host "Enter username"
            $localPort = Read-Host "Enter local port"
            $remotePort = Read-Host "Enter remote port"
            $keyFile = Read-Host "Enter key file path (optional)"
            
            if ([string]::IsNullOrWhiteSpace($keyFile)) {
                $keyFile = $null
            }
            
            $tunnelId = New-SSHTunnel -RemoteHost $remoteHost -Username $username -LocalPort $localPort -RemotePort $remotePort -KeyFile $keyFile -TunnelType "Remote"
            
            if ($tunnelId) {
                Write-Log "Tunnel created with ID: $($tunnelId.Substring(0,8))" "Green"
            }
            
            Read-Host "Press Enter to continue"
        }
        "3" {
            # Dynamic SSH tunnel (SOCKS proxy)
            $remoteHost = Read-Host "Enter remote host"
            $username = Read-Host "Enter username"
            $localPort = Read-Host "Enter SOCKS proxy port (e.g., 1080)"
            $keyFile = Read-Host "Enter key file path (optional)"
            
            if ([string]::IsNullOrWhiteSpace($keyFile)) {
                $keyFile = $null
            }
            
            $tunnelId = New-SSHTunnel -RemoteHost $remoteHost -Username $username -LocalPort $localPort -RemotePort 0 -KeyFile $keyFile -TunnelType "Dynamic"
            
            if ($tunnelId) {
                Write-Log "SOCKS proxy created on port $localPort" "Green"
                Write-Log "Configure your browser to use 127.0.0.1:$localPort as SOCKS proxy" "Cyan"
                Write-Log "Tunnel ID: $($tunnelId.Substring(0,8))" "Green"
            }
            
            Read-Host "Press Enter to continue"
        }
        "4" {
            # Port forward
            $localPort = Read-Host "Enter local port"
            $remoteHost = Read-Host "Enter remote host"
            $remotePort = Read-Host "Enter remote port"
            $interface = Read-Host "Enter interface (default: 127.0.0.1)"
            
            if ([string]::IsNullOrWhiteSpace($interface)) {
                $interface = "127.0.0.1"
            }
            
            $tunnelId = New-PortForward -LocalPort $localPort -RemoteHost $remoteHost -RemotePort $remotePort -Interface $interface
            
            if ($tunnelId) {
                Write-Log "Port forward created with ID: $($tunnelId.Substring(0,8))" "Green"
            }
            
            Read-Host "Press Enter to continue"
        }
        "5" {
            # Generate SSH key
            $keyName = Read-Host "Enter key name (default: tunnel_key)"
            if ([string]::IsNullOrWhiteSpace($keyName)) {
                $keyName = "tunnel_key"
            }
            
            $keyPath = New-SSHKeyPair -KeyName $keyName
            
            if ($keyPath) {
                Write-Host "Key files created:" -ForegroundColor Green
                Write-Host "Private key: $keyPath" -ForegroundColor White
                Write-Host "Public key: $keyPath.pub" -ForegroundColor White
                
                if (Test-Path "$keyPath.pub") {
                    Write-Host "`nPublic key content:" -ForegroundColor Cyan
                    Get-Content "$keyPath.pub"
                }
            }
            
            Read-Host "Press Enter to continue"
        }
        "6" {
            Show-ActiveTunnels
            Read-Host "Press Enter to continue"
        }
        "7" {
            Show-ActiveTunnels
            if ($Global:ActiveTunnels.Count -gt 0) {
                $tunnelId = Read-Host "Enter tunnel ID to stop (first 8 characters)"
                $fullTunnelId = ($Global:ActiveTunnels | Where-Object { $_.Id.StartsWith($tunnelId) })[0].Id
                
                if ($fullTunnelId) {
                    Stop-SSHTunnel -TunnelId $fullTunnelId
                } else {
                    Write-Log "Tunnel not found" "Red"
                }
            }
            Read-Host "Press Enter to continue"
        }
        "8" {
            Stop-AllTunnels
            Read-Host "Press Enter to continue"
        }
        "9" {
            $host = Read-Host "Enter host to test"
            $port = Read-Host "Enter port to test"
            
            Write-Log "Testing connection to $host`:$port..." "Yellow"
            
            if (Test-PortConnection -Host $host -Port $port) {
                Write-Log "Connection successful!" "Green"
            } else {
                Write-Log "Connection failed" "Red"
            }
            
            Read-Host "Press Enter to continue"
        }
        "0" {
            Write-Log "Goodbye!" "Green"
            exit 0
        }
        default {
            Write-Log "Invalid choice!" "Red"
            Read-Host "Press Enter to continue"
        }
    }
}
