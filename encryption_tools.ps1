# Encryption Tools - Windows PowerShell Version
# File/Folder Encryption and Security Tools
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

#Requires -Version 5.1

param(
    [switch]$Help,
    [ValidateNotNullOrEmpty()]
    [string]$EncryptFile,
    [ValidateNotNullOrEmpty()]
    [string]$DecryptFile,
    [switch]$GenerateKey
)

# Configuration
$ConfigDir = Join-Path $env:USERPROFILE ".encryption_tools"
$KeyDir = Join-Path $ConfigDir "keys"
$VaultDir = Join-Path $ConfigDir "vaults"
$LogFile = Join-Path $ConfigDir "encryption.log"

# Create directories
if (!(Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
if (!(Test-Path $KeyDir)) { New-Item -ItemType Directory -Path $KeyDir -Force | Out-Null }
if (!(Test-Path $VaultDir)) { New-Item -ItemType Directory -Path $VaultDir -Force | Out-Null }

# Set secure permissions
$acl = Get-Acl $ConfigDir
$acl.SetAccessRuleProtection($true, $false)
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $ConfigDir -AclObject $acl

# Logging function
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [ValidateSet("White", "Red", "Green", "Yellow", "Cyan", "Magenta", "Blue")]
        [string]$Color = "White"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp - $Message"
        Write-Host $Message -ForegroundColor $Color
        Add-Content -Path $LogFile -Value $logEntry
    }
    catch {
        Write-Host "Failed to write log: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host " ███████╗███╗   ██╗ ██████╗██████╗ ██╗   ██╗██████╗ ████████╗" -ForegroundColor Cyan
    Write-Host " ██╔════╝████╗  ██║██╔════╝██╔══██╗╚██╗ ██╔╝██╔══██╗╚══██╔══╝" -ForegroundColor Cyan
    Write-Host " █████╗  ██╔██╗ ██║██║     ██████╔╝ ╚████╔╝ ██████╔╝   ██║   " -ForegroundColor Cyan
    Write-Host " ██╔══╝  ██║╚██╗██║██║     ██╔══██╗  ╚██╔╝  ██╔═══╝    ██║   " -ForegroundColor Cyan
    Write-Host " ███████╗██║ ╚████║╚██████╗██║  ██║   ██║   ██║        ██║   " -ForegroundColor Cyan
    Write-Host " ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝        ╚═╝   " -ForegroundColor Cyan
    Write-Host ""
    Write-Host " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗" -ForegroundColor Cyan
    Write-Host " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║" -ForegroundColor Cyan
    Write-Host "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║" -ForegroundColor Cyan
    Write-Host "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║" -ForegroundColor Cyan
    Write-Host " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║" -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    Encryption Tools - Windows PowerShell" -ForegroundColor Green
    Write-Host "    File/Folder Encryption and Security Tools" -ForegroundColor Green
    Write-Host "    Educational and Authorized Use Only" -ForegroundColor Yellow
    Write-Host ""
}

# Generate secure random key
function New-EncryptionKey {
    [CmdletBinding()]
    param(
        [ValidateRange(16, 128)]
        [int]$Length = 32
    )

    try {
        $bytes = New-Object byte[] $Length
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
        $rng.GetBytes($bytes)
        $rng.Dispose()

        return [Convert]::ToBase64String($bytes)
    }
    catch {
        Write-Log "Failed to generate encryption key: $($_.Exception.Message)" "Red"
        throw
    }
}

# Generate secure password
function New-SecurePassword {
    [CmdletBinding()]
    param(
        [ValidateRange(8, 128)]
        [int]$Length = 32
    )

    try {
        $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        $password = ""
        $random = New-Object System.Random

        for ($i = 0; $i -lt $Length; $i++) {
            $password += $chars[$random.Next(0, $chars.Length)]
        }

        return $password
    }
    catch {
        Write-Log "Failed to generate secure password: $($_.Exception.Message)" "Red"
        throw
    }
}

# Encrypt file using AES
function Protect-FileAES {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    try {
        if (!(Test-Path $FilePath)) {
            Write-Log "File not found: $FilePath" "Red"
            return $false
        }

        Write-Log "Encrypting file: $FilePath" "Yellow"

        # Read file content
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

        # Create AES encryption
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        # Derive key from password
        $salt = New-Object byte[] 16
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
        $rng.GetBytes($salt)
        $rng.Dispose()

        $key = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, 10000)
        $aes.Key = $key.GetBytes(32)
        $aes.IV = $key.GetBytes(16)

        # Encrypt
        $encryptor = $aes.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($fileBytes, 0, $fileBytes.Length)

        # Combine salt + encrypted data
        $finalBytes = $salt + $encryptedBytes

        # Write to output file
        [System.IO.File]::WriteAllBytes($OutputPath, $finalBytes)

        # Cleanup
        $aes.Dispose()
        $key.Dispose()
        $encryptor.Dispose()

        Write-Log "File encrypted successfully: $OutputPath" "Green"
        return $true
    }
    catch {
        Write-Log "Encryption failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Decrypt file using AES
function Unprotect-FileAES {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath
    )

    try {
        if (!(Test-Path $FilePath)) {
            Write-Log "File not found: $FilePath" "Red"
            return $false
        }

        Write-Log "Decrypting file: $FilePath" "Yellow"

        # Read encrypted file
        $encryptedBytes = [System.IO.File]::ReadAllBytes($FilePath)

        if ($encryptedBytes.Length -lt 16) {
            Write-Log "Invalid encrypted file format" "Red"
            return $false
        }

        # Extract salt and encrypted data
        $salt = $encryptedBytes[0..15]
        $encryptedData = $encryptedBytes[16..($encryptedBytes.Length - 1)]

        # Create AES decryption
        $aes = [System.Security.Cryptography.Aes]::Create()
        $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
        $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7

        # Derive key from password
        $key = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($Password, $salt, 10000)
        $aes.Key = $key.GetBytes(32)
        $aes.IV = $key.GetBytes(16)

        # Decrypt
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)

        # Write to output file
        [System.IO.File]::WriteAllBytes($OutputPath, $decryptedBytes)

        # Cleanup
        $aes.Dispose()
        $key.Dispose()
        $decryptor.Dispose()

        Write-Log "File decrypted successfully: $OutputPath" "Green"
        return $true
    }
    catch {
        Write-Log "Decryption failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Encrypt folder
function Protect-Folder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderPath
    )

    try {
        if (!(Test-Path $FolderPath)) {
            Write-Log "Folder not found: $FolderPath" "Red"
            return
        }

        $folderName = Split-Path $FolderPath -Leaf
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archiveName = "${folderName}_${timestamp}"
        $zipPath = Join-Path $VaultDir "$archiveName.zip"
        $encryptedPath = Join-Path $VaultDir "$archiveName.zip.encrypted"
        $keyPath = Join-Path $KeyDir "$archiveName.key"

        Write-Log "Creating archive..." "Yellow"

        # Create ZIP archive
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($FolderPath, $zipPath)

        Write-Log "Encrypting folder..." "Yellow"

        # Generate random password
        $password = New-SecurePassword 64
        [System.IO.File]::WriteAllText($keyPath, $password)

        # Encrypt archive
        if (Protect-FileAES -FilePath $zipPath -Password $password -OutputPath $encryptedPath) {
            Remove-Item $zipPath -Force

            Write-Log "Folder encrypted successfully: $encryptedPath" "Green"
            Write-Log "Key saved to: $keyPath" "Green"

            # Optionally delete original
            $deleteOriginal = Read-Host "Delete original folder? (y/N)"
            if ($deleteOriginal -eq 'y' -or $deleteOriginal -eq 'Y') {
                Remove-Item $FolderPath -Recurse -Force
                Write-Log "Original folder deleted" "Green"
            }
        }
    }
    catch {
        Write-Log "Folder encryption failed: $($_.Exception.Message)" "Red"
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        throw
    }
}

