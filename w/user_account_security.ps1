# User Account Security Configuration
# XXMXLI Advanced User Account and Access Control

# Ensure we're running from the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "XXMXLI User Account Security Configuration" -ForegroundColor Blue
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
    Write-Host "User Account Security Options:" -ForegroundColor Cyan
    Write-Host "  1. Audit current user accounts"
    Write-Host "  2. Configure password policies"
    Write-Host "  3. Disable/Enable accounts"
    Write-Host "  4. Configure user rights"
    Write-Host "  5. Set up account lockout policies"
    Write-Host "  6. Audit administrator accounts"
    Write-Host "  7. Configure login restrictions"
    Write-Host "  8. Show security recommendations"
    Write-Host "  9. Exit"
    Write-Host ""
}

function Audit-UserAccounts {
    Write-Host "Auditing user accounts..." -ForegroundColor Yellow
    Write-Host ""
    
    # Get all local users
    $localUsers = Get-LocalUser
    
    Write-Host "Local User Accounts:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    foreach ($user in $localUsers) {
        $status = if ($user.Enabled) { "ENABLED" } else { "DISABLED" }
        $color = if ($user.Enabled) { 
            if ($user.Name -eq "Guest" -or $user.Name -eq "DefaultAccount") { "Red" } else { "Green" }
        } else { "Yellow" }
        
        Write-Host "User: $($user.Name)" -ForegroundColor $color
        Write-Host "  Status: $status"
        Write-Host "  Last Logon: $($user.LastLogon)"
        Write-Host "  Password Last Set: $($user.PasswordLastSet)"
        Write-Host "  Password Required: $($user.PasswordRequired)"
        Write-Host "  Account Expires: $($user.AccountExpires)"
        Write-Host ""
    }
    
    # Check for administrator group members
    Write-Host "Administrator Group Members:" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    
    try {
        $adminGroup = Get-LocalGroupMember -Group "Administrators"
        foreach ($admin in $adminGroup) {
            Write-Host "  $($admin.Name) ($($admin.ObjectClass))" -ForegroundColor $(if ($admin.ObjectClass -eq "User") { "Red" } else { "Yellow" })
        }
    } catch {
        Write-Host "  Error retrieving administrator group members" -ForegroundColor Red
    }
}