# Decrypt folder
function Unprotect-Folder {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Available encrypted folders:" -ForegroundColor Cyan
        $encryptedFiles = Get-ChildItem -Path $VaultDir -Filter "*.encrypted" -ErrorAction SilentlyContinue

        if ($encryptedFiles.Count -eq 0) {
            Write-Log "No encrypted folders found" "Yellow"
            return
        }

        for ($i = 0; $i -lt $encryptedFiles.Count; $i++) {
            $file = $encryptedFiles[$i]
            $size = [math]::Round($file.Length / 1MB, 2)
            Write-Host "[$($i+1)] $($file.Name) ($size MB) - $($file.LastWriteTime)" -ForegroundColor White
        }

        $choice = Read-Host "Select folder to decrypt (1-$($encryptedFiles.Count))"

        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $encryptedFiles.Count) {
            $selectedFile = $encryptedFiles[[int]$choice - 1]
            $archiveName = $selectedFile.Name -replace '\.zip\.encrypted$', ''
            $keyPath = Join-Path $KeyDir "$archiveName.key"

            if (!(Test-Path $keyPath)) {
                Write-Log "Key file not found: $keyPath" "Red"
                return
            }

            $password = [System.IO.File]::ReadAllText($keyPath)
            $tempZipPath = Join-Path $env:TEMP "$archiveName.zip"

            Write-Log "Decrypting folder..." "Yellow"

            if (Unprotect-FileAES -FilePath $selectedFile.FullName -Password $password -OutputPath $tempZipPath) {
                $extractPath = Read-Host "Enter extraction directory (or press Enter for current)"
                if ([string]::IsNullOrWhiteSpace($extractPath)) {
                    $extractPath = Get-Location
                }

                Write-Log "Extracting archive..." "Yellow"
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZipPath, $extractPath)

                Remove-Item $tempZipPath -Force
                Write-Log "Folder decrypted and extracted to: $extractPath" "Green"
            }
        }
    }
    catch {
        Write-Log "Folder decryption failed: $($_.Exception.Message)" "Red"
        throw
    }
}

# Secure file deletion
function Remove-FileSecure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    try {
        if (!(Test-Path $FilePath)) {
            Write-Log "File not found: $FilePath" "Red"
            return
        }

        Write-Host "WARNING: This will permanently destroy the file!" -ForegroundColor Red
        Write-Host "Target: $FilePath" -ForegroundColor Yellow
        $confirm = Read-Host "Type 'DELETE' to confirm"

        if ($confirm -eq "DELETE") {
            Write-Log "Securely deleting file..." "Yellow"

            # Get file size
            $fileInfo = Get-Item $FilePath
            $fileSize = $fileInfo.Length

            # Overwrite with random data multiple times
            for ($pass = 1; $pass -le 3; $pass++) {
                Write-Log "Overwrite pass $pass/3..." "Cyan"

                $randomBytes = New-Object byte[] $fileSize
                $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
                $rng.GetBytes($randomBytes)
                $rng.Dispose()

                [System.IO.File]::WriteAllBytes($FilePath, $randomBytes)
            }

            # Final delete
            Remove-Item $FilePath -Force
            Write-Log "File securely deleted" "Green"
        }
        else {
            Write-Log "Operation cancelled" "Yellow"
        }
    }
    catch {
        Write-Log "Secure deletion failed: $($_.Exception.Message)" "Red"
        throw
    }
}

# Create encrypted vault
function New-EncryptedVault {
    [CmdletBinding()]
    param()

    try {
        $vaultName = Read-Host "Enter vault name"
        if ([string]::IsNullOrWhiteSpace($vaultName)) {
            Write-Log "Vault name cannot be empty" "Red"
            return
        }

        $vaultPath = Join-Path $VaultDir $vaultName

        if (Test-Path $vaultPath) {
            Write-Log "Vault already exists: $vaultName" "Red"
            return
        }

        New-Item -ItemType Directory -Path $vaultPath -Force | Out-Null

        # Set secure permissions
        $acl = Get-Acl $vaultPath
        $acl.SetAccessRuleProtection($true, $false)
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $vaultPath -AclObject $acl

        # Create vault info file
        $vaultInfo = @{
            Name = $vaultName
            Created = Get-Date
            Description = "Encrypted file vault"
            Warning = "Do not modify this file"
        } | ConvertTo-Json -Compress

        $vaultInfo | Out-File (Join-Path $vaultPath ".vault_info.json")

        Write-Log "Vault created: $vaultPath" "Green"
        Write-Log "You can now add files to encrypt in this vault" "Cyan"
    }
    catch {
        Write-Log "Failed to create vault: $($_.Exception.Message)" "Red"
        throw
    }
}