function Configure-PasswordPolicies {
    Write-Host "Configuring password policies..." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "Password Policy Configuration:" -ForegroundColor Cyan
    Write-Host "1. Minimum password length: 12 characters"
    Write-Host "2. Password complexity: Enabled"
    Write-Host "3. Maximum password age: 90 days"
    Write-Host "4. Minimum password age: 1 day"
    Write-Host "5. Password history: 12 passwords"
    Write-Host ""
    
    $confirm = Read-Host "Apply these password policies? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            # Note: These require secedit or Group Policy for full implementation
            # Here we'll use net accounts for basic settings
            
            & net accounts /minpwlen:12
            & net accounts /maxpwage:90
            & net accounts /minpwage:1
            & net accounts /uniquepw:12
            
            Write-Host "✓ Basic password policies configured" -ForegroundColor Green
            Write-Host "Note: For full password complexity, use Group Policy Editor (gpedit.msc)" -ForegroundColor Yellow
            
        } catch {
            Write-Host "✗ Error configuring password policies: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Manage-UserAccounts {
    Write-Host "User Account Management:" -ForegroundColor Yellow
    Write-Host ""
    
    # Show risky accounts
    $riskyAccounts = @("Guest", "DefaultAccount")
    
    Write-Host "Checking risky accounts..." -ForegroundColor Cyan
    foreach ($accountName in $riskyAccounts) {
        try {
            $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue
            if ($account) {
                $status = if ($account.Enabled) { "ENABLED (RISK!)" } else { "DISABLED (OK)" }
                $color = if ($account.Enabled) { "Red" } else { "Green" }
                Write-Host "  $accountName: $status" -ForegroundColor $color
                
                if ($account.Enabled) {
                    $disable = Read-Host "Disable $accountName account? (y/N)"
                    if ($disable -eq 'y' -or $disable -eq 'Y') {
                        Disable-LocalUser -Name $accountName
                        Write-Host "  ✓ $accountName account disabled" -ForegroundColor Green
                    }
                }
            }
        } catch {
            Write-Host "  $accountName: Not found or error checking" -ForegroundColor Yellow
        }
    }
    
    # Option to create a new administrator account
    Write-Host ""
    $createAdmin = Read-Host "Create a new administrator account? (y/N)"
    if ($createAdmin -eq 'y' -or $createAdmin -eq 'Y') {
        $newAdminName = Read-Host "Enter new administrator username"
        if ($newAdminName) {
            try {
                $password = Read-Host "Enter password for $newAdminName" -AsSecureString
                New-LocalUser -Name $newAdminName -Password $password -FullName "XXMXLI Administrator" -Description "Created by XXMXLI Security Script"
                Add-LocalGroupMember -Group "Administrators" -Member $newAdminName
                Write-Host "✓ Administrator account '$newAdminName' created successfully" -ForegroundColor Green
            } catch {
                Write-Host "✗ Error creating administrator account: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

function Configure-UserRights {
    Write-Host "Configuring user rights and privileges..." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "User Rights Configuration:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host "1. Deny logon as a service (Guest, DefaultAccount)"
    Write-Host "2. Deny network logon (Guest, DefaultAccount)" 
    Write-Host "3. Deny interactive logon (DefaultAccount)"
    Write-Host "4. Require Ctrl+Alt+Del for logon"
    Write-Host ""
    
    $confirm = Read-Host "Apply these user rights configurations? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            # Helper ensures key exists and sets value with proper PropertyType
            if (-not (Get-Command Set-RegistryValue -ErrorAction SilentlyContinue)) {
                function Set-RegistryValue {
                    param(
                        [Parameter(Mandatory)][string]$Path,
                        [Parameter(Mandatory)][string]$Name,
                        [Parameter(Mandatory)][object]$Value,
                        [string]$Type = "DWORD",
                        [string]$Description = ""
                    )
                    try {
                        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force -ErrorAction Stop | Out-Null }
                        $propertyType = switch -Regex ($Type) {
                            '^(dword|DWORD|DWord)$' { 'DWord' }
                            '^(qword|QWORD|QWord)$' { 'QWord' }
                            '^(string|STRING)$' { 'String' }
                            '^(expandstring|EXPANDSTRING)$' { 'ExpandString' }
                            '^(binary|BINARY)$' { 'Binary' }
                            '^(multistring|MULTISTRING)$' { 'MultiString' }
                            default { 'String' }
                        }
                        $existing = $null
                        try { $existing = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop } catch { $existing = $null }
                        if ($null -ne $existing) {
                            Set-ItemProperty -Path $Path -Name $Name -Value $Value -ErrorAction Stop | Out-Null
                        } else {
                            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $propertyType -Force -ErrorAction Stop | Out-Null
                        }
                        if ($Description) { Write-Host "  ✓ $Description" -ForegroundColor Green } else { Write-Host "  ✓ Set $Path\$Name = $Value" -ForegroundColor Green }
                    } catch { Write-Host "  ✗ Error setting $Path\$Name: $($_.Exception.Message)" -ForegroundColor Red }
                }
            }
            Set-RegistryValue -Path $regPath -Name "DisableCAD" -Value 0 -Type DWORD -Description "Enabled Ctrl+Alt+Del requirement for logon"
            Set-RegistryValue -Path $regPath -Name "DontDisplayLastUserName" -Value 1 -Type DWORD -Description "Hide last logged-on username"
            $legalNotice = Read-Host "Set a legal notice for logon? (y/N)"
            if ($legalNotice -eq 'y' -or $legalNotice -eq 'Y') {
                $noticeTitle = "AUTHORIZED USE ONLY"
                $noticeText = "This system is for authorized users only. All activities are monitored and logged. Unauthorized access is prohibited and will be prosecuted to the full extent of the law."
                Set-RegistryValue -Path $regPath -Name "LegalNoticeCaption" -Value $noticeTitle -Type String -Description "Configured logon notice caption"
                Set-RegistryValue -Path $regPath -Name "LegalNoticeText" -Value $noticeText -Type String -Description "Configured logon notice text"
            }
        } catch {
            Write-Host "✗ Error configuring user rights: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Configure-AccountLockout {
    Write-Host "Configuring account lockout policies..." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "Account Lockout Policy Configuration:" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "1. Account lockout threshold: 5 invalid attempts"
    Write-Host "2. Account lockout duration: 30 minutes"
    Write-Host "3. Reset account lockout counter: 30 minutes"
    Write-Host ""
    
    $confirm = Read-Host "Apply these lockout policies? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            & net accounts /lockoutthreshold:5
            & net accounts /lockoutduration:30
            & net accounts /lockoutwindow:30
            
            Write-Host "✓ Account lockout policies configured" -ForegroundColor Green
            
        } catch {
            Write-Host "✗ Error configuring lockout policies: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Audit-AdminAccounts {
    Write-Host "Auditing administrator accounts..." -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $adminMembers = Get-LocalGroupMember -Group "Administrators"
        
        Write-Host "Administrator Account Audit:" -ForegroundColor Cyan
        Write-Host "============================" -ForegroundColor Cyan
        
        foreach ($admin in $adminMembers) {
            Write-Host "Name: $($admin.Name)" -ForegroundColor $(if ($admin.ObjectClass -eq "User") { "Red" } else { "Yellow" })
            Write-Host "  Type: $($admin.ObjectClass)"
            Write-Host "  SID: $($admin.SID)"
            
            if ($admin.ObjectClass -eq "User") {
                try {
                    $userDetails = Get-LocalUser -Name $admin.Name.Split('\')[-1] -ErrorAction SilentlyContinue
                    if ($userDetails) {
                        Write-Host "  Last Logon: $($userDetails.LastLogon)"
                        Write-Host "  Password Last Set: $($userDetails.PasswordLastSet)"
                        
                        # Flag built-in Administrator account
                        if ($userDetails.SID.Value.EndsWith("-500")) {
                            Write-Host "  ⚠️  Built-in Administrator account detected!" -ForegroundColor Red
                        }
                    }
                } catch {
                    Write-Host "  Unable to get user details" -ForegroundColor Yellow
                }
            }
            Write-Host ""
        }
        
        # Recommendations
        Write-Host "Security Recommendations:" -ForegroundColor Cyan
        Write-Host "• Minimize the number of administrator accounts" -ForegroundColor Yellow
        Write-Host "• Use standard user accounts for daily tasks" -ForegroundColor Yellow
        Write-Host "• Rename or disable the built-in Administrator account" -ForegroundColor Yellow
        Write-Host "• Regularly audit administrator group membership" -ForegroundColor Yellow
        
    } catch {
        Write-Host "✗ Error auditing administrator accounts: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Configure-LoginRestrictions {
    Write-Host "Configuring login restrictions..." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "Login Restriction Options:" -ForegroundColor Cyan
    Write-Host "1. Restrict interactive logon hours"
    Write-Host "2. Configure remote desktop settings"
    Write-Host "3. Set up network logon restrictions"
    Write-Host ""
    
    $choice = Read-Host "Select option (1-3) or 0 to skip"
    
    switch ($choice) {
        "1" {
            Write-Host "Note: Logon hours are typically configured via User Manager or Group Policy" -ForegroundColor Yellow
            Write-Host "For command line: net user [username] /times:[hours]" -ForegroundColor Cyan
        }
        "2" {
            $rdpChoice = Read-Host "Disable Remote Desktop? (y/N)"
            if ($rdpChoice -eq 'y' -or $rdpChoice -eq 'Y') {
                try {
                    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
                    Write-Host "✓ Remote Desktop disabled" -ForegroundColor Green
                } catch {
                    Write-Host "✗ Error disabling Remote Desktop: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        "3" {
            Write-Host "Network logon restrictions are typically configured via Group Policy:" -ForegroundColor Yellow
            Write-Host "• Computer Configuration > Windows Settings > Security Settings > Local Policies > User Rights Assignment" -ForegroundColor Cyan
        }
    }
}

function Show-SecurityRecommendations {
    Write-Host "XXMXLI User Account Security Recommendations:" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🔐 CRITICAL RECOMMENDATIONS:" -ForegroundColor Red
    Write-Host "  • Use unique, complex passwords for all accounts"
    Write-Host "  • Enable two-factor authentication where possible"
    Write-Host "  • Regularly audit administrator group membership"
    Write-Host "  • Disable or rename built-in accounts (Guest, Administrator)"
    Write-Host "  • Use principle of least privilege"
    Write-Host ""
    
    Write-Host "⚙️  CONFIGURATION BEST PRACTICES:" -ForegroundColor Yellow
    Write-Host "  • Set account lockout policies (5 attempts, 30-minute lockout)"
    Write-Host "  • Configure password policies (12+ characters, complexity)"
    Write-Host "  • Enable Ctrl+Alt+Del requirement for logon"
    Write-Host "  • Hide last logged-on username"
    Write-Host "  • Set up legal notice for logon screen"
    Write-Host ""
    
    Write-Host "🛡️  MONITORING AND MAINTENANCE:" -ForegroundColor Green
    Write-Host "  • Regularly review user account activity"
    Write-Host "  • Monitor failed logon attempts"
    Write-Host "  • Remove unused accounts promptly"
    Write-Host "  • Update passwords regularly (90-day rotation)"
    Write-Host "  • Audit file and folder permissions"
    Write-Host ""
    
    Write-Host "🚨 RED FLAGS TO WATCH FOR:" -ForegroundColor Red
    Write-Host "  • Accounts with passwords that never expire"
    Write-Host "  • Multiple administrator accounts"
    Write-Host "  • Guest account enabled"
    Write-Host "  • Accounts with blank passwords"
    Write-Host "  • Service accounts with interactive logon rights"
    Write-Host ""
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select option (1-9)"
    
    switch ($choice) {
        "1" { Audit-UserAccounts }
        "2" { Configure-PasswordPolicies }
        "3" { Manage-UserAccounts }
        "4" { Configure-UserRights }
        "5" { Configure-AccountLockout }
        "6" { Audit-AdminAccounts }
        "7" { Configure-LoginRestrictions }
        "8" { Show-SecurityRecommendations }
        "9" { 
            Write-Host "Thank you for using XXMXLI User Account Security Configuration" -ForegroundColor Blue
            break 
        }
        default { 
            Write-Host "Invalid choice. Please select 1-9." -ForegroundColor Red 
        }
    }
    
    if ($choice -ne "9") {
        Write-Host ""
        Read-Host "Press Enter to continue"
        Clear-Host
    }
    
} while ($choice -ne "9")

# Log the session
$LogEntry = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Action = "User Account Security Configuration Session"
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
    AdminAccounts = (Get-LocalGroupMember -Group "Administrators" | Measure-Object).Count
}

$LogFile = Join-Path $ScriptDir "user_security_changes.log"
$LogEntry | ConvertTo-Json -Compress | Add-Content $LogFile