# List vaults
function Get-EncryptedVaults {
    [CmdletBinding()]
    param()

    try {
        Write-Host "Available Vaults:" -ForegroundColor Cyan
        Write-Host "=================" -ForegroundColor Cyan

        $vaults = Get-ChildItem -Path $VaultDir -Directory -ErrorAction SilentlyContinue

        if ($vaults.Count -eq 0) {
            Write-Host "No vaults found" -ForegroundColor Yellow
            return
        }

        foreach ($vault in $vaults) {
            $fileCount = (Get-ChildItem -Path $vault.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
            $size = (Get-ChildItem -Path $vault.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $sizeStr = if ($size -gt 1MB) { "$([math]::Round($size/1MB, 2)) MB" } else { "$([math]::Round($size/1KB, 2)) KB" }

            Write-Host "📁 $($vault.Name) - $fileCount files ($sizeStr)" -ForegroundColor Green
        }
    }
    catch {
        Write-Log "Failed to list vaults: $($_.Exception.Message)" "Red"
        throw
    }
}

# Show menu
function Show-Menu {
    [CmdletBinding()]
    param()

    try {
        Write-Host "`nEncryption Tools Menu:" -ForegroundColor Green
        Write-Host "======================" -ForegroundColor Green
        Write-Host "[1] Encrypt file (AES)" -ForegroundColor White
        Write-Host "[2] Decrypt file (AES)" -ForegroundColor White
        Write-Host "[3] Encrypt folder" -ForegroundColor White
        Write-Host "[4] Decrypt folder" -ForegroundColor White
        Write-Host "[5] Create encrypted vault" -ForegroundColor White
        Write-Host "[6] List vaults" -ForegroundColor White
        Write-Host "[7] Secure file deletion" -ForegroundColor White
        Write-Host "[8] Generate password" -ForegroundColor White
        Write-Host "[0] Exit" -ForegroundColor White
        Write-Host ""
    }
    catch {
        Write-Log "Failed to show menu: $($_.Exception.Message)" "Red"
        throw
    }
}

# Generate and display password
function Show-GeneratedPassword {
    [CmdletBinding()]
    param()

    try {
        $length = Read-Host "Enter password length (default: 32)"
        if ([string]::IsNullOrWhiteSpace($length)) { $length = 32 }

        if ($length -match '^\d+$' -and [int]$length -ge 8 -and [int]$length -le 128) {
            $password = New-SecurePassword ([int]$length)

            Write-Host "`nGenerated password:" -ForegroundColor Green
            Write-Host $password -ForegroundColor White
            Write-Host "`nPassword strength: $length characters" -ForegroundColor Yellow

            # Optional save to file
            $savePassword = Read-Host "Save password to file? (y/N)"
            if ($savePassword -eq 'y' -or $savePassword -eq 'Y') {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $passwordFile = Join-Path $KeyDir "password_$timestamp.txt"
                $password | Out-File $passwordFile
                Write-Log "Password saved to: $passwordFile" "Green"
            }
        }
        else {
            Write-Log "Invalid length. Use 8-128" "Red"
        }
    }
    catch {
        Write-Log "Failed to generate password: $($_.Exception.Message)" "Red"
        throw
    }
}

# Help function
function Show-Help {
    [CmdletBinding()]
    param()

    try {
        Write-Host @"
Encryption Tools - Windows PowerShell

SYNOPSIS
    File and folder encryption toolkit for Windows

DESCRIPTION
    This tool provides comprehensive encryption capabilities including:
    - AES file encryption/decryption
    - Folder encryption with compression
    - Encrypted vault management
    - Secure file deletion
    - Password generation

PARAMETERS
    -Help          Show this help message
    -EncryptFile   Encrypt a specific file
    -DecryptFile   Decrypt a specific file
    -GenerateKey   Generate encryption key

EXAMPLES
    .\encryption_tools.ps1
    .\encryption_tools.ps1 -EncryptFile "document.txt"
    .\encryption_tools.ps1 -GenerateKey

REQUIREMENTS
    - Windows 10/11 or Windows Server
    - PowerShell 5.0 or later
    - .NET Framework 4.5 or later

ENCRYPTION FEATURES
    - AES-256 encryption
    - PBKDF2 key derivation
    - Secure random key generation
    - ZIP compression for folders
    - Secure file deletion
    - Password generation

SECURITY NOTES
    - Keys are stored with restricted permissions
    - Files are encrypted with salted passwords
    - Multiple overwrite passes for secure deletion
    - Vaults use Windows ACLs for protection

"@
    }
    catch {
        Write-Log "Failed to show help: $($_.Exception.Message)" "Red"
        throw
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

Show-Banner

if ($EncryptFile) {
    if (Test-Path $EncryptFile) {
        $password = Read-Host "Enter encryption password" -AsSecureString
        $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        $outputPath = Join-Path (Split-Path $EncryptFile -Parent) ((Split-Path $EncryptFile -Leaf) + ".encrypted")
        Protect-FileAES -FilePath $EncryptFile -Password $passwordText -OutputPath $outputPath
    } else {
        Write-Log "File not found: $EncryptFile" "Red"
    }
    exit 0
}

if ($DecryptFile) {
    if (Test-Path $DecryptFile) {
        $password = Read-Host "Enter decryption password" -AsSecureString
        $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        $outputPath = $DecryptFile -replace '\.encrypted$', ''
        Unprotect-FileAES -FilePath $DecryptFile -Password $passwordText -OutputPath $outputPath
    } else {
        Write-Log "File not found: $DecryptFile" "Red"
    }
    exit 0
}

if ($GenerateKey) {
    $key = New-EncryptionKey
    Write-Host "Generated encryption key:" -ForegroundColor Green
    Write-Host $key -ForegroundColor White
    exit 0
}

# Main interactive loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Enter your choice (0-8)"
    
    switch ($choice) {
        "1" {
            $filePath = Read-Host "Enter file path to encrypt"
            if (Test-Path $filePath) {
                $password = Read-Host "Enter encryption password" -AsSecureString
                $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
                $outputPath = Join-Path (Split-Path $filePath -Parent) ((Split-Path $filePath -Leaf) + ".encrypted")
                Protect-FileAES -FilePath $filePath -Password $passwordText -OutputPath $outputPath
            } else {
                Write-Log "File not found: $filePath" "Red"
            }
            Read-Host "Press Enter to continue"
        }
        "2" {
            $filePath = Read-Host "Enter encrypted file path"
            if (Test-Path $filePath) {
                $password = Read-Host "Enter decryption password" -AsSecureString
                $passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
                $outputPath = $filePath -replace '\.encrypted$', ''
                Unprotect-FileAES -FilePath $filePath -Password $passwordText -OutputPath $outputPath
            } else {
                Write-Log "File not found: $filePath" "Red"
            }
            Read-Host "Press Enter to continue"
        }
        "3" {
            $folderPath = Read-Host "Enter folder path to encrypt"
            Protect-Folder -FolderPath $folderPath
            Read-Host "Press Enter to continue"
        }
        "4" {
            Unprotect-Folder
            Read-Host "Press Enter to continue"
        }
        "5" {
            New-EncryptedVault
            Read-Host "Press Enter to continue"
        }
        "6" {
            Get-EncryptedVaults
            Read-Host "Press Enter to continue"
        }
        "7" {
            $filePath = Read-Host "Enter file path to securely delete"
            Remove-FileSecure -FilePath $filePath
            Read-Host "Press Enter to continue"
        }
        "8" {
            Show-GeneratedPassword
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
